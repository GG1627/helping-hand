# ESP32 glove firmware

The PlatformIO target is `adafruit_feather_esp32s3`. Public module interfaces
live in `include/`; implementations live in `src/`. PlatformIO automatically
compiles the `.cpp` files in `src/`.

| File | Responsibility |
| --- | --- |
| `src/main.cpp` | Startup order, sampling schedule, sequence numbers, and coordinating each packet |
| `include/firmware_config.h` | Board pins, stream rate, optional magnetometer probe, and ML demo switch |
| `include/sensor_types.h` | Shared IMU and flex readings |
| `src/flex_sensors.cpp` | ADC setup, five flex readings, and ADC normalization |
| `src/imu_sensor.cpp` | I2C setup, discovery, register access, unit conversion, offline recovery, and optional AK8963 probe |
| `src/classifier.cpp` | Recorded-data static TFLite MLP, preserved 36-class baseline, feature scaling, tensor arena, and category predictions |
| `src/ble_transport.cpp` | Nordic UART service, connection callbacks, advertising, and notifications |
| `src/telemetry.cpp` | Formatting online/offline packets for the Flutter parser |
| `src/asl_model_data.h` | Preserved synthetic 36-class baseline model bytes |
| `include/recorded_static_model_data.h` | Generated real-recording model bytes, 34 labels, scaler, and calibration checks |

`setup()` initializes flex sensors, the IMU, the classifier, then BLE.
`loop()` services IMU retries and, at the configured rate, reads flex sensors,
classifies them, reads the IMU, formats a packet, and sends it to Serial and BLE.
IMU failure still allows flex readings and predictions to stream.

Keep sensor acquisition in its sensor module, inference changes in the classifier,
and packet field changes in telemetry. The classifier currently uses five flex
readings, not motion sequences. The original synthetic model remains available
as the regression baseline; the default build now uses the real-recording MLP.

## Configuration and build

From the repository root, with PlatformIO installed:

```sh
pio run -d ESP32
pio run -d ESP32 -t upload
pio device monitor -d ESP32
```

The default stream rate is 40 Hz. Add `-D HH_SENSOR_RATE_HZ=25` (25–50 allowed)
to the existing `build_flags` in `platformio.ini` to change it.
`-D HH_ENABLE_AK8963_PROBE=1` enables the existing one-time diagnostic probe;
it does not enable magnetometer streaming. Set `kUseHardcodedMlTest` in
`include/firmware_config.h` to enable the rotating demo flex vectors.

This module split preserves the existing UUIDs, BLE telemetry field ordering and
precision, model, retry interval, and sampling schedule. After flashing,
check live predictions and telemetry in Flutter, BLE disconnect/reconnect, and
IMU offline/recovery behavior on the glove. Actual throughput and negotiated MTU
still require hardware validation.

## Flex 0 / flex 1 model calibration

Live model inputs use a separate linear calibration for flex 0 and flex 1,
configured in `include/firmware_config.h`:

| Sensor | Measured fully bent bound | Measured straight | Model fully bent | Model straight |
| --- | --- | --- | --- | --- |
| Flex 0 (thumb) | 400 | 515 | 120 | 550 |
| Flex 1 (index) | 400 | 515 | 120 | 550 |

The straight endpoint approximates the supplied glove samples; the bent bound
is the requested 400 for both sensors. Target endpoints match `FLEX_BENT_ADC`
/ `FLEX_STRAIGHT_ADC` in `backend/generate_asl_data.py`. Intermediate readings
map linearly; readings at or below 400 clamp to 120 and readings at or above
515 clamp to 550. These are ADC-equivalent model inputs, not physical readings.
Calibration runs before the existing training mean/scale standardization.
Flex 2–4 pass through unchanged.

Serial lines append `flex0_ml` and `flex1_ml` showing the ADC-equivalent inputs
before standardization. Existing `flexN_raw` and `flexN_norm` fields still show
physical ADC readings and raw/4095 respectively; BLE packets retain their
existing fields so recordings retain the original measurements. BLE packets
also append category predictions as described below.

Set `kUseFlexModelCalibration = false` to restore original model inputs for a
baseline comparison. Hardcoded ML demo vectors automatically bypass calibration
because they already use model-scale values. Re-measure the endpoints if the
glove fit, sensor placement, or wiring changes. The mapping increases sensitivity
to noise and does not establish improved recognition accuracy.

Hardware validation: **Not run**. After upload, check approximately
`flex0_ml=550` / `flex1_ml=550` at raw 515 and approximately `120` at raw 400,
then check intermediate poses and known signs. Readings below 400 all map to
120, so their bend differences are not represented in these model inputs.

## Recorded static demo model

The default build uses the model trained on real static recordings. It includes
all 34 recorded classes (0–9 and A–Y excluding J); J and Z have no training
recordings and are excluded. Recent recordings supply A, B, 1, and 3 with 4x
per-class training weight; the older session supplies the remaining classes.
See [the training/evaluation record](../docs/STATIC_MLP_DEMO_MODEL.md) for the
trial split, measured results, limitations, and reproduction commands.

The generated header packages the TFLite bytes, class order, and training-only
scaler together. Compile-time checks reject calibration changes that would make
live preprocessing disagree with this model. Retrain/export after changing the
calibration. Keep `kUseHardcodedMlTest = false` for the recorded model.

To build the preserved synthetic baseline, add
`-D HH_USE_RECORDED_STATIC_MODEL=0` to the existing `build_flags` in
`platformio.ini`. Remove that flag to return to the recorded model. The original
model header and `backend/models/asl_model.*` artifacts are retained.

One inference produces the global winner (`pred`/`pred_conf`) and the best class
in each category (`pred_letter`/`pred_letter_conf`,
`pred_number`/`pred_number_conf`). Category scores retain their full-model
probabilities; they are not renormalized to increase confidence. Developer BLE
views continue to show the global prediction. Updated learner practice chooses
the corresponding category and keeps the existing confidence and hold rules.
Older firmware's opposite-category prediction is hidden on learner pages.

After flashing, expect `Static model: real recorded MLP (34 classes)` at boot.
Physical inference, BLE delivery, and fresh live recognition: **Not run**.
