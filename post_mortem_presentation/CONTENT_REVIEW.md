# Post-mortem content review

Draft 01 was prepared November 6, 2026. This review was updated November 19.
The [presentation handoff](../docs/POST_MORTEM_PRESENTATION_PLAN.md#november-19-handoff-for-the-slides)
and [run sheet](demo_checklist.md) describe the current working app and demo.
Slide edits and delivery assignments remain open.

## Confirmed

- Local HTML in the beta style; eight proposed main slides plus two backups.
- Seven-minute assignment, questions throughout; prepared content targets 6:10.
- Planned live order is G, Z, 3, Hello, and Please. The final glove uses wired
  perfboard with laptop USB power.
- App vocabulary: Hello, Thank You, Please, Sorry, Yes, No, Eat, Drink.
- The original beta deck is preserved. Draft 01 still uses the October assets.

## Open content slots

| Slide | Item | Current fact / draft treatment | Final update needed | Owner |
| --- | --- | --- | --- | --- |
| 1, 3 | Final glove photo | The [as-built photo](../docs/figures/r4/IMG_9891.jpeg) shows the wired perfboard, five flex strips, and piezos. | Replace the October photo and update its caption and alt text. | TBD |
| 3 | PCB image | [Prototype PCB photo](../docs/figures/r4/IMG_9894.jpeg). The team returned to perfboard after unreliable connections. | Use the PCB as an iteration comparison. | TBD |
| 2, 3, 5 | Haptic feedback | Gael reported success with manual mapping and automatic Number 3 cues. Hello and Please replay preset patterns after a match and have software-test evidence. | Show the BLE command/acknowledgment path and current cue meaning. Rehearse both new word patterns live. | TBD |
| 2, 3 | New IMU | Gael reported the installed ICM-20948 working. The six-face diagnostic flagged two Y captures. | Show the actual sensor and avoid unmeasured fusion or orientation claims. | TBD |
| 4, backup 1 | Letters and digits | ESP32 MLP covers 24 letters and ten digits. J/Z use a separate IMU TCN with offline results. | Show both paths and label live rehearsal separately from offline results. | TBD |
| 4, backup 1 | Words | Eight lessons are listed. The bundled recognizer covers Hello, Please, and Yes. Saved completions have a green row and checkmark. | Use current coverage and a current Words screenshot. | TBD |
| 4 | Current app photos | October Home, disconnected B practice, word picker. | Final connected practice, actual feedback, and completion/progress screens. | TBD |
| 4, backup 2 | Results | LIVE-04 records reported live attempts. EVAL-05 records the small offline J/Z check. HAPT-03 records Number 3 on the glove. | Give the result scope and any new rehearsal observations. | TBD |
| 6 | Three successes | Two historical/integrated stories plus one conditional final-wearable story. | Three team-confirmed examples with why the approach worked and actual outcomes. | TBD |
| 7 | Three challenges | Sensor/data examples and a physical/software dependency prompt. | Concrete team experience, why difficult, impact, and future improvement for each. | TBD |
| 8 | Final takeaway | Proposed integration lesson; final outcome/limit pending. | Strongest supported final outcome and most important remaining limit. | TBD |
| All | Delivery | Timing targets supplied; assignments TBD. | Speakers, wearer, phone operator, slide operator, transitions, and actual rehearsal time. | TBD |

## Before final export

- [ ] Replace all bracketed content and resolve candidate stories.
- [ ] Update historical photos/captions and final supported vocabulary.
- [ ] Update the architecture diagram to actual final recognition and haptic paths.
- [ ] Label any remaining incomplete or unrun items accurately.
- [ ] Keep implementation thresholds distinct from accuracy and learning outcomes.
- [ ] Update both inline HTML notes and standalone speaker notes together.
- [ ] Rehearse the actual demo and recovery route within the seven-minute talk.
- [ ] Remove Draft 01 labels only when final claims/content have been settled.
- [ ] Regenerate and inspect PDF; decide whether Canvas export includes backups.

Sources: [current handoff](../docs/GLOVE_MODEL_SESSION_HANDOFF.md),
[historical demo observations](../docs/R3_DEMO_OBSERVATIONS.md), and
[the presentation plan](../docs/POST_MORTEM_PRESENTATION_PLAN.md).
