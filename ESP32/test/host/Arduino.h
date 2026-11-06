// Minimal board constants for host-only telemetry tests. No hardware emulation.
#pragma once
#include <cstddef>
#include <cstdint>
constexpr int SDA=3, SCL=4, A0=18, A1=17, A2=16, A3=15, A4=14, A5=8;
constexpr int SCK=36, MISO=37, MOSI=35;

// Only the startup test supplies these definitions. Telemetry needs no I/O.
struct HostSerial {
  bool neverConnect = true;
  uint32_t connectsAfterMs = 0;
  explicit operator bool() const;
};
extern HostSerial Serial;
uint32_t millis();
void delay(uint32_t milliseconds);
