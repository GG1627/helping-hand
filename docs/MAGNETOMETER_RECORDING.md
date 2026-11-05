# Optional magnetometer recording

Implemented November 5, 2026. This extends acquisition and export; it does not
retrain the static or word models or implement orientation fusion.

For sensor operation, wiring, calibration, sampling/filter limitations, and the
next recognition experiments, see the November 5
[ICM-20948 integration reference](../research/ICM20948_INTEGRATION_REFERENCE.md).

## Data path

The ESP32 reads the AK09916 through the existing ICM-20948 driver. Each telemetry
packet appends either `mag=ok,mx=0.000,my=-12.500,mz=31.200` or
`mag=unavailable`. Values are uncalibrated microteslas in the magnetometer's
native axes. Not-ready, overflow, failed reads, and absent hardware are treated
as unavailable for that packet; no previous sample is substituted.

Flutter retains the exact packet and parses the optional fields independently
of the existing model inputs. Old packets become `not_reported`. An incomplete,
nonfinite, or inconsistent magnetic vector becomes `invalid`, with blank axes.
CSV exports append `mag_status,mx_ut,my_ut,mz_ut` to `word-sequence-v1`.
The JSON manifest records actual magnetic sample counts and calibration/frame
metadata. See [the recording contract](../backend/data/README.md).

The existing static classifier and 11-feature word model remain active. Magnetic
data is preserved for later analysis and model comparisons, not silently added
to the current model tensor. Existing six-axis firmware and recordings remain
supported; old tools that require an exact CSV header may need updating to
ignore the optional columns.

## Deployment and physical checks

Flash the updated firmware and rebuild/install Flutter to record the extension.
Updating only Flutter can still record old firmware, but its magnetic status
will be `not_reported`. Updating only firmware preserves the old app's base
inputs, but that app does not export magnetic columns.

The app requests BLE MTU 512. The formatter limits complete packets to 509 bytes
(plus a string terminator) and drops/logs buffer overflow rather than sending a
truncated record. This does not establish successful MTU negotiation or sustained
delivery on a physical phone. No fragmentation protocol is introduced here.

Physical acceptance checks below are **Not run**:

- Verify ICM/AK identity and bench readings with the hardware owner; confirm
  magnetic axes and units. Calibrate/align before using them as orientation.
- Connect the Fairphone, verify negotiated MTU accommodates the full packet,
  and check sequence continuity and delivery rate at 40 Hz with magnetic data.
- Record/export complete trials and inspect all four magnetic CSV columns and
  JSON counts. Include unavailable samples; confirm their axes are blank.
- Validate the exported CSV using `backend/prepare_word_sequences.py`; check
  magnetic warnings and confirm the original 11-feature pipeline still runs.
- Repeat static and Hello/Please/Yes practice to check the live baseline.

## Software verification (November 5)

- `platformio run`: **Passed** for Feather ESP32-S3. RAM 122,984 bytes
  (37.5%); application flash 1,213,141 bytes (84.1%). Dependency compilation
  emitted warnings; the firmware linked and the binary was produced.
- Targeted Flutter analysis: **Passed**, no issues in the parser, recording
  service, and their test files.
- Flutter packet, recording/export, and sequence preprocessing tests: **16
  passed**. Added checks verify magnetic extensions leave the three recorded
  word-model input tensors unchanged.
- Backend recording/dataset regression: **17 passed**. Covers old CSV files,
  optional magnetic fields, invalid vectors, and unchanged 11-feature inputs.
- Actual C++ telemetry formatter, compiled/run with MSVC on the host: **Passed**.
  The representative magnetic packet was 394 bytes. Checks cover measured zero,
  unavailable/nonfinite data, IMU-offline frames, exact-fit buffers, and rejection
  of truncated output. This length is one test case, not a physical throughput
  measurement.

Reproduce the Flutter checks from `flutter_app/`:

```powershell
flutter test test/ble_packet_test.dart test/recording_service_test.dart test/word_sequence_test.dart
flutter analyze lib/services/ble_packet.dart lib/services/recording_service.dart test/ble_packet_test.dart test/recording_service_test.dart
```

Run backend checks from the repository root with its pytest environment:

```powershell
python -m pytest backend/tests/test_word_data.py backend/tests/test_word_dataset.py -q
```

Run the formatter test from `ESP32/` in an MSVC developer command prompt:

```text
cl /nologo /EHsc /std:c++14 /Itest\host /Iinclude src\telemetry.cpp test\telemetry_host_test.cpp /Fo.pio\build\ /Fe.pio\build\telemetry_host_test.exe
.pio\build\telemetry_host_test.exe
```

Alternatively compile the same two source files with a C++11-or-newer host
compiler and include `test/host` and `include`. Software tests and compilation
do not establish hardware performance.
