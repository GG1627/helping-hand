// Compile this file with src/telemetry.cpp, -Itest/host and -Iinclude.
// Uses the actual formatter; no sensor, BLE, or classifier runtime is simulated.
#include "telemetry.h"
#include <cassert>
#include <cstring>
#include <limits>
#include <cstdio>

int main() {
  ImuSample motion{0.1f, -0.2f, 1.0f, 1.1f, 2.2f, 3.3f};
  MagneticSample magnetic{0.0f, -12.5f, 31.2f};
  FlexReadings flex{};
  for (size_t i = 0; i < FLEX_SENSOR_COUNT; ++i) {
    flex.raw[i] = 4095;
    flex.norm[i] = 1.0f;
  }
  FlexPrediction prediction;
  prediction.overall = ClassPrediction("A", 99.9f);
  prediction.letter = ClassPrediction("A", 99.9f);
  prediction.number = ClassPrediction("1", 0.1f);
  char payload[kTelemetryCapacity];
  auto format = [&](size_t capacity, bool imuOk, bool magOk) {
    return formatTelemetry(payload, capacity, 123456789, 1234567890, 0xEA,
                           motion, imuOk, flex, "-", prediction, true,
                           magnetic, magOk);
  };
  assert(format(sizeof(payload), true, true));
  assert(std::strstr(payload, ",mag=ok,mx=0.000,my=-12.500,mz=31.200"));
  assert(std::strstr(payload, "flex4_raw=4095"));
  assert(std::strstr(payload, "pred_letter=A"));
  const size_t completeLength = std::strlen(payload);
  assert(completeLength <= 509);
  std::printf("Complete magnetic packet: %zu bytes\n", completeLength);
  // Exact fit, then one byte short at the last append; no truncated evidence.
  assert(format(completeLength + 1, true, true));
  assert(!format(completeLength, true, true));
  assert(payload[0] == '\0');
  assert(!format(32, true, true));
  assert(payload[0] == '\0');
  assert(!format(0, true, true));
  assert(format(sizeof(payload), true, false));
  assert(std::strstr(payload, ",mag=unavailable"));
  assert(!std::strstr(payload, ",mx="));
  magnetic.mxUt = std::numeric_limits<float>::quiet_NaN();
  assert(format(sizeof(payload), true, true));
  assert(std::strstr(payload, ",mag=unavailable"));
  assert(format(sizeof(payload), false, false));
  assert(std::strstr(payload, "imu=offline"));
  assert(std::strstr(payload, "flex4_raw=4095"));
  std::puts("PASS: magnetic fields, unavailable/offline, size and overflow handling");
}
