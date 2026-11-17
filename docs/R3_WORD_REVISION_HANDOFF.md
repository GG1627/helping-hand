# R3 preliminary report: Word revision handoff

Session started November 12, 2026.

## User direction

The user reports that the previous submission was flagged as entirely
AI-generated and wants to redo it in Microsoft Word. They will assemble the
Word document, with assistance translating the previous submission into
clearer, more natural prose and checking it against the assignment.
No code changes are requested.

Use straightforward student-team writing that the team can explain and verify.
Retain necessary technical detail, citations, and honest limitations. Do not
invent experiences, measurements, or results, add deliberate errors, or promise
an AI-detector outcome. AI assistance remains subject to the repository's
disclosure requirements.

## Existing material

- [Assignment prompt](../R3-Preliminary-Report.md): already saved; matches the
  assignment supplied again in this session. Preserve its original wording.
- [Previous PDF](../output/pdf/R3_Preliminary_Report.pdf).
- [Previous LaTeX source](R3_Preliminary_Report.tex): reference for content;
  the new report will be prepared in Word.
- [Report review](R3_REPORT_REVIEW.md): previous coverage assessment and checks.
- [Evidence/readiness notes](R3_REPORT_READINESS.md).
- [Research source notes](../research/R3_REPORT_SOURCE_NOTES.md).
- [Word reference plan and full old-bibliography audit](../research/R3_WORD_REFERENCE_PLAN.md).
- [Settled sources and section citation plan](../research/R3_WORD_REFERENCES.md).
- [Active citation order and draft progress](../research/R3_WORD_CITATION_LEDGER.md).
- [Numbered bibliography for Word](R3_WORD_BIBLIOGRAPHY.md).
- [Assembled Word report review](R3_WORD_REVIEW.md).
- [Demo observations](R3_DEMO_OBSERVATIONS.md).

Preserve the previous PDF and source as historical artifacts. This handoff is
preparation for revision, not a rewritten report or a new submission.

## Scope and dates

The user confirmed retaining the original **October 28, 2026 evidence cutoff**
for the rewrite in the November 12 follow-up.
Later hardware arrivals and November software changes must not be presented
as completed work at the original cutoff. A revised cutoff would require
rechecking the affected design, results, and status claims.

The assignment transcription says CEN3908C. Earlier review notes record the
user's confirmation of CEN4908C for the report. Keep that distinction visible
and use the previously confirmed report course unless corrected.

## Working approach

Work section by section with the user. Review the reference plan first, then
start with the introduction or design; write the abstract after the main text
settles. The user supplied these writing references, both read for style:

- `C:/Users/gael8/OneDrive/Desktop/Release_Candidate_Report.docx`
- `C:/Users/gael8/OneDrive/Desktop/Alpha_Build_Report.docx`

The examples use direct technical explanations, short paragraphs, concrete
examples, and first-person plural for team work. No separate voice-establishing
exercise is needed. These are style references, not permission to move later
project results into the October report. Ask focused section-specific questions
when team experience or missing facts would improve the content; flag useful
photos or diagrams, including readable hand drawings the user can supply.

The user authorized settling the reference selection before drafting. The
selected-reference file now contains 22 sources (21 external and one repository
pointer), bibliography metadata, a section citation plan, and verification
limits. It supersedes the audit's earlier 16-source proposal. Magnetic
calibration, haptic perception, cloud HTTPS, and the actual phone inference
package have been included for specific content needs. Extra internal
citations remain working evidence links. Final IEEE numbering follows first
use; remove unused sources when reconciling the finished report. Source
selection is complete for the intended scope; proceed to the Introduction.

Follow-up drafting progress: the user copied the Introduction into Word and
confirmed that the report should speak from the October deadline's viewpoint,
not retrospectively. Use past tense for completed work, present tense for
current status, and future tense for planned work. The user supplied the
personal motivation: Deaf relatives/friends, the team's limited ASL knowledge,
and a change in project direction from sign-to-voice translation to helping
beginners learn ASL. Preserve that meaning and the user's direct writing voice.

The Background draft introduces citations [1]-[6]; the Design draft adds [7]-[14].
The Tools section adds [15]-[21], and Needs and Impact adds [22]. The next
new source would be [23]; all 22 currently selected sources now have numbers.
Use the active ledger for the definitive mapping. The user is removing links
from in-text numbers manually; final bibliography details remain in the
selected-reference file. Drafting changes should be saved locally and batched
into meaningful commits, rather than committed after each exchange. Describe
actual assistance accurately and retain required disclosure when committing.

### Design clarifications supplied by the user

- Right-hand glove only, due to project scope and time constraints.
- Five flex sensors sewn onto the fingers over their main bending joints.
  The user explicitly corrected the accidental reference to finger IMUs.
- The IMU and ESP32 are currently on perfboard at the back of the hand.
  Planned arrangement: ESP32 at the wrist, IMU retained on the back of the
  hand, with space for the planned back-of-hand piezos. Do not describe this
  relocation or haptic integration as completed.
- Both computer USB and a LiPo battery were used. Battery-powered operation
  had power/connectivity problems; computer USB is currently the reliable
  method. Exact fault mechanism, battery rating, and runtime are unconfirmed.
- Cost and portability were the team's main priorities: approachable cost
  and a compact, properly assembled wearable rather than a bulky system.
  Affordability and comfort are design goals, not measured outcomes.
- The user confirms visual inspiration from SignAloud. University of
  Washington's April 12, 2016 account identifies the developers as UW students
  Navid Azodi and Thomas Pryor; they won a Lemelson-MIT prize. The user's
  original MIT-student attribution was corrected. SIGNALOUD is a new selected
  source for this specific design influence, not technical-performance proof.
- November 13 cost clarification: keeping cost low is a general priority,
  with a goal of staying under $100. The user reports that purchased flex
  sensors, the replacement IMU, piezo elements, and the glove remain under
  that amount. Limit the cost claim to those listed purchases; a complete BOM,
  ESP32/phone costs, and receipt-level totals are not established.
- The user will add the Design images later. The Tools, Design Constraints,
  and Engineering Standards draft follows Design; it introduces citations
  [15]-[21] and reuses existing protocol references. Do not make extra commits
  for these drafting updates.

### Needs and impact clarifications supplied by the user

- Team members and a couple of friends contributed sensor recordings.
  Contributors knew the data would be used for training and could be stored
  in the repository. Do not turn this into a claim of formal written consent,
  confirmed anonymization, restricted access, or independent-signer testing.
  This broad contributor account does not establish which people appear in
  each existing training/evaluation dataset; retain the model-specific limits.
- An ASL-club person reviewed the project without necessarily wearing the
  glove. They raised concerns about full usability for complex signs,
  facial expressions, and other body information. The team explained that
  those capabilities exceed the current project's scope. The user did not
  identify this as a distinct new reviewer/study separate from the earlier
  club discussion, nor confirm a Deaf/fluent/instructor role.
- Treat this feedback as a meaningful boundary on claims, not evidence of
  hands-on comfort, language accuracy, or learning effectiveness. A limited
  learning aid still needs accurate instruction and honest capability limits.
- Needs and Impact Analysis draft covers the intended social benefit,
  cultural/community input, global language limits, scoped economic costs,
  repair/waste considerations, contributor awareness/privacy, false feedback,
  and future user/learning evaluation. It adds citation [22] (DEAF-LED).

### Results clarifications and October TCN check

- The user reports E attempts being classified as L when the damaged thumb
  and index flex channels indicated an unbent state despite bent fingers.
  Do not turn this into an exact linguistic description of E or a quantified
  E/L confusion rate. Other letters/numbers were affected but not enumerated.
- Physical checks were informal team testing. No physical attempt counts,
  pass/fail totals, or controlled recognition-accuracy records were kept.
  This does not mean there were no training recordings or software-test logs.
- Troubleshooting involved watching each flex channel while bending the
  corresponding finger. Thumb/index bending did not change their readings,
  helping the team identify the failed sensors. Exact fault onset, raw traces,
  and the date/location of this specific diagnostic check are unconfirmed;
  do not automatically assign it to the October 5-6 demonstration.
- The user expects replacement sensors to fix this issue. Keep replacement
  and recalibration/retesting planned at the October 28 cutoff unless actual
  completion is later confirmed; do not claim a measured repair outcome.
- The user recalled possible TCN noise-handling work. Inspection of
  `cf59fd98:docs/R3_TCN_IMPROVEMENT_REVIEW.md`, the October training record,
  and relevant Git history shows dropout 0.25 and L2 0.0001 already existed
  in the October 5 model. The October 27 review explicitly says no proposed
  candidate was implemented, trained, benchmarked, or shown to improve
  accuracy in that review. Broader data coverage, gesture-window handling,
  rejection, and sensor/orientation robustness are review/planning findings,
  not demonstrated new denoising or improved accuracy. Exclude November
  augmentation and later work from this October report.
- Results drafting uses the existing alpha software records, October demo
  observations, the new E/L diagnostic account, limited static regression
  results, 9/3/3 word comparison, and emulator replay checks. Reuse [11] for
  artifact traceability; no new bibliography entry is needed.

### Status and planned schedule

- After Results, the user reports having added everything supplied so far to
  their Word document. The actual Word file has not been inspected in this
  revision session; final word count and citation reconciliation remain pending.
- The user supplied targets for the report's forward-looking schedule:
  November 13 PCB fabrication/assembly; November 15 glove reassembly with
  replacement flex sensors; November 17 mounting/integration of the piezos,
  new IMU, and PCB; November 18 final slides and demo preparation; November
  19 presentation. They explicitly corrected "December 17" to November 17.
- The user agreed to a separate calibration, fresh-recording, retraining,
  and testing milestone. Use November 17-18 as a proposed initial-work window
  after hardware integration, not a guarantee of comprehensive validation.
  The schedule is tight and depends on usable hardware/data; readiness should
  depend on test outcomes. Keep haptic mounting separate from working cue logic.
- Present these dates as planned targets from the report's October viewpoint.
  Do not report the November targets as completed or import November software
  work/results. No completed hardware upgrade was established by this exchange.
- Status draft includes historical September/October software/model/demo/PCB
  milestones plus the proposed November schedule. It introduces no new sources.

### Conclusion and abstract progress

- The user reports adding the Status draft. The Conclusion draft summarizes
  the implemented glove/app paths, evidence limits, sensor repair, and planned
  hardware/data/testing work. The user agreed to proceed to the Abstract.
- The Abstract is now drafted as one paragraph of 200-300 words, without
  citations, for placement at the beginning of the report. It retains the
  October reporting viewpoint and does not import November completions.
- No new citation numbers are introduced by Status, Conclusion, or Abstract.
  All 22 selected sources have assigned numbers in the active ledger.
- The bibliography has now been assembled as `docs/R3_WORD_BIBLIOGRAPHY.md`
  in ledger order [1]-[22], checked against the selected source IDs, and
  supplied for pasting. No source numbers changed. Access dates reflect the
  actual November checks and were not backdated to the project cutoff.
- Next: obtain the user's assembled Word file/path and inspect/reconcile it
  for word count, citation order, dates, rubric coverage, and consistency.
  Images remain the user's later addition. No Word edits, render review,
  revised PDF export, or final report checks have occurred yet. Keep the
  working notes/bibliography local until a meaningful batch-commit milestone.

### Assembled Word report inspected November 13

- The user supplied `C:/Users/gael8/OneDrive/Desktop/Preliminary_Report.docx`
  and says only the two images remain to be added. The actual file has now
  been read structurally and all nine pages inspected in native Word. Its
  text was not edited. The report has all required sections, an approximately
  3,262-word body including headings/tables/placeholders, a 230-word abstract,
  and US Letter pages with 0.75-inch margins.
- See `R3_WORD_REVIEW.md` for exact corrections: PlatformIO [14] must be [15];
  "Fabricated and assemble" must be "Fabricate and assemble"; the unrun-test
  sentence should say not yet run; remove the raw repo URL after [11]; make
  the disclosure accurately include drafting assistance.
- A date line is a useful optional clarification. The two figure placeholders
  remain. Final body count, figure/caption flow, and PDF inspection must follow
  image insertion. No revised PDF or submission exists from this review.
- No major clipping/overlap was observed in Word, and both tables fit. Native
  Word visual review was used; the packaged DOCX renderer was not run. Do not
  describe this as a completed final render/export or claim the small text
  corrections have already been made.

### Planned-layout photograph and architecture figure

- The user requested a simpler diagram without an embedded title or bottom
  caption text. Use `docs/figures/r3/helping-hand-architecture-basic.png`
  for Word; matching SVG and editable draw.io files are available. This
  version uses plain white boxes and short labels. Planned items remain
  dashed, and the PCB is explicitly marked planned and not fabricated.
  A small legend labels solid lines Implemented and dashed lines Planned.
  The earlier detailed version is retained. The revised PNG was visually
  checked; the Word document was not edited.

- The user supplied the photograph at
  `C:/Users/gael8/Downloads/50370A6D-5362-4B72-8A5A-1C59B66C3F06.jpg`
  and requested a draw.io-style architecture image. They explicitly reiterated
  that the PCB was still planned and had not been completed or fabricated.
- The photo shows sensors, piezo elements, the new IMU and ESP32 arranged on
  the glove; it does not show a custom PCB. Treat it as a proposed component
  layout, not a completed or physically validated October assembly.
- Assets are in `docs/figures/r3/`: unchanged photo copy, architecture PNG,
  SVG and editable draw.io XML. See that folder's README for captions and the
  two short insertion sentences. The user is inserting images into Word;
  this operation did not edit their DOCX.
- Diagram preserves the implemented ESP32/static, phone/TCN/local progress,
  BLE and Firebase paths. Planned nine-axis replacement, custom PCB,
  piezo drivers and correction logic are dashed. PCB explicitly not fabricated.
- Creation used deterministic native vector text/shapes and local PNG export,
  not ImageGen or an external service. The diagram image was visually checked;
  draw.io XML parsed but not opened in the draw.io app. No application source
  changed and no commit was made.

Use ordinary paragraphs, simple headings, and Word-compatible tables or
figures where useful. First-person plural is appropriate for documented team
decisions and actions, without implying an unrecorded experience.

For each section, retain the useful facts from the previous submission,
explain them plainly, and identify missing team input. Keep scholarly support
in the background section and cite tools and standards where discussed.
Check that every rewritten claim still agrees with its evidence; simpler
wording must not turn a limited observation into a broad performance claim.

## Assignment checklist

- US Letter or A4; margins 0.5-0.75 inches (12-20 mm).
- No more than 3,500 words, excluding references and acknowledgements.
- Begin with a 200-300 word abstract describing the report.
- Introduction: need, importance, intended impact, and approach.
- Background: relevant theory, prior art, scholarly articles/reports, and
  applicable team experiments, with citations.
- Design: user interfaces, internal subsystems, communication media and
  protocols, useful diagrams, and design risks with mitigations.
- Tools, constraints, and standards: explain what was used, cite it, and
  show how constraints influenced design decisions.
- Needs and impact: cultural, global, economic, environmental, and social
  implications; ethical/professional considerations; limitations, drawbacks,
  and future work. Connect these to the original design and intended users.
- Results: alpha/beta procedures and outcomes, including what, how, when,
  where, why, expected behavior, observations, lessons, and resulting changes.
  Be reproducible where records allow; identify missing details rather than
  supplying invented ones. Label unexecuted procedures `Not run`.
- Status: completed, in-progress, and planned external interfaces and
  internal systems, with implementation/planning detail and a dated timeline.
- Conclusion: connect purpose, approach, progress, and next steps.
- References: include all resources used and match citations to bibliography
  entries. Source code does not belong in the report.
- Final submission: export the Word document to PDF for Canvas. No Canvas
  submission or revised Word/PDF export has been performed in this session.

## Evidence boundaries to retain

Separate physical demonstrations, offline model evaluation, recorded replay,
and software checks. None alone establishes learning effectiveness, broad
signer generalization, or end-to-end live reliability.

The prior report distinguishes the preserved 36-class static baseline, the
recorded 34-class static model, and the Hello/Please/Yes word model. Preserve
those distinctions and the small dataset/split limitations. Consult the
linked evidence notes for exact figures before reusing them.

Hardware acquisition, installation, implementation, and validation are
different milestones. Keep haptic and orientation goals separate from
demonstrated capabilities at the chosen cutoff.
