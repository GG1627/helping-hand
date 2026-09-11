# IMU-Based Word-Level ASL Recognition

## Purpose

The current Helping Hand classifier treats recognition primarily as static pose classification: flex-sensor and IMU values are passed to a TFLite MLP for 36 classes. Word-level American Sign Language recognition is a different problem. A sign is a sequence of sensor measurements, so the system must model temporal motion while remaining reliable when the glove or wrist is held at a different orientation.

This document summarizes research relevant to that transition and records the current architecture recommendation. Reported results below come from different datasets, sensor configurations, and evaluation protocols; they should be used as design evidence rather than as directly comparable performance guarantees.

## Main design problems

1. **Temporal modeling:** A word-level sign contains an ordered motion sequence. The model should receive a fixed-length or streamed time window instead of treating each sample as an independent pose.
2. **Orientation invariance:** The same sign should remain recognizable when wrist pitch, roll, or yaw changes. Orientation normalization should be evaluated as a preprocessing stage, in addition to ordinary data augmentation.

## Temporal-model findings

| Approach | Research finding | Relevance to Helping Hand |
| --- | --- | --- |
| Multi-IMU LSTM/RNN | A wearable system using six IMUs reported an average recognition rate of 99.81% on 27 word-based ASL signs. | Strong evidence that recurrent models can work well for IMU-only word recognition, although the hardware and dataset differ from ours. |
| CNN-GRU | A comparison study reported 94% accuracy for a CNN-GRU with ELU activation, compared with 93% for the standard CNN-GRU and CNN-LSTM configurations. | GRUs use fewer gates than LSTMs and may offer a useful real-time and TFLite efficiency tradeoff. |
| Parallel LSTM-CNN | A 126 g glove using IMU and flex sensors with a 41-dimensional signal used parallel CNN and LSTM branches to learn spatial and temporal features separately. | This is close to our glove design and supports testing a parallel or sequential CNN-recurrent hybrid once enough sequence data is available. |
| TCN, Transformer, CNN-GRU, BiLSTM-Attention, and I3D | The SIGMA-ASL benchmark reported that I3D with STFT preprocessing slightly outperformed CNN-GRU on IMU data for user-independent accuracy: 63.10% versus approximately 62.3%. Top-3 and top-5 accuracy were substantially higher than top-1 across the evaluated models. | Non-recurrent models remain viable, and top-5 accuracy is a meaningful metric for a wearable assistant. User-independent evaluation is substantially harder than user-dependent evaluation. |
| MediaPipe LSTM-GRU | A video-based MediaPipe landmark model reported 94.8% accuracy on INCLUDE-50. | Useful as a general word-level sign-language reference, but not a direct target for our IMU-only system. |

## Orientation-invariance findings

### Quaternion-based normalization

The strongest preprocessing direction is to estimate sensor orientation, express motion relative to the Earth frame, and represent changes between consecutive samples with quaternions. This separates the motion signal from the physical orientation of the sensor and can be placed before a conventional classifier or temporal network.

Quaternions are preferable to Euler angles for chained rotations because they avoid Euler-angle gimbal lock and support efficient rotation composition through quaternion multiplication.

### Related wearable results

- A wrist-worn, orientation-agnostic sensing system used magnetometer-stabilized quaternion fusion with a lightweight 1D CNN and reported macro F1 of 0.91 without per-user calibration.
- TRI-HAR uses per-location equivariant encoding followed by invariant projection for multiple IMUs whose mounting orientations can change independently. This is less directly applicable to a single wrist IMU, but it is a useful methodology if the glove later gains additional IMUs.

### Hardware consideration

The current runtime exposes accelerometer and gyroscope data. A magnetometer-stabilized pipeline may require a sensor that measures the Earth’s magnetic field; a six-axis IMU can estimate gravity-based pitch and roll, but yaw estimation from integrated gyroscope data can drift. Before selecting a final normalization method, the team should verify the installed IMU capabilities and compare:

- Earth-frame acceleration and angular velocity after sensor-fusion orientation estimation
- Relative quaternion rotations between adjacent samples
- Gyroscope-only or six-axis fusion with controlled yaw augmentation when absolute yaw is unavailable

## Current recommendation

The leading candidate pipeline is:

```text
IMU/flex samples
    -> synchronized time windows
    -> calibration and scaling
    -> quaternion-based orientation normalization
    -> temporal feature extraction
    -> CNN + GRU classifier
    -> word probabilities and top-1/top-5 output
```

Use a GRU as the first deployment candidate when model size, latency, and battery use are tight. Compare it with an LSTM when accuracy has priority and the embedded/mobile inference budget allows it. A parallel CNN-LSTM branch is also worth benchmarking because it matches the glove architecture reported in the wearable-system research.

The model should be trained and evaluated on complete sign windows rather than isolated sensor rows. The evaluation should report top-1, top-5, macro F1, latency, and model size. Results should be separated into user-dependent and user-independent splits so that apparent accuracy is not caused by samples from the same signer appearing in both training and testing.

## Suggested experiment sequence

1. Establish a sequence baseline using the existing sensor channels and a small CNN-GRU.
2. Compare CNN-GRU and CNN-LSTM under the same windowing, scaling, and train/test split.
3. Add quaternion-derived features and compare them against raw sensor features.
4. Test controlled wrist-orientation changes and report performance by orientation condition.
5. Measure top-1/top-5 accuracy, macro F1, inference latency, and TFLite size on the intended runtime.
6. Keep the static 36-class MLP as a regression baseline while the word-level sequence pipeline is developed.

## Limitations and interpretation

The cited studies do not use identical sign vocabularies, sensor counts, sampling rates, preprocessing, signer populations, or split strategies. In particular, the 99.81% result should not be treated as an expected Helping Hand accuracy without reproducing comparable conditions. The SIGMA-ASL user-independent benchmark is a more conservative indicator of deployment difficulty, while the MediaPipe result is video-based and is included only for context.

## Sources

The numbered source records are maintained in [`LINKS.md`](LINKS.md).

- Multi-IMU LSTM word-level ASL result: *Recent Advances on Deep Learning for Sign Language Recognition*.
- CNN-GRU/CNN-LSTM comparison: *Efficient spatio-temporal modeling for sign language recognition using CNN and RNN architectures*.
- Wearable IMU/flex glove and Para-LSTM-CNN: *A Wearable System for Recognizing American Sign Language in Real-Time Using IMU and Surface EMG Sensors*.
- Multimodal IMU benchmark: *SIGMA-ASL: Sensor-Integrated Multimodal Dataset for Sign Language Recognition*.
- Video-only comparison: *Word Level Sign Language Recognition Using MediaPipe and LSTM-GRU Network*.
- Quaternion Earth-frame normalization: *Activity Recognition Invariant to Wearable Sensor Unit Orientation Using Differential Rotational Transformations Represented by Quaternions*.
- Quaternion gesture representation: *Quaternion-Based Gesture Recognition Using Wireless Wearable Motion Capture Sensors*.
- Wrist-worn orientation-agnostic sensing: *WristSense: Sensing Hidden Wrist Strain in Routine Activities via Inertial Tokenization and LLM-Based Feedback*.
- Multi-IMU rotation-invariant encoding: *Rotation-Invariant Multi-IMU Activity Recognition under Independent Per-Location Orientation Shifts*.
