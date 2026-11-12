# R3 preliminary report: draft review and build notes

Prepared October 27, 2026 for the October 28 submission. Course confirmed by
the user: **CEN4908C**. Original assignment wording remains unchanged in
[R3-Preliminary-Report.md](../R3-Preliminary-Report.md).

## Draft artifacts

- [PDF draft](../output/pdf/R3_Preliminary_Report.pdf)
- [Editable LaTeX source](R3_Preliminary_Report.tex)
- [Evidence/readiness notes](R3_REPORT_READINESS.md)
- [Research source notes](../research/R3_REPORT_SOURCE_NOTES.md)
- [Current TCN review](R3_TCN_IMPROVEMENT_REVIEW.md)

The PDF is a complete draft for team content review, not a record of new
hardware tests. It covers all assignment topics and uses the evidence cutoff
October 28. It contains a system
architecture figure, prototype photograph, draft schematic, candidate comparison
and milestone table. No source-code
listings are included.

Review update, October 27: the user reviewed the PDF by skimming, said it looked
good, and explicitly authorized committing/pushing it. The additional rubric
assessment and reminder organization below were requested in that same update.
The approved PDF/source content was not changed during this rubric review.

Hardware revision, October 28: the user reports the glove still uses the demo's
perfboard assembly and confirms the piezo parts and ICM-20948 are received.
A piezo link was supplied and subsequently confirmed as the correct purchase.
The report now reflects receipt rather than an awaited IMU and cites the
confirmed purchase listing. No installation or new hardware test is inferred. This
revision is subsequent to the October 27 user review and needs content review.

Demonstration follow-up, October 28: the user confirms October 5-6 observations
in the NSC senior design lab, using the repo-documented Fairphone configuration
(Gen 6 / Android 15), with letter completions and Hello/Please recognition and
completion. Number attempts and Firebase-backed progress saving are reported.
Thumb/index sensor faults are identified. See
[the observation record](R3_DEMO_OBSERVATIONS.md). This is retrospective team
evidence; controlled counts and precise revisions are still missing.
Gael subsequently confirmed that progress was verified using green app
completion indicators and corresponding records in the actual Firebase database.
Restart persistence, account isolation and offline recovery were not separately
confirmed. The updated Results section distinguishes these
observations from software replay and fresh post-repair tests.

Final refinement pass, October 28: updated the Design, Results, timeline and
references to use the confirmed piezo purchase and app/database progress checks.
Reviewed assignment coverage, evidence boundaries and consistency of completed
versus planned work; tightened wording and fixed a caption-link warning.
No required report content is missing. Remaining uncertainties are explicitly
described engineering limitations, rather than prerequisites for this report.

## Rubric coverage and candid assessment

The user supplied ten equally weighted categories, each worth four points
(40 total). The rubric itself gives no further performance descriptors; the
assignment specification remains the detailed content standard. The assessment
below describes coverage and risks, not predicted or awarded grades.

| Category | Points available | Coverage in the current draft | Main review consideration |
| --- | ---: | --- | --- |
| Formatting | 4 | Letter paper, configured 0.65-inch margins, approximately 3,430 words including title and schematic labels, readable figures/tables, no source-code listings | Verified on all ten updated PDF pages. Recheck after later edits. |
| Abstract | 4 | 251-word synopsis covering purpose, approach, results, limitations and next work | Meets the 200-300-word requirement. |
| Introduction | 4 | Hearing-beginner practice need, educational purpose and bounded system scope | Clearly connects the problem to the proposed aid; benefits remain intended rather than measured. |
| Background | 4 | Peer-reviewed wearable, orientation, haptic and educator research, plus a clearly labeled TCN preprint | Stronger than a tutorial-only background. Different sensing systems/results are qualified. |
| Design | 4 | Architecture figure, actual prototype photograph, exported KiCad draft, hardware/data paths, inference placement, practice interfaces, BLE/I2C/cloud communication and risks | Clearly labels the schematic as incomplete and distinguishes it from the demonstrated perfboard. An as-built schematic and validated driver remain future work. |
| Status | 4 | Implemented/in-progress/planned states, sensor blocker, PCB/TCN work, timeline and upcoming milestones | Future work has a credible sequence, but owners and several dates remain broad/unconfirmed. |
| Impact | 4 | Cultural/social, global, economic, environmental and professional/ethical discussion with limitations | Covers each required dimension without claiming measured learning or sustainability benefits. More fluent/Deaf educator input would strengthen project evidence. |
| Results | 4 | Historical software checks, static pilot, recorded-model evaluation, team-reported October 5-6 physical demo, Android replay and lessons | Physical demo details now strengthen this category. Controlled counts, post-repair validation and independent-user coverage remain incomplete. |
| Conclusion | 4 | Connects achieved integration, limitations, repair dependency and next steps | Consistent with the reported evidence and project goals. |
| References | 4 | 38 cited research, official documentation and project records; all citation keys resolve | Includes the confirmed piezo purchase, cloud transport documentation and retrospective demonstration record. Core literature metadata/claims were checked against primary sources. |

Overall assessment: a technically credible, organized preliminary report with
strong coverage and honest interpretation. Its main weakness is limited current
experimental evidence, not missing section headings or formatting. Some passages
are dense with model/protocol detail; the added prototype and schematic figures
now make the hardware more concrete.
Additional general literature is a lower priority than obtaining the specific
missing hardware facts and test records. No full-marks guarantee is warranted.

## Prioritized reminders

| Priority | Missing input / work | Effect on the report or project |
| --- | --- | --- |
| First | **Obtain piezo datasheet/drive ratings** | Correct purchase link and product match are confirmed as of October 28. Suitable driver, mounting and tactile performance still need verification. See S17 in the source notes. |
| First | Haptic driver/power arrangement, directional cue pattern and method for identifying finger error | Needed to turn the planned haptic behavior into an implementable design; a TCN word label is not already a correction vector. |
| First | Remaining demo records: actual build/firmware, trial counts and original logs/videos | October 5-6, NSC, Fairphone configuration, signs, thumb/index faults and progress verification in app/database are now recorded. Additional run evidence would strengthen reproducibility. |
| Next | Thumb/index fault onset, affected sessions, replacement-flex arrival and recalibration | Affected channels and bad readings are now reported; session-specific impact is unresolved. |
| Next | Old IMU identity, as-built schematic/pin map, power source/battery and actual paid BOM costs | Strengthens Design and Constraints; the replacement flex and ICM-20948 product identities are already recorded. |
| Next | Task owners, internal integration/test dates and final written-report deadline | Makes the roadmap actionable. November 19 is the presentation date; December 3 showcase remains tentative. |
| Later validation | Fresh glove/phone recognition, rejection of wrong/idle gestures, sustained BLE delivery, phone latency, account isolation/sync and external-user/cue-perception testing | Important project completion work, not a result already established by the draft or by code review. |
| Later validation | Fluent ASL/Deaf educator review and defined learning/retention evaluation | Needed before stronger linguistic or educational-effectiveness claims; current remote learner feedback is formative only. |

The confirmations resolve the earlier missing-link and progress-verification
questions. No required report section or essential drafting input is missing.
The table primarily tracks engineering completion and opportunities to strengthen
evidence. These items can remain identified as unresolved in a preliminary
report; they need not all be completed before the October 28 submission.

## Verification completed

- Built with Tectonic 0.17.0; final compilation had no TeX layout, missing
  citation or undefined-reference warnings. A nonfatal Fontconfig message was
  emitted; the resulting embedded Latin Modern text rendered correctly.
- US Letter, 11-point main text, configured 0.65-inch margins with footer
  included. Extracted text bounds, including the footer, remain within at
  least 0.5 inch of all page edges.
- Abstract: **251 word tokens**. Main report text including the abstract,
  headings, architecture labels, captions and tables: **3,240 word tokens**.
  Adding title/author/date metadata and a conservative **163 schematic-label
  tokens** gives **3,429**, excluding footers and references. Schematic labels
  were extracted from the SVG because the embedded PNG has no extractable text;
  the count includes repeated SVG text and pin numerals. Counts normalize PDF
  line-break hyphenation and treat hyphenated words as one token. This is a
  working count, not an instructor-specific counting rule; retain the current
  margin below 3,500 when editing.
- Ten nonblank pages; all ten rendered and visually inspected after the final
  changes (first four confirmed pixel-identical to the inspected version).
  Figure orientation, schematic legibility, table placement, bibliography order,
  footers and page breaks reviewed. References occupy their own final two pages.
- No unresolved citation/figure markers; 100 PDF link annotations present in
  the final October 28 revision. All 38 bibliography entries are cited.
- Poppler was unavailable on PATH; PyMuPDF rendered the verification images.
  No training, implementation tests or physical experiments were rerun to
  generate these report checks.

## Detailed submission audit, October 28

- Matched the original assignment against the report: required sections,
  scientific background, user/internal interfaces, communication paths, tools
  and standards, constraints, all five impact dimensions, ethics, results,
  status/timeline, conclusion and bibliography are present. No source-code
  listings or invented physical measurements were added.
- Checked firmware A0-A4 mapping, 100 kHz I2C configuration, NUS UUIDs,
  notification/write characteristics, USB-serial startup dependency and empty
  piezo implementation. The report now makes clear that the write path only
  logs commands and is not an implemented haptic command protocol.
- Checked static practice thresholds, word attempt handling, local progress,
  Firestore ownership path and the Python/Dart sequence pipeline. Expanded
  technical acronyms and specified the 40 Hz / 96-sample word window.
- Inspected raw CSV counts again: static pilot 5,518 frames / 35 trials; word
  source 1,770 packets / 15 trials; newer static source 3,263 frames / 21 trials.
  Compared retained static metadata and word selection/split reports with the
  report. Both packaged model hashes match their versioned records; TCN is
  48,324 bytes. This is artifact inspection, not a rerun of training or tests.
- Rechecked the principal ASL, TCN, orientation, educator and haptic sources
  against publisher, author or institutional records. Completed the haptic
  study's 2025 volume/issue/page metadata while retaining its 2024 online date.
  Added official Firebase HTTPS documentation for the cloud networking path.
- Added the real `glove-current.jpg`, preserving its original file and using
  LaTeX rotation for correct display. Exported the October 22 schematic with
  KiCad CLI 9.0; user first requested a preview, then approved report inclusion.
  Their color screenshot is preserved alongside the export. The report uses
  the clean PNG and identifies the circuit as an incomplete connection draft.
- Flagged actual schematic follow-up: repeated `PIEZO PIN` net labels, generic
  Feather pin mapping and unshown sensor/driver circuitry need review. The
  original KiCad source and board were not edited. See
  [export provenance and notes](../pcb/exports/README.md).
- Retained the limits of retrospective demo evidence and distinguished cloud
  writes observed in app/database from unrun restart/account/offline checks.
  Fresh hardware experiments remain planned and are not submission blockers.

The report is ready for final team factual review and Canvas upload. The audit
does not certify untested hardware, linguistic accuracy or educational benefit.

Final submission check after user review, October 28: the user said the updated
report looked good. A further read-through found no substantive factual or
rubric issue requiring PDF edits. Read-only checks reconfirmed ten Letter pages,
251 abstract words, 3,429 report tokens including title/schematic labels, 38
cited bibliography entries, two embedded hardware images, 100 link annotations,
consistent page numbers and text within the required margins. No placeholder
text or unresolved citation/figure keys were found. The unchanged PDF was
rendered again for a final layout overview. Submission PDF SHA-256:
`b0822ba88695607468ec6d996dda961a7432fc4aa1befd3adc9a33252b29e73c`.

## Team review and outstanding inputs

- [x] User reviewed the first PDF draft and authorized commit/push on October 27.
- [x] Receive the [piezo product link](https://www.amazon.com/dp/B077YJ3H6R)
  and user confirmation that it is the correct purchased product, October 28.
- [ ] **Reminder: obtain piezo datasheet/drive ratings.** Driver, mounting, tactile cue patterns and
  error mapping still need verification. Do not fill these with assumptions.
- [x] Record the October 28 update: perfboard glove retained; IMU and piezo
  parts received. Installation and validation are not yet documented.
- [x] Record October 5-6 demo location, Fairphone reference, letter successes,
  Hello/Please recognition/completion and thumb/index faults in the observation notes.
- [x] Record Gael's verification of green completion indicators in the app and
  corresponding letter/number/word progress records in the actual Firebase database.
- [ ] Confirm team spelling/order and report date; CEN4908C is already confirmed.
- [ ] Confirm thumb/index fault onset, actual replacement-flex arrival and
  repair owner. Replacement-flex receipt/installation is not yet reported.
- [ ] Confirm installed old IMU identity, power source/battery, as-built wiring,
  actual paid costs and any additional physical-run metadata the team has.
- [ ] Review the alpha/beta results against original evidence. October 5-6 demo
  date, location and phone reference are recorded; exact software revisions,
  controlled counts and original run evidence remain incomplete. Post-repair
  checks explicitly marked Not run remain unrun.
- [ ] Review the distinction between preserved synthetic 36-class baseline,
  default recorded 34-class static candidate and three-word phone TCN.
- [ ] Confirm proposed engineering milestones/owners. November 19 presentation
  is scheduled; December 3 showcase is tentative. Final written-report due
  date remains unconfirmed.
- [ ] Review citations and the original-design/SME interpretations. The draft
  does not treat remote ASL-learner comments as worn comfort or learning evidence.
- [x] October 28 final refinement build: all ten pages rendered and visually
  checked; margins, word limits and all 38 citation keys verified. Repeat this
  check only if the PDF is edited again. Final team read-through and Canvas
  submission remain outstanding.
- [ ] Final team read-through and Canvas PDF upload. Canvas upload has not
  been performed.

## Rebuilding

From the repository root, with Tectonic installed:

```powershell
tectonic --outdir output/pdf docs/R3_Preliminary_Report.tex
```

The bibliography and TikZ architecture are in the source file, so no separate
BibTeX build is needed. Preserve the referenced photograph in
`beta_presentation/assets/hardware/` and schematic PNG in `pcb/exports/` when
moving the project. Tectonic may download missing TeX resources
on the first build. Modify content in the LaTeX file; update these verification
counts after changes. Temporary compilation logs and page renders are not
submission deliverables.

The draft and its wording were prepared with Codex assistance. The user
reviewed and authorized the October 27 version; the October 28 hardware revision
awaits review. Remaining factual/team checks are above. Follow the repository's
AI disclosure/review rules for later edits.
