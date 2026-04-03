#include <Arduino.h>
#include <BLEDevice.h>

void setup() {
  Serial.begin(115200);
  
  // Wait for USB-CDC serial to actually connect
  while (!Serial) delay(10);
  delay(500);

  Serial.println("=== HelpingHand Boot Check ===");
  Serial.println("CPU Freq: " + String(getCpuFrequencyMhz()) + " MHz");
  Serial.println("Free Heap: " + String(ESP.getFreeHeap()) + " bytes");

  Serial.println("\nInitializing BLE...");
  BLEDevice::init("HelpingHand-Glove");
  
  Serial.println("BLE Name: " + String(BLEDevice::toString().c_str()));
  Serial.println("BLE MAC: " + String(BLEDevice::getAddress().toString().c_str()));
  Serial.println("\nESP32 is ON and BLE is UP!");
}

void loop() {
  Serial.println("ESP32 is running...");
  delay(5000); // Check every 5 seconds
  // nothing needed for this check
}