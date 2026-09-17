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
| `src/classifier.cpp` | Static 36-class TFLite model, feature scaling, tensor arena, inference, and demo inputs |
| `src/ble_transport.cpp` | Nordic UART service, connection callbacks, advertising, and notifications |
| `src/telemetry.cpp` | Formatting online/offline packets for the Flutter parser |
| `src/asl_model_data.h` | Existing embedded model bytes; included only by the classifier |

`setup()` initializes flex sensors, the IMU, the classifier, then BLE.
`loop()` services IMU retries and, at the configured rate, reads flex sensors,
classifies them, reads the IMU, formats a packet, and sends it to Serial and BLE.
IMU failure still allows flex readings and predictions to stream.

Keep sensor acquisition in its sensor module, inference changes in the classifier,
and packet field changes in telemetry. The classifier currently uses five flex
readings, not motion sequences. Its static model remains the regression baseline.

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

This module split preserves the existing UUIDs, telemetry field ordering and
precision, scaling, model, retry interval, and sampling schedule. After flashing,
check live predictions and telemetry in Flutter, BLE disconnect/reconnect, and
IMU offline/recovery behavior on the glove. Actual throughput and negotiated MTU
still require hardware validation.
