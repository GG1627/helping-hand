# Presentation sources

## Slide 2: parental hearing status

- Source: NIH, National Institute on Deafness and Other Communication Disorders (NIDCD), [Quick Statistics About Hearing, Balance, & Dizziness](https://www.nidcd.nih.gov/health/statistics/quick-statistics-hearing).
- Checked: October 5, 2026. Page last updated September 20, 2024.
- Slide figure: greater than 90%; the population is deaf children born to hearing parents.
- NIDCD's underlying citation: Mitchell, R. E., and Karchmer, M. A. (2004), *Chasing the mythical ten percent: Parental hearing status of deaf and hard of hearing students in the United States*, Sign Language Studies 4(2), 138–163.
- Interpretation: background context for accessible ASL learning; not a 2026 measurement, an estimate of ASL proficiency, or a result from Helping Hand.
- The earlier deck's 500,000+ U.S. signer estimate is not used here.

## Slide 6: selected TCN and comparison results

- `../backend/word_models.py` and `../flutter_app/assets/models/words_tcn/model_metadata.json`: actual TCN architecture and selected configuration. A 16-filter projection feeds three residual blocks with two kernel-5 causal convolutions per block, dilation 1/2/4, normalization, ReLU, and dropout. Global temporal averaging feeds a 16-unit dense layer and three-class softmax.
- `../docs/WORD_MODEL_DEMO_TRAINING.md`: 15 real recordings from the reported demo wearer, identical whole-trial split of 9 train / 3 validation / 3 test, train-only standardization. All three candidates achieved 3/3 validation. TCN won the predefined size tie-break at 48,324 bytes, then achieved 3/3 reserved test and macro F1 1.00. Tiny offline sample, not general recognition accuracy or a signer-independent result.
- `../docs/WORD_DEMO_INTEGRATION.md` and the Flutter word services: complete-attempt input preparation, on-phone TFLite inference, actual argmax output, completion rules, three Android emulator replay checks, and remaining live validation.
- The editable diagram summarizes this deployed architecture. It omits the projection, normalization, dropout, and intermediate details. Sensor traces are illustrative. Vocabulary labels are not a fabricated measured prediction.
- Desktop median inference was 0.0488 ms, excluding BLE/window/preprocessing. Emulator attempt-owned load/invoke timings are not physical-phone benchmarks. Intended-phone latency and fresh glove/phone validation: **Not run**. No orientation normalization or rest/unknown class is implemented.

## Slide 8: static practice thresholds

- `../flutter_app/lib/services/stable_prediction_tracker.dart`: default confidence 80%, stable duration 750 ms, five matching packets, and maximum packet gap 250 ms.
- Static completion also requires matching the selected target. These thresholds are implementation details, not validation results or dynamic-word acceptance criteria.
- Word completion instead requires the actual top predicted word to match the selected target with ≥80% confidence after Finish sign. `../flutter_app/lib/services/word_practice_controller.dart` and `progress_repository.dart` implement capture checks and saved completion. Live word cloud sync remains Not run.

## Implementation and validation boundaries

- `../docs/BETA_BUILD_STATUS.md`
- `../docs/BETA_TEST_PLAN_WORKING_NOTES.md`
- User-supplied alpha materials and beta UI screenshots are labeled by stage/state. Generated intro/problem/haptic images are conceptual illustrations.
