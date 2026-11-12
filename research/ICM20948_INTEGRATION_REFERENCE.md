# ICM-20948 reference and Helping Hand integration plan

Research date: November 5, 2026. Hardware: **Adafruit ICM-20948 breakout #4554**,
already received. Goal: reliable selected-sign practice for the main glove
wearer, followed by broader evaluation. This reference separates sourced device
behavior, inspected project implementation, and proposed experiments. No new
hardware or recognition validation was performed during this research.

## 1. What the upgrade provides

The board combines three-axis acceleration, angular rate, and magnetic-field
sensing. Its accelerometer ranges are ±2/4/8/16 g; gyro ranges are
±250/500/1000/2000 degrees/s. The compass range is approximately ±4900 µT.
The breakout includes regulation and level translation around a chip that needs
lower-voltage interfaces. [Adafruit product](https://www.adafruit.com/product/4554)

For our project, think of these as three different observations:

| Observation | Practical interpretation | Our intended use / limitation |
| --- | --- | --- |
| Acceleration | Specific force, including the gravity contribution when stationary | Tilt information and gesture dynamics; moving acceleration complicates tilt estimation |
| Angular rate | How quickly the sensor rotates | Wrist rotation and motion timing; integrating bias produces drift |
| Magnetic field | Local field vector, not a direct yaw measurement | Additional heading reference after calibration; nearby disturbances can make it unreliable |

These interpretations motivate combining sensors. Orientation fusion can use
gravity and magnetic information to constrain gyro integration, but needs
application-specific tuning. The VQF research explicitly treats gyro bias and
magnetic disturbance rejection; its results are orientation-estimation evidence,
not Helping Hand recognition results.
[Laidig and Seel, VQF](https://arxiv.org/abs/2203.17024)

**Nine axes do not mean nine independent pose coordinates.** One wrist sensor
does not directly measure finger spread, fingertip contact, facial expression,
the other hand, or reliable position relative to the face. Double-integrating
acceleration is not a dependable general-purpose hand-position tracker.
[x-io position FAQ](https://x-io.co.uk/contact/)

Our inference: this upgrade is most promising for wrist orientation, dynamic
letters/words, and consistent motion features. It cannot guarantee separation
of signs whose distinguishing information the glove does not observe.

## 2. Wiring and breakout-specific details

Use the **breakout's** electrical guidance, not bare-chip pin voltages:

| Feather ESP32-S3 | Adafruit #4554 | Project instruction |
| --- | --- | --- |
| 3.3 V | VIN | Use the Feather's regulated logic supply |
| GND | GND | Share ground |
| SDA board alias (current configuration GPIO 3) | SDA | Verify the actual Feather variant and wiring |
| SCL board alias (current configuration GPIO 4) | SCL | Keep bus wiring secure and short |

Adafruit documents VIN and main I2C pins for 3–5 V systems, with SDA/SCL pullups.
The auxiliary AD/AC and FS pins are **1.8 V only**. Do not treat those as extra
3.3 V GPIO connections. Default board address is documented as 0x69; alternate
address is 0x68. The pinout page's wording about address-pin polarity conflicts
with its Arduino guide, so verify the physical jumper/schematic and I2C scan
rather than choosing polarity from prose.
[Pinouts](https://learn.adafruit.com/adafruit-tdk-invensense-icm-20948-9-dof-imu/pinouts),
[Arduino wiring](https://learn.adafruit.com/adafruit-tdk-invensense-icm-20948-9-dof-imu/arduino)

Project recommendations: secure a repeatable dorsal-hand mount, photograph its
axes, use strain relief, and bench-test before final sewing. Use insulated
flexible wire for I2C/power initially. Check the actual assembled bus before
changing its clock. Repositioning the board changes the sensor-to-hand transform
and should trigger a mounting/calibration version change.

The official resource pages disagree about lifecycle: the InvenSense page labels
the part EOL, while TDK Product Center says Production (NRND). They also differ
on a summarized I/O voltage. Use the breakout guide and detailed datasheet for
engineering, and obtain vendor confirmation for future production purchasing.
This is not a reason to discard our received prototype boards.
[InvenSense product](https://www.invensense.tdk.com/en-us/products/9-axis/icm-20948),
[TDK Product Center](https://product.tdk.com/en/search/sensor/mortion-inertial/imu/info?part_no=ICM-20948)

## 3. What the repository currently does

Inspected at the November 5 recording update, commit `ea38c33`:

| Area | Current implementation | Remaining work |
| --- | --- | --- |
| Discovery | Probes 0x68/0x69; legacy MPU path retained; ICM identity 0xEA | Verify received board on the real bus |
| Main sensor configuration | Banked-register driver; ±2 g and ±250 degrees/s; DLPF configuration 3; sample dividers zero | Measure clipping/noise and select bandwidth/ranges deliberately |
| Acquisition | Latest accel/gyro registers polled in a target 40 Hz loop; bus 100 kHz | Measure delivered rate and capture timing; no FIFO acquisition yet |
| Magnetometer access | Disables internal I2C master; enables bypass; reads AK09916 at 0x0C; checks identity bytes 0x48/0x09 | Bench-check this access path; independent magnetometer recovery is absent |
| Magnetic sampling | Requests 100 Hz compass mode; polls at the packet rate; checks ready and overflow; reads through ST2 | Record overrun diagnostics and per-sensor freshness/age |
| Conversion | Accel counts /16384 → g; gyro /131 → degrees/s; magnetic counts ×0.15 → µT | Confirm axes, signs, and stationary measurements |
| Data transport | Optional `mag=ok,mx=...,my=...,mz=...` or `mag=unavailable` | Verify negotiated MTU, packet integrity, and rate on phone |
| Export | CSV magnetic status/axes and manifest coverage counts; missing readings stay blank | Add calibration/mount/range/filter versions before new datasets |
| Models | Static MLP: five flex inputs; word TCN: five flex + six motion inputs | No magnetic features or fused orientation in deployed inference |
| Fusion | None; no DMP firmware loaded | Choose and validate one fusion path |

Local sources: [driver](../ESP32/src/imu_sensor.cpp),
[configuration](../ESP32/include/firmware_config.h),
[runtime](../ESP32/src/main.cpp),
[recording extension](../docs/MAGNETOMETER_RECORDING.md).
Build and host checks establish software compatibility, not physical correctness.

### Important manufacturer cross-checks

The chip uses register banks; the compass has its own access/status sequence.
The datasheet defines different accel/gyro and magnetic axis diagrams; do not
assume identical native frames. Bypass requires the internal I2C master disabled.
ST2 ends a compass read, and its overflow flag invalidates that magnetic sample.
ST1 overrun means an update was skipped, distinct from overflow.
[TDK datasheet, sections 8.6, 13, 15](https://product.tdk.com/system/files/dam/doc/product/sensor/mortion-inertial/imu/data_sheet/ds-000189-icm-20948-v1.5.pdf)

With our DLPF setting, documented gyro/accel bandwidths are approximately
51.2/50.4 Hz. With dividers zero, documented internal output rate is 1125 Hz.
These are not our 40 Hz recorded rate. [TDK, tables 16 and 18](https://product.tdk.com/system/files/dam/doc/product/sensor/mortion-inertial/imu/data_sheet/ds-000189-icm-20948-v1.5.pdf)

Engineering implication: polling the latest output at 40 Hz can alias motion or
vibration above its 20 Hz Nyquist frequency. Interpolation afterward cannot
recover discarded information. Compare narrower filters against faster local
acquisition followed by filtering/decimation. A 3 dB cutoff below 20 Hz alone
does not establish adequate stopband attenuation; measure the tradeoff between
noise suppression, gesture detail, and delay. Do not change the filter and then
assume an old model remains compatible.

At 100 Hz compass conversion and about 40 Hz polling, some magnetic conversions
will naturally be skipped. That is not necessarily failed BLE delivery.
Recommendation: report compass overrun separately from sequence gaps and
overflow. The current single packet timestamp is a host capture timestamp,
not proof that all sensors sampled simultaneously.

## 4. Driver and fusion choices

### Retain the custom driver, with explicit tests

Lowest code churn, preserves our units, and keeps the existing model baseline.
Recommended near-term checks: register readback; compass-only failure/retry;
stationary bias; range saturation; axis mapping; bandwidth and sample age.
If the compass fails initialization while accel/gyro stay healthy, the current
driver does not periodically retry only the compass. Document this limitation
before relying on automatic recovery.

### Adafruit ICM20X driver as a reference or replacement

Adafruit's driver uses the ICM's internal I2C master to proxy compass readings,
instead of our bypass method, and includes auxiliary-bus setup retries. Its
scaling matches our selected raw range factors. These are alternatives, not
proof our bypass path is defective. Pin a library release/commit and compare
raw readings before replacing the working interface.
[Adafruit ICM20948 implementation](https://github.com/adafruit/Adafruit_ICM20X/blob/master/Adafruit_ICM20948.cpp)

**Unit trap:** public Unified Sensor events expose acceleration in m/s² and
gyro in radians/s; magnetic events remain µT. Our BLE contract uses g and
degrees/s. Convert explicitly (g = m/s² / 9.80665; degrees/s = radians/s ×
180/π), or intentionally version and retrain the complete pipeline. The
library's initialization defaults also differ from ours; configure ranges and
rates explicitly. [Adafruit event/default code](https://github.com/adafruit/Adafruit_ICM20X/blob/master/Adafruit_ICM20X.cpp)

### Host-side fusion versus onboard DMP

SparkFun documents DMP support for six- and nine-axis quaternion outputs. It
requires loading firmware, configuring outputs, and draining/parsing FIFO data;
it is not automatically enabled by reading this chip. Its documentation reports
roughly 14 KB of DMP program data and partial feature support. If selected,
measure actual linked memory and review distribution/license terms rather than
assuming it is free in memory or interchangeable with our driver.
[SparkFun DMP guide](https://github.com/sparkfun/SparkFun_ICM-20948_ArduinoLibrary/blob/main/DMP.md)

For the first experiment, I recommend reproducible host-side fusion on captured
data, then porting the chosen causal configuration to the ESP32 or phone.
The x-io Fusion implementation provides orientation, gravity-removed acceleration,
and acceleration/magnetic rejection diagnostics. VQF is another researched
candidate; compare its **online** variant for deployment. Offline smoothing has
future samples and must not be presented as live performance.
[Fusion implementation guide](https://github.com/xioTechnologies/Fusion),
[VQF paper](https://arxiv.org/abs/2203.17024)

Recommendation: begin with one pinned implementation and log sample intervals,
startup, rejected references, and resets. Test six-axis fallback when magnetic
data is absent or disturbed. Do not blindly pass stale or zero-filled vectors
to fusion. Specify quaternion order, transform direction, world-frame convention,
and gyro units in the metadata; algorithms do not share a universal convention.

## 5. Calibration and coordinate-frame protocol

Magnetic calibration must account for offsets, distortion, and alignment with
the inertial axes. Kok and Schön develop a calibration method covering these
effects and show why alignment matters for heading estimation.
[Calibration paper](https://arxiv.org/abs/1601.05257)

Proposed Helping Hand protocol, not completed validation:

1. **Freeze the assembly.** Record board identity, firmware/library revision,
   mounting photograph, supply, axis directions, sensor ranges, filters, and rate.
2. **Stationary capture.** Warm up; record repeated still segments. Estimate
   gyro bias and its variability. Do not calibrate the gyro while the wearer moves.
3. **Accel checks.** Hold several known orientations, including opposite faces.
   Inspect axis signs, magnitude, offset, and scale. Fit a documented calibration
   if needed; do not force moving acceleration to have unit norm.
4. **Magnetic sweep.** Rotate through diverse orientations in the final mounted
   assembly away from temporary nearby metal. Fit offset and distortion terms
   from calibration captures, then assess separate repeat sweeps. A quick
   min/max correction is an initial diagnostic, not proof of full calibration.
5. **Frame alignment.** Establish separate sensor-to-common-frame mappings.
   Confirm right-handedness and known rotations on all axes. Then establish the
   common sensor-to-glove mounting transform. Do not copy a permutation from an
   unrelated breakout photo.
6. **Disturbance test.** Repeat with normal battery/electronics positions and
   with haptics off/on. Test the intended demo area near desks and the phone.
   Measure field/orientation changes; do not assume piezos are either harmless
   or equivalent to magnetic vibration motors.
7. **Repeatability.** Remove/re-don the glove and repeat neutral/known poses.
   Version calibration parameters; retain original raw data. Separate calibration
   captures from final recognition evaluation attempts.

An illustrative model is `m_common = R * A * (m_raw - b)`, with offset `b`,
distortion/scale matrix `A`, and alignment rotation `R`. Parameterization and
fitting must be documented; arbitrary fitted matrices are not automatically
physical rotations. Success means repeatable measurements and useful held-out
recognition behavior, not just a visually round calibration plot.

## 6. How we should use this for recognition

The following are project hypotheses to test, not promised accuracy gains:

| Candidate | Inputs / change | Question |
| --- | --- | --- |
| M0 | Existing five-flex MLP | Frozen regression baseline |
| M1 | Flex plus calibrated gravity/tilt representation | Does wrist tilt help selected static-letter distinctions? |
| M2 | M1 plus validated heading-related features | Does heading add value without depending on room direction? |
| T0 | Existing 11-feature TCN | Baseline on fresh repaired-glove recordings |
| T1 | Five flex + calibrated nine sensor axes (14 total) | Does magnetic data improve held-out attempts? |
| T2 | Flex + aligned motion + relative orientation features | Does orientation help at different starting wrist positions? |
| T3 | T2 with tested magnetic rejection/fallback | Does performance survive magnetic disturbances? |

M1/M2 change the embedded model's input shape and export/runtime code; changing
only the output layer is insufficient. T1–T3 require matching training and phone
preprocessing and a newly trained bundle. Keep the current model until a
replacement passes the chosen criteria.

Preserve both initial orientation and movement when useful. An attempt-relative
rotation can reduce dependence on where the wearer initially faces, while
gravity-relative orientation may retain palm tilt. Removing every absolute
orientation could erase a real sign distinction. Quaternion signs also need a
consistent representation: `q` and `-q` encode the same rotation but differ
numerically. These are preprocessing requirements to test, not implemented
features in the current TCN.

For J/Z, record complete correctly performed sequences and confusable static
holds; test whether wrist sensing actually captures the relevant path. A wrist
IMU is not a fingertip tracker. For words, fix the existing gesture-window
truncation alongside feature experiments, but isolate each change in comparisons.
See [the main-wearer optimization audit](../docs/DEMO_MODEL_OPTIMIZATION.md).

For directional haptics, compare a calibrated reference pose/trajectory with the
attempt only after defining timing alignment and tolerances. A classifier's
confidence does not identify the wrong finger or a corrective direction. Design
and validate that error-to-cue mapping separately.

## 7. Experiment and acceptance record

Use the same new-glove recordings and whole-trial development split for each
candidate. For the declared personalized goal, collect fresh repetitions across
sessions and re-donning by the main wearer, including wrong words, incomplete
motion, still holds, and idle movement. Add other wearers later as a separately
reported objective. Historical test recordings are development/regression
evidence after continued tuning.

Measure per-sign lesson completion, false completion, macro F1/confusions,
orientation/magnetic-condition results, capture quality, model size, and repeated
end-to-end phone latency. Select using validation only; reserve a fresh final
session for the chosen model. Compare six-axis and nine-axis processing on the
same new hardware to isolate magnetic contribution from the board replacement.
Evaluate augmentation only against real held-out attempts.

| Procedure | Evidence to save | Status |
| --- | --- | --- |
| Identify board and check wiring/address | Photos, identity logs, schematic revision | Not run |
| Readback, signed axes, static checks | Raw bench captures and settings | Not run |
| Clipping/filter/rate study | Saturation counts, spectral/rate checks, delay | Not run |
| Bias/magnetic calibration and alignment | Versioned parameters + separate validation capture | Not run |
| Haptics-on/off and room disturbance | Raw/fused data and rejection diagnostics | Not run |
| Full BLE recording on Fairphone | Negotiated MTU, packet counts/gaps, exports | Not run |
| Same-split model feature comparison | Configurations, source hashes, per-sign results | Not run |
| Main-wearer final rehearsal | Fresh trials, failures, latency, configuration | Not run |

Choose numerical pass criteria before running each experiment. Do not copy
vendor range/precision numbers or another paper's accuracy as our performance.
The staged work above is how we determine which use of this IMU is best for
Helping Hand, rather than assuming that more channels must improve detection.

## 8. Source/version notes and follow-up

All external links above were inspected November 5, 2026; primary manufacturer,
library-author, and research-author sources were used. The directly readable
datasheet reviewed is **DS-000189 revision 1.5, September 2, 2021**. InvenSense's
new product page lists revision 1.6, but its download was not available as a
readable PDF during this review; do not claim 1.6 was checked. Adafruit's older
datasheet URL redirects to a download page. Its downloads page also links the
board design files for hardware review:
[Adafruit downloads](https://learn.adafruit.com/adafruit-tdk-invensense-icm-20948-9-dof-imu/downloads).

Library links track moving branches. Pin exact versions before implementing
their algorithms or changing drivers. No library was installed or substituted,
no firmware/model settings changed, and no existing report's historical cutoff
was revised by this research.

Immediate engineering priorities: bench-check the received board; establish
axes/units/calibration; resolve filtering and acquisition timing; capture real
nine-axis data; compare bounded model variants; then integrate validated
orientation-based feedback. Retain six-axis and original-model fallbacks.
