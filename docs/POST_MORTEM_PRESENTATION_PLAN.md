# Helping Hand post-mortem presentation plan

Updated November 19, 2026. **Presentation: November 19, 2026**, confirmed by Gael.
This document plans the presentation while project development continues.
It does not schedule completion of the hardware, firmware, models, or app.
The [P3 assignment](../P3-Post-Mortem-Presentation.md) governs requirements.

## November 19 handoff for the slides

- **Live order:** G → Z → 3 → Hello → Please. Use the
  [timed run sheet](../post_mortem_presentation/demo_checklist.md) for exact
  app actions, buzzer patterns, and recovery. Finish on the green learned
  rows in Words. The selected setup is laptop USB power and a signed-in,
  connected Android phone with Developer Mode enabled.
- **Hardware:** Use [the final wired perfboard glove photo](figures/r4/IMG_9891.jpeg)
  as the product image. The fabricated PCB was abandoned after connection and
  trace-quality problems. [Component-side photo](figures/r4/IMG_9894.jpeg) and
  [reverse-side photo](figures/r4/IMG_9893.jpeg) show that prototype. A later
  conductive-thread attempt gave way to discrete wiring after suspected shorts.
  The ten piezos sit at five fingers and five back-of-hand plus positions.
- **Architecture:** Flex and IMU readings feed the ESP32. Its MLP handles held
  poses. The phone runs separate TCNs for J/Z and Hello/Please/Yes, then records
  accepted practice progress. Show BLE in both directions. The glove sends
  readings and output acknowledgments, and the app sends haptic requests.
- **Results to label:** G, I, 1, Hello, Please, and Yes have operator-reported
  live recognition. J/Z's 4/4 matching and 36/36 rejected unrelated attempts
  are offline results. Gael confirmed the automatic **3** cue worked on the
  glove. The Hello/Please cue patterns passed software tests with simulated
  output responses. Live Z and live word cue playback still need a rehearsal.
- **Coverage:** The static MLP has 34 classes, and J/Z use a separate motion
  model. The Words list has eight lessons with green learned rows. The bundled
  recognizer covers Hello, Please, and Yes. Automatic finger correction is
  implemented for 3, and the word cues replay preset patterns after a match.

Use the [evidence checklist](FINAL_REPORT_EVIDENCE_CHECKLIST.md) for BUILD-01,
LIVE-04, EVAL-05, and HAPT-01 through HAPT-04. The app source and model updates
are in the current working copy pending code review and commit. The deck and
its PDF still reflect Draft 01. Refresh the slides, screenshots, notes, and
export together in the presentation session.

## First HTML draft

Draft 01 was built November 6 in
[`post_mortem_presentation/index.html`](../post_mortem_presentation/index.html),
with eight main slides, two separated backups, inline/standalone speaker notes,
and a draft PDF. See the [deck README](../post_mortem_presentation/README.md),
[content review](../post_mortem_presentation/CONTENT_REVIEW.md), and
[recorded presentation checks](../post_mortem_presentation/verification.md).
Final photos, results, haptic behavior, coverage, team stories, and speaker/demo
assignments remain draft content. The beta deck is unchanged.

## Confirmed presentation direction

- Build another **local HTML presentation in the beta style**, with local
  assets/fonts, keyboard navigation, a thin progress line, and a PDF export.
- Prepare the story, layouts, notes, and demo flow now. Add final photos,
  supported capabilities, and results as the team finishes development.
- Use the intended final scope as context for the post-mortem. It included a
  mounted PCB, ICM-20948, integrated haptics, A–Z, 0–9, and all eight words.
- The eight words are **Hello, Thank You, Please, Sorry, Yes, No, Eat, Drink**.
  Source: [`WordsTab.candidateWords`](../flutter_app/lib/screens/tabs/words_tab.dart).

Use the November 19 handoff above for the delivered implementation and
evidence available for this presentation.

## Starting point

The October beta deck told this story: learning problem -> glove/app pipeline
-> alpha foundation -> beta learner experience -> word model -> live demo
-> current limitations -> haptic roadmap -> questions.

The post-mortem should answer: **What did we build, what can the learner do,
what worked well, and what would we change about how we developed it?**
Use the final artifact as the thread connecting those answers. Give the
required three successes and three challenges enough speaking time to explain
causes and lessons, rather than placing six unexplained bullets at the end.

## What to carry forward from beta

| Beta material | Post-mortem use |
| --- | --- |
| [HTML deck](../beta_presentation/index.html), local assets, keyboard controls, 16:9 PDF workflow | Reuse the presentation structure in a separate `post_mortem_presentation/` folder when building the new deck. Preserve the beta deck as its historical submission. |
| [App-matched style](BETA_PRESENTATION_STYLE_GUIDE.md) | Keep ivory, teal, mint, DM Sans, restrained Fraunces branding, spacious composition, and short visual explanations. Adapt content to P3 rather than copying beta-specific requirements. |
| Problem and sensor-to-app pipeline | Compress the introduction; one clear need and one system diagram are enough. |
| Glove photos and app screenshots | Replace with final-assembly photos and current screenshots where available. Label retained October images by date/stage. Prefer the actual final glove for the main product image. |
| Static-versus-sequence model explanation | Keep the conceptual distinction. Put detailed architecture, preprocessing, and evaluation tables in backup material. |
| Dedicated live-demo slide and [demo checklist](../beta_presentation/demo_checklist.md) | Keep a clear transition into live use and prepare the account, BLE connection, wearer, phone projection, and selected targets beforehand. |
| Alpha history and beta feature tour | Fold into final-state evidence and success stories instead of repeating both milestone sections. |
| Haptic roadmap and proposed dates | Replace with the actual final haptic state and a lesson from the work. Describe unfinished work plainly. |

## Proposed running order

P3 specifies **7 minutes with questions throughout**. The beta deck's separately
agreed 5-6 minute presentation plus Q&A does not carry over to this assignment.
Aim for **6 minutes 10 seconds of prepared content**, leaving approximately
50 seconds for interruptions and transitions within seven minutes. This is a
planning target, not a separate Q&A period; rehearse and adjust after the demo
duration and speakers are known.

| Slide | Purpose | Target |
| --- | --- | --- |
| 1. Helping Hand: the need | Introduce the team and explain the ASL practice-feedback need in one sentence, with a strong final-glove image. | 25 s |
| 2. What we built | Show final glove -> ESP32 -> BLE -> Flutter -> practice feedback/progress. Distinguish where static and word inference run. | 30 s |
| 3. The final glove | Annotated final assembly/PCB photos explain the physical changes since beta, including IMU and haptic placement. | 35 s |
| 4. What the learner can practice | Current app journey, final letter/number/word coverage, recognition approach, measured results and limitations. | 35 s |
| 5. Live learner scenario | Demonstrate actual practice feedback, a complete word, and saved completion; include the final haptic behavior. | 90 s |
| 6. Three successes | Explain three challenge -> approach -> outcome stories, about 23 seconds each. | 70 s |
| 7. Three challenges and lessons | Explain three difficulty -> impact -> future change stories, about 23 seconds each. | 70 s |
| 8. Final takeaway | State the delivered capability, its main limit, and the strongest engineering lesson. | 15 s |
| **Prepared content** | | **370 s / 6:10** |

Use concise visual labels on slides 6 and 7; put the explanation in speaker
notes. If six stories do not fit intelligibly, simplify the earlier technical
explanation and expand the reflection time. Eight slides is a proposal, not an
assignment requirement. Assign speaking/demo roles after the content is settled.

## Slide-by-slide creative brief

### 1. Helping Hand: the need

Use the Helping Hand wordmark, team names, a real final-glove photo, and one
sentence about the practice-feedback need. Explain that reference material
alone cannot measure the learner's own hand position or give personalized
correction. Keep the introduction brief. A background statistic is optional;
include one only with appropriate source attribution. Avoid claiming measured
learning effectiveness from prototype recognition results.

### 2. From hand motion to practice feedback

Reuse the editable beta pipeline as one large visual. Explain what finger
bending and motion sensors contribute and how recognition reaches the learner.
Show where static and word inference run in the final architecture. If haptics
are integrated, draw the real feedback path back to the glove, with its actual
trigger source. Keep model internals in backup slides.

### 3. The final glove

Make the final assembly the main visual. Label the cuff perfboard, flex strips,
and piezo locations. Use the fabricated PCB as an iteration comparison and
identify it as the abandoned prototype.
Explain the purpose of the two or three most important physical changes.
Do not turn this into a component inventory. A labeled design render can reserve
the photo space in an early draft; replace it with a real image when available.

### 4. What the learner can practice

Use two or three readable current app screenshots: target selection, practice,
and completion. Include the intended A-Z/0-9 coverage and eight-word list in
drafts, then state actual supported coverage in the final version. Explain
poses versus motion sequences in one sentence. Add a small final-results
callout with its wearer, trial count, and evaluation scope. Keep detailed
architecture, preprocessing, per-sign results, and latency tables in backup
slides. Do not assume the final eight-word model retains the old TCN design
or inherits its historical three-trial score.

### 5. Helping Hand in action

Leave a simple cue slide visible during the live demo. The audience should
follow one learner task through real feedback, adjustment, and saved progress.
Use the proposed run sheet below, adapting it to the actual final UX.

### 6. Three things that went well

Show three numbered story labels with a small relevant visual or outcome each.
Explain **challenge -> action -> outcome -> why it worked** in the notes.
Choose distinct stories and use the candidate pool below. Technical achievements
and concrete collaboration examples are both valid.

### 7. Three challenges and what we learned

Use three concise difficulty/lesson pairs. Explain **difficulty -> why it was
difficult -> impact -> future change**. A resolved difficulty can still be
one of the best post-mortem stories. Select examples from the team's actual
experience rather than treating today's unfinished features as the final list.

### 8. Final takeaway

Return to the learner experience: strongest supported final capability,
most important remaining limit, and one lesson that represents the semester.
Leave this slide visible for questions. If haptics are delivered, replace
beta's future-haptics closing message with the final outcome.

## HTML visual and interaction direction

Use [the beta style guide](BETA_PRESENTATION_STYLE_GUIDE.md): warm ivory
`#FFFCF5`, dark green ink `#183B36`, teal `#007A70`, mint `#C8F0DD`, and a small
gold accent. Keep DM Sans for slide content and restrained Fraunces Italic
for Helping Hand branding. Preserve 16:9, large projected type, open alignment,
and flat surfaces. Give each slide one clear takeaway and one main visual.

Use real glove/PCB photography prominently. Keep app screenshots readable,
preserve proportions, and use short annotations. Explain with editable diagrams
where they help; avoid dense paragraphs and repeated decorative cards.

Reuse the beta keyboard navigation, fullscreen, overview, speaker notes, and
thin progress line. Keep notes/help off the projected screen during delivery.
Support reduced motion and readable contrast. All deck assets should work
locally without internet or a build step; the live app's connection needs are
separate. Check the new slide count and print behavior rather than retaining
assumptions about beta's ten slides.

## Live-demo run sheet

Use the [November 19 run sheet](../post_mortem_presentation/demo_checklist.md) for
the 90-second G → Z → 3 → Hello → Please sequence. Have the phone signed in,
connected, and projected before starting. Agree on a short recovery for retry
or reconnect and use each live result as it occurs.

## Candidate success stories

Select three stories from the expected final build and the documented examples
below. Confirm what happened and why each approach worked before scripting it.

Expected-final-build candidates, conditional on the delivered outcome:

- **Closing the feedback loop:** connect sensing, recognition, meaningful haptic
  cues, and the learner's correction. Explain the integration decision that helped.
- **Building the final wearable:** use the prototype PCB and final wired
  perfboard photos to explain how the team handled connection failures and
  recovered a demo-ready assembly.
- **Expanding recognition coverage:** explain how the separate J/Z model
  handles motion alongside held poses and the three bundled words.

A completed feature can be a success without a measured before/after gain.
Claim improved comfort, reliability, accuracy, or learning only with evidence.
The historical examples below are alternatives and source material, not a
requirement to keep the post-mortem focused on the beta build.

| Success | Challenge and approach to explain | Outcome and supporting evidence |
| --- | --- | --- |
| Connecting sensing to a learner experience | Getting sensor capture, BLE, recognition feedback, and progress to work together. Explain the shared packet contract and how the team checked each stage. | Historical physical glove-to-phone operation is documented. Later team observations report practiced signs and progress visible in the app and Firebase. Use [demo observations](R3_DEMO_OBSERVATIONS.md); confirm the final assembly separately. |
| Adding motion-based word practice | A static pose cannot represent the time evolution of a word. The team recorded complete attempts, compared TCN/CNN-GRU/CNN-LSTM, selected a small TCN, and integrated Start/Finish inference in Flutter. | Hello/Please/Yes are packaged; Hello and Please recognition/completion were reported during the October demo. The comparison used only 15 real attempts. Use [training](WORD_MODEL_DEMO_TRAINING.md), [integration](WORD_DEMO_INTEGRATION.md), and [physical observations](R3_DEMO_OBSERVATIONS.md). |
| Turning predictions into saved practice progress | A predicted label alone does not complete a learner workflow. Explain target selection, static stability checks, word-attempt matching, completion feedback, and account-scoped storage. | The learner flow is implemented; the team reported checking completion indicators and corresponding Firebase progress. This does not establish measured human learning or retention, restart recovery, or cross-device reliability. Use [release-candidate documentation](../RELEASE_CANDIDATE.md) and [demo observations](R3_DEMO_OBSERVATIONS.md). |

The first story should emphasize device/software integration; the third should
emphasize the learner interaction and persistence design so they remain distinct.
Replace one with a communication/versioning/task-distribution success if the team
has a specific, better-supported example. Explain the actual mechanism and result.

## Candidate challenges and future changes

| Challenge | What made it difficult / effect | Future change to discuss |
| --- | --- | --- |
| Sensor damage and changing calibration | Thumb/index sensor faults were reported, and replacement sensors/mounting can change input distributions. Historical model results cannot establish performance on the rebuilt glove. | Add regular raw-signal health checks, mounting/strain-relief checks, calibration records, and repeated attempts after re-donning. Collect and evaluate data on the actual final assembly before reporting improvement. |
| Limited data and motion coverage | The three-word and J/Z results come from small datasets. The J/Z replay included a focused set of matching trials and unrelated motions. | Reserve fresh attempts, distinct wearers and orientations, confusable signs, and incomplete or unrelated gestures. Record false completions along with correct ones. |
| Completing hardware/software integration | The custom PCB and conductive-thread assembly had unreliable connections. The team finished the demo glove with wired perfboard. The automatic 3 cue worked in rehearsal, and the new word cues have software checks. | Plan smaller end-to-end milestones with explicit acceptance checks. Reserve time for wiring continuity, interruption checks, and wearer perception tests. |

Sources: [current glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md),
[demo observations](R3_DEMO_OBSERVATIONS.md), and
[model optimization audit](DEMO_MODEL_OPTIMIZATION.md). If final work resolves
one of these issues, retain the historical difficulty and explain the actual
resolution rather than continuing to label it unfinished.

## Presentation content and assets to update

Build the layouts and notes now, using visible draft markers such as
`[final glove photo]`, `[PCB close-up]`, `[haptic cue meaning]`,
`[final recognition coverage]`, and `[measured result + scope]`.
Do not invent data to fill a layout. Remove all draft markers from the final deck.

| Content | Prepare now | Update as development finishes |
| --- | --- | --- |
| Cover/problem | Team, purpose, short problem statement. | Final glove image. |
| System diagram | Editable sensing/recognition/feedback structure. | Actual final inference and haptic paths. |
| Hardware slide | Photo layout and beta reference image. | Final wired glove, abandoned PCB comparison, IMU, and haptic placement. |
| App/capability slide | Learner journey and eight-word target list. | Current screenshots and actual supported coverage. |
| Results callout | Fields for scope, trials, result, model size, and latency. | Relevant measured final figures and their sources. |
| Reflection | Story prompts and provisional selection. | Team-confirmed examples, decisions, outcomes, and lessons. |
| Demo cue/notes | Scenario, roles, transitions, recovery wording. | Rehearsed targets, real feedback behavior, starting app state. |

For each unfinished content item, record its slide, intended message, current
fact, source/asset location, owner, and final wording in the deck's content review.
The checks below guide accurate presentation content; they do not impose an
engineering schedule or expand the assignment's test requirements.

Use the November 19 handoff at the top as the technical starting point. The
October beta deck and November 6 plans remain historical references.

- Record the final hardware, firmware/app revisions, phone, model bundle, and
  calibration configuration; take final assembly photos and current screenshots.
- Confirm final feature/mode status, including sign practice, word practice,
  accounts/progress, recording/developer tools, and haptics. State what is
  integrated, what was physically tested, and what remains incomplete.
- Record fresh demo attempts and failures on the intended glove/phone. Choose
  reliable targets from those results. Preconfigure login and BLE, then show
  actual use rather than spending the demo on setup.
- Report measured performance with its scope: attempts per sign, failures/false
  completions, actual delivered packet rate, model size, and intended-phone
  latency where measured. Keep unexecuted measurements labeled **Not run**.
- Keep implementation thresholds separate from measured accuracy. The current
  recorded static model has 34 classes, excluding J/Z; the original 36-class
  baseline is preserved. The packaged word TCN covers Hello, Please, Yes.
- Do not promote the historical three-trial test result into general accuracy.
  Historical data reused during development is regression evidence; reserve
  fresh attempts for a final evaluation claim.
- Describe Number 3 as finger-and-direction feedback. Describe the word
  cues as preset playback. Give the actual wearer observation if discussing
  how strongly the piezos can be felt.
- Prepare a short recovery path for live failures. Continue showing genuine
  available functionality, explain the failure, and keep the live-use requirement.
  Recordings/screenshots can support an explanation but do not fulfill that requirement.

## Presentation production schedule

These dates organize presentation work only. They do not set deadlines for
completing project features or require engineering work to stop before Nov 19.

| Dates | Presentation work | Reviewable output |
| --- | --- | --- |
| Nov 6-8 | Settle the story, slide order, and preferred demo scenario. Gather each teammate's success/challenge examples and assign presentation responsibilities. | Agreed outline, provisional reflection stories, speaker/demo roles. |
| Nov 9-12 | Build the HTML first draft and rough speaker notes in the beta style. Reserve final-photo/result spaces with explicit draft markers. | A complete deck that can be narrated from start to finish. |
| Nov 13-16 | Add available photos, screenshots, and results; refine story choices and diagrams. Rehearse narration and transitions. | Coherent slides, current content checklist, timed narration rehearsal. |
| Nov 17-18 | Rehearse the actual live sequence, update claims to match the build being shown, check projection/layout, and inspect the PDF. | Timed full rehearsal, final run sheet, readable submission export. |
| Nov 19 | Check props/devices/projection, open the final deck, deliver live, and submit slides/props on Canvas per course instructions. | Presentation and submission materials. |

If a feature changes late, revise its claim, image, and demo step. The narrative,
reflection, layouts, and speaker preparation can proceed now.

## HTML presentation files

Create these during slide production, using beta as the starting point:

```text
post_mortem_presentation/
  index.html              # Main slides and separated backup slides
  styles.css              # App-matched slide and print layout
  presentation.js         # Keyboard, overview, notes, fullscreen, progress
  README.md               # Open, present, and export instructions
  speaker_notes.md        # Script, timing, transitions, speaker roles
  demo_checklist.md       # Presentation setup and live run sheet
  CONTENT_REVIEW.md       # Draft slots, evidence, final content checks
  sources.md              # Claim and asset attribution
  assets/                 # Local fonts, photos, screenshots, diagrams
  exports/                # Canvas PDF
```

Keep backups outside the timed main-deck flow. Decide whether they belong in
the Canvas PDF, and make the navigation/export behavior match that decision.

## Speaker preparation and backup material

Give each teammate a meaningful speaking or demo responsibility, with exact
assignments to be agreed by the team. Keep related explanations together to
avoid constant speaker changes. Put handoff lines in the notes and assign
someone to advance slides and someone to manage the phone.

Prepare concise backup answers about sensor/IMU choice, PCB purpose, haptic cue
meaning, static versus motion recognition, J/Z, eight-word coverage, dataset
splits, wearer/orientation scope, confusable signs/false completions, latency,
model size, saved progress, and remaining limitations. Use the actual final
implementation and measurements.

## Final presentation checklist

- [ ] Context, final state, live use, three successes, and three challenges are covered.
- [ ] Notes explain why things worked or were difficult, and what the team learned.
- [ ] Narration, transitions, and live demo fit seven minutes with room for questions.
- [ ] Photos, claims, vocabulary, results, and haptic descriptions match the demonstrated build.
- [ ] No draft markers, stale beta roadmap dates, or proposed results presented as facts remain.
- [ ] Local HTML/assets, keyboard controls, fullscreen, notes privacy, and backup access work.
- [ ] Projected slides and exported PDF are readable with no clipping or overlaps.
- [ ] Wearer, phone operator, speakers, projection, and recovery transitions are rehearsed.
- [ ] Props, professional attire, device preparation, and Canvas materials are ready.

Browser/slide/PDF checks validate the presentation artifact; they are not glove,
model, haptic, or usability validation.
