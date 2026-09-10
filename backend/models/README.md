# Model artifacts

The existing `asl_model.keras`, `asl_model.tflite`, and `scaler_params.json`
belong to the legacy static 36-class MLP baseline. They must remain available
and must not be overwritten by word-model experiments.

No retained trained word model exists yet. Future sequence-model runs are
written below the ignored `word_runs/` directory so generated weights and
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
