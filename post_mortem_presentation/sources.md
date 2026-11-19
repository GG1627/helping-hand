# Sources and asset provenance

## Claims

- Slide 2 uses [Lieberman, Mitchiner, and Pontecorvo, §3.2.1 and Table 3](https://sites.bu.edu/lavalab/files/2022/06/Lieberman-Mitchiner-Pontecorvo-2022.pdf).
  Of 100 hearing parents surveyed who had learned ASL, 94 reported using
  self-teaching resources, including books, videos, and apps.

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

- [Cover product scene](assets/illustrations/cover-product-scene-knit.png) is a
  built-in ImageGen edit of the [ivory cover](assets/illustrations/cover-product-scene-ivory.png).
  Gael's supplied `Smart Glove Hand Tracking Demo.png` guides hand pose and
  hardware placement. The [final prototype photo](../docs/figures/r4/IMG_9891.jpeg)
  guides the knit texture. The phone uses the original
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
- [Sign-in screen](assets/screenshots/sign-in-cleared.png) derives from Gael's
  November 19, 05:15:06 screenshot. The built-in ImageGen tool cleared the email
  and masked password fields for projection.
- The system diagram and icons are editable HTML/CSS/SVG. DM Sans and Fraunces
  Italic follow the [beta style guide](../docs/BETA_PRESENTATION_STYLE_GUIDE.md).
  Their local font licenses are in `assets/fonts/`.

### Sign-in screenshot edit prompt

> Precise document screenshot cleanup for a presentation. Use the supplied portrait screenshot as the exact edit target. Clear only the typed email-address value inside the Email address input and the six masked-password dots inside the Password input, leaving those two input interiors uniformly blank in their original shade. Preserve the original image's tall portrait framing, proportions and edge-to-edge app screenshot, every other pixel and text as closely as possible. Keep the Helping Hand wordmark, tagline, Welcome back, sign-in explanation, field outlines and their labels Email address and Password, eye icon, Forgot password?, Sign in button, Create account, top status icons and bottom navigation line. Do not add replacement text, placeholder values, device frame or any other object. The email address value must not appear anywhere.

### Cover product scene generation prompt

The [first composition](assets/illustrations/cover-product-scene.png) used this prompt.

> Use case: compositing for a full-bleed 16:9 technical presentation cover. Image 1 is the beta composition reference; recreate its ivory desktop scene, negative space, lighting, and left-to-right staging, while updating the wearable. Image 2 shows the real final prototype; it is the hardware reference and takes precedence over the beta version. Image 3 is the actual Android Home capture and is the placement and aspect-ratio reference for the phone display, which will be composited separately. Keep the left 44 percent of the landscape frame nearly empty, evenly lit warm ivory all the way down, for editable text later. In the right foreground show an adult wearing the exact black knitted glove from Image 2, seen straight-on from the back of the hand with the thumb on the left, fingers relaxed and open, and the wrist extending off the lower-right edge. Keep all five long silver striped flex strips, ten small round golden/ivory piezo discs in the photographed layout, the loose red, orange and black wires, and the blue perfboard and black ESP32 mounted at the cuff. Match the shape, component placements and colors of Image 2 as faithfully as possible. Keep the fingers and cuff in frame. Do not bring back the older green circuit board or silver battery. Behind and just to the left of the glove at roughly 57% of the image width, place one upright modern slim black Android phone resting on a small stand on the desk. Its whole screen is visible and unobscured, facing the camera straight-on with edges nearly vertical, portrait screen with interior aspect ratio approximately 0.45, and a uniform solid pale ivory display that I can replace with Image 3. Keep the phone a little smaller than the glove and keep the background soft. Warm natural desk lighting, restrained muted green plant or accents on the far right. Photorealistic product staging, authentic engineering prototype, no extra electronics, no extra phones, no generated text or logo.

### Relaxed hand edit prompt

The [earlier relaxed-hand scene](assets/illustrations/cover-product-scene-relaxed.png)
used this prompt.

> Use case: precise object edit. Image 1 is the edit target, a 16:9 Helping Hand cover photo. Image 2 is the final hardware reference. Edit only the worn glove and the hand within it on the right of Image 1. Change the existing rigid fingers-up pose to a natural, relaxed adult hand pose, as though the wearer has lifted a resting hand slightly off a desk. Rotate the wrist subtly so the fingers angle gently diagonally rather than pointing straight up. Let the fingers curve forward at their knuckles in a loose, shallow arc, with different amounts of curl and small natural gaps. Give the thumb a relaxed angle toward the palm. Keep the back of the hand broadly facing the viewer, all five fingers anatomically believable with proportional length, and the black knitted fabric resting over each finger instead of appearing flat or stiff. The flex strips should bend around the fingers with the fabric. Preserve the final glove's five striped silver flex strips, positioned piezo discs, red, orange and black wires and blue perfboard at the cuff from Image 2; preserve the same hardware version and realistic proportions. Keep the electronics visible and let the forearm enter from the lower right as in Image 1. The hand is simply relaxed, with no intended ASL sign. Preserve everything outside the hand and glove as closely as possible: the exact 16:9 composition, empty ivory left half, the phone's exact position, angle, blank ivory screen and four screen corners, stand, desktop, background, plant, lighting and scale. The phone screen is overlaid with a separate image afterwards, so do not reframe or redraw it. Photorealistic; no text, extra fingers, or new hardware.

### Open hand and centered cuff edit prompt

This prompt produced the [previous open-hand scene](assets/illustrations/cover-product-scene-open.png).

> Use case: precise object edit. Image 1 is the exact 16:9 slide cover scene to edit. Image 2 is the final prototype hardware reference. Change only two things on the worn glove at the right of Image 1. (1) OPEN AND STRAIGHTEN all five fingers at the knuckles and finger joints, including the thumb. Each should be physically straight rather than curling forward. Preserve the existing diagonal wrist rotation, the angle in the picture of each digit, the spacing/spread between digits, the overall hand position, and a normal right-hand anatomy. The four long digits should angle diagonally toward the upper left as they already do, fanning slightly, not all parallel and vertical. Keep all five fingertips in the frame and let the silver-striped flex strips rest flat along the straight fingers. (2) Move the entire blue perfboard and attached black ESP32 together a short distance to viewer-right, to visibly center the assembly across the black wrist cuff. Center it between the cuff's left and right edges, exactly over the longitudinal centerline of the wrist, while keeping the same size, direction, height along the cuff, and short red/orange/black wires connected. Keep the black knit, five silver flex strips, gold-and-ivory piezo discs, and all other hardware visually the same. Match reference hardware; do not add battery or electronics. Preserve everything outside the glove exactly: phone, position and geometry of all four corners of the blank ivory phone display, plant, desktop, forearm, light, empty ivory copy area, and canvas dimensions. No text, logos, additional fingers, or new objects.

### Beta hand pose and warm-white background prompts

> Use case: precise object edit for Helping Hand's 16:9 slide cover. Image 1 is the current post-mortem cover and the edit target. Image 2 is the beta cover and provides ONLY the hand-pose reference. Image 3 is the photo of the final prototype and provides ONLY the hardware reference. On Image 1, adjust the worn glove's finger positioning and spacing to match the beta hand in Image 2. Copy the beta's natural, open right hand silhouette and knuckle alignment: middle finger tallest, index and ring slightly lower, little finger distinctly shorter, thumb outward and lower, fingers comfortably separated. Match the visible placement, orientation, and gaps from Image 2 without copying its glove hardware. Keep the four fingers extended with natural slight individual angles, not curled, rigidly identical or unnaturally stretched. Maintain the current glove's five striped flex sensors, round piezo discs, wire colors and the blue perfboard with ESP32 centered on the cuff. Keep all of the final version's hardware and expose the cuff. Preserve the adult forearm, blank ivory text area, the phone's exact four screen corners and blank display, its stand, desktop, plant, framing, light, and 16:9 dimensions from Image 1. The real Android Home capture is composited separately over the blank phone screen. Do not change any object other than the hand and fingers of the worn glove. No text, extra fingers, battery, or new objects.

> Precise background color edit for the attached full-bleed 16:9 presentation cover. Keep the exact glove, beta-inspired finger positions and spacing, wrist-mounted hardware, hand and forearm, phone and all four corners of its blank display, phone stand, plant, camera framing, proportions and positions pixel-aligned. Change the room backdrop and desktop color only: make it a bright warm-white studio scene to match a presentation with background color #FFFCF5. The left half should be seamlessly warm white (#FFFCF5) for slide text, with no pink or brown cast. Behind the glove and around the phone, use a soft off-white wall and a nearly white tabletop with faint natural texture and the existing soft shadows. Keep the small green accent soft. Preserve real hardware colors and natural skin tone. No text, graphics or extra objects. Same canvas size and composition.

### Knit fabric edit prompt

> Precise product-photo edit for slide 1. Image 1 is the full 16:9 slide background and the edit target. Image 2 is the user's close-up reference for the glove, natural straight open fingers and centered wrist-mounted board. Image 3 is the real glove photograph, the material and hardware reference. Update ONLY the black glove cloth in Image 1: make it look like the real, inexpensive soft black knitted fabric from Image 3, with tiny interlocking yarn loops visible on fingers, fine woven/matte soft fabric on the back of the hand, some soft lint, and an actual rib-knit cuff. Subtle, irregular thread highlights in charcoal, slight fuzzy textile silhouette, and smooth tension over the back of the hand. Remove the molded glossy rubber texture, fine etched lines, and deep wrinkled ripples. Keep the five naturally open extended fingers and all five sensor strips. Follow the close-up for the visible gold piezo disks, red, orange and black wires, and blue perfboard centered on the wrist. Hold the exact camera and composition of Image 1, including the exact phone bezel position, empty ivory phone display for a later overlay, blank warm-white left space, tabletop, soft background and overall hand outline. No added text, don't crop. Full-width 16:9 background. Photorealistic soft indoor light.

### Earlier cover backdrop generation prompt

The previous cover used [this generated backdrop](assets/illustrations/cover-backdrop.png).

> Use case: productivity-visual. Generate only the image background for the opening slide of Helping Hand, an ASL learning glove and app. Full-bleed 16:9 landscape. Make it look like a premium editorial product photograph of a carefully art-directed empty studio flat lay, with a real photographed object and a phone to be composited later. The left 45% is a continuously blank warm ivory paper surface (#FFFCF5), very even light and low texture, for dark slide type. The right half is a boldly colored field of rich deep teal (#00645C) matte paper, filling the right edge and bottom edge, entering from the upper edge at 60% frame width and easing to a soft angled edge near 44% at the bottom. Layer a sculptural mint paper ribbon or curled strip on the far right edge and lower-right corner, with realistic directional sunlight and clean soft shadows, evocative of motion and a haptic pulse. Add one very small golden yellow accent in the upper right. Keep the center-right area relatively quiet so two foreground product images can sit there. Restrained modern product-launch art direction, crisp clear geometry, subtle physical paper grain, refined and confident. No glove, hands, phone, electronics, frames, circles, words, lettering, typography, or logos.
