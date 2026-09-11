# Word-sequence data contract

The legacy `asl_synthetic.csv` is the static 36-class MLP baseline and remains
separate from this word-sequence contract. Do not append dynamic trials to it or
replace it with word fixtures.

## Storage and data handling

The intended working layout is:

```text
backend/data/
  raw/<session_id>/trials.csv + manifest.json
  processed/<data_version>/...
  splits/<data_version>/...
```

`raw/`, `processed/`, and `splits/` are ignored by Git. Store consented exports
in a team-approved restricted backup location. Participant IDs must be
pseudonymous (`signer_01`), and names/emails must not appear in labels, IDs,
paths, packets, or manifests.

## CSV schema: `word-sequence-v1`

The CSV contains one row per received BLE notification. Metadata repeats on
each row so the file stays self-describing. Column order is fixed for exports,
although the backend loader validates by column name.

| Column | Type / unit | Meaning |
| --- | --- | --- |
| `schema_version` | string | Exactly `word-sequence-v1`. |
| `session_id` | string | App-created collection session ID. |
| `trial_id` | string | Unique saved trial ID within the session. |
| `sample_index` | integer | Zero-based, contiguous receive order within a trial. |
| `device_sequence` | integer | Firmware sequence number; strictly increasing within a trial. |
| `device_timestamp_ms` | integer ms | Monotonic device time since boot from `t_ms`. |
| `receive_timestamp_ms` | integer ms | Phone receive time as UTC Unix epoch milliseconds. |
| `word` | string | Lowercase snake_case word label. |
| `vocabulary_version` | string | Immutable vocabulary ID once D1 is approved; currently `words-draft` for pilots. |
| `signer_id` | string | Pseudonymous ID beginning with `signer_`. |
| `orientation_condition` | enum | `neutral`, `pitch_up`, `roll_left`, or `yaw_right`. |
| `who` | hex string | IMU `WHO_AM_I`, formatted `0xNN`; it is not proof of a magnetometer. |
| `ax`, `ay`, `az` | finite float, g | Accelerometer axes as streamed by firmware. |
| `gx`, `gy`, `gz` | finite float, degrees/s | Gyroscope axes as streamed by firmware. |
| `flex_thumb_raw` … `flex_pinky_raw` | integer ADC | Five authoritative raw 12-bit flex readings. |
| `raw_packet` | string | Exact decoded BLE notification before parsing; CSV quoting preserves commas. |
| `packet_valid` | boolean | True only when all required recording fields parsed successfully. |

Malformed notifications are retained with `raw_packet`, `packet_valid=false`,
and blank unavailable parsed fields. The validator reports those blanks as
quality errors rather than silently inventing values.

Firmware also preserves the legacy `expected`, `pred`, `pred_conf`, and
normalized flex fields in the BLE packet so the static classifier remains
usable. Those derived/static diagnostic values are preserved inside
`raw_packet`; raw flex and the six IMU fields are the word schema inputs.

## Manifest

`manifest.json` contains the schema/session ID, `data_origin`, app version,
configured target rate, observed `who` values, vocabulary/version, saved-trial
summaries, discarded-trial reasons, total/valid counts, and an explicit
magnetometer-data flag. App exports set `data_origin=real`; deterministic test
fixtures set `data_origin=synthetic_fixture` and
`accuracy_reporting_allowed=false`.

The current 40 Hz value is a firmware/app target, not a measured guarantee.
Validate packet delivery on each target phone. `WHO_AM_I=0x70` is compatible
with MPU-6500/MPU-9250-class devices but does not identify an accessible
magnetometer.

## Validation and preprocessing preview

From the repository root:

```text
python backend/prepare_word_sequences.py exported/session/trials.csv
python backend/prepare_word_sequences.py exported/session/trials.csv \
  --vocabulary path/to/words-v1.txt --target-rate-hz 40 \
  --window-samples 128 --report-json quality-report.json
```

The loader checks required columns, finite numerics, schema/label/orientation
validity, trial metadata consistency, packet counts, contiguous sample indexes,
monotonic timestamps/device sequences, sequence gaps, delivered rate, and
sensor ranges. It flags suspicious input and does not repair the raw export.

`resample_trial` uses the device clock and linear interpolation. `fixed_window`
center-trims long complete trials and edge-pads short trials, recording trim/pad
counts. `word_dataset.py` keeps trials indivisible, creates deterministic
user-dependent or signer-held-out split manifests, and fits per-feature
standardization on the training split only. Session-specific flex calibration
and activity-boundary selection still require pilot data.

## Untrained model pipeline

The model contract starts with a float tensor shaped
`[batch, window_samples, feature_count]`. The current raw feature order is the
11 fields in `FEATURE_COLUMNS`; both the window length and feature count remain
configurable because real delivery rate, sign duration, and orientation features
have not been finalized.

`word_models.py` defines three candidates:

- a small dilated 1D temporal CNN (`tcn`);
- a convolutional front end followed by a GRU (`cnn_gru`);
- the same front end followed by an LSTM (`cnn_lstm`).

`train_word_models.py` gives all selected candidates the same split manifest,
vocabulary order, training-only standardizer, random seed, and training policy.
It refuses invalid recordings, mixed real/synthetic origins, real data without
an explicit vocabulary, empty splits, missing training classes, and an existing
output directory. A future real-data run will follow this form after the values
are approved:

```text
python backend/train_word_models.py session_a/trials.csv session_b/trials.csv \
  --vocabulary path/to/words-v1.txt --data-version words-real-v1 \
  --output-directory backend/models/word_runs/words-real-v1 \
  --window-samples <approved-value> --target-rate-hz <measured-value>
```

Each run directory records the Keras and float TFLite artifacts, model
configuration, feature order, vocabulary, standardizer, source hashes, split
manifest, training history, and validation/test JSON. Evaluation includes top-1,
top-5 when at least five labels exist, macro F1, a confusion matrix, and grouped
signer/orientation results. Latency remains `null` until measured on the target
runtime. Quantization remains disabled until representative real data exists.
Reports also keep `final_accuracy_claim_ready=false`; using real data is
necessary but does not replace review of protocol coverage, exclusions, and
split integrity before publishing a final result.

GRU and LSTM graphs use the fixed window unrolled at export so conversion stays
within built-in TFLite operators instead of silently requiring Select TensorFlow
operators. This increases graph size and must be included in the later
same-window model size/latency comparison.

## Synthetic fixtures

Generate deterministic smoke-test data separately:

```text
python backend/generate_word_sequence_fixtures.py .tmp/word-fixture --seed 7
```

Fixtures include still lead/tail behavior, smooth temporal motion, seeded
sensor noise, a deliberate packet gap, and controlled orientation variation.
They are only for automated tests and pipeline/UI smoke checks. Never mix them
into real-data evaluation or cite their behavior as model accuracy.

The training command refuses fixtures unless `--allow-synthetic-smoke` is
provided. Even with that explicit flag, generated reports set
`accuracy_reporting_allowed=false`; no fixture-trained artifact may be selected
for deployment or presented as a recognition result.
