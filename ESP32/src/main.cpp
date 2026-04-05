#include <Arduino.h>
#include <BLEDevice.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

Adafruit_MPU6050 mpu;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  delay(2000);

  Serial.println("\n=== HelpingHand Boot Sequence ===");

  // --- The MPU6050 Un-Sticker (Hard Power Cycle) ---
  #if defined(PIN_I2C_POWER)
    Serial.println("Power cycling I2C bus to clear locked sensors...");
    pinMode(PIN_I2C_POWER, OUTPUT);
    digitalWrite(PIN_I2C_POWER, LOW);  // Kill power
    delay(500);                        // Drain capacitors
    digitalWrite(PIN_I2C_POWER, HIGH); // Restore power
    delay(100);                        // Allow boot up
  #endif
  // -------------------------------------------------

  // Initialize MPU6050
  Serial.println("Initializing MPU6050...");
  if (!mpu.begin()) {
    Serial.println("FAILED! MPU6050 not found. Check physical wiring.");
    while (1) {
      delay(10); // Halt here if it fails
    }
  }
  Serial.println("MPU6050 Connected Successfully!");

  // Set sensor ranges
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  // Initialize BLE
  Serial.println("\nInitializing BLE...");
  BLEDevice::init("HelpingHand-Glove");
  Serial.println("BLE MAC: " + String(BLEDevice::getAddress().toString().c_str()));
  Serial.println("ESP32 is ON and BLE is UP!\n");
  Serial.println("---------------------------------");
}

void loop() {
  /* Get new sensor events with the readings */
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  /* Print out the values */
  Serial.printf("Accel [m/s^2]: X=%.2f  Y=%.2f  Z=%.2f\n", a.acceleration.x, a.acceleration.y, a.acceleration.z);
  Serial.printf("Gyro  [rad/s]: X=%.2f  Y=%.2f  Z=%.2f\n", g.gyro.x, g.gyro.y, g.gyro.z);
  Serial.println("---");
  
  delay(500);
}