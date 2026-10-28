# R3: team-reported physical demonstration observations

Reported by Gael on October 28, 2026 while reviewing the preliminary report.
These are retrospective team observations, not an independently executed test
or a controlled recognition-accuracy dataset. Do not derive percentages from
the number of signs listed.

The user confirms these observations were made **October 5-6, 2026, in the
senior design lab in NSC (Nuclear Sciences building)**. They identify the phone
as the Fairphone documented in the repo. The reference configuration is
**Fairphone Gen 6 / Android 15**, recorded in
[T1](T1_ALPHA_TEST_PLAN.md) and [T2](T2_Beta_Test_Plan.tex). This is a
team-confirmed phone matched to existing configuration documentation, not a
new inspection of the phone's settings.

## Reported behavior

| Area | Team observation | Evidence limits / remaining clarification |
| --- | --- | --- |
| Phone/application | The user reports the phone/app flow worked; Fairphone Gen 6 / Android 15 is the documented configuration | App build and firmware revision are not yet confirmed. |
| Letter practice | The team was able to learn A, B, C, L, S, U and Y | Other letters were also tried, but a complete attempted-sign list and per-sign trial/failure counts were not recorded. |
| Number practice | The user reports trying all digits, 0-9 | Exact completion outcomes per digit and trial counts were not separately recorded. |
| Word practice | The app recognized Hello and Please and marked both lessons complete, confirmed by the user | Trial counts, confidence logs, failed attempts and independent run evidence were not supplied. |
| Saved progress | Gael verified green completion indicators for practiced letters, numbers and words in the app, then checked corresponding progress records in the actual Firebase database | Verification method confirmed October 28. The implementation uses Cloud Firestore for progress. Restart persistence, cross-device behavior, offline recovery and account isolation were not separately confirmed. No per-item count or original screenshots/database export was supplied. |
| Sensor faults | Thumb and index flex sensors broke and produced bad values; some signs remained difficult | Exact fault onset, raw traces, failed sign list and affected recording sessions remain unknown. Do not conclude that every older recording was faulty. |
| Current hardware | The glove retains the demo's perfboard-based electronics; new piezo elements and ICM-20948 are received | Installation, repair and new validation were not reported. Replacement-flex arrival remains unconfirmed. |

## Demo configuration still to confirm

- [x] Date: October 5-6, 2026.
- [x] Location: senior design lab, NSC (Nuclear Sciences building).
- [x] Phone: Fairphone, matched to the repo's Gen 6 / Android 15 reference.
- [ ] App build/firmware revision if available.
- [x] Progress observed in both the app (green completion indicators) and actual Firebase database, confirmed by Gael October 28.
- [ ] Restart persistence or other recovery scenarios, if separately tested.
- [x] Hello and Please recognized, with lesson completion reported.
- [ ] Any available original video, screenshot, packet export or test notes.

## Confirmed component follow-up

On October 28, Gael confirmed that [Amazon ASIN B077YJ3H6R](https://www.amazon.com/dp/B077YJ3H6R)
is the correct purchase link for the received TIMESETL piezo pickup discs.
The earlier tentative product match is resolved. Drive ratings, mounting,
driver circuitry and integrated tactile performance remain unverified.

## Interpretation for the report

These observations can strengthen the Results narrative as a team-reported
physical demonstration of learner interaction and saved progress. They should
be kept separate from recorded-data held-out evaluation, software replay,
formal reliability testing and post-repair validation. Reports that signs
were learned describe the application's completion feedback, not measured
human learning or retention.

## Development timing after the demo

The user recalls PCB work and temporal-model improvement planning during the
week before October 28, without an exact day. The saved KiCad work is dated
October 22, 2026; use that evidenced date for PCB documentation. Temporal-model
planning can be dated approximately the week of October 19, with the specific
day unrecorded. The separate code review was performed October 27. Do not
assign a precise historical experiment date or measured improvement to either.
