#pragma once

#include "sensor_types.h"
#include "classifier.h"

// App requests MTU 512: reserve three ATT bytes and one C-string terminator.
constexpr size_t kTelemetryCapacity = 510;

// Preserves the Flutter comma-separated telemetry protocol.
// Returns false (and clears payload) instead of emitting a truncated packet.
bool formatTelemetry(char* payload, size_t capacity, uint64_t packetSequence,
                     uint64_t deviceTimestampMs, uint8_t imuWhoAmI,
                     const ImuSample& sample, bool imuSampleOk,
                     const FlexReadings& flex, const char* expectedLabel,
                     const FlexPrediction& prediction,
                     bool predictionOk, const MagneticSample& magnetic,
                     bool magneticOk);
