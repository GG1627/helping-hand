# Live demonstration run sheet · November 19, 2026

Reserve 90 seconds within the talk for **G → Z → 3 → Hello → Please**. Rehearse
Z and the two new word cue patterns on the intended glove and phone before
presenting. Assign the wearer, phone operator, narrator, and slide operator.

| Time | Action | Narration purpose |
| --- | --- | --- |
| 0–8 s | Show the wired glove and open Alphabet. | Establish live use of the actual artifact. |
| 8–20 s | Open **G**, form it, and hold for the recognition result. | The ESP32 recognizes steady poses. |
| 20–34 s | Open **Z**, tap **Start attempt**, trace Z, then **Finish sign** within four seconds. | The separate phone model recognizes the motion of J and Z. |
| 34–55 s | Open **Numbers → 3**, scroll to **Demo**, and hold a deliberately curled middle finger. After five seconds, leave time for the cue, then straighten it and complete 3. | The finger pulse identifies the finger. Bottom → center → top means straighten. The active dots show which buzzers the glove reports. |
| 55–80 s | Use **Start attempt** and **Finish sign** for **Hello**, then **Please**. Let Hello's left → center → right cue play, then allow time for Please's three left → top → right → bottom laps. | Matching words replay selected, preset motion cues on the back-of-hand plus. |
| 80–90 s | Return to **Words** and point out the green learned rows and checkmarks. | Saved completion is visible at a glance. |

For Number 3, start with the correction needed so practice does not complete
during the five-second grace period. A still-needed cue repeats after a
two-second pause. The demo stops when the app records completion. Show the
animation as the output location, and describe tactile sensation using the
wearer's actual experience.

## Evidence for the selected targets

- Gael reported live recognition for G, I, 1, Hello, Please, and Yes, including
  3/3 each in one check. I is the rehearsed fallback if Z misses live.
- J/Z offline replay accepted 4/4 held-out matching recordings and rejected
  36/36 unrelated recordings. The same small recording set was used in earlier
  development checks. Verify Z live on the presentation setup.
- The manual buzzer locations matched the display, and Gael separately
  reported that the hands-free Number 3 demo worked on the glove. The two new
  word cue sequences have software checks with simulated glove responses.
- The bundled word recognizer covers Hello, Please, and Yes. The Words screen
  lists eight lessons. The other five recognizer labels and expanded haptic
  coverage remain post-presentation work.

See [the evidence checklist](../docs/FINAL_REPORT_EVIDENCE_CHECKLIST.md) for
LIVE-04, EVAL-05, and HAPT-01 through HAPT-04.

## Before the presentation

- [ ] Record demonstrated app/firmware/model, glove configuration, phone, and wearer scope.
- [ ] Select final rehearsed targets and record actual outcomes, including failures.
- [ ] Use the active working build and the known `piezo_demo` firmware. Start
  the app with `flutter run` from `flutter_app` and turn on Developer Mode.
- [ ] Plug the glove into the laptop for USB power. Sign in, connect through
  **Developer → BLE Testing**, and verify projection before presenting.
- [ ] Put needed targets within easy reach; rehearse operator/wearer coordination.
- [ ] Verify demo cue wording matches the actual implemented behavior.
- [ ] Rehearse transition from slide 4 to live use, then back to reflection.
- [ ] Keep notes and overview closed on the projected screen.
- [ ] Have a short retry/reconnect route, charged devices, and necessary cables ready.

## If a live step fails

Describe what actually happened. Try one short recovery when practical, then
continue with available live functionality. Do not claim a sign completed if it
did not. Screenshots or recorded clips can support an explanation but cannot
replace the assignment's required live use.
