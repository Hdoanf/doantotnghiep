#include <Wire.h>
#include "MAX30105.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

MAX30105 particleSensor;
BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

#define SERVICE_UUID        "19b10000-e8f2-537e-4f6c-d104768a1214"
#define CHARACTERISTIC_UUID "19b10001-e8f2-537e-4f6c-d104768a1214"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; };
    void onDisconnect(BLEServer* pServer) { deviceConnected = false; }
};

void setup() {
    Serial.begin(115200);
    if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
        Serial.println("MAX30102 not found!");
    } else {
        particleSensor.setup(); 
    }

    BLEDevice::init("HealthPulse_ESP32");
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    pServer->getAdvertising()->start();
    Serial.println("Waiting for BLE connection...");
}

void loop() {
    if (deviceConnected) {
        long irValue = particleSensor.getIR();
        
        // Simplified simulated data for demo
        float bpm = (irValue > 10000) ? 72.0 + (millis() % 5) : 0; 
        float spo2 = (irValue > 10000) ? 98.0 + (millis() % 2) : 0;

        String payload = "{\"bpm\":" + String(bpm) + ",\"spo2\":" + String(spo2) + ",\"raw\":" + String(irValue) + "}";
        pCharacteristic->setValue(payload.c_str());
        pCharacteristic->notify();
    }
    delay(50);
}
