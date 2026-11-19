# Sources and asset provenance

## Claims

- Slide 2 uses the [NIDCD hearing statistics](https://www.nidcd.nih.gov/health/statistics/quick-statistics-hearing)
  for the percentage of deaf children born to hearing parents. NIDCD cites
  [Mitchell and Karchmer (2004)](https://gallaudetcdn.com/gal-media/Documents/Research-Support-and-International-Affairs/SLS_Paper.pdf).
  The statistic describes parental hearing status. The feedback gap is the
  problem Helping Hand addresses.

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

- [Cover product scene](assets/illustrations/cover-product-scene-open.png) is a
  built-in ImageGen visualization based on the
  [beta composition](../beta_presentation/assets/illustrations/intro-product-scene.png)
  and the supplied final glove photo. The phone display uses the original
  [Home capture](assets/screenshots/home-nov19.png) from November 19, 05:13:01.
  Slide 5 shows the original hardware photo.
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

### Cover product scene generation prompt

The [first composition](assets/illustrations/cover-product-scene.png) used this prompt.

> Use case: compositing for a full-bleed 16:9 technical presentation cover. Image 1 is the beta composition reference; recreate its ivory desktop scene, negative space, lighting, and left-to-right staging, while updating the wearable. Image 2 shows the real final prototype; it is the hardware reference and takes precedence over the beta version. Image 3 is the actual Android Home capture and is the placement and aspect-ratio reference for the phone display, which will be composited separately. Keep the left 44 percent of the landscape frame nearly empty, evenly lit warm ivory all the way down, for editable text later. In the right foreground show an adult wearing the exact black knitted glove from Image 2, seen straight-on from the back of the hand with the thumb on the left, fingers relaxed and open, and the wrist extending off the lower-right edge. Keep all five long silver striped flex strips, ten small round golden/ivory piezo discs in the photographed layout, the loose red, orange and black wires, and the blue perfboard and black ESP32 mounted at the cuff. Match the shape, component placements and colors of Image 2 as faithfully as possible. Keep the fingers and cuff in frame. Do not bring back the older green circuit board or silver battery. Behind and just to the left of the glove at roughly 57% of the image width, place one upright modern slim black Android phone resting on a small stand on the desk. Its whole screen is visible and unobscured, facing the camera straight-on with edges nearly vertical, portrait screen with interior aspect ratio approximately 0.45, and a uniform solid pale ivory display that I can replace with Image 3. Keep the phone a little smaller than the glove and keep the background soft. Warm natural desk lighting, restrained muted green plant or accents on the far right. Photorealistic product staging, authentic engineering prototype, no extra electronics, no extra phones, no generated text or logo.

### Relaxed hand edit prompt

The [earlier relaxed-hand scene](assets/illustrations/cover-product-scene-relaxed.png)
used this prompt.

> Use case: precise object edit. Image 1 is the edit target, a 16:9 Helping Hand cover photo. Image 2 is the final hardware reference. Edit only the worn glove and the hand within it on the right of Image 1. Change the existing rigid fingers-up pose to a natural, relaxed adult hand pose, as though the wearer has lifted a resting hand slightly off a desk. Rotate the wrist subtly so the fingers angle gently diagonally rather than pointing straight up. Let the fingers curve forward at their knuckles in a loose, shallow arc, with different amounts of curl and small natural gaps. Give the thumb a relaxed angle toward the palm. Keep the back of the hand broadly facing the viewer, all five fingers anatomically believable with proportional length, and the black knitted fabric resting over each finger instead of appearing flat or stiff. The flex strips should bend around the fingers with the fabric. Preserve the final glove's five striped silver flex strips, positioned piezo discs, red, orange and black wires and blue perfboard at the cuff from Image 2; preserve the same hardware version and realistic proportions. Keep the electronics visible and let the forearm enter from the lower right as in Image 1. The hand is simply relaxed, with no intended ASL sign. Preserve everything outside the hand and glove as closely as possible: the exact 16:9 composition, empty ivory left half, the phone's exact position, angle, blank ivory screen and four screen corners, stand, desktop, background, plant, lighting and scale. The phone screen is overlaid with a separate image afterwards, so do not reframe or redraw it. Photorealistic; no text, extra fingers, or new hardware.

### Open hand and centered cuff edit prompt

> Use case: precise object edit. Image 1 is the exact 16:9 slide cover scene to edit. Image 2 is the final prototype hardware reference. Change only two things on the worn glove at the right of Image 1. (1) OPEN AND STRAIGHTEN all five fingers at the knuckles and finger joints, including the thumb. Each should be physically straight rather than curling forward. Preserve the existing diagonal wrist rotation, the angle in the picture of each digit, the spacing/spread between digits, the overall hand position, and a normal right-hand anatomy. The four long digits should angle diagonally toward the upper left as they already do, fanning slightly, not all parallel and vertical. Keep all five fingertips in the frame and let the silver-striped flex strips rest flat along the straight fingers. (2) Move the entire blue perfboard and attached black ESP32 together a short distance to viewer-right, to visibly center the assembly across the black wrist cuff. Center it between the cuff's left and right edges, exactly over the longitudinal centerline of the wrist, while keeping the same size, direction, height along the cuff, and short red/orange/black wires connected. Keep the black knit, five silver flex strips, gold-and-ivory piezo discs, and all other hardware visually the same. Match reference hardware; do not add battery or electronics. Preserve everything outside the glove exactly: phone, position and geometry of all four corners of the blank ivory phone display, plant, desktop, forearm, light, empty ivory copy area, and canvas dimensions. No text, logos, additional fingers, or new objects.

### Earlier cover backdrop generation prompt

The previous cover used [this generated backdrop](assets/illustrations/cover-backdrop.png).

> Use case: productivity-visual. Generate only the image background for the opening slide of Helping Hand, an ASL learning glove and app. Full-bleed 16:9 landscape. Make it look like a premium editorial product photograph of a carefully art-directed empty studio flat lay, with a real photographed object and a phone to be composited later. The left 45% is a continuously blank warm ivory paper surface (#FFFCF5), very even light and low texture, for dark slide type. The right half is a boldly colored field of rich deep teal (#00645C) matte paper, filling the right edge and bottom edge, entering from the upper edge at 60% frame width and easing to a soft angled edge near 44% at the bottom. Layer a sculptural mint paper ribbon or curled strip on the far right edge and lower-right corner, with realistic directional sunlight and clean soft shadows, evocative of motion and a haptic pulse. Add one very small golden yellow accent in the upper right. Keep the center-right area relatively quiet so two foreground product images can sit there. Restrained modern product-launch art direction, crisp clear geometry, subtle physical paper grain, refined and confident. No glove, hands, phone, electronics, frames, circles, words, lettering, typography, or logos.
