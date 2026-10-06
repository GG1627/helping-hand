# Model artifacts

The existing `asl_model.keras`, `asl_model.tflite`, and `scaler_params.json`
belong to the legacy static 36-class MLP baseline. They must remain available
and must not be overwritten by word-model experiments.

The recorded word comparison is retained under `word_runs/demo-real-v1/`.
TCN was selected from TCN, CNN-GRU, and CNN-LSTM for `hello`, `please`, and `yes`.
It is packaged in Flutter for complete word attempts and saved completion;
fresh glove/phone validation is Not run. See [the word model record](../../docs/WORD_MODEL_DEMO_TRAINING.md)
for the split, results, preprocessing contract, and evidence limits.
See [the integration record](../../docs/WORD_DEMO_INTEGRATION.md) for the app flow.

Sequence-model runs are written below the ignored `word_runs/` directory so generated weights and
recordings are not accidentally committed:

```text
word_runs/<data-and-run-version>/
  split_manifest.json
  quality_reports.json
  training_summary.json
  tcn/
    model.keras
    model.tflite
    model_metadata.json
    training_history.json
    evaluation_validation.json
    evaluation_test.json
    split_manifest.json
  cnn_gru/
    ...
  cnn_lstm/
    ...
```

The demo comparison also includes root `preparation.json` and `selection.json`.
Its nonselected candidates have validation reports only; the selected TCN was
evaluated on the reserved test trials after selection.

Every deployable word artifact must be paired with its metadata. The metadata
freezes the input shape, feature order, vocabulary order, standardization
statistics, split assignments, source hashes, model configuration, and data
origin. A `.tflite` file without that metadata is incomplete.

Current automated conversion uses float weights and built-in TFLite operators.
It only proves software compatibility. Quantization needs representative real
training data, and latency needs measurement on the intended runtime. Synthetic
fixture reports are always marked `accuracy_reporting_allowed=false`.
All generated reports initially keep `final_accuracy_claim_ready=false` until a
human reviews the real dataset protocol, exclusions, and split integrity.

## Recorded static MLP candidate

The real-recording static demo candidate is retained separately in ignored
`static_runs/recorded-priority-v2/`. It contains `model.keras`, `model.tflite`,
`metadata.json`, `split_manifest.json`, `history.json`, and `demo_readiness.json`.
The generated deployment header at `ESP32/include/recorded_static_model_data.h`
contains the selected model bytes, scaler, class order, and calibration guards.
The original synthetic baseline artifacts above are preserved.

See [the static model record](../../docs/STATIC_MLP_DEMO_MODEL.md) for the source
recordings, priority weighting, whole-trial evaluation, and reproduction steps.
The interrupted `recorded-priority-v1/` directory contains an incomplete save;
it is not a trained/evaluated deployment artifact.
