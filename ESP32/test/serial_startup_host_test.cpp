#include "serial_startup.h"
#include <cassert>
#include <cstdio>
#include <limits>

HostSerial Serial;
uint32_t clockMs = 0;
uint32_t elapsedMs = 0;
uint32_t millis() { return clockMs; }
void delay(uint32_t duration) { clockMs += duration; elapsedMs += duration; }
HostSerial::operator bool() const {
  return !neverConnect && elapsedMs >= connectsAfterMs;
}

int main() {
  Serial.neverConnect = true;
  waitForSerialStartup(1500);
  assert(elapsedMs == 1500);  // Execution continues with no USB host.
  elapsedMs = 0;
  Serial.neverConnect = false;
  Serial.connectsAfterMs = 0;
  waitForSerialStartup(1500);
  assert(elapsedMs == 0);
  Serial.connectsAfterMs = 350;
  waitForSerialStartup(1500);
  assert(elapsedMs == 350);
  Serial.neverConnect = true;
  elapsedMs = 0;
  clockMs = std::numeric_limits<uint32_t>::max() - 20;
  waitForSerialStartup(50);
  assert(elapsedMs == 50);
  assert(clockMs == 29);
  elapsedMs = 0;
  waitForSerialStartup(0);
  assert(elapsedMs == 0);
  std::puts("PASS: no host, immediate/delayed host, disabled wait and clock wrap");
}
