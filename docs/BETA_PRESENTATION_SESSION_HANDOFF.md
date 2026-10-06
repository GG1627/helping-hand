# Beta presentation session handoff

Updated October 6, 2026. Presentation: October 6, 2026.
Reviewed presentation baseline: [`2bd6ee1`](https://github.com/GG1627/helping-hand/commit/2bd6ee1aeb48c08b4023957829068a690d77e8c3), committed and pushed to `gael`.
This handoff records presentation progress, not new application or hardware validation.

## Read first

1. Root `AGENTS.md` and `ai-policy/AI-USAGE.md` for repository and commit policy.
2. [Presentation guidelines](../Beta_Presentation_Guidelines.md) and [style guide](BETA_PRESENTATION_STYLE_GUIDE.md).
3. [Deck README](../beta_presentation/README.md), [content follow-up](../beta_presentation/CONTENT_REVIEW.md), and [live demo checklist](../beta_presentation/demo_checklist.md).
4. [Asset checklist](../beta_presentation/assets/ASSET_CHECKLIST.md), [speaker notes](../beta_presentation/speaker_notes.md), and [sources](../beta_presentation/sources.md).
5. [Beta build status](BETA_BUILD_STATUS.md), [test-plan working notes](BETA_TEST_PLAN_WORKING_NOTES.md), and Issue #7 research when updating implementation claims. Inspect the actual demo build for changes since those snapshots.

## Decisions confirmed with the user

- Ten slides; 16:9 HTML, local images/fonts, no build step. Open `beta_presentation/index.html` directly in a browser.
- User-corrected timing: **5–6 minutes including the demo**, then **1–2 minutes Q&A**. The original course document still says 8–10 and 2–3; preserve that source and use the user's correction for this deck.
- Keep the approved ivory/teal/mint app identity, short copy, and visual explanations. The user approved the deck's appearance and later content revisions.
- Bottom navigation was removed at the user's request. Keep only the thin slide-progress line; keyboard shortcuts are documented in the deck README.
- **Live demonstration**, confirmed with instructors; slide 7 says “LIVE DEMO!!!”. Reserve about 90 seconds. The prerecorded-video idea was superseded.
- Trained word vocabulary: **Hello, Please, Yes**. The user plans to present two words, chosen after fresh rehearsal with the recorded wearer. Recognition uses explicit Start attempt / Finish sign boundaries. The final two choices remain pending.
- Team: Srinitha Srikanth, Brian Paz, Gael Garcia, Kali Schuchhardt. Speaker/demo assignments remain **TBD**.
- Main next milestone: haptics. Proposed layout is five piezo elements in an X pattern plus one per finger, ten total. Corrective feedback should reflect positioning deviation; error estimation, pulse/intensity mapping, drivers, and tactile calibration remain planned.
- Slide 9's October 7–November 3 dates are proposed for team review, not a confirmed final deadline.

## Completed presentation work

- [x] Built all ten slides: intro, learning problem, system pipeline, alpha vertical slice, beta app, sequence-model explanation, live demo, current state, haptic roadmap, and questions.
- [x] Added supplied current app screenshots, historical alpha evidence, generated intro/problem/haptic illustrations, and local licensed fonts.
- [x] Added editable HTML/SVG architecture and timeline visuals; slide 6 now explains the selected, integrated TCN with CNN-GRU/CNN-LSTM as evaluated alternatives.
- [x] Updated the problem slide with the sourced NIDCD **>90%** statistic and scoped the feedback gap to books/prerecorded reference videos alone.
- [x] Added specific app capabilities and static acceptance rules without presenting thresholds as measured accuracy.
- [x] Added speaker notes, source attribution, content/asset checklists, and live-demo preparation.
- [x] Exported [ten-page PDF](../beta_presentation/exports/helping-hand-beta.pdf), approximately 3.4 MB after the TCN update.
- [x] Reviewed all ten browser slides and PDF pages; checked keyboard navigation, progress boundaries, overview, notes, fullscreen, mobile fit, local assets, and print behavior. No text overflow or browser errors were observed in the recorded checks.
- [x] User reviewed the presentation; baseline commit pushed to `gael`.

### Follow-up changes after the baseline

- October 5: trained TCN, CNN-GRU, and CNN-LSTM on the 15 recorded word trials.
  Selected **TCN** by validation results and exported size; all three were 3/3
  on validation, and selected TCN was 3/3 on reserved test trials. See
  [the training record](WORD_MODEL_DEMO_TRAINING.md). The trained vocabulary is
  **hello, please, yes**. Flutter now integrates complete-attempt recognition
  and saved completion; three real-TCN Android emulator replay checks passed.
  Fresh glove/phone rehearsal and phone latency are **Not run**. See
  [the integration guide](WORD_DEMO_INTEGRATION.md). The required slide 6
  follow-up is now applied to the deck/PDF. Software replay does not establish
  a working physical live demo.

- October 6 model-slide follow-up: replaced the proposed CNN-GRU diagram with
  the selected TCN, actual 96 × 11 input at 40 Hz, dilation 1/2/4 residual blocks,
  temporal average, three-word vocabulary, and on-phone inference. Added model
  size and tiny whole-trial evaluation scope. Aligned slides 5/7/8, speaker notes,
  sources, and demo checklist. The diagram remains editable; an optional GPT
  illustration prompt is in `beta_presentation/assets/prompts.md`. The PDF is
  regenerated and all ten PDF pages checked. The user accepted the update and
  requested committing and pushing all work on October 6.

- October 5: lowered the left section of slide 10's mint curve so it clears
  “Next: guidance you can feel.” Checked the closing slide at desktop/mobile
  sizes and keyboard navigation, then regenerated and inspected the PDF closing
  page. The user reviewed the adjustment and authorized committing/pushing it
  together with this session handoff and the related documentation updates.

## Remaining work and evidence boundaries

| Item | Status / next action |
| --- | --- |
| Slide 6 final model | **Completed in the deck/PDF.** Selected TCN, vocabulary, input/window/preprocessing, deployment, size, and tiny trial-split result match the implementation. Intended-phone latency remains Not run. |
| Dynamic live demo | **TCN integrated for complete attempts; Android recorded replay passed; fresh rehearsal Not run.** Use Start attempt / Finish sign with the recorded wearer and phone. Choose the two demo words after fresh trials and update evidence only when measured. |
| Current hardware photos | **Pending.** Slide 3 has two placeholders. Add `assets/hardware/glove-current.jpg` and `circuit-current.jpg`, enable their entries in `assets/asset-manifest.js`, reload, and re-export the PDF. |
| Speaker/demo assignments | **TBD.** Include all team members and rehearse within the agreed time. |
| Haptic roadmap | **Planned.** Confirm milestone dates and mounting/calibration details with the team. The illustration is conceptual. |
| Physical beta procedures | **Not run in the current documentation.** Deck/browser/PDF checks are presentation checks, not glove/BLE/Firebase/model validation. Record new results only with evidence. |
| Submission | PDF prepared; Canvas upload and presentation delivery are not recorded as completed. |

The generated intro is a staged product visualization, not physical test evidence. Alpha images/results stay historical. The static practice screenshot shows a disconnected state. Keep these distinctions when editing slides or speaking notes.

## Next session work order

1. Review current branch/build changes and any newly supplied hardware photos or model evidence.
2. Replace the two hardware placeholders when the photos arrive; keep the approved design and slide count.
3. Review the completed TCN slide update. Record new live-model evidence only after testing, then adjust claims and re-export if needed.
4. Confirm speakers, rehearse the live scenario, and record the build/device/firmware and actual limitations in the demo checklist.
5. Regenerate the PDF after changing slide content or images; check the affected slides and export pages.
6. Update these status/checklist documents as items are completed. Follow the AI policy for review and any later commit/push; the earlier approval covers the reviewed baseline, not new unreviewed changes.

Suggested next-session prompt:

> Continue the Helping Hand beta presentation. Read docs/BETA_PRESENTATION_SESSION_HANDOFF.md first. Preserve the approved ten-slide design and thin progress line. Check the remaining hardware photos, required slide 6 model update, and live-demo preparation against the actual build. Keep unrun validation labeled Not run and regenerate the PDF after deck changes.
