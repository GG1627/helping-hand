# Codex Instructions

Before committing, read and follow /ai-policy/AI-USAGE.md. Use `AI-Assisted: codex` as your trailer identity.

## Project context

Helping Hand is a wearable-assisted American Sign Language learning project.
The system uses an ESP32 glove to capture IMU and flex-sensor data, streams
sensor packets over BLE, and presents the data through a Flutter application.
The current ML baseline is a static 36-class TFLite MLP. The next phase is
dynamic, word-level ASL recognition from sensor sequences.

## Active work: Teach ML Words (#7)

Issue #7 upgrades the ML pipeline from static hand-pose classification to
dynamic word recognition using real-time, five-channel IMU streams. The model
must learn motion and spatial wrist orientation while remaining robust to
pitch, roll, and yaw changes.

The research phase for this work is documented in
`research/IMU_WORD_LEVEL_ASL_RESEARCH.md`. Its current direction is to treat
the sensor data as time windows, evaluate CNN-GRU and CNN-LSTM alternatives,
and test quaternion-based orientation normalization before inference. The
reported research results are not assumed to transfer directly to Helping
Hand because the cited datasets and hardware differ.

## Issue #7 objectives

- Collect and label target ASL word gestures performed at varied wrist angles.
- Build preprocessing that synchronizes, scales, and normalizes the five IMU
  features at each time step.
- Add orientation-invariant features or preprocessing for wrist pitch, roll,
  and yaw variation.
- Expand the target encoding and output layer from static characters to the
  selected ASL word vocabulary.
- Tune dropout and other regularization to reduce signer- and sensor-noise
  overfitting.
- Evaluate top-1 and top-5 accuracy, macro F1, and confusion matrices across
  varied orientations and user-dependent/user-independent splits.
- Export a validated, lightweight TFLite model suitable for low-latency use
  in the Flutter ASL curriculum pipeline.

## Development priorities

Keep the existing static 36-class MLP as a regression baseline while the
sequence model is developed. Track model size, inference latency, and data
split strategy in addition to accuracy. Before implementing quaternion fusion,
confirm the installed IMU capabilities: the current runtime exposes
accelerometer and gyroscope data, while magnetometer-stabilized yaw correction
may require different hardware or a fallback strategy.
