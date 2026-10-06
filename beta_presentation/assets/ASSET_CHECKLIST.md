# Presentation image checklist

PNG preferred for screenshots; JPG or PNG for photos. Preserve original resolution and screenshot proportions. Filenames below are suggestions; no need to crop to a slide shape. Use a demo account and remove personal information.

## Real photographs

Both current hardware photos are supplied and enabled in `asset-manifest.js` for HTML slide 3. The historical alpha glove is available as `hardware/glove-alpha.jpeg`. Slide 6 uses an editable diagram of the integrated TCN. A Hello screenshot is optional supporting material after fresh live recognition. The existing PDF predates the hardware-photo update; the user requested HTML only for this change.

- [x] `hardware/glove-current.jpg`: supplied complete glove photo with finger sensors, wiring, and mounted perfboard. Slide 3, left. Slide 1 uses the generated product visualization; slide 10 does not require a photo.
- [x] `hardware/circuit-current.jpg`: supplied close-up showing ESP32-S3, power components, and sensor wiring on the perfboard. Slide 3, right.
- [x] `hardware/glove-alpha.jpeg`: supplied historical alpha glove photo. Slide 4; clearly identified as alpha.

## Real app screenshots

Capture from the same current beta build, full resolution, without editor/browser chrome where possible.

- [x] `screenshots/beta-home.png`: supplied Home showing learning paths and progress. Slide 5.
- [x] `screenshots/beta-sign-in.png`: supplied sign-in screen with no real credentials. Slide 5.
- [x] `screenshots/beta-alphabet.png`: supplied alphabet target picker. Slide 5.
- [x] `screenshots/beta-static-practice.png`: supplied letter B practice page in the disconnected state. Slide 5; not evidence of recognition success.
- [x] `screenshots/beta-words.png`: supplied beginner word picker including Hello. Slide 5.
- [ ] Optional `screenshots/beta-hello-practice.png`: Hello practice page from the actual integrated demo build. Capture after fresh live validation and label the actual state. No current placeholder depends on this file.
- [x] `screenshots/alpha-app.png`: supplied historical alpha screen. Slide 4; historical material only.

## Optional generated illustrations

All three illustrations are supplied and used: `illustrations/intro-product-scene.png` (slide 1), `illustrations/learning-problem.png` (slide 2), and `illustrations/haptic-concept.png` (slide 9).

- [x] `illustrations/learning-problem.png`: supplied learner illustration. Slide 2.
- [x] `illustrations/haptic-concept.png`: supplied conceptual glove with vibration marks. Slide 9; not an exact actuator mounting schematic.
- [ ] Optional TCN illustration: no generated image is needed for the current editable diagram. An architecture-specific prompt is in `prompts.md` if the user chooses to replace it. Check generated labels and connections before use.

## Diagrams to create during deck implementation

No generated images needed for these. Use editable HTML/SVG with readable labels.

- System architecture: glove → ESP32 → BLE → mobile recognition → feedback.
- Dynamic pipeline: sensor time window → sequence model → word prediction.
- Dated remaining-work timeline: haptics integration → testing → reliability/polish → release.

Do not generate app screenshots, physical prototype evidence, accuracy plots, or instructional ASL hand poses. Use actual measured data for result visuals.
