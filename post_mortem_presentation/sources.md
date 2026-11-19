# Sources and asset provenance

## Claims

- [P3 assignment](../P3-Post-Mortem-Presentation.md) and the November 19 rubric
  image supplied by Gael set the presentation and grading requirements.
- [November 19 presentation handoff](../docs/POST_MORTEM_PRESENTATION_PLAN.md#november-19-handoff-for-the-slides)
  describes the presentation build, including the separate J/Z model and the
  Number 3 and word haptic demos.
- [Final report evidence checklist](../docs/FINAL_REPORT_EVIDENCE_CHECKLIST.md)
  records the physical assembly (BUILD-01), one-wearer practice and persistence
  (LIVE-03/04), offline models (EVAL-04/05), haptic checks (HAPT-01–04),
  informal tryouts (USER-01), and Firestore rules change (APP-09).
- Gael supplied `Final_Report.pdf` (R4, pp. 3–8) and
  `Product_Release_Report.pdf` (M6, pp. 1–2). These support the earlier
  release snapshot, including the final hardware, tested practice flow, word
  retraining and offline replay, live counts, and saved app progress. The
  November 19 handoff records the later presentation-build work.
- [Word model metadata](../flutter_app/assets/models/words_tcn/model_metadata.json)
  lists Hello, Please, and Yes. The
  [Words tab](../flutter_app/lib/screens/tabs/words_tab.dart) lists eight lessons.
- The [ESP32 classifier](../ESP32/src/classifier.cpp) uses finger-bend readings.
  The [J/Z bundle](../flutter_app/assets/models/motion_letters_tcn/model_metadata.json)
  uses an IMU sequence. The word bundle uses a sequence of flex and IMU readings.
- [Original design draft](../design_draft/Helping_Hand_Design_Draft.pdf) and the
  project plan provide the original prototype and feature goals used in backup 1.

## Visuals

- [Cover backdrop](assets/illustrations/cover-backdrop.png) was generated with
  the built-in ImageGen tool. The cover layers the original glove photograph
  and the actual Words screenshot over it.
- [Problem illustration](assets/illustrations/learning-problem.png) reuses the
  generated artwork from the [beta presentation](../beta_presentation/assets/prompts.md#learning-problem).
  The slide uses it to illustrate practice alone.
- The bars and trace on slide 4 are schematic input illustrations.

- `assets/hardware/glove-final.jpg` matches the supplied `IMG_9891.jpeg`
  and the [repository original](../docs/figures/r4/IMG_9891.jpeg).
- `assets/hardware/pcb-prototype.jpg` is the
  [component-side prototype photo](../docs/figures/r4/IMG_9894.jpeg).
  The [reverse-side photo](../docs/figures/r4/IMG_9893.jpeg) is available for
  questions or supporting material.
- `assets/screenshots/alphabet-nov19.png`,
  `assets/screenshots/letter-a-nov19.png`, and
  `assets/screenshots/words-progress-nov19.png` are Gael's November 19 Android
  captures from 05:13:57, 05:14:02, and 05:13:49 respectively. The Letter A
  screen shows the reference in a disconnected state. The Words photo shows
  already-saved completion.
- The system diagram and icons are editable HTML/CSS/SVG. DM Sans and Fraunces
  Italic follow the [beta style guide](../docs/BETA_PRESENTATION_STYLE_GUIDE.md).
  Their local font licenses are in `assets/fonts/`.

### Cover backdrop generation prompt

> Use case: productivity-visual. Generate only the image background for the opening slide of Helping Hand, an ASL learning glove and app. Full-bleed 16:9 landscape. Make it look like a premium editorial product photograph of a carefully art-directed empty studio flat lay, with a real photographed object and a phone to be composited later. The left 45% is a continuously blank warm ivory paper surface (#FFFCF5), very even light and low texture, for dark slide type. The right half is a boldly colored field of rich deep teal (#00645C) matte paper, filling the right edge and bottom edge, entering from the upper edge at 60% frame width and easing to a soft angled edge near 44% at the bottom. Layer a sculptural mint paper ribbon or curled strip on the far right edge and lower-right corner, with realistic directional sunlight and clean soft shadows, evocative of motion and a haptic pulse. Add one very small golden yellow accent in the upper right. Keep the center-right area relatively quiet so two foreground product images can sit there. Restrained modern product-launch art direction, crisp clear geometry, subtle physical paper grain, refined and confident. No glove, hands, phone, electronics, frames, circles, words, lettering, typography, or logos.
