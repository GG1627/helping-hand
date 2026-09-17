#pragma once

#include <Arduino.h>

constexpr int I2C_SDA_PIN = SDA;
constexpr int I2C_SCL_PIN = SCL;
constexpr size_t FLEX_SENSOR_COUNT = 5;
constexpr int FLEX_SENSOR_PINS[FLEX_SENSOR_COUNT] = {A0, A1, A2, A3, A4};
// Override with -D HH_SENSOR_RATE_HZ=<25..50> in platformio.ini when testing a
// different collection rate. Forty hertz is the recording default; delivered
// phone-side rate and packet loss still require measurement on physical hardware.
#ifndef HH_SENSOR_RATE_HZ
#define HH_SENSOR_RATE_HZ 40
#endif
static_assert(
  HH_SENSOR_RATE_HZ >= 25 && HH_SENSOR_RATE_HZ <= 50,
  "HH_SENSOR_RATE_HZ must stay within the collection target range (25-50 Hz)."
);
constexpr uint32_t kSensorRateHz = HH_SENSOR_RATE_HZ;
constexpr uint32_t kSensorIntervalUs = 1000000UL / kSensorRateHz;

// Diagnostic only. Enabling this probes the MPU-9250-style AK8963 address and
// WIA register once; it does not enable, stream, or claim magnetometer support.
#ifndef HH_ENABLE_AK8963_PROBE
#define HH_ENABLE_AK8963_PROBE 0
#endif
constexpr bool kUseHardcodedMlTest = false;
