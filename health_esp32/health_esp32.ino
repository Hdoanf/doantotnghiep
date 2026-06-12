#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

MAX30105 particleSensor;

const byte RATE_SIZE = 1;
float rates[RATE_SIZE];
byte rateSpot = 0;
byte rateCount = 0;
long lastBeat = 0;
float beatsPerMinute = 0;
float bpmEma = 0.0f;
float bpmOutStable = 0.0f;
float dynamicThreshold = 1200.0f; // kept for debug visibility

BLECharacteristic *pCharacteristic = nullptr;
bool deviceConnected = false;
bool sensorReady = false;
unsigned long lastSerialLogMs = 0;
unsigned long lastNotifyMs = 0;
unsigned long lastBlinkMs = 0;
unsigned long lastFingerMs = 0;

#define LED_PIN 2
#define SERVICE_UUID        "19b10000-e8f2-537e-4f6c-d104768a1214"
#define CHARACTERISTIC_UUID "19b10001-e8f2-537e-4f6c-d104768a1214"

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    (void)pServer;
    deviceConnected = true;
    Serial.println("BLE connected");
  }

  void onDisconnect(BLEServer *pServer) override {
    (void)pServer;
    deviceConnected = false;
    Serial.println("BLE disconnected -> restart advertising");
    BLEDevice::startAdvertising();
  }
};

static void setupBle() {
  BLEDevice::init("HF_health");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE advertising started: HF_health");
}

static void setupSensor() {
  Wire.begin(8, 9);
  Wire.setClock(100000);
  delay(50);

  bool found = false;
  for (int i = 0; i < 5; i++) {
    if (particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
      found = true;
      break;
    }
    delay(120);
  }

  if (!found) {
    sensorReady = false;
    Serial.println("MAX3010x not found, continue BLE-only mode");
    return;
  }

  // Heart-rate profile tuned for MAX3010x + finger placement
  byte ledBrightness = 0x1F;
  byte sampleAverage = 4;
  byte ledMode = 2;      // Red + IR
  int sampleRate = 100;  // Hz
  int pulseWidth = 411;  // us
  int adcRange = 4096;
  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  particleSensor.setPulseAmplitudeRed(0x1F);
  particleSensor.setPulseAmplitudeIR(0x1F);
  particleSensor.setPulseAmplitudeGreen(0);
  sensorReady = true;
  Serial.println("MAX3010x ready");
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  setCpuFrequencyMhz(160);
  Serial.begin(115200);
  delay(200);

  setupSensor();
  setupBle();
}

void loop() {
  long irValue = sensorReady ? particleSensor.getIR() : 0;
  bool fingerPresent = sensorReady && irValue > 15000;
  if (fingerPresent) lastFingerMs = millis();

  if (fingerPresent) {
    bool beat = checkForBeat(irValue);
    if (beat) {
      long now = millis();
      long delta = now - lastBeat;
      if (lastBeat > 0 && delta > 260 && delta < 1800) {
        float correctedDelta = (float)delta;
        if (bpmOutStable > 0.0f) {
          float expectedIbi = 60000.0f / bpmOutStable;
          // If one beat is likely missed, compensate to avoid false BPM drop.
          if (correctedDelta > 1.55f * expectedIbi && correctedDelta < 2.5f * expectedIbi) {
            correctedDelta *= 0.5f;
          }
        }

        beatsPerMinute = 60000.0f / correctedDelta;
        if (beatsPerMinute >= 45.0f && beatsPerMinute <= 180.0f) {
          // Faster response: strongly prioritize newest beat.
          bpmEma = (bpmEma <= 0.0f) ? beatsPerMinute : (0.20f * bpmEma + 0.80f * beatsPerMinute);
          rates[rateSpot++] = bpmEma;
          rateSpot %= RATE_SIZE;
          if (rateCount < RATE_SIZE) rateCount++;
          float sum = 0.0f;
          for (byte i = 0; i < rateCount; i++) sum += rates[i];
          bpmOutStable = sum / rateCount;
          Serial.print("BEAT rawBpm=");
          Serial.print(beatsPerMinute, 1);
          Serial.print(" stable=");
          Serial.print(bpmOutStable, 1);
          Serial.print(" ibiMs=");
          Serial.println(correctedDelta, 1);
        }
      }
      lastBeat = now;
    }
  } else {
    rateCount = 0;
    bpmEma = 0.0f;
    bpmOutStable = 0.0f;
    lastBeat = 0;
    dynamicThreshold = 1200.0f;
  }

  float finalBpm = 0.0f;
  if (fingerPresent && rateCount > 0) {
    finalBpm = bpmOutStable;
  } else if (millis() - lastFingerMs < 1200 && bpmOutStable > 0.0f) {
    // avoid instant drop when finger briefly shifts
    finalBpm = bpmOutStable;
  }

  if (millis() - lastSerialLogMs >= 500) {
    lastSerialLogMs = millis();
    Serial.print("sensorReady=");
    Serial.print(sensorReady ? "1" : "0");
    Serial.print(" connected=");
    Serial.print(deviceConnected ? "1" : "0");
    Serial.print(" ir=");
    Serial.print(irValue);
    Serial.print(" bpmStable=");
    Serial.print(bpmOutStable, 1);
    Serial.print(" thr=");
    Serial.print(dynamicThreshold, 1);
    Serial.print(" bpmOut=");
    Serial.println(finalBpm, 1);
  }

  if (deviceConnected && millis() - lastNotifyMs >= 1000) {
    lastNotifyMs = millis();
    String payload = "{\"bpm\":" + String(finalBpm, 1) +
                     ",\"spo2\":0"
                     ",\"sys\":0"
                     ",\"dia\":0"
                     ",\"raw\":" + String(irValue) + "}";
    pCharacteristic->setValue(payload.c_str());
    pCharacteristic->notify();
  }

  if (deviceConnected) {
    digitalWrite(LED_PIN, LOW);
  } else if (millis() - lastBlinkMs >= 300) {
    lastBlinkMs = millis();
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
  }
}
