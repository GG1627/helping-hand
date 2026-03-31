// Simulated in Wokwi, Work in Progress
/* #include <NimBLEDevice.h>
#include "esp_task_wdt.h" // Modern Watchdog Header

// Temporary IDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

void setup() {
  Serial.begin(115200);
  delay(1000); 
  Serial.println("Initializing HelpingHand Bluetooth...");

  // * Can Remove for Non-Wokwi Workspaces, Only for Preventing Reboots
  esp_task_wdt_config_t twdt_config = {
      .timeout_ms = 30000, // Increase timeout to 30 seconds
      .idle_core_mask = 0, // Don't watch any idle cores
      .trigger_panic = false,
  };
  esp_task_wdt_reconfigure(&twdt_config); 
  * //

  NimBLEDevice::init("HelpingHand-Glove");
  
  NimBLEServer *pServer = NimBLEDevice::createServer();
  NimBLEService *pService = pServer->createService(SERVICE_UUID);

  NimBLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         NIMBLE_PROPERTY::READ |
                                         NIMBLE_PROPERTY::WRITE |
                                         NIMBLE_PROPERTY::NOTIFY
                                       );

  pCharacteristic->setValue("Glove Ready");
  pService->start();

  NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->enableScanResponse(true);
  pAdvertising->start();
  
  Serial.println("BLE Setup Complete! Scanning for App...");
}

void loop() {
  delay(1000);
}
*/
