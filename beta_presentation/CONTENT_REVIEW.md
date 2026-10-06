# Presentation content follow-up

Presentation: October 6, 2026. Speaker assignments remain TBD.

## Slide 6 model update

**Status: Completed in the deck.** Slide 6 now explains the selected and
integrated **TCN (Temporal Convolutional Network)**. The editable diagram shows
the actual sensor window, dilated residual blocks, temporal averaging, and
three-word output. Slide 7, slide 8, speaker notes, sources, demo checklist,
and the PDF are aligned with complete-attempt recognition. Presentation checks
do not establish fresh hardware or model validation.

October 5 training update: **TCN is the selected trained candidate**, compared
with CNN-GRU and CNN-LSTM on 15 real trials for **hello, please, yes**. All three
classified the same three validation trials correctly; TCN won the predetermined
TFLite-size tie-break (48,324 bytes). The selected TCN then classified all three
reserved test trials correctly, with macro F1 1.00. These are small offline
results from the reported demo wearer, not a general accuracy claim.

Input is 96 samples at 40 Hz with 11 channels (five raw flex ADC values and six
accelerometer/gyroscope values), device-clock resampling, center trimming/edge
padding, and training-only standardization. No orientation normalization was
used. Desktop latency is measured; Android latency and live validation are
**Not run** on the intended physical phone. Flutter now packages the TCN for
Start attempt / Finish sign recognition and UID-scoped saved word completion.
See [the integration record](../docs/WORD_DEMO_INTEGRATION.md) for software checks
and remaining live rehearsal. This flow is user-delimited isolated-word practice.
See [the training record](../docs/WORD_MODEL_DEMO_TRAINING.md) for artifacts and
evaluation details. Slide 6 uses the integrated TCN and its actual 11-channel
preprocessing. Its traces remain illustrative and the output lists the three
trained words rather than fabricating a measured prediction.

Model content checklist:

- [x] Confirm the selected TCN architecture against the builder and bundled metadata.
- [x] Show the three trained words: Hello, Please, Yes.
- [x] Match 96 samples at 40 Hz, 11 raw channels, resampling, trim/pad, and train-only standardization. No orientation normalization.
- [x] Identify on-phone Flutter TFLite inference and the 48,324-byte export.
- [x] Record the whole-trial 9/3/3 split, reported demo wearer, tied validation scores, size tie-break, and tiny reserved-test result.
- [x] Keep illustrative traces and vocabulary output clearly separate from measured recognition.
- [x] Align slides 5/7/8, speaker notes, sources, checklist, and PDF.
- [ ] Measure inference latency on the intended physical phone. **Not run** and not substituted with desktop/emulator figures.
- [ ] Rehearse fresh glove attempts and choose the two live demo words. **Not run**.

No generated TCN image is required. The slide diagram remains editable.
An optional illustration prompt is saved in `assets/prompts.md`.

## Problem-slide wording and source

Slide 2 uses the NIDCD statistic that more than 90% of deaf children are born to hearing parents, citing Mitchell and Karchmer (2004). This is background motivation for accessible ASL learning, not a current survey of our users or evidence of glove effectiveness. See `sources.md`.

The feedback gap is scoped to books and ordinary prerecorded videos. Do not restore blanket claims that all current tools provide zero feedback: instructors and interactive tools can provide feedback. The intended point is that a reference alone does not measure the learner's own hand position or provide personalized real-time correction.

## Other specifics added

- Slide 5 names Firebase sign-in, dedicated practice pages, and account-specific static progress.
- Slide 8 shows implemented static matching thresholds (correct target label, ≥80% confidence, ≥750 ms hold, ≥5 matching packets, ≤250 ms packet gaps). These are acceptance rules, not measured recognition accuracy, and do not apply to dynamic word recognition.
- Slide 3 still needs current glove/circuit photos. The architecture is already specific; replace the placeholders when photos arrive.
- Slide 9 already specifies the proposed piezo layout and calibration plan. Its dates remain proposed until the team confirms them.
