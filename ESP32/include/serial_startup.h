#pragma once

#include <Arduino.h>

// Unsigned elapsed time remains valid when millis() wraps.
inline void waitForSerialStartup(uint32_t maximumWaitMs) {
  const uint32_t startedMs = millis();
  while (!Serial && static_cast<uint32_t>(millis() - startedMs) < maximumWaitMs) {
    delay(10);
  }
}
