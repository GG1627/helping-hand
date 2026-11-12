# R3 Word report reference plan

**Selection settled:** use [R3 Word selected references](R3_WORD_REFERENCES.md)
as the authoritative drafting list. It selects 21 sources from this audit and
the follow-up checks, including one repository pointer. This file preserves
the original 38-entry audit and reserve-source decisions; its 16-source
starting list below is the earlier proposal, not the current selection.

Prepared November 12, 2026 for the Word rewrite. The user confirmed that the
report retains its **October 28, 2026 project cutoff**.

This is the working source list and audit, not the report's final numbered
bibliography. Keep the historical [PDF](../output/pdf/R3_Preliminary_Report.pdf)
and [LaTeX source](../docs/R3_Preliminary_Report.tex) unchanged. Earlier detailed
research checks remain in [R3 source notes](R3_REPORT_SOURCE_NOTES.md).

## Decisions for drafting

- Choose sources because they support a specific retained statement. A long
  bibliography or self-citation is not evidence of AI authorship; relevance,
  accurate attribution, and clear reporting are the concerns here.
- Use scholarly work for research findings, official documentation for tools
  and protocols, and the team's own methods/results for original work.
- Describe our experiments directly in Results, including procedures, counts,
  splits, failures, and limits. A citation to an internal summary cannot replace
  those details. Keep the supporting record links in our working notes.
- Use one versioned repository citation if it helps readers locate our artifacts.
  Add a separate design-report citation only if the text actually relies on
  that prior report as a distinct source. Do not create a bibliography entry
  for every internal note merely because we consulted it while checking facts.
  If we reproduce or specifically rely on a distinct prior document, cite it.
- The assignment explicitly requires citations for tools and standards.
  Retain appropriate tool documentation. Avoid a paragraph listing incidental
  packages solely to create more bibliography entries; if a package or document
  materially informs the report, acknowledge it appropriately.
- Record all candidate sources now, but assign final IEEE numbers in order of
  first appearance after drafting. Reuse a source's number each time it is cited.
  Draft with the stable IDs below so adding a sentence does not break numbering.
- Give each numbered entry one source. A mirror or DOI for the same paper is
  not another source, but a seller listing and a separate manufacturer's
  datasheet are different sources and should not share one entry.
- Keep publication dates and project dates separate from access dates. Sources
  rechecked in this session were accessed November 12, 2026. Do not backdate
  those checks to October 28. An access date after the project cutoff does not
  establish that later project work had already occurred.
- Do not use current documentation to infer the team's October software
  versions, deployed security configuration, certification, or physical results.

IEEE checks: [official reference guide](https://journals.ieeeauthorcenter.ieee.org/wp-content/uploads/sites/7/IEEE_Reference_Guide.pdf?WT.ac=journals)
and [IEEE Computer Society author guidance](https://www.computer.org/publications/author-resources).
The guide's indexed official text confirms one source per reference number;
Computer Society guidance confirms numbering in order of appearance. Direct
guide retrieval redirects to a Google document that was not fully readable in
this session. Do not imply a full current-style-manual inspection. These are
editorial aids, not automatic entries in the project's report bibliography.
The assignment governs document formatting; IEEE referencing does not require
IEEE two-column paper layout.

## Recommended starting list

These 16 sources cover the likely main text. This is a selection for drafting,
not a required count or permission to omit another source we actually use.
Each entry gives reusable IEEE-style metadata without a final number.
Web entries use the honest current access date; refresh if consulted later.

### ASL-CONTEXT

National Institute on Deafness and Other Communication Disorders, "American
Sign Language." Accessed: Nov. 12, 2026. [Online]. Available:
https://www.nidcd.nih.gov/health/american-sign-language

Use in Introduction or Impact for ASL's grammar, hand/face expression, and
the fact that sign languages differ across countries. Official public-health
context, not a study showing demand for or effectiveness of Helping Hand.
Page content checked this session.

### ASL-EDUCATORS

S. Hassan et al., "ASL Educators' Perspectives on AI for Enhancing Student
Learning in American Sign Language Education," in *Proc. 2026 CHI Conference
on Human Factors in Computing Systems*, 2026, pp. 1-20,
doi: 10.1145/3772318.3791928.

Readable author-hosted paper: https://saadh.info/papers/hassan-chi26/hassan-chi26.pdf

Use in Background for educator perspectives on feedback and supplementary
practice. Interviews involved 12 educators; follow-up focus groups involved
six of those educators. This is not a learning-effectiveness experiment on
our glove. Author-hosted paper and its citation block checked this session.
The old institutional record URL redirected to a general university page;
use the DOI and working author PDF rather than that record link.

### WEARABLE-ASL

B. G. Lee, T.-W. Chong, and W.-Y. Chung, "Sensor Fusion of Motion-Based Sign
Language Interpretation with Deep Learning," *Sensors*, vol. 20, no. 21,
Art. no. 6256, 2020, doi: 10.3390/s20216256.

Publisher: https://www.mdpi.com/1424-8220/20/21/6256
Open primary-paper mirror: https://pmc.ncbi.nlm.nih.gov/articles/PMC7663682/

Use in Background as direct wearable word-level ASL prior art. The system
uses six IMUs and an LSTM; our hardware and evaluation differ. Avoid copying
its high reported accuracy as an expected score for Helping Hand. The primary
paper was checked through PMC after publisher retrieval errors.

### TCN

S. Bai, J. Z. Kolter, and V. Koltun, "An Empirical Evaluation of Generic
Convolutional and Recurrent Networks for Sequence Modeling," arXiv preprint
arXiv:1803.01271, 2018, doi: 10.48550/arXiv.1803.01271.

https://arxiv.org/abs/1803.01271

Use in Background to explain considering temporal convolution alongside
recurrent models. It is a general sequence-modeling preprint, not an
ASL-specific benchmark or evidence that our TCN is more accurate. Author
abstract, names, date, and preprint identifier checked this session.

### DEAF-LED

A. Desai, M. De Meulder, J. A. Hochgesang, A. Kocab, and A. X. Lu,
"Systemic Biases in Sign Language AI Research: A Deaf-Led Call to Reevaluate
Research Agendas," in *Proc. LREC-COLING 2024 11th Workshop on the
Representation and Processing of Sign Languages: Evaluation of Sign Language
Resources*, 2024, pp. 54-65. [Online]. Available:
https://aclanthology.org/2024.signlang-1.6/

Use in Needs and Impact for community participation and careful problem
framing. The authors reviewed 101 papers; this does not establish community
endorsement of our device. Publication metadata and primary PDF checked.

### BLE

Bluetooth SIG, "The Bluetooth Low Energy primer," ver. 1.3.0, Oct. 15, 2024.
Accessed: Nov. 12, 2026. [Online]. Available:
https://www.bluetooth.com/bluetooth-le-primer/

Use for BLE, GATT, characteristics, and notifications in Design/Standards.
Relevant sections are 12 and 13. The primer explains the standards; it is
not itself a product-compliance certificate. Revision history and relevant
section structure checked. Use the Core Specification if a normative
requirement is discussed in detail; do not invent a tested Bluetooth version.

### NUS

Nordic Semiconductor, "Nordic UART Service (NUS)." Accessed: Nov. 12, 2026.
[Online]. Available:
https://nrfconnectdocs.nordicsemi.com/ncs/latest/nrf/libraries/bluetooth/services/nus.html

Use for the custom service's UUID and RX-write/TX-notify pattern if retained
in Design. NUS is vendor-defined, not a Bluetooth SIG standard serial-port
profile. Current documentation checked; its SDK version is not our firmware
version, and our project-specific packet text is not defined by this page.

### I2C

NXP Semiconductors, *I2C-bus Specification and User Manual*, UM10204,
rev. 7.0, Oct. 1, 2021. [Online]. Available:
https://www.nxp.com/docs/en/user-guide/UM10204.pdf

Use in Standards for the sensor bus and Standard-mode. The 100 kHz project
configuration comes from our code, not the specification. PDF revision,
date, and bus-mode descriptions checked. This is a protocol specification.

### FLUTTER

Flutter, "Flutter documentation." Accessed: Nov. 12, 2026. [Online]. Available:
https://docs.flutter.dev/

Use in Tools for Flutter/Dart app development. Documentation checked; do
not infer October's installed release from today's documentation.

### PLATFORMIO

PlatformIO, "What is PlatformIO?" Accessed: Nov. 12, 2026. [Online]. Available:
https://docs.platformio.org/en/latest/what-is-platformio.html

Use in Tools for embedded build/development support. Documentation checked;
the project's Arduino/C++ configuration is our implementation detail.

### TENSORFLOW

TensorFlow, "Keras: The high-level API for TensorFlow." Accessed: Nov. 12,
2026. [Online]. Available: https://www.tensorflow.org/guide/keras

Use in Tools for model training. Official documentation checked. The source
does not validate our trained models or replace our evaluation results.

### TFLITE-MICRO

Google AI Edge, "LiteRT for Microcontrollers." Accessed: Nov. 12, 2026.
[Online]. Available:
https://developers.google.com/edge/litert/microcontrollers/overview

Use in Tools for the embedded TensorFlow Lite deployment approach and
resource constraints. Official documentation checked. Preserve the project's
TensorFlow Lite terminology where accurate. This page does not document
the phone's tflite_flutter integration or prove compatibility with newer APIs.

### FIREBASE

Firebase, "Get started with Firebase in your Flutter project." Accessed:
Nov. 12, 2026. [Online]. Available:
https://firebase.google.com/docs/flutter/setup

Use as a consolidated tool reference when describing Firebase's Flutter
integration and naming Authentication and Cloud Firestore. Page and plugin
table checked. If we discuss ownership rules, password authentication, or
transport protection specifically, use the corresponding conditional source
below. This overview does not prove that our deployment enforces isolation.

### KICAD

The KiCad Documentation Contributors, *Getting Started in KiCad*, ver. 9.0.
Accessed: Nov. 12, 2026. [Online]. Available:
https://docs.kicad.org/9.0/en/getting_started_in_kicad/getting_started_in_kicad.html

Use in Tools for schematic and PCB development. Versioned documentation
checked; reference version 9.0 does not identify the team's installed version
or establish that a PCB was fabricated or passed rule checks.

### FLEX

Adafruit Industries, "Short Flex Sensor," product 1070. Accessed: Nov. 12,
2026. [Online]. Available: https://www.adafruit.com/product/1070

Use for the identified replacement part and its contact strain-relief
guidance. Product description and handling warning checked. This does not
establish the cause of our particular sensor failures. Use the separate
manufacturer datasheet below for specifications taken from that document.
Do not substitute a present-day listing price for actual team expenditure.

### IMU

Adafruit Industries, "Adafruit TDK InvenSense ICM-20948 9-DoF IMU
(MPU-9250 Upgrade)," product 4554. Accessed: Nov. 12, 2026. [Online].
Available: https://www.adafruit.com/product/4554

Use for the received replacement module's acceleration, gyroscope, and
magnetometer channels. Product description checked. The device had been
received by the cutoff, but installation and improved recognition were not
established. Do not use this listing to identify the old installed IMU or
to imply that nine axes automatically improve recognition.

## Conditional sources

Retain these when their specific content remains in the rewritten report.
They are not poor sources merely because they may be unnecessary in a
shorter report. Metadata below comes from the earlier bibliography/source
notes; fresh checks performed this session are explicitly identified.
Reopen the relevant passages before drafting a substantive claim from them.

| Draft ID | Source and link | Decision and verification |
| --- | --- | --- |
| ORIENTATION | A. Yurtman, B. Barshan, and B. Fidan, "Activity Recognition Invariant to Wearable Sensor Unit Orientation Using Differential Rotational Transformations Represented by Quaternions," *Sensors*, vol. 18, no. 8, Art. no. 2725, 2018, doi: [10.3390/s18082725](https://doi.org/10.3390/s18082725). | Retain for a substantive quaternion-preprocessing proposal. Publisher page retrieved this session. Activity recognition is not ASL; normalization was not implemented at the cutoff. |
| MAGNETIC | M. Kok and T. B. Schön, "Magnetometer Calibration Using Inertial Sensors," *IEEE Sensors Journal*, vol. 16, no. 14, pp. 5679-5689, 2016, doi: [10.1109/JSEN.2016.2569160](https://doi.org/10.1109/JSEN.2016.2569160). [Author record](https://arxiv.org/abs/1601.05257). | Retain for heading drift, magnetic calibration, or fusion rationale. Journal metadata and author abstract checked this session. Cite the journal article, not a second separate entry for its preprint copy. |
| HAPTIC-STUDY | M. Tajdari, J. Forsyth, and S. Lim, "Sensitivity to Vibrotactile Stimulation in the Hand and Wrist: Effects of Motion, Temporal Patterns, and Biological Sex," *Human Factors*, vol. 67, no. 4, pp. 331-346, Apr. 2025, doi: [10.1177/00187208241275734](https://doi.org/10.1177/00187208241275734). | Retain if discussing research on cue perception during movement. Publisher abstract/metadata checked; first online Aug. 23, 2024. Does not validate our purchased actuators. |
| FIREBASE-AUTH | Firebase, "Authenticate with Firebase using password-based accounts on Flutter." https://firebase.google.com/docs/auth/flutter/password-auth | Reserve for specific authentication guidance. Rechecked Nov. 12, including email/password sign-in. Current selection uses the general integration page for basic tool attribution. |
| FIRESTORE-RULES | Firebase, "Writing conditions for Cloud Firestore Security Rules." https://firebase.google.com/docs/firestore/security/rules-conditions | Reserve for specific ownership-rule discussion. Rechecked Nov. 12, including request identity and document ownership conditions. Does not establish that our deployment was verified. |
| FIREBASE-PRIVACY | Firebase, "Privacy and Security in Firebase." https://firebase.google.com/support/privacy/ | Promoted to the settled list for HTTPS/cloud transport. Data-encryption section and Sep. 24, 2026 modification date checked Nov. 12. Does not prove application account isolation. |
| FLEX-DATASHEET | Spectra Symbol, *Flex Sensor Datasheet*, rev. A2. https://cdn-shop.adafruit.com/datasheets/SpectraFlex2inch.pdf | Retain if using its electrical/mechanical specifications. Manufacturer PDF retrieved and revision checked this session. Do not combine with the Adafruit product page under one number. |
| IMU-GUIDE | Adafruit Industries, "ICM-20948 Arduino Guide." https://learn.adafruit.com/adafruit-tdk-invensense-icm-20948-9-dof-imu/arduino | Retain only if using this particular implementation guidance, which must remain planned at the cutoff. Previously recorded; not freshly rechecked. |
| IEEE-ETHICS | IEEE, "IEEE Code of Ethics." https://ieee-cas.org/about/ieee-code-ethics | Retain if explicitly applying the code. The page returned little usable text this session; verify a readable official copy before quoting a clause. A citation alone does not establish ethical practice. |
| E-WASTE | ITU/UNITAR, *Global E-waste Monitor 2024*, 2024. https://www.itu.int/en/publications/ITU-D/pages/publications.aspx?media=electronic&parent=D-GEN-E_WASTE.01-2024 | Retain for global e-waste context or figures. Not needed solely to explain our own replacement/repair decisions. Previously recorded; not freshly rechecked. |
| SCALER | scikit-learn, "StandardScaler." https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html | Retain if explaining this implementation or using its documentation. A training-only normalization description must still match our actual pipeline. Previously recorded; not freshly rechecked. |
| PYTEST | pytest, "pytest documentation." https://docs.pytest.org/en/stable/ | Retain if pytest is discussed as a development tool. Software-test results come from our run records. Previously recorded; not freshly rechecked. |
| FLUTTER-TESTS | Flutter, "Testing Flutter apps." https://docs.flutter.dev/testing/overview | Retain if explaining test types/processes rather than just naming app development. Previously recorded; not freshly rechecked. |
| GIT | Git, "git documentation." https://git-scm.com/docs/git | Retain if discussing Git as a tool or its workflow. Avoid a separate citation merely to repeat the repository URL. Previously recorded; not freshly rechecked. |

For conditional web entries, add the actual access date after the relevant
page is rechecked. Do not paste this table into the report as its bibliography.

## Sources to leave out unless a specific need arises

The old piezo entry combines the [TIMESETL seller listing](https://www.amazon.com/dp/B077YJ3H6R)
and [Murata external-drive guidance](https://www.murata.com/en-global/support/faqs/sound/diaphragm/char/sch0001).
The listing identifies the team's purchase; it does not establish drive ratings
or effective tactile feedback. Murata's general guidance is not the datasheet
for those purchased parts. Describe the team's acquired piezos and unresolved
driver work directly. Cite the listing only if precise product identification
is needed; cite a separately checked technical source if discussing a driver
design. Do not bundle these into one IEEE entry. Neither page was freshly
rechecked here, and a matching manufacturer datasheet remains unavailable.

Do not add other papers from the larger research inventory merely to enlarge
the bibliography. In particular, video-based Tanzanian-sign recognition and
motor-driven Korean-sign teaching gloves require a clear comparative purpose
and careful explanation of their differences if used.

## Audit of all 38 old bibliography entries

The old keys below refer to the preserved LaTeX bibliography. "Internal"
means retain traceability in our working evidence notes; cite a distinct prior
document in the report when it is actually used as such. It does not mean
that original results need no evidence.

| Old entry | Action for the Word rewrite |
| --- | --- |
| nidcd | Keep as ASL-CONTEXT. |
| design | Internal; cite the original design report if specifically comparing against it. |
| educators | Keep as ASL-EDUCATORS; replace the unhelpful institutional landing link with DOI/author PDF. |
| lee | Keep as WEARABLE-ASL; use the primary paper, with hardware/evaluation differences. |
| tcn | Keep as TCN; label the preprint accurately. |
| quaternion | Conditional ORIENTATION. |
| magnetic | Conditional MAGNETIC. |
| hapticstudy | Conditional HAPTIC-STUDY. |
| ble | Keep as BLE; distinguish explanatory primer from formal compliance. |
| nus | Keep as NUS when describing the custom service. |
| staticrecord | Internal evidence; explain the static experiment directly in Design/Results. |
| wordrecord | Internal evidence; retain dataset/split/model-selection details in the report. |
| integration | Internal evidence; summarize relevant checks and their limits directly. |
| auth | Conditional FIREBASE-AUTH; general tool use can use FIREBASE. |
| firestore | Conditional FIRESTORE-RULES. |
| cloudsecurity | Conditional FIREBASE-PRIVACY. |
| piezo | Remove the combined entry; seller listing and Murata guidance are separate sources if needed. |
| flex | Keep FLEX; split off FLEX-DATASHEET if its specifications are used. |
| repo | At most one general versioned repository entry; do not append it to every project statement. |
| platformio | Keep PLATFORMIO. |
| flutter | Keep FLUTTER. |
| keras | Keep TENSORFLOW. |
| litert | Keep TFLITE-MICRO within its embedded scope. |
| scaler | Conditional SCALER. |
| pytest | Conditional PYTEST. |
| fluttertests | Conditional FLUTTER-TESTS. |
| kicad | Keep KICAD with documentation-version caveat in working notes. |
| git | Conditional GIT. |
| i2c | Keep I2C. |
| imu | Keep IMU; separate IMU-GUIDE only if used. |
| sme | Internal observations; explain participants, remote review, and feedback limits directly. |
| deafled | Keep DEAF-LED. |
| ewaste | Conditional E-WASTE. |
| ethics | Conditional IEEE-ETHICS. |
| pilot | Internal evidence; include acquisition and delivery details in Results if retained. |
| demoobservations | Internal team observations; report them with dates and missing trial-count limits. |
| testplans | Internal procedures; describe executed tests directly. If citing T1 and T2 as documents, give each its own number. |
| review | Internal planning/code review; no new experimental outcome. Cite separately only if explicitly relying on that distinct document. |

## Internal evidence and optional repository entry

Keep these accessible while writing even when they are not separate entries
in the report's bibliography. Working links open current files, which can
contain later updates; check dated passages and the frozen snapshot before
using them for October claims:

- [First-semester design](../design_draft/Helping_Hand_Design_Draft.pdf).
- [Static model record](../docs/STATIC_MLP_DEMO_MODEL.md).
- [Word model record](../docs/WORD_MODEL_DEMO_TRAINING.md).
- [Word integration record](../docs/WORD_DEMO_INTEGRATION.md).
- [Alpha procedures](../docs/T1_ALPHA_TEST_PLAN.md) and
  [beta procedures](../docs/T2_Beta_Test_Plan.tex).
- [Team demonstration observations](../docs/R3_DEMO_OBSERVATIONS.md).
- [Stakeholder discussion](../SME.md).
- [Pilot exports](../backend/recorded_data).
- [TCN review](../docs/R3_TCN_IMPROVEMENT_REVIEW.md).
- [Readiness/evidence limits](../docs/R3_REPORT_READINESS.md).

Optional REPO entry:

Helping Hand team, "Helping Hand," source code and project records, GitHub,
commit cf59fd98feed2f5e6b90997c8b5ff4ae2b700b48, Oct. 28, 2026. [Online].
Available: https://github.com/GG1627/helping-hand/tree/cf59fd98feed2f5e6b90997c8b5ff4ae2b700b48

This October 28 report-finalization commit contains the report and team-demo
notes, checked using Git history and tree inspection. It is an archive pointer,
not proof of when every feature was implemented or of which build ran at a
demo. The older report used a35d0f5 (October 27); the selected snapshot also
preserves the later October 28 observation record. Read each record's own
dates and limitations.

## Before finalizing the Word report

1. Check each source against the exact sentence it supports. Add needed sources
   rather than stretching a broad overview to support a specific claim.
2. Recheck conditional sources that are actually used; complete metadata and
   record honest access dates. Exclude sources not cited or otherwise used.
3. Verify dates, participants, hardware, splits, and metric meanings in every
   retained research comparison. Keep our results distinct from other studies.
4. Replace stable draft IDs with IEEE numbers in first-citation order and
   cross-check every number against one bibliography entry.
5. Check attribution for any borrowed figure, wording, or distinct prior
   report. Label original team drawings/photos as such where useful.
6. Preserve AI-assistance disclosure under the repository/course policy.
