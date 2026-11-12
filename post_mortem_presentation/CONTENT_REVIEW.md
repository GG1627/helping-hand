# Post-mortem content review

Draft 01: November 6, 2026. Presentation: November 19. This is a presentation
checklist, not an engineering implementation schedule. All owners remain TBD.

## Confirmed

- Local HTML in the beta style; eight proposed main slides plus two backups.
- Seven-minute assignment, questions throughout; prepared content targets 6:10.
- Intended final build includes PCB, new IMU, haptics, A-Z, 0-9, and eight words.
- App vocabulary: Hello, Thank You, Please, Sorry, Yes, No, Eat, Drink.
- Original beta deck is preserved. Current photos/screenshots are historical.

## Open content slots

| Slide | Item | Current fact / draft treatment | Final update needed | Owner |
| --- | --- | --- | --- | --- |
| 1, 3 | Final glove photo | October beta photo, labeled historical. | Final assembled glove; update alt text/caption and asset source. | TBD |
| 3 | PCB image | October perfboard photo, explicitly not custom PCB. | Final mounted PCB close-up and explanation of actual design benefit. | TBD |
| 2, 3, 5 | Haptic feedback | Firmware output support; integrated cue behavior pending. Dashed path is conceptual. | Actual trigger source, circuit/placement, sensation, cue meaning, and demo behavior. | TBD |
| 2, 3 | New IMU | ICM-20948 received; physical assembled-board checks unconfirmed. | Actual final sensor configuration and measured behavior; no assumed fusion benefit. | TBD |
| 4, backup 1 | Full letters/digits | Recorded static model has 34 classes excluding J/Z; 36-class legacy baseline retained. | Final supported labels, actual J/Z motion path, and coverage evidence. | TBD |
| 4, backup 1 | Eight words | App lists eight; model currently trains Hello/Please/Yes only. | Evaluated eight-word model and actual app completion behavior. | TBD |
| 4 | Current app photos | October Home, disconnected B practice, word picker. | Final connected practice, actual feedback, and completion/progress screens. | TBD |
| 4, backup 2 | Results | Explicit pending fields; no invented final values. | Fresh trial counts, wearer/configuration, correct/false completion results, size and phone latency where measured. | TBD |
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
