# Presentation sources

## Slide 2: parental hearing status

- Source: NIH, National Institute on Deafness and Other Communication Disorders (NIDCD), [Quick Statistics About Hearing, Balance, & Dizziness](https://www.nidcd.nih.gov/health/statistics/quick-statistics-hearing).
- Checked: October 5, 2026. Page last updated September 20, 2024.
- Slide figure: greater than 90%; the population is deaf children born to hearing parents.
- NIDCD's underlying citation: Mitchell, R. E., and Karchmer, M. A. (2004), *Chasing the mythical ten percent: Parental hearing status of deaf and hard of hearing students in the United States*, Sign Language Studies 4(2), 138–163.
- Interpretation: background context for accessible ASL learning; not a 2026 measurement, an estimate of ASL proficiency, or a result from Helping Hand.
- The earlier deck's 500,000+ U.S. signer estimate is not used here.

## Slide 6: sequence-model candidates

- `../research/IMU_WORD_LEVEL_ASL_RESEARCH.md`: CNN-GRU as first deployment candidate, compared with CNN-LSTM.
- `../backend/word_models.py`: configurable untrained CNN-GRU/CNN-LSTM/TCN builders; recurrent variants use convolution/pooling, a GRU or LSTM, and dense/softmax output.
- Diagram is simplified. It omits normalization, dropout, and intermediate layers; no performance is inferred from the architecture.

## Slide 8: static practice thresholds

- `../flutter_app/lib/services/stable_prediction_tracker.dart`: default confidence 80%, stable duration 750 ms, five matching packets, and maximum packet gap 250 ms.
- Static completion also requires matching the selected target. These thresholds are implementation details, not validation results or dynamic-word acceptance criteria.

## Implementation and validation boundaries

- `../docs/BETA_BUILD_STATUS.md`
- `../docs/BETA_TEST_PLAN_WORKING_NOTES.md`
- User-supplied alpha materials and beta UI screenshots are labeled by stage/state. Generated intro/problem/haptic images are conceptual illustrations.
