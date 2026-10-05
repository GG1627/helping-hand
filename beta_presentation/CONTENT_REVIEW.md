# Presentation content follow-up

Presentation: October 6, 2026. Speaker assignments remain TBD.

## Required: update slide 6 after model selection and integration

**Status: Pending.** Slide 6 currently explains the proposed CNN-GRU pipeline and names CNN-LSTM as a comparison candidate. It must be updated once the actual model is trained, selected, and integrated. The architecture diagram is a candidate explanation, not a claim of deployed model performance.

Repository research recommends CNN-GRU first, compared with CNN-LSTM. `backend/word_models.py` defines untrained CNN-GRU, CNN-LSTM, and TCN builders. Supported builders do not establish a final selected model.

Before finalizing slide 6:

- [ ] Confirm the architecture used by the demo build; change the diagram if CNN-LSTM, TCN, or another model is selected.
- [ ] Confirm the vocabulary and class count; replace the provisional 3–4-word scope.
- [ ] Match input channels, window duration/sampling, scaling, and any orientation preprocessing to the actual pipeline.
- [ ] Confirm the exported TFLite model and where inference runs.
- [ ] Record dataset/signer split and measured evaluation results before adding accuracy/F1 claims.
- [ ] Record model size and measured inference latency on the intended device; distinguish latency from the gesture window length.
- [ ] Replace illustrative traces/output only if actual examples are available and useful.
- [ ] Update slide 8 status, speaker notes, demo checklist, and PDF consistently.

## Problem-slide wording and source

Slide 2 uses the NIDCD statistic that more than 90% of deaf children are born to hearing parents, citing Mitchell and Karchmer (2004). This is background motivation for accessible ASL learning, not a current survey of our users or evidence of glove effectiveness. See `sources.md`.

The feedback gap is scoped to books and ordinary prerecorded videos. Do not restore blanket claims that all current tools provide zero feedback: instructors and interactive tools can provide feedback. The intended point is that a reference alone does not measure the learner's own hand position or provide personalized real-time correction.

## Other specifics added

- Slide 5 names Firebase sign-in, dedicated practice pages, and account-specific static progress.
- Slide 8 shows implemented static matching thresholds (correct target label, ≥80% confidence, ≥750 ms hold, ≥5 matching packets, ≤250 ms packet gaps). These are acceptance rules, not measured recognition accuracy, and do not apply to dynamic word recognition.
- Slide 3 still needs current glove/circuit photos. The architecture is already specific; replace the placeholders when photos arrive.
- Slide 9 already specifies the proposed piezo layout and calibration plan. Its dates remain proposed until the team confirms them.
