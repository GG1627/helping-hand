# Live demonstration run sheet · November 19, 2026

Slide 7 runs from **2:15 to 4:15** in the seven-minute talk. The planned order
is **G → Z → 3 → Hello → Please → Words progress**. Rehearse on the intended
glove and phone. Assign the wearer, phone operator, narrator, and slide operator.

| Time | Action | Narration purpose |
| --- | --- | --- |
| 0–10 s | Show the worn glove and open Alphabet on the projected phone. | Establish the learner’s task. |
| 10–25 s | Open **G**, form it, and hold for the recognition result. | Point to the match and hold indicator. |
| 25–43 s | Open **Z**, tap **Start attempt**, trace Z, then **Finish sign** within four seconds. | Contrast a moving attempt with the held G. |
| 43–72 s | Open **Numbers → 3**, scroll to **Demo**, and hold a deliberately curled middle finger. After five seconds, leave time for the cue, then straighten it. | The finger pulse identifies the finger. Bottom → center → top means straighten. Show what the app reports after the correction. |
| 72–108 s | Open **Hello** and wait three seconds for the left → center → right cue. It replays after a two-second pause. Use **Start attempt** and **Finish sign**, then repeat the flow for **Please** if time permits. Please plays three left → top → right → bottom laps per cue. | Show the motion guidance before signing. Describe the physical output and wearer sensation as observed. |
| 108–120 s | Return to **Words**, point to the green rows and checkmarks, then return to slide 8. | Show saved completion. Call out a newly completed row only if it changes during the attempt. |

If the previous steps or audience questions use up the buffer, go from Hello
directly to Words. Protect the saved progress reveal and the reflection time.

For Number 3, start with the correction needed so practice does not complete
during the five-second grace period. A still-needed cue repeats after a
two-second pause. The demo stops when the app records completion. Show the
animation as the output location, and describe tactile sensation using the
wearer's actual experience.

## Evidence for the selected targets

- Gael reported live recognition for G, I, 1, Hello, Please, and Yes, including
  3/3 each in one check. I is the rehearsed fallback if Z misses live.
- J/Z offline replay accepted 4/4 held-out matching recordings and rejected
  36/36 unrelated recordings. Some recordings were examined earlier in
  development. Live Z on the presentation setup still needs a check.
- The manual buzzer locations matched the display, and Gael separately
  reported that the hands-free Number 3 demo worked on the glove. The two new
  word cue sequences have software checks with simulated glove responses.
- The rehearsal recognizer covers Hello, Please, and Yes. Sorry and No use
  a second model with offline results. The Words screen lists eight lessons,
  and Hello and Please have preset guidance.

See [the evidence checklist](../docs/FINAL_REPORT_EVIDENCE_CHECKLIST.md) for
LIVE-04, EVAL-05, EVAL-06, and HAPT-01 through HAPT-05.

## Before the presentation

- [ ] Record the actual running revision and local changes, firmware environment,
  model bundles, phone/OS, and glove setup. The planned demo uses app version
  1.0.1+2 from the presentation working copy and the `piezo_demo` firmware.
- [ ] Select final rehearsed targets and record actual outcomes, including failures.
- [ ] Use the active working build and the known `piezo_demo` firmware. Start
  the app with `flutter run` from `flutter_app` and turn on Developer Mode.
- [ ] Plug the glove into the laptop for USB power. Sign in, connect through
  **Developer → BLE Testing**, and verify projection before presenting.
- [ ] Put needed targets within easy reach; rehearse operator/wearer coordination.
- [ ] Verify demo cue wording matches the actual implemented behavior.
- [ ] Rehearse the transition from slide 6 to projected live use, then back to
  slide 8. Assign speaker handoffs and time the 4:45 talk and 2:00 demo.
- [ ] Keep notes and overview closed on the projected screen.
- [ ] Have a short retry/reconnect route, charged devices, and necessary cables ready.

## If a live step fails

Describe what actually happened. Try one short recovery when practical, then
continue with available live functionality. Acknowledge missed matches and cues
that did not play. Screenshots can support the explanation while the audience
sees the actual glove and phone in use.
