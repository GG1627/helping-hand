#pragma once

#include "sensor_types.h"

constexpr size_t kTelemetryCapacity = 512;

// Preserves the Flutter comma-separated telemetry protocol.
void formatTelemetry(char* payload, size_t capacity, uint64_t packetSequence,
                     uint64_t deviceTimestampMs, uint8_t imuWhoAmI,
                     const ImuSample& sample, bool imuSampleOk,
                     const FlexReadings& flex, const char* expectedLabel,
                     const char* predictedLabel, float predictedConfidence,
                     bool predictionOk);
