#include "ble_transport.h"
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <cstring>

using namespace std;

namespace {
// UART
static const char* BLE_DEVICE_NAME = "HelpingHand-Glove";
static const char* BLE_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static const char* BLE_RX_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";  // app -> ESP32
static const char* BLE_TX_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";  // ESP32 -> app

BLECharacteristic* txCharacteristic = nullptr;
bool bleClientConnected = false;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) override {
    bleClientConnected = true;
    Serial.println("BLE client connected");
  }

  void onDisconnect(BLEServer* server) override {
    bleClientConnected = false;
    Serial.println("BLE client disconnected; restarting advertising");
    server->getAdvertising()->start();
  }
};

class RxCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    const string value = characteristic->getValue();
    if (!value.empty()) {
      Serial.print("BLE RX: ");
      Serial.println(value.c_str());
    }
  }
};

}

void setupBle() {
  BLEDevice::init(BLE_DEVICE_NAME);
  BLEDevice::setMTU(517);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* service = server->createService(BLE_SERVICE_UUID);
  txCharacteristic = service->createCharacteristic(
    BLE_TX_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  txCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic* rxCharacteristic = service->createCharacteristic(
    BLE_RX_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  rxCharacteristic->setCallbacks(new RxCallbacks());

  service->start();
  BLEAdvertising* advertising = server->getAdvertising();
  advertising->addServiceUUID(BLE_SERVICE_UUID);
  advertising->start();
}

void sendBlePayload(char* payload) {
  if (bleClientConnected && txCharacteristic != nullptr) {
    txCharacteristic->setValue(reinterpret_cast<uint8_t*>(payload), strlen(payload));
    txCharacteristic->notify();
  }
}
