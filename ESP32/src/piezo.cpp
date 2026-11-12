#include "piezo.h"
#include "firmware_config.h"

namespace {
bool initialized = false;
int activePin = -1;
uint32_t startedMs = 0;
uint32_t pulseDurationMs = 0;

constexpr bool avoidsFlex(int pin, size_t index = 0) {
  return index == FLEX_SENSOR_COUNT ||
         (pin != FLEX_SENSOR_PINS[index] && avoidsFlex(pin, index + 1));
}
constexpr bool isUnique(size_t index, size_t previous = 0) {
  return previous == index ||
         (PIEZO_PINS[index] != PIEZO_PINS[previous] && isUnique(index, previous + 1));
}
constexpr bool pinsAreAvailable(size_t index = 0) {
  return index == PIEZO_COUNT ||
         (PIEZO_PINS[index] != I2C_SDA_PIN && PIEZO_PINS[index] != I2C_SCL_PIN &&
          avoidsFlex(PIEZO_PINS[index]) && isUnique(index) && pinsAreAvailable(index + 1));
}
static_assert(pinsAreAvailable(), "Piezo outputs conflict with sensor pins or each other.");
static_assert(static_cast<size_t>(Piezo::Count) == PIEZO_COUNT, "Piezo pin count mismatch.");
}

void stopPiezos() {
  if (activePin < 0) return;
  ledcWrite(kPiezoLedcChannel, 0);
  ledcDetachPin(activePin);
  digitalWrite(activePin, LOW);
  pinMode(activePin, OUTPUT);
  activePin = -1;
}

void setupPiezos() {
  stopPiezos();
  for (size_t i = 0; i < PIEZO_COUNT; ++i) {
    digitalWrite(PIEZO_PINS[i], LOW);
    pinMode(PIEZO_PINS[i], OUTPUT);
  }
  initialized = true;
}

bool startPiezo(Piezo output, uint32_t frequencyHz, uint32_t durationMs) {
  const size_t index = static_cast<size_t>(output);
  if (!initialized || activePin >= 0 || index >= PIEZO_COUNT ||
      frequencyHz < 20 || frequencyHz > 20000 || durationMs == 0 ||
      durationMs > kPiezoMaxDurationMs) return false;

  if (ledcSetup(kPiezoLedcChannel, frequencyHz, kPiezoResolutionBits) == 0) return false;
  ledcWrite(kPiezoLedcChannel, 0);
  activePin = PIEZO_PINS[index];
  ledcAttachPin(activePin, kPiezoLedcChannel);
  startedMs = millis();
  pulseDurationMs = durationMs;
  ledcWrite(kPiezoLedcChannel, 1U << (kPiezoResolutionBits - 1));
  return true;
}

void updatePiezos() {
  if (activePin >= 0 && static_cast<uint32_t>(millis() - startedMs) >= pulseDurationMs) {
    stopPiezos();
  }
}

