# R3 report: verified source notes and citation corrections

Checked October 27, 2026 for the [report-readiness assessment](../docs/R3_REPORT_READINESS.md).
These are working source notes, not a finished bibliography or Helping Hand
experimental results. Include only sources actually used in the final report.
Research papers, standards and tool documentation support different kinds of
claims; vendor pages and university news do not replace empirical studies.

## Priority research and context sources

### S1. ASL learning needs and educator perspectives

S. Hassan et al., "ASL Educators' Perspectives on AI for Enhancing Student
Learning in American Sign Language Education," *Proceedings of CHI 2026*,
20 pages, 2026. DOI: [10.1145/3772318.3791928](https://doi.org/10.1145/3772318.3791928).
[Institutional record](https://www.open-access.bcu.ac.uk/17020/) and
[author-hosted paper](https://saadh.info/papers/hassan-chi26/hassan-chi26.pdf).

The study interviewed eleven Deaf and one hearing ASL instructor and held
follow-up focus groups with six Deaf educators. It directly addresses feedback
and practice tools for ASL education. Use for motivation and educator-informed
design priorities. It does not validate Helping Hand or show that a glove
improves retention. This is more directly relevant to our educational purpose
than relying entirely on translator-glove papers.

### S2. Direct wearable temporal-ASL prior art

B. G. Lee, T.-W. Chong, and W.-Y. Chung, "Sensor Fusion of Motion-Based Sign
Language Interpretation with Deep Learning," *Sensors*, 20(21), 6256, 2020.
DOI: [10.3390/s20216256](https://doi.org/10.3390/s20216256).
[Published article](https://www.mdpi.com/1424-8220/20/21/6256).

The primary paper behind the existing 27-word/99.81% reference uses six IMUs,
including fingertip sensors, and an LSTM-based system. It supports temporal
modeling as a feasible approach. Its sensing arrangement and protocol differ
from our five flex sensors plus one wrist IMU; its score is not a target or a
direct comparison for Helping Hand. Cite this paper instead of attributing the
result only to the review article in the old source list.

### S3. TCN architecture rationale

S. Bai, J. Z. Kolter, and V. Koltun, "An Empirical Evaluation of Generic
Convolutional and Recurrent Networks for Sequence Modeling," arXiv:1803.01271,
2018. [Author preprint](https://arxiv.org/abs/1803.01271).

This foundational comparative sequence-modeling study motivates considering
temporal convolution alongside recurrent networks. Label it an arXiv preprint,
not an ASL-specific trial or proof that TCN will outperform alternatives here.
Our deployment choice is separately supported by the recorded local size
tie-break, not by a proven accuracy advantage on three validation examples.

### S4. Orientation preprocessing theory

A. Yurtman, B. Barshan, and B. Fidan, "Activity Recognition Invariant to Wearable
Sensor Unit Orientation Using Differential Rotational Transformations
Represented by Quaternions," *Sensors*, 18(8), 2725, 2018.
DOI: [10.3390/s18082725](https://doi.org/10.3390/s18082725).
[Published article](https://www.mdpi.com/1424-8220/18/8/2725).

The paper evaluates Earth-frame transformations and differential quaternion
rotations for activity recognition under changing sensor orientation. Use for
a planned preprocessing experiment, with its sensing assumptions explained.
It is not ASL-specific, and our demo implements no such normalization. Verify
the physical IMU and available magnetometer data before selecting fusion.
Also test whether normalization preserves orientation distinctions meaningful
to the selected signs; nuisance mounting rotations and sign orientation are
different design concerns.

### S5. Deaf-led critique and stakeholder participation

A. Desai, M. De Meulder, J. A. Hochgesang, A. Kocab, and A. X. Lu, "Systemic
Biases in Sign Language AI Research: A Deaf-Led Call to Reevaluate Research
Agendas," *Proceedings of the LREC-COLING 2024 11th Workshop on the
Representation and Processing of Sign Languages*, pp. 54-65, 2024.
[Published paper and citation record](https://aclanthology.org/2024.signlang-1.6/).

The authors analyze 101 papers and discuss biases in problem framing, data,
annotations and research participation. Use for the ethical case for Deaf
participation and careful task definitions. Do not treat two ASL-learner
conversations in SME.md as representative community endorsement.

### S6. Responsible sign-language technology development

M. De Meulder, "Is 'good enough' good enough? Ethical and responsible development
of sign language technologies," *Proceedings of the 1st International Workshop
on Automatic Translation for Signed and Spoken Languages*, pp. 12-22, 2021.
[Published paper and citation record](https://aclanthology.org/2021.mtsummit-at4ssl.2/).

Discusses design ideologies, dataset bias, user feedback and intended uses,
particularly for avatars. Useful ethical context; its system focus is different
from a sensor glove. Tie recommendations to specific project choices rather
than claiming that citation alone establishes responsible practice.

### S7. ASL language context

National Institute on Deafness and Other Communication Disorders (NIDCD),
"American Sign Language."
[Official page](https://www.nidcd.nih.gov/health/american-sign-language).

Supports explaining ASL as a natural language with its own grammar, expressed
through the hands and face; sign languages are not universal. Use in the
introduction, global/cultural impact and single-glove limitations. Recognition
of a few hand movements does not establish grammatical competence.

### S8. Optional demographic context

NIDCD, "Quick Statistics About Hearing, Balance, & Dizziness."
[Official page](https://www.nidcd.nih.gov/health/statistics/quick-statistics-hearing).

The page states that more than 90% of deaf children are born to hearing
parents, citing Mitchell and Karchmer (2004). If retained, state the population
and underlying historical source. This is not a 2026 user survey, an ASL
proficiency measure, or evidence of demand for this particular glove. The
educator study S1 provides a closer connection to the learning problem.

## Existing sources that need careful qualification

### S9. CNN-GRU/CNN-LSTM comparison is video and Tanzanian Sign Language

K. Myagila, D. G. Nyambo, and M. A. Dida, "Efficient spatio-temporal modeling
for sign language recognition using CNN and RNN architectures," *Frontiers in
Artificial Intelligence*, 8, 1630743, 2025.
DOI: [10.3389/frai.2025.1630743](https://doi.org/10.3389/frai.2025.1630743).
[Publisher paper](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1630743/full).

The old research table's 94%/93% figures come from phone-video experiments on
Tanzanian Sign Language, not wearable IMU ASL. Its separate unseen-signer
results are much lower. Use only as cross-modal temporal-model context; do not
present the headline score as signer-independent sensor performance.

### S10. The IMU/sEMG paper is not the 126 g Para-LSTM-CNN glove

J. Wu, L. Sun, and R. Jafari, "A Wearable System for Recognizing American Sign
Language in Real-Time Using IMU and Surface EMG Sensors," *IEEE Journal of
Biomedical and Health Informatics*, 20(5), pp. 1281-1290, 2016.
DOI: [10.1109/JBHI.2016.2598302](https://doi.org/10.1109/JBHI.2016.2598302).
[Publisher abstract](https://ieeexplore.ieee.org/document/7552525/).

The primary abstract describes IMU plus sEMG, feature selection and an SVM,
evaluated on 80 ASL signs and four subjects. It does not support the existing
research note's 126 g glove/41-dimensional/parallel-LSTM-CNN description.
That description appears under a different title, "Wearable Electronic Glove
and Multilayer Para-LSTM-CNN-Based Method for Sign Language Recognition,"
DOI `10.1109/JIOT.2024.3454215`. Retrieve and inspect that primary paper before
reusing its detailed hardware/performance claims; publisher full text was not
retrieved in this assessment. Do not silently preserve the incorrect citation.

### S11. A relevant IMU glove study uses Chinese signs

A. Ji et al., "Dataglove for Sign Language Recognition of People with Hearing
and Speech Impairment via Wearable Inertial Sensors," *Sensors*, 23(15), 6693,
July 26, 2023. DOI: [10.3390/s23156693](https://doi.org/10.3390/s23156693).
[Primary article](https://www.mdpi.com/1424-8220/23/15/6693),
[indexed abstract](https://pubmed.ncbi.nlm.nih.gov/37571476/).

Useful wearable and temporal-classification prior art. The experiment uses
20 Chinese sign-language gestures; it is not an ASL learning study. Correct
the January date in the existing bibliography to the actual July publication.

### S12. Current multimodal benchmark is a preprint

X. Xiao et al., "SIGMA-ASL: Sensor-Integrated Multimodal Dataset for Sign
Language Recognition," arXiv:2605.06351, 2026.
[Author preprint](https://arxiv.org/abs/2605.06351),
[full text](https://arxiv.org/html/2605.06351).

The preprint describes 20 participants and 160 signs with two wrist IMUs and
other modalities. Table 3 supports the old note's 63.10% I3D/STFT and 62.31%
CNN-GRU IMU user-independent top-1 figures. Useful for the difficulty of
unseen-user evaluation and a broader sensing comparison. Label the source as
a preprint unless a reviewed venue is independently confirmed. It does not
establish Helping Hand's accuracy or supply finger-flex data.

### S13. Educational glove paper has a different feedback mechanism

H.-J. Kim and S.-W. Baek, "Application of Wearable Gloves for Assisted Learning
of Sign Language Using Artificial Neural Networks," *Processes*, 11(4), 1065,
2023. DOI: [10.3390/pr11041065](https://doi.org/10.3390/pr11041065).
[Primary article](https://www.mdpi.com/2227-9717/11/4/1065).

Potential optional educational prior art, but not a like-for-like benchmark:
its Korean-sign recognition uses video-derived skeletal data, and the glove
generates finger movement using motors. Do not describe its recognition score
as sensor-glove ASL performance or a measured educational benefit.

## Official standards, hardware and development documentation

| ID | Citation target | What it supports / project use |
| --- | --- | --- |
| T1 | Bluetooth SIG, [The Bluetooth Low Energy primer](https://www.bluetooth.com/bluetooth-le-primer/) | BLE architecture, ATT/GATT, characteristics, notifications and connection behavior. Cite the relevant Core Specification/version if discussing normative requirements; this primer does not certify the prototype. |
| T2 | Nordic Semiconductor, [Nordic UART Service](https://nrfconnectdocs.nordicsemi.com/ncs/latest/nrf/libraries/bluetooth/services/nus.html) | NUS is a custom GATT service, with the UUID/TX-notify/RX-write pattern used in firmware. Do not call the custom text packet format a Bluetooth SIG standard. |
| T3 | NXP, [UM10204: I2C-bus specification and user manual, Rev. 7.0, October 1, 2021](https://www.nxp.com/docs/en/user-guide/UM10204.pdf) | Sensor-bus electrical/protocol background. Current `Wire.setClock(100000)` uses a 100 kHz configured clock; the original design proposed 400 kHz. Actual signal integrity has not been measured here. |
| T4 | Adafruit, [ESP32-S3 Feather overview](https://learn.adafruit.com/adafruit-esp32-s3-feather/overview) | Current board-family capabilities and power/logic guidance. Confirm the exact purchased variant and battery before claiming part-specific ratings. |
| T5 | Flutter, [Testing Flutter apps](https://docs.flutter.dev/testing/overview) | Unit, widget and integration-test distinctions; developer tool/process reference rather than an engineering communications standard. |
| T6 | PlatformIO, [What is PlatformIO?](https://docs.platformio.org/en/latest/what-is-platformio.html) | Embedded development/build/test tooling. Cite alongside the actual project configuration/version. |
| T7 | Google AI Edge, [LiteRT for Microcontrollers](https://developers.google.com/edge/litert/microcontrollers/overview) | Microcontroller inference constraints and supported deployment approach. The repo's TensorFlowLite_ESP32 dependency and phone `tflite_flutter` are specific integrations; modern documentation does not prove compatibility of every newer API. |
| T8 | Firebase, [Writing conditions for Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/rules-conditions) | Authentication/ownership rules. Cite actual checked-in rules and current end-to-end tests separately; documentation does not prove deployed account isolation. |
| T9 | KiCad, [Getting Started in KiCad](https://docs.kicad.org/9.0/en/getting_started_in_kicad/getting_started_in_kicad.html) | Schematic/PCB workflow, electrical/design-rule checks and fabrication outputs. This documentation version is a reference, not proof that the team used KiCad 9.0 or ran ERC/DRC. |
| T10 | IEEE, [Code of Ethics](https://ieee-cas.org/about/ieee-code-ethics) | Professional obligations concerning public welfare, privacy, sustainable practices, fair treatment and evidence-based technical claims. An ethical framework, not a product certification. |
| T11 | ITU/UNITAR, [Global E-waste Monitor 2024](https://www.itu.int/en/publications/ITU-D/pages/publications.aspx?media=electronic&parent=D-GEN-E_WASTE.01-2024) | Background for electronics disposal and repairability. Does not quantify this glove's environmental footprint or establish a net sustainability benefit. |

Identify replacement flex-sensor and IMU part numbers before adding their exact
datasheets. Do not substitute a convenient generic sensor datasheet for an
unidentified installed part. Review the existing TI datasheets and peer-reviewed
haptic studies in [LINKS.md](LINKS.md) if the final report includes detailed
haptic-driver decisions; this assessment did not re-audit every haptic source.

## 9-axis versus 6-axis IMU: rationale for the planned upgrade

Team update, October 27: a 9-axis replacement is ordered; its product identity
is pending. The following supports the design rationale, not a finding that the
ordered part has already improved Helping Hand.

In the usual terminology, a 6-axis device provides three acceleration and three
angular-rate channels. A 9-axis device adds three magnetic-field channels.
Accelerometer/gyroscope fusion can estimate tilt and short-term rotation, but
gravity alone does not provide a heading reference for yaw. A calibrated
magnetometer can add that reference and reduce heading drift when its field
measurement is reliable. Bosch's mode table illustrates relative orientation
from accelerometer/gyroscope fusion versus absolute orientation with magnetic
fusion. This is an example device, not identification of the team's order.
[Bosch BNO055 Quick start guide, BST-BNO055-AN007-00, March 2015, p. 3](https://www.bosch-sensortec.com/media/boschsensortec/downloads/application_notes_1/bst-bno055-an007.pdf).

The potential Helping Hand benefit is more consistent wrist heading for
orientation features or quaternion-based preprocessing. This is an engineering
hypothesis; it needs a fair comparison on real sign attempts. Nine axes do not
automatically improve word accuracy, recover body-relative hand position,
capture the other hand/face, or make all wrist-angle changes irrelevant to ASL.
Magnetic north is not the same as the signer's body frame; do not train the
system to require learners to face one compass direction.

### S14. Peer-reviewed magnetic-calibration evidence

M. Kok and T. B. Schön, "Magnetometer Calibration Using Inertial Sensors,"
*IEEE Sensors Journal*, 16(14), pp. 5679-5689, 2016.
DOI: [10.1109/JSEN.2016.2569160](https://doi.org/10.1109/JSEN.2016.2569160).
[Author manuscript and journal reference](https://arxiv.org/abs/1601.05257).

The authors evaluate calibration for magnetic disturbances, sensor errors and
misalignment with inertial axes, demonstrating improved heading estimates on
two commercial units. This supports calibration as part of the upgrade, not
a guaranteed recognition improvement for this glove.

Test magnetic conditions in the assembled glove and intended room; compare
sensor readings with haptics off and on. Haptics-on/off checks should cover
mechanical vibration and electrical interference without assuming that piezo
elements contain the permanent magnets used in some motor actuators. Driver
and wiring effects depend on the actual selected parts.

The firmware must actually read/use the magnetometer or fused orientation to
benefit from the extra measurements. The current word model has a fixed
11-feature contract; adding magnetic or quaternion channels requires a
versioned data/preprocessing/model update and new evaluation. Simply replacing
the physical module does not update the trained model. Preserve a baseline
and check axes, units, range, sampling and calibration even when retaining
the same feature count.

A practical evaluation can measure stationary/return-to-start heading error,
repeatability across power cycles and wrist conditions, and recognition on
held-out attempts. Compare fusion modes on the same replacement hardware if
supported; otherwise label the old/new test as a hardware-system comparison.
Record sample counts, calibration, environment and failure cases. Preserve
meaningful palm orientation rather than normalizing it away indiscriminately.

Suggested report wording: "A nine-axis inertial/magnetic sensor has been
ordered to evaluate whether magnetometer-assisted fusion improves heading
stability and wrist-orientation representation. Integration, calibration and
comparison with the current six-axis approach remain planned."

## Suggested compact citation strategy

For a report limited to 3,500 words, prioritize S1, S2, S3, S4, S5/S6 and S7
for background, need and ethics; select a few more only where they explain a
specific design decision. Add official documentation for each tool/protocol
actually discussed. Source count is not an assignment requirement.

For every research comparison, record the language, sensing modality, vocabulary,
participants, split protocol and evaluation unit before citing a score. Use
existing team results only with their dataset, date/build, trial counts and
limitations. Keep proposed targets, confidence thresholds, training fit, test
accuracy and live-device measurements distinct.
