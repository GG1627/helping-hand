# R3 Word report citation ledger

Updated November 13, 2026. Project reporting viewpoint: October 28, 2026.

The user is assembling the report in Word and replacing linked citation
numbers from chat with plain bracketed numbers. Maintain this ledger as
sections are drafted so the final bibliography matches the Word text.
Save drafting updates locally; batch commits at meaningful milestones under
the user's revised workflow preference.

## Current first-use order

| IEEE number | Stable source ID | First use | Supported material |
| --- | --- | --- | --- |
| [1] | ASL-CONTEXT | Background, paragraph 1 | ASL grammar and expression through hands and face. |
| [2] | ASL-EDUCATORS | Background, paragraph 2 | Educator interviews/focus groups and considerations for learning feedback. |
| [3] | WEARABLE-ASL | Background, paragraph 3 | Six-IMU, LSTM-based recognition of 27 word-level ASL signs; hardware/evaluation differ from ours. |
| [4] | TCN | Background, paragraph 4 | General convolutional/recurrent sequence-model comparison; identified as a preprint. |
| [5] | MAGNETIC | Background, paragraph 5 | Magnetometer calibration and alignment for heading estimation; no claimed improvement for our glove. |
| [6] | HAPTIC-STUDY | Background, paragraph 6 | Reduced vibration-cue identification during repetitive hand movement; no validated Helping Hand cues. |
| [7] | SIGNALOUD | Design, opening paragraph | User-confirmed visual inspiration; correct University of Washington attribution. |
| [8] | I2C | Design, recognition and communication | Sensor-bus protocol. |
| [9] | BLE | Design, recognition and communication | BLE/GATT and notifications. |
| [10] | NUS | Design, recognition and communication | Vendor-defined UART-style service with notify/write characteristics. |
| [11] | REPO | Design, recognition and communication | One October 28 archive pointer for the team's model and implementation artifacts. |
| [12] | FIREBASE-PRIVACY | Design, app and progress | HTTPS protection of Firebase service traffic; not evidence of verified app account isolation. |
| [13] | IMU | Design, planned improvements and risks | ICM-20948 replacement's additional magnetic-field channels. |
| [14] | FLEX | Design, planned improvements and risks | Contact strain-relief guidance relevant to replacement-sensor mounting. |
| [15] | PLATFORMIO | Tools, paragraph 1 | Embedded firmware development/build tool. |
| [16] | FLUTTER | Tools, paragraph 1 | Flutter/Dart application development. |
| [17] | TENSORFLOW | Tools, paragraph 1 | TensorFlow/Keras model training. |
| [18] | TFLITE-MICRO | Tools, paragraph 1 | Embedded TensorFlow Lite inference approach. |
| [19] | TFLITE-FLUTTER | Tools, paragraph 1 | Phone inference through the Flutter plugin. |
| [20] | FIREBASE | Tools, paragraph 2 | Firebase Flutter integration, Authentication, and Firestore. |
| [21] | KICAD | Tools, paragraph 2 | Schematic and PCB design tooling. |
| [22] | DEAF-LED | Needs and Impact Analysis, cultural/global discussion | Meaningful Deaf stakeholder participation in sign-language technology development. |

**The next newly introduced source receives [23].** Reuse [1]-[22] whenever
the corresponding source appears again. Do not number a source according to
its position in the selected-source file: that file's ordering is not the
report's citation order.

## Source details for the final bibliography

Full IEEE-style metadata and verified links are in
[R3 Word selected references](R3_WORD_REFERENCES.md), under the matching IDs.
The [copy-ready numbered bibliography](../docs/R3_WORD_BIBLIOGRAPHY.md)
was assembled from those entries in this ledger's order, with all 22 numbers
checked for a gap-free sequence and a matching source ID. It was initially
reconciled against the user's Word document November 13. The body
has one typo: PlatformIO is cited as [14], which should be [15]. With that
single correction, the first-use order matches [1]-[22] and all entries are
cited. The correction has been recommended, not applied to the Word file.
The Background entries are:

- [1] National Institute on Deafness and Other Communication Disorders,
  "American Sign Language."
- [2] S. Hassan et al., "ASL Educators' Perspectives on AI for Enhancing
  Student Learning in American Sign Language Education," CHI 2026,
  doi: 10.1145/3772318.3791928.
- [3] B. G. Lee, T.-W. Chong, and W.-Y. Chung, "Sensor Fusion of Motion-Based
  Sign Language Interpretation with Deep Learning," *Sensors*, 2020,
  doi: 10.3390/s20216256.
- [4] S. Bai, J. Z. Kolter, and V. Koltun, "An Empirical Evaluation of Generic
  Convolutional and Recurrent Networks for Sequence Modeling," arXiv preprint
  arXiv:1803.01271, 2018.
- [5] M. Kok and T. B. Schön, "Magnetometer Calibration Using Inertial Sensors,"
  *IEEE Sensors Journal*, 2016, doi: 10.1109/JSEN.2016.2569160.
- [6] M. Tajdari, J. Forsyth, and S. Lim, "Sensitivity to Vibrotactile
  Stimulation in the Hand and Wrist: Effects of Motion, Temporal Patterns,
  and Biological Sex," *Human Factors*, 2025,
  doi: 10.1177/00187208241275734.

Design entries, in first-use order:

- [7] University of Washington, UW News SignAloud article, Apr. 12, 2016.
- [8] NXP Semiconductors, *I2C-bus Specification and User Manual*, UM10204,
  rev. 7.0, Oct. 1, 2021.
- [9] Bluetooth SIG, "The Bluetooth Low Energy primer," ver. 1.3.0.
- [10] Nordic Semiconductor, "Nordic UART Service (NUS)."
- [11] Helping Hand team, October 28 repository snapshot cf59fd98.
- [12] Firebase, "Privacy and Security in Firebase."
- [13] Adafruit Industries, ICM-20948 product 4554.
- [14] Adafruit Industries, Short Flex Sensor product 1070.

Tools entries, in first-use order:

- [15] PlatformIO, "What is PlatformIO?"
- [16] Flutter, "Flutter documentation."
- [17] TensorFlow, "Keras: The high-level API for TensorFlow."
- [18] Google AI Edge, "LiteRT for Microcontrollers."
- [19] TensorFlow, "tflite_flutter," version 0.12.1.
- [20] Firebase, "Get started with Firebase in your Flutter project."
- [21] The KiCad Documentation Contributors, *Getting Started in KiCad*,
  documentation version 9.0, not a confirmed installed team version.

These seven official documentation pages were rechecked November 13.

Needs and Impact entry:

- [22] A. Desai, M. De Meulder, J. A. Hochgesang, A. Kocab, and A. X. Lu,
  "Systemic Biases in Sign Language AI Research: A Deaf-Led Call to Reevaluate
  Research Agendas," LREC-COLING SignLang Workshop, 2024, pp. 54-65.
  The publication record was rechecked November 13; the primary PDF was
  inspected in the earlier reference review. This section also reuses [1].

## Draft progress and reconciliation

- Introduction: user reports copying it into Word. No numbered citations.
  The last sentence was revised in chat to use a current project viewpoint:
  "This report explains the project's background and design, the results
  from our alpha and beta work, our current progress, and what we still
  need to complete."
- Background: six-paragraph draft supplied in chat, with [1]-[6] in order.
  The user will manually retain just the bracketed numbers in Word.
- Abstract: single-paragraph draft supplied after the Conclusion, within the
  required 200-300 words. No citations. Summarizes purpose, sensing/app design,
  limited 15-trial word comparison and 3/3 reserved result, physical sensor
  faults, incomplete hardware integration, and planned calibration/data/testing.
  It will be placed before the Introduction in Word.
- Design: draft supplied in chat after the user's assembly/power/priorities
  answers and confirmation that the finger-mounted devices are flex sensors.
  Introduces [7]-[14]. User review/copying is not yet confirmed. Useful diagram
  and prototype-photo placement are discussed separately from the prose.
- Tools, Design Constraints, and Engineering Standards: draft supplied in
  chat November 13 after the user's cost clarification. Adds [15]-[21] and
  reuses [8], [9], [10], and [12] for protocols. The team reports staying
  under $100 for the flex sensors, new IMU, piezo elements, and glove; this
  is not a complete system/BOM cost or an independently checked receipt total.
- Images: the user will work on and add them later; drafting continues.
- Needs and Impact Analysis: draft supplied after the user confirmed team
  members and a couple of friends contributed sensor recordings with awareness
  of training and possible repository storage. This establishes reported
  awareness, not a signed-consent procedure, de-identification, an access
  audit, or signer-independent model evaluation. An ASL-club reviewer raised
  concerns about complex/body/facial signs without wearing the glove; do not
  count this as a separate confirmed study or hands-on usability validation.
  Adds [22] and reuses [1]. User review/copying of this draft is not confirmed.
- Results: draft supplied after the user's E-to-L misclassification example
  and informal per-finger diagnostic procedure. No physical attempt counts
  exist in that account. Keep the E/L sensor fault distinct from recorded
  training-fit confusions, and do not claim post-replacement validation.
  October TCN records confirm existing regularization and proposed follow-up
  work, not a new tested noise-handling improvement. The draft distinguishes
  alpha software checks, informal physical demonstrations, static regression
  evaluation, the small word comparison, and emulator replay. Reuses [11];
  no new source number. The user subsequently reports adding everything
  supplied so far to their Word document, including Results.
- Status: draft supplied with the user-confirmed November 13/15/17/18/19
  targets; "December 17" was corrected to November 17. November 17-18 is
  the proposed initial calibration/data/retraining/testing window after
  integration. All November engineering milestones are plans from the October
  reporting viewpoint, not completed work. No new source number. Copying of
  the Status draft is not yet confirmed.
- The user subsequently confirmed adding the Status material and agreed to
  proceed. Conclusion draft supplied and accepted in conversation; exact Word
  text remains to be reconciled. Conclusion adds no sources. The remaining
  assembly work is the ordered bibliography, full word-count/citation/rubric
  review, and the images the user is adding separately.
- Remaining sections: pending. No further numbers assigned.
- References: numbered [1]-[22] supplied for pasting into Word and saved in
  `docs/R3_WORD_BIBLIOGRAPHY.md`. Web access dates reflect the actual November
  source checks, while project status retains the October cutoff. No new
  sources or renumbering were introduced. Await the assembled Word file/path
  for final word-count, citation, consistency, and rubric review. Images
  remain the user's later addition; no DOCX/PDF has been edited or exported.
- Assembled report review: source `C:/Users/gael8/OneDrive/Desktop/Preliminary_Report.docx`
  inspected November 13. All sections and references are present. Approximate
  body count 3,262; abstract 230; Letter paper and 0.75-inch margins. All nine
  pages viewed in native Word; source text unchanged. See
  [Word review](../docs/R3_WORD_REVIEW.md) for the citation typo and other
  small corrections. Figures/captions and final PDF checks remain outstanding.
- Figure preparation: user-supplied staged glove photo plus an original
  architecture diagram are saved in `docs/figures/r3/`. No new reference
  numbers; existing [11] remains the project architecture/evidence pointer.
  Source photo credit belongs to the team; diagram preparation received
  Codex assistance. The caption must not claim a PCB is pictured or completed.

When another section is drafted, append newly used sources and record reuse
of existing numbers as helpful. If a source is added earlier in the report,
or a cited paragraph is removed/reordered, explicitly identify any required
renumbering for the user. At final assembly, reconcile against the actual
Word text because the user may make edits outside chat. Exclude unused
selected sources and verify every citation has one matching bibliography
entry. Keep bibliography URLs/DOIs even when in-text numbers are plain text.
