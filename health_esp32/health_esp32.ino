#include <Wire.h>
#include "MAX30105.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

MAX30105 particleSensor;
BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

#define LED_PIN 8
#define SERVICE_UUID        "19b10000-e8f2-537e-4f6c-d104768a1214"
#define CHARACTERISTIC_UUID "19b10001-e8f2-537e-4f6c-d104768a1214"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; };
    void onDisconnect(BLEServer* pServer) { 
        deviceConnected = false; 
        BLEDevice::startAdvertising();
    }
};

void setup() {
    pinMode(LED_PIN, OUTPUT);
    setCpuFrequencyMhz(80);
    Wire.begin(5, 4);
    particleSensor.begin(Wire, I2C_SPEED_STANDARD);
    BLEDevice::init("HF_health");
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    BLEDevice::getAdvertising()->addServiceUUID(SERVICE_UUID);
    BLEDevice::startAdvertising();
}

void loop() {
    if (deviceConnected) {
        digitalWrite(LED_PIN, LOW); 

        // Giả lập dữ liệu nhịp tim và huyết áp
        float bpm = 72.0 + random(0, 5);
        int sys = 118 + (int)(bpm/10) + random(0, 3); 
        int dia = 78 + (int)(bpm/20) + random(0, 2);

        // Gói tin gửi mỗi giây (1Hz)
        String payload = "{\"bpm\":" + String(bpm) + ",\"spo2\":98.5,\"sys\":" + String(sys) + ",\"dia\":" + String(dia) + ",\"raw\":" + String(bpm) + "}";
        pCharacteristic->setValue(payload.c_str());
        pCharacteristic->notify();
        
        delay(1000); // Gửi 1 lần mỗi giây theo yêu cầu
    } else {
        digitalWrite(LED_PIN, !digitalRead(LED_PIN));
        delay(500);
    }
}
