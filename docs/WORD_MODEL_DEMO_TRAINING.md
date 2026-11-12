# Recorded word demo model

Training completed October 5, 2026. **Selected candidate: TCN**, exported as
`backend/models/word_runs/demo-real-v1/tcn/model.tflite`. Training and offline
evaluation are complete. Flutter now packages the selected model for complete
word attempts and saved completion; see [the integration record](WORD_DEMO_INTEGRATION.md).
Fresh live glove validation and intended-phone latency measurement: **Not run**.
The static MLP baseline and recorded static demo model remain separate.

## Data and comparison protocol

The source is `backend/recorded_data/trials_1.csv` with `manifest_1.json`:
15 real trials, five each for **hello, please, yes**, totaling 1,770 packets.
The user reports that the demo wearer supplied these recordings. The recorded
`signer_01` through `signer_05` identifiers are retained as metadata; they do not
establish five independent people or a signer-independent evaluation.

Seed 7 assigns three whole trials per word to training, one to validation, and
one to test: **9 / 3 / 3 trials**. No trial is shared between splits. All three
architectures use identical assignments and preprocessing. Model selection was
fixed before training: highest validation top-1 accuracy, then macro F1, then
smallest TFLite file, then lowest desktop median inference latency. Test trials
were evaluated only for the selected model, after selection.

The dataset validator reported zero errors and 15 warnings about repeated phone
receive timestamps. Device timestamps are strictly increasing and provide the
resampling clock; no trials were excluded for those warnings.

## Input and training

- Float32 input shape: `[1, 96, 11]`, representing about 2.4 seconds at 40 Hz.
- Feature order: raw thumb, index, middle, ring, and pinky ADC readings, then
  `ax, ay, az, gx, gy, gz`.
- Linear resampling uses the device clock. Longer trials are center-trimmed;
  shorter trials receive symmetric padding with their edge samples. Some longer
  `yes` recordings therefore contribute only their central motion segment.
- Per-feature mean and standard deviation are fitted on training trials only.
  The static thumb/index calibration is not applied to these raw word inputs.
- Shared settings: 16 convolution filters, 16 recurrent units where applicable,
  16 dense units, dropout 0.25, L2 regularization 0.0001, Adam learning rate
  0.001, batch size 3, maximum 150 epochs, early-stopping patience 20, seed 7.
- Class order: `hello, please, yes`. All recordings are labeled neutral; no
  quaternion fusion or orientation normalization was used.

## Measured results

| Architecture | Validation correct | Macro F1 | TFLite bytes | Desktop median / p95 (ms) | Epochs |
| --- | --- | --- | --- | --- | --- |
| **TCN** | **3 / 3** | **1.00** | **48,324** | 0.0488 / 0.0619 | 150 |
| CNN-GRU | 3 / 3 | 1.00 | 180,212 | 0.0442 / 0.0481 | 123 |
| CNN-LSTM | 3 / 3 | 1.00 | 159,320 | 0.0611 / 0.0894 | 128 |

TCN wins the predetermined size tie-break. CNN-GRU is slightly faster in this
desktop measurement; accuracy does not distinguish the candidates on three
validation trials. All exports use built-in TFLite operators with float weights.
Maximum Keras/TFLite validation probability difference is below `1e-8` for every
candidate.

The selected TCN also classified **3 / 3 reserved test trials** correctly,
with macro F1 **1.00**:

| Test trial | Expected / predicted | Predicted probability |
| --- | --- | --- |
| `word_hello_0008` | hello / hello | 99.85% |
| `word_please_0011` | please / please | 99.95% |
| `word_yes_0005` | yes / yes | 98.81% |

The test confusion matrix is the 3-by-3 identity matrix: one correct example per
class. Top-5 accuracy is not applicable to three classes. These are small
offline results, not proof of reliable live or general ASL recognition.
Desktop latency includes tensor copy, invocation, and output copy with one
TFLite thread, 10 warmups, and 100 measured calls. It excludes BLE, buffering,
preprocessing, and the gesture window; it is not Android latency.

## Artifacts and reproduction

The ignored run directory retains all three Keras/TFLite models, metadata,
training histories, identical split manifests, validation reports, and desktop
latency reports. The root `preparation.json` records source hashes, quality
checks, preprocessing, and scaler statistics. `selection.json` records the
comparison and selected test results. Only TCN has a test report.

Selected TFLite SHA-256:
`7664ceacd04b488fc896b04210490e4c0908d852050ad22ed4dc2b80fe561a8a`.
Focused dataset/trainer/evaluation regression checks: **10 passed**. Artifact
checks confirmed disjoint 9/3/3 assignments, identical scaler/feature/class order
across candidates, the reported file sizes, and test reports only for TCN.

From the repository root, using the project's Python environment:

```powershell
python backend/train_demo_word_models.py --output-directory backend/models/word_runs/demo-real-v2
```

Use a new output directory. Re-running against the same reserved trials after
changing the training protocol is no longer an untouched-test experiment.
`backend/train_word_models.py --defer-test` supports validation-only candidate
training; the demo orchestrator applies this option before freezing selection.

## Integration and live demo work remaining

The chosen TFLite model and scaler/class order are connected to Flutter word
practice using explicit Start attempt / Finish sign boundaries, raw flex fields,
and matching window preparation. Test fresh gestures on the actual wearer,
glove, and phone before choosing the two demo words. The model has no
rest/unknown class, so unrelated motion can still receive a word prediction.
Continuous sliding windows, gesture boundaries, confidence/completion rules,
new wrist orientations, and other wearers have not been validated.

Do not describe the presentation demo as working word recognition until those
integration and live checks have evidence. Slide 6 follow-up remains tracked
in `beta_presentation/CONTENT_REVIEW.md`.
