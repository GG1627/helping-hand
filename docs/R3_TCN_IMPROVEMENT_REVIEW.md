# R3: current TCN improvement review

Review date: October 27, 2026. This records a source-code and documentation
review for the preliminary report, not new training or physical testing.
The user reports reviewing ways to improve the TCN since the October 6 demo
but does not recall the individual changes considered. The findings below
were established in this review; they are not a reconstructed experiment log.

## Current model and deployment

- Three trained words: Hello, Please and Yes.
- Fifteen real complete trials from the user-reported demo wearer; all neutral.
- Identical whole-trial split for candidate comparison: nine training, three
  validation and three reserved test trials. Multiple signer IDs do not prove
  independent participants.
- Raw five-finger flex readings plus six accelerometer/gyroscope channels.
- Device-clock resampling at 40 Hz; center trimming or edge padding to 96
  samples, followed by training-only per-feature standardization.
- TCN projection, three residual blocks with dilations 1/2/4, temporal average,
  hidden dense layer and three-class softmax. Selected configuration already
  has dropout 0.25 and L2 regularization 0.0001.
- Flutter accepts a complete attempt when the actual top predicted word
  matches the selected target at at least 80% confidence. There is no
  rest/unknown class and no implemented quaternion normalization.

These are existing implementation facts, not changes made by this review.
See [training](WORD_MODEL_DEMO_TRAINING.md),
[integration](WORD_DEMO_INTEGRATION.md),
[model builder](../backend/word_models.py),
[demo training procedure](../backend/train_demo_word_models.py),
[Python window preparation](../backend/word_data.py), and
[Flutter preparation](../flutter_app/lib/services/word_sequence.dart).

## Improvement opportunities identified

| Priority / area | Current evidence | Candidate next work and evaluation |
| --- | --- | --- |
| 1. Data coverage | Only five trials per word, neutral orientation and one reported wearer; one reserved test trial per word | Collect independent repetitions across sessions, signers and valid signing conditions after repairing sensors. Keep whole trials indivisible and distinguish same-user from held-out-user evaluation. This addresses the evidence gap before assuming a larger network is needed. |
| 2. Complete-gesture timing | The model retains 96 samples, about 2.4 seconds at 40 Hz. Documented Yes attempts last roughly 3.3-5.3 seconds, so center trimming can omit initial/final motion | Compare the current window with longer windows or an activity-boundary method that retains meaningful motion. Keep candidate splits fixed, tune on validation only, and measure accuracy, model size and phone latency. This is a plausible weakness, not a measured cause of errors. Update Python and Flutter preprocessing together. |
| 3. Idle/unrelated-motion rejection | Every model output is one of three words; capture integrity checks and an 80% threshold do not establish unknown-sign rejection | Collect explicit idle, transition, unrelated-motion and wrong-sign examples. Evaluate a rest/other class or rejection rule using validation data. Report false completions and per-word recall on independent trials; one other class will not guarantee rejection of every unseen motion. |
| 4. Sensor/calibration and orientation robustness | Word inputs are raw ADC values with train-only standardization; demo data are neutral-only. Flex replacements and the ordered IMU change the input hardware | Establish the repaired glove's ranges, axes and units. Compare feature calibration and orientation representations on the same splits. Evaluate magnetometer-assisted fusion only after the new part is identified/calibrated. Preserve palm orientation meaningful to the signs; do not promise invariance to every rotation. |
| 5. Controlled model tuning | Dropout and L2 already exist; the small validation set cannot reliably distinguish architectures by accuracy | Once coverage improves, compare limited changes to regularization, capacity, kernel size or temporal receptive field, one factor at a time where practical. Preserve the baseline and record configurations. Do not claim that adding dropout is new work or that tuning has already improved the score. |
| 6. Physical-phone performance | Existing desktop timings exclude the full learner path; emulator replay is not a phone benchmark | Measure repeated end-to-end attempt-finish-to-feedback latency and component timings on the intended phone. Use those measurements to decide whether runtime or model optimization is needed. |

No candidate above was implemented, trained, benchmarked or shown to improve
accuracy in this review. Existing reserved test recordings should not be reused
as an untouched final test set after repeated design tuning.

Hardware identification follow-up: the user supplied Adafruit Short Flex Sensor
#1070 and ICM-20948 breakout #4554 links. Their identification resolves the
replacement-part question, not calibration or model performance. See the
[hardware source notes](../research/R3_REPORT_SOURCE_NOTES.md) for citations.
The current model remains an 11-feature accelerometer/gyro/flex model; using
magnetic or derived orientation features requires an explicit pipeline update.
On October 28, the user confirmed the ICM-20948 was received and the glove
remained at its perfboard/demo hardware stage. Receipt does not establish new
inference, sensor-fusion or calibration results.

## Connection to planned haptics

The planned ten-buzzer system should identify a finger requiring correction and
provide directional guidance. Current TCN output is a word-probability vector;
it does not directly identify which finger is wrong or whether it should bend
or straighten. A separate error-estimation/cue-mapping design remains needed.
Do not describe classification confidence as a finger-level corrective signal.

## Report wording supported by this review

"Development following the October 6 demonstration has included KiCad circuit
design and review of improvements to the TCN recognition pipeline. The current
review identifies broader signer and orientation coverage, gesture-window
handling and rejection of unrelated motion as priorities for the next model
iteration. Replacement flex sensors and a planned nine-axis IMU will require
calibration and fresh recordings before these changes can be evaluated.
Training and physical validation of the proposed improvements remain pending."

Use the specific opportunities as current review findings. Do not assign them
to an earlier date, individual or completed experiment without team confirmation.
