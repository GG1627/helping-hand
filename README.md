# Helping Hand

Helping Hand is a wearable-assisted ASL learning project built around an ESP32 glove and a Flutter app.  
The system currently demonstrates a full sensor-to-app path: embedded IMU capture, BLE transport, and live visualization on mobile.

Repository: https://github.com/GG1627/helping-hand

## Project goals

- Build a practical ASL learning workflow that combines wearable sensing and guided mobile practice.
- Capture motion/sensor signals from glove hardware.
- Process and transmit device data in real time.
- Present learner progress and live sensor state in a clean, modular app.
- Evolve toward cloud-backed persistence and ML-assisted sign classification.

## Repository layout

- `ESP32/`  
  PlatformIO firmware for Adafruit Feather ESP32-S3, including BLE runtime and IMU integration.

- `flutter_app/`  
  Flutter app with modular tab-based UI and BLE client functionality.

- `backend/`  
  Data generation + ML experimentation (training notebooks and model artifacts).

- `research/`
  Project research sources, hardware documents, and the word-level IMU/ASL recognition summary.

- `embedded/`  
  Additional embedded prototyping area.

## System architecture

### 1) Embedded runtime (`ESP32/src/main.cpp`)

- Board target: `adafruit_feather_esp32s3`
- I2C sensor bus initialized from board-defined pins (`SDA=GPIO3`, `SCL=GPIO4`).
- IMU discovery attempts addresses `0x68` and `0x69`.
- Runtime reads raw accel/gyro registers and converts to engineering units.
- BLE service advertises as `HelpingHand-Glove`.
- Sensor packets are sent as BLE notifications.

Resilience behavior:
- retries IMU discovery if not found at boot
- recovers when IMU appears later (hot-plug flow)
- restarts advertising after client disconnect

### 2) Mobile runtime (`flutter_app/lib/`)

- App shell is split into independent screens/tabs:
  - Start screen
  - Dashboard
  - Alphabet
  - Numbers
  - Record Signs
  - BLE Testing
- A shell-owned BLE service handles:
  - adapter state monitoring
  - permission checks
  - scan/connect/disconnect
  - characteristic discovery and notify subscription
  - shared packet parsing and live metric updates for both BLE-facing tabs
- Record Signs captures labeled word trials, saves app-private CSV/JSON session
  files, and opens the platform share sheet for export.
- Basic Firebase persistence path is integrated for app-side data flow.

### 3) Data + ML workspace (`backend/`)

- Synthetic ASL data generation script
- Word-sequence CSV validation, quality reporting, resampling/window foundations,
  and deterministic test-only sequence fixtures
- Configurable, currently untrained TCN, CNN-GRU, and CNN-LSTM candidates with
  deterministic split manifests, train-only standardization, evaluation
  reports, and float-TFLite compatibility checks
- Training notebooks
- Saved model artifacts:
  - `backend/models/asl_model.keras`
  - `backend/models/asl_model.tflite`
  - `backend/models/scaler_params.json`

## BLE protocol details

BLE transport uses Nordic UART-style UUIDs shared by firmware and app:

- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- RX (app -> ESP32): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (ESP32 -> app notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

The firmware's recording stream defaults to 40 Hz. Set the compile-time
`HH_SENSOR_RATE_HZ` build flag to an integer from 25 through 50 to test another
target. Forty hertz is a configured target, not a measured phone-side delivery
claim; packet rate, loss, ordering, and notification length must be verified on
the target phone.

Packet format (legacy fields remain present):

```text
seq=...,t_ms=...,who=0xNN,ax=...,ay=...,az=...,gx=...,gy=...,gz=...,
expected=...,pred=...,pred_conf=...,
flex0_raw=...,flex0_norm=...,...,flex4_raw=...,flex4_norm=...
```

Example:

```text
seq=42,t_ms=1050,who=0x70,ax=0.020,ay=0.008,az=1.029,gx=-5.947,gy=1.435,gz=-0.260,...
```

`seq` is a monotonically increasing sample ID and `t_ms` is monotonic device
uptime in milliseconds. The app also stores a phone receive timestamp. A
`WHO_AM_I` value of `0x70` is compatible with MPU-6500/MPU-9250-class hardware
but does not confirm that a magnetometer exists or is usable.

## Current implementation status

Working:
- ESP32 BLE advertising and live IMU packet transmission
- BLE receive verification on phone tools (nRF Connect)
- Flutter BLE screen parsing + live value display
- Word recording UI and local CSV/JSON export implementation (physical-device
  validation still required)
- Backend word-recording schema validator and deterministic preprocessing tests
- Untrained word-model architecture/training/evaluation code; all three
  candidates pass shape and built-in-only float-TFLite smoke tests
- Modular Flutter app structure and progress UI flow
- Basic Firebase-backed persistence path connected

In progress:
- Flex sensor hardware integration (sensors not available before current build cutoff)
- Sign classification runtime integration with embedded/mobile flow
- Physical validation of the 40 Hz recording stream, long BLE notifications,
  packet loss/order, and mobile share destinations
- Additional data integrity controls (packet checksum/CRC, stronger validation)

## Setup and run

## ESP32 firmware

```bash
cd ESP32
python -m platformio run --target upload
python -m platformio device monitor --baud 115200
```

Expected runtime output:
- `BLE ready and advertising`
- continuous sensor packets beginning with `seq=...,t_ms=...,who=...`

To change the collection target or enable the diagnostic-only AK8963 probe, add
the applicable build flag under `build_flags` in `ESP32/platformio.ini`:

```text
-D HH_SENSOR_RATE_HZ=25
-D HH_ENABLE_AK8963_PROBE=1
```

The magnetometer probe reads only the MPU-9250-style AK8963 identity register,
prints the result, and returns to accel/gyro-only runtime. It does not enable
magnetometer streaming or establish final hardware capability.

## Flutter app

```bash
cd flutter_app
flutter pub get
flutter run
```

Saved trials use the `word-sequence-v1` contract described in
`backend/data/README.md`. Validate an exported session from the repository root:

```bash
python backend/prepare_word_sequences.py path/to/trials.csv
```

The model-development commands are present for use after a vocabulary and real
dataset version are approved:

```bash
python backend/train_word_models.py --help
python backend/evaluate_word_models.py --help
```

No word model has been trained on real data or selected, and no fixture-trained
artifact is retained. Synthetic fixture execution requires an explicit opt-in
and its reports are marked as non-reportable software smoke results. See
`backend/data/README.md` and `backend/models/README.md` for the contracts and
artifact layout.

## Hardware and platform notes

- BLE testing should be done on real hardware.
- Android emulator BLE scanning is not representative for real-device discovery.
- iOS deployment requires Apple signing and a macOS build path (local Mac or cloud Mac workflow).

## Testing and debugging workflow

Run the backend validator, split, evaluation, architecture, and float-TFLite
smoke tests with:

```bash
python -m pytest backend/tests -q
```

Primary validation flow used:
- verify ESP32 serial stream
- verify BLE advertisement + notify with nRF Connect
- verify Flutter app scan/connect/parse/render on physical Android device

Deep IMU bring-up diagnostics were developed during integration and preserved for reproducibility:
- `ESP32/docs/main_diagnostics_reference.cpp`
- `ESP32/docs/imu_bringup_diagnostics.md`

These diagnostics include:
- I2C scans and address probing
- register reads and sensor profiling
- line-state checks
- bus recovery experiments
- failure logs and recovery outcomes

## Known limitations

- Packet-level integrity checks (CRC/checksum) are not yet enabled.
- Full production cloud data model is still evolving.
- Flex-sensor-dependent features remain pending hardware availability.
- The first immutable word vocabulary and real dynamic-sign dataset are not yet
  available. Synthetic word sequences are test fixtures only.
- Word-model code exists, but no word candidate has been trained on real data,
  benchmarked, quantized, selected, or deployed.

## Key files

- Firmware runtime: `ESP32/src/main.cpp`
- Firmware diagnostics archive: `ESP32/docs/main_diagnostics_reference.cpp`
- Firmware diagnostics notes: `ESP32/docs/imu_bringup_diagnostics.md`
- Flutter BLE screen: `flutter_app/lib/screens/tabs/ble_testing_tab.dart`
- Flutter recording screen: `flutter_app/lib/screens/tabs/record_signs_tab.dart`
- Word data contract: `backend/data/README.md`
- Word model builders: `backend/word_models.py`
- Word training/evaluation: `backend/train_word_models.py`,
  `backend/evaluate_word_models.py`
- Word model artifact policy: `backend/models/README.md`
- Collection protocol: `docs/word_data_collection_protocol.md`
- Flutter app shell: `flutter_app/lib/screens/main_shell.dart`
- Flutter start screen: `flutter_app/lib/screens/start_screen.dart`
- ML training notebook: `backend/asl_train.ipynb`
- Word-level recognition research: `research/IMU_WORD_LEVEL_ASL_RESEARCH.md`
