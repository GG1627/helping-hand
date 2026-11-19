#include <Arduino.h>

#include "firmware_config.h"
#include "piezo.h"
#include "serial_startup.h"

namespace {
constexpr uint32_t kTestFrequenciesHz[] = {500, 1000, 2000, 2500, 3000, 4000};
constexpr size_t kTestFrequencyCount = sizeof(kTestFrequenciesHz) / sizeof(kTestFrequenciesHz[0]);
constexpr uint32_t kTestDurationMs = 400;
size_t frequencyIndex = 3;  // Start at the original 2500 Hz test frequency.

struct TestOutput {
  char key;
  Piezo output;
  const char* label;
};

constexpr TestOutput kTestOutputs[] = {
    {'1', Piezo::Thumb, "Thumb"},
    {'2', Piezo::Index, "Index"},
    {'3', Piezo::Middle, "Middle"},
    {'4', Piezo::Ring, "Ring"},
    {'5', Piezo::Pinky, "Pinky"},
    {'6', Piezo::HandLeft, "Back of hand left"},
    {'7', Piezo::HandRight, "Back of hand right"},
    {'8', Piezo::HandCenter, "Back of hand center"},
    {'9', Piezo::HandUp, "Back of hand up"},
    {'0', Piezo::HandDown, "Back of hand down"},
};
static_assert(sizeof(kTestOutputs) / sizeof(kTestOutputs[0]) == PIEZO_COUNT,
              "Test menu must cover all piezo outputs.");

void printMenu() {
  Serial.println("\nHelping Hand piezo test");
  Serial.printf("Press a number to play a %lu Hz tone for %lu ms.\n",
                static_cast<unsigned long>(kTestFrequenciesHz[frequencyIndex]),
                static_cast<unsigned long>(kTestDurationMs));
  Serial.println("Press [ or ] to change frequency. Press ? for this menu.");
  for (const TestOutput& output : kTestOutputs) {
    const int pin = PIEZO_PINS[static_cast<size_t>(output.output)];
    Serial.printf("  %c  %s (GPIO %d)\n", output.key, output.label, pin);
  }
}
}

void setup() {
  setupPiezos();
  Serial.begin(115200);
  waitForSerialStartup(kSerialStartupWaitMs);
  printMenu();
}

void loop() {
  updatePiezos();

  const int key = Serial.read();
  if (key < 0) {
    delay(1);
    return;
  }
  if (key == '?') {
    printMenu();
    return;
  }
  if (key == '[' || key == ']') {
    if (key == '[' && frequencyIndex > 0) --frequencyIndex;
    if (key == ']' && frequencyIndex + 1 < kTestFrequencyCount) ++frequencyIndex;
    Serial.printf("Selected %lu Hz for the next tone.\n",
                  static_cast<unsigned long>(kTestFrequenciesHz[frequencyIndex]));
    return;
  }
  for (const TestOutput& output : kTestOutputs) {
    if (key != output.key) continue;

    const int pin = PIEZO_PINS[static_cast<size_t>(output.output)];
    const uint32_t frequencyHz = kTestFrequenciesHz[frequencyIndex];
    if (startPiezo(output.output, frequencyHz, kTestDurationMs)) {
      Serial.printf("Tone started on %s (GPIO %d) at %lu Hz. Verify sound and feel.\n",
                    output.label, pin, static_cast<unsigned long>(frequencyHz));
    } else {
      Serial.printf("Could not start %s (GPIO %d). Wait a second and retry.\n", output.label, pin);
    }
    return;
  }
}
