#pragma once

#include <Arduino.h>

constexpr int I2C_SDA_PIN = SDA;
constexpr int I2C_SCL_PIN = SCL;
constexpr size_t FLEX_SENSOR_COUNT = 5;
constexpr int FLEX_SENSOR_PINS[FLEX_SENSOR_COUNT] = {A0, A1, A2, A3, A4};
// Set to 0 with a build flag to restore the preserved synthetic 36-class model.
#ifndef HH_USE_RECORDED_STATIC_MODEL
#define HH_USE_RECORDED_STATIC_MODEL 1
#endif
// Live glove calibration: requested bent bound 425 and straight bound 625 for all fingers.
// Disable to compare the original static-model baseline. Targets match
// backend/generate_asl_data.py.
constexpr bool kUseFlexModelCalibration = true;
constexpr size_t kCalibratedFlexCount = 5;
constexpr float kFlexMeasuredStraight[kCalibratedFlexCount] = {625.0f, 625.0f, 625.0f, 625.0f, 625.0f};
constexpr float kFlexMeasuredBent[kCalibratedFlexCount] = {425.0f, 425.0f, 425.0f, 425.0f, 425.0f};
constexpr float kFlexModelStraight[kCalibratedFlexCount] = {550.0f, 550.0f, 550.0f, 550.0f, 560.0f};
constexpr float kFlexModelBent[kCalibratedFlexCount] = {120.0f, 120.0f, 120.0f, 120.0f, 80.0f};
static_assert(kCalibratedFlexCount <= FLEX_SENSOR_COUNT, "Too many calibrated flex sensors.");
static_assert(kFlexMeasuredStraight[0] > kFlexMeasuredBent[0] &&
              kFlexMeasuredStraight[1] > kFlexMeasuredBent[1] &&
              kFlexMeasuredStraight[2] > kFlexMeasuredBent[2] &&
              kFlexMeasuredStraight[3] > kFlexMeasuredBent[3] &&
              kFlexMeasuredStraight[4] > kFlexMeasuredBent[4],
              "Flex straight endpoints must exceed bent endpoints.");
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
