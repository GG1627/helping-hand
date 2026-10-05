# Presentation image checklist

PNG preferred for screenshots; JPG or PNG for photos. Preserve original resolution and screenshot proportions. Filenames below are suggestions; no need to crop to a slide shape. Use a demo account and remove personal information.

## Real photographs

Current deck placeholders: `hardware/glove-current.jpg` and `hardware/circuit-current.jpg`. After adding a file, enable its entry in `asset-manifest.js`, reload, and regenerate the PDF. The historical alpha glove is available as `hardware/glove-alpha.jpeg`. Slide 6 now uses an architecture diagram; the Hello screenshot is optional future supporting material after model integration.

- [ ] `hardware/glove-current.jpg`: current complete glove, all fingers and wrist visible, uncluttered background, landscape framing with space around the glove. Slides 1/3/10.
- [ ] `hardware/circuit-current.jpg`: sharp overhead or angled close-up showing the actual ESP32, IMU, flex-sensor connections, and wiring. No labels needed; add them in the deck. Slide 3 or supporting hardware detail.
- [x] `hardware/glove-alpha.jpeg`: supplied historical alpha glove photo. Slide 4; clearly identified as alpha.

## Real app screenshots

Capture from the same current beta build, full resolution, without editor/browser chrome where possible.

- [x] `screenshots/beta-home.png`: supplied Home showing learning paths and progress. Slide 5.
- [x] `screenshots/beta-sign-in.png`: supplied sign-in screen with no real credentials. Slide 5.
- [x] `screenshots/beta-alphabet.png`: supplied alphabet target picker. Slide 5.
- [x] `screenshots/beta-static-practice.png`: supplied letter B practice page in the disconnected state. Slide 5; not evidence of recognition success.
- [x] `screenshots/beta-words.png`: supplied beginner word picker including Hello. Slide 5.
- [ ] Optional `screenshots/beta-hello-practice.png`: Hello practice page from the actual integrated demo build. Capture after integration; use if useful when revising slide 6. No current placeholder depends on this file.
- [x] `screenshots/alpha-app.png`: supplied historical alpha screen. Slide 4; historical material only.

## Optional generated illustrations

All three illustrations are supplied and used: `illustrations/intro-product-scene.png` (slide 1), `illustrations/learning-problem.png` (slide 2), and `illustrations/haptic-concept.png` (slide 9).

- [x] `illustrations/learning-problem.png`: supplied learner illustration. Slide 2.
- [x] `illustrations/haptic-concept.png`: supplied conceptual glove with vibration marks. Slide 9; not an exact actuator mounting schematic.

## Diagrams to create during deck implementation

No generated images needed for these. Use editable HTML/SVG with readable labels.

- System architecture: glove → ESP32 → BLE → mobile recognition → feedback.
- Dynamic pipeline: sensor time window → sequence model → word prediction.
- Dated remaining-work timeline: haptics integration → testing → reliability/polish → release.

Do not generate app screenshots, physical prototype evidence, accuracy plots, or instructional ASL hand poses. Use actual measured data for result visuals.
