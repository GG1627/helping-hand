# Live demo preparation

Status: TCN integration and Android recorded replay complete; fresh rehearsal and physical-device validation **Not run**.

Presentation: October 6, 2026. Instructors confirmed the demonstration must be live. Slide 7 displays “LIVE DEMO!!!”; leave it visible while operating the glove/app. Speaker and demo operator assignments remain TBD.

## Scenario

1. Show the learner Home and saved progress.
2. Open a rehearsed static target, preferably A, B, 1, or 3, and demonstrate actual feedback.
3. Open Words and choose one of the two rehearsed words from **Hello, Please, Yes**.
4. A teammate taps **Start attempt** while the recorded wearer performs the complete sign, then taps **Finish sign** immediately after it.
5. Show the actual predicted word and confidence. A matching target at ≥80% saves completion. Repeat with the second word if timing permits.

Reserve approximately 90 seconds. The final two word choices remain pending fresh rehearsal. Avoid long idle intervals around the gesture. The three-class model has no rest/unknown class, and unrelated motion can receive a confident label.

## Before presenting

- [ ] Record build/commit, phone/OS, glove hardware, and firmware.
- [ ] Install and rehearse the actual demo build.
- [ ] Charge phone/glove; prepare connection and display/mirroring.
- [ ] Confirm account access and intended starting progress.
- [ ] Rehearse static recognition and all three words with the recorded wearer using the same glove placement.
- [ ] Choose the two most reliable words and record fresh attempt counts, actual predictions, and failures.
- [ ] Confirm Start attempt / Finish sign feedback, retries, disconnect recovery, and saved completion after restart.
- [ ] Measure intended-phone latency separately from gesture duration. Current status: Not run.
- [ ] Record recognition limitations and any scripted/simulated behavior for disclosure.
- [ ] Prepare a recovery path if the live recognition/connection fails; screenshots are supporting material, not a substitute for the required live use.
- [ ] Assign speaking and demo roles to include every team member.
