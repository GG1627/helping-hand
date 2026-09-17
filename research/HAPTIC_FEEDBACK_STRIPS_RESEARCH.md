# Haptic Feedback Strips for Hand/Wrist ASL Guidance

## Purpose and current status

This document records the research foundation for Issue #6, **Research On
Vibrating Strips for Hands**. The goal is to add tactile cues that can tell a
learner about wrist-orientation errors, hand-posture errors, success, or system
state without requiring constant visual attention.

This is a design recommendation and experiment plan, not a completed hardware
evaluation. As of September 10, 2026:

- no actuator or driver has been selected through a physical comparison;
- no haptic circuit has been added to the glove;
- no end-to-end haptic latency, power, heat, noise, or IMU-interference result
  has been measured;
- no user study has been performed; and
- the Issue #6 sub-50 ms figure remains an acceptance target, not a measured
  capability.

## Our Conclusions
We plan to prototype a haptic feedback system using **two piezoelectric coin actuators on each of the four fingers and one on the thumb, for nine actuators total**. The two actuators on each finger will be activated in sequence to test whether users can distinguish cues for bending or straightening that finger. The thumb’s single actuator will use different pulse patterns to communicate corrections.

We will begin with a single-finger prototype to evaluate placement, comfort, and cue recognition before expanding to the full glove. This testing will also help us select suitable piezo drivers and assess power consumption, durability, and interference with the glove’s sensors. Our goal is to provide clear tactile guidance during ASL practice while preserving natural hand movement.

## Research provenance

The initial source list and synthesis were supplied by a project contributor,
who reported using Claude Sonnet 5 to assist that research. Codex then checked
the source trail, separated vendor claims from peer-reviewed or official
technical material, corrected several over-broad conclusions, and organized
the findings for this repository. AI-assisted summaries are not experimental
evidence. Datasheets, cited papers, and measurements from the eventual Helping
Hand prototype remain the evidence of record.

## Design constraints for Helping Hand

The haptic subsystem must:

- remain light and low-profile enough not to restrict signing;
- avoid the five flex-sensor bend paths, the IMU, and pressure points;
- provide cues that remain perceptible while the hand is moving;
- coexist with the current ESP32 BLE telemetry connection;
- use bounded activation time and intensity;
- expose a versioned command and acknowledgement protocol;
- keep actuator vibration from silently corrupting ML sensor windows; and
- fit within a power budget established from measured current, battery
  capacity, pulse duty cycle, and surface temperature.

The glove currently uses the Nordic UART-style BLE service. The RX
characteristic (`6E400002-B5A3-F393-E0A9-E50E24DCCA9E`) accepts app-to-device
writes, but firmware currently only logs those writes. This is a convenient
future command path, not an implemented haptic API.

## Actuator comparison

| Technology | Useful properties | Main limitations for this project | Current disposition |
| --- | --- | --- | --- |
| **ERM coin or cylinder motor** | Inexpensive, common, and electrically simple | Rotating inertia makes crisp start/stop behavior harder; vibration amplitude and motor speed are coupled; usually less energy-efficient than an appropriately driven LRA | Low-cost comparison/control condition or fallback |
| **LRA (Concept B / Concept A)** | Faster, crisper effects than ERM; one-axis motion; closed-loop drivers can overdrive, brake, and track resonance | Narrow-band resonant device; mounting shifts resonance; requires 1 driver channel per actuator (`0x5A` address collision requires multiplexing) | Preferred MVP prototype (Concept B: 1 per finger; Concept A: 2 per finger) |
| **Piezoelectric bender/patch** | Thin construction (less than 1.0 mm), instant response (less than 1 ms), broader waveform control, and flexible mounting options | Requires high-voltage boost drivers (50 V to 105 V peak-to-peak); complex driver circuits, boost inductors, and trace safety margins | Stretch candidate if thickness or pattern fidelity disqualifies LRA |
| **Piezoelectric coin array (Concept C)** | Ultra-thin profile (less than 1.0 mm); instant response (less than 1 ms); 3–4 spatial coins per finger enable fine-grained directional sweep waves | Requires high-voltage boost drivers (50 V to 105 V peak-to-peak) and a multiplexing matrix for 15–20 elements; PZT ceramics are brittle and prone to cracking under finger joint flexion; electrical series wiring divides drive voltage | High-risk stretch candidate; requires single-element high-voltage bench testing and bend-strain validation first |
| **Research-stage flexible/electroosmotic actuator** | Demonstrates that very thin, skin-conformal haptics are technically possible | Cited devices are laboratory research prototypes, not evidence of availability, glove durability, safe integration, or production cost for Helping Hand | Literature reference only, not the MVP |

## Recommended first hardware direction

Start with one or two small LRAs mounted on a removable flexible textile or
flex-PCB carrier and driven by a closed-loop LRA driver. This satisfies the
intent of a conforming strip while keeping the first prototype based on
obtainable components. It does not claim that the actuator itself is bendable.
This one- or two-channel setup is a bench and perception-validation step; it
does not preclude a later five-finger array if the measurements support one.

The DRV2605L is a reasonable evaluation candidate because it:

- drives either one ERM or one LRA;
- operates from 2.0 V to 5.2 V;
- provides I2C, PWM, and analog control modes;
- includes a waveform library, auto-calibration, resonance tracking,
  overdrive, and braking; and
- uses the fixed 7-bit I2C address `0x5A` [19][20].

`0x5A` does not collide with the glove's current IMU addresses (`0x68` or
`0x69`). Multiple independently controlled DRV2605L channels cannot simply
share one I2C bus at the same fixed address. They require an I2C switch or
another isolation/multiplexing design; TI's multi-driver evaluation kit uses
this type of arrangement [21]. A single-driver breakout should be used for the
first bench experiment before laying out a custom board.

The final schematic must be based on the selected actuator datasheet. It must
include appropriate supply decoupling, I2C pull-ups, logic levels, rated and
overdrive settings, connector strain relief, current measurement access, and a
hard-off path. The actuator rail must not be sized from generic current figures
in a comparison article.

## Placement and ergonomics evidence

Placement results from other devices provide hypotheses, not final dimensions
for this glove:

- A 2019 on-body tacton study reported about 92% perception for its hand
  configuration and significantly higher accuracy on the hand than the wrist;
  its apparatus and task differ from Helping Hand [22].
- A 2024 hand/wrist study found that repetitive hand motion reduced
  vibrotactile identification accuracy and that hand placement outperformed
  wrist placement [23]. Correction cues must therefore be tested while the
  signer is moving, not only while stationary.
- A 2025 forearm study found that two simultaneous stimuli were best detected
  at 90 mm separation, reaching up to 96% in its transverse, approximately
  opposite-around-the-wrist arrangement. The authors also found that actuator
  orientation could not be robustly distinguished [24]. This discourages
  closely spaced simultaneous wrist tactors and does not establish a universal
  90 mm rule for every wearer.

### Initial placement hypotheses

1. **Dorsal wrist zone:** candidate for wrist-orientation correction, located
   away from the IMU and any strap edge.
2. **Dorsal hand zone:** candidate for finger/hand-posture correction, located
   where it does not cross knuckles or flex-sensor routing.
3. **Finger-level zones:** defer until the two-zone system is proven. Added
   wires, mass, contact pressure, and spacing may restrict natural motion.

Each actuator should be removable and repositionable during fit tests. Record
hand dimensions, placement coordinates, contact method, strap tension,
dominant hand, and whether the cue was tested at rest or in motion. Do not infer
comfort or perceptual accuracy from anatomy tables alone.

## Per-finger correction concepts

The contributor supplied two candidate interfaces for conveying *how* a
finger differs from a target. Both are research hypotheses. Neither has been
validated on the Helping Hand glove, and neither solves the upstream problem
of estimating a meaningful per-finger correction from the sensor/model output.

### Concept B: one actuator per finger and error-coded intensity

The preferred first per-finger architecture is one LRA per finger (five total).
The active finger identifies where the correction is needed, while pulse
intensity encodes the magnitude of a normalized error: stronger means farther
from the target and weaker means closer. A dead band around the target should
prevent continuous buzzing, and firmware must clamp intensity, pulse length,
repeat rate, and total activation time.

This encoding is a better match for an LRA than an ERM because an LRA driver
can shape the intensity envelope while keeping the actuator near resonance.
It does **not** require or imply arbitrary frequency control. The mapping must
be calibrated psychophysically; equal numeric steps in flex-sensor error must
not be assumed to produce equal perceived intensity steps.

The error signal also needs a precise definition. A flex-sensor deviation can
support a finger-bend cue, but the glove's wrist orientation is shared rather
than independently measured for each finger. For dynamic word recognition, a
class label alone does not provide frame-by-frame corrective targets. Initial
testing should therefore use known calibration poses or instructor-recorded
target trajectories, and it should trigger feedback after the captured model
window until haptic contamination of the IMU is understood.

### Concept A: two actuators per finger and directional motion

A more expressive alternative places proximal and distal tactors on a finger.
Driving them in order could represent `open/move outward` versus `close/move
inward`, so direction is encoded spatially rather than inferred through trial
and error. At least two independently driven locations are required for this
travel direction; one actuator can encode timing or intensity but cannot
create motion between two skin locations.

Related tactile illusions use several mechanisms that should not be treated as
interchangeable:

- **saltation/apparent motion:** successive stimuli at separated locations can
  be perceived as intermediate or moving taps when their timing is suitable;
- **funneling/phantom sensation:** simultaneous neighboring tactors with
  controlled relative amplitudes can shift the perceived location between the
  physical tactors; and
- **continuous tactile stroke algorithms:** coordinated amplitude, onset, and
  duration across a sparse array can synthesize a smoother moving sensation
  [31][32][34].

These effects are established in tactile-display research, and recent work
continues to evaluate directional funneling cues [33]. However, the cited
systems use tactile grids or body sites such as the trunk and shank; they do
not validate proximal-to-distal motion on an actively signing finger. The
available finger width and an expected actuator separation around 15-20 mm
are therefore experiment inputs, not evidence that the illusion will be
reliable. Start with the index finger and thumb, compare both directions
against isolated-tap controls, and measure direction accuracy, missed cues,
response time, comfort, and performance during motion before scaling.

### Concept C: three or four piezoelectric coins and continuous spatial sweeps

A higher-density alternate places 3 or 4 piezoelectric coin sensors in a line down each finger. Firing them in a sequence creates a continuous sweep or wave along the finger, giving the signer a sliding directional nudge (such as a sweep prompting them to flex a finger further) with higher spatial resolution than Concept A.

Piezo disks are more user friendly because they are under 1mm thick, so the signer will not feel them, and react almost instantly (under 1ms). However, concept C introduces electric and mechanical issues.

- **Physical series vs Electrical series**
  While the coins sit in a physical line down the finger, they must not be wired in electrical series. Piezos are capacitive loads, so an electrical series connection divides the drive voltage (Vpiezo = Vtotal/N) and drops vibration below what the skin can feel. Each piezo coin needs its own signal path or high-voltage switch.

- **High-voltage boost drivers**
  Unlike LRAs running on standard 2.0V - 5.2V rails; piezo sensors need specialized drivers (like the TI DRV2667 or DRV2700) with integrated boost converters generating 50V - 105V peak-to-peak.
  This introduces board isolation needs, larger boost inductors, and higher peak current draw.

- **Ceramic cracking from fingers**
  Standard PZT ceramic coins are brittle. Repeated joint bending during signing could potentially fracture the ceramic or snap solder joints. 

### Channel-count and ergonomic trade-off

Concept B requires 5 actuator channels, Concept A requires 10, and Concept C scales to 15 or 20 elements across five fingers.

With DRV2605L (LRA) or DRV2667 (Piezo) implementations, every driver IC uses a fixed I2C address (e.g., `0x5A` for the DRV2605L). Multi-channel designs cannot connect directly to a single shared bus; they require I2C multiplexing, bus switches, or a custom high-voltage switching matrix.

Scaling beyond Concept B also multiplies wiring mass, connector pin counts, and peak power concurrency. Small LRAs still occupy substantial space beside full-length flex sensors, while Piezo arrays introduce high-voltage safety margins. All concepts require a mechanical layout drawing and physical fit test before layout.

### Recommended prototype sequence

1. Validate one LRA and one driver on the bench, then compare candidate
   intensity levels on one removable finger mount.
2. If the single-finger cue is perceptible during motion without unacceptable
   restriction or IMU contamination, build Concept B as a five-finger array.
3. Measure power and thermal behavior for realistic and worst-case concurrent
   cues; do not assume all channels may run at full intensity.
4. Prototype Concept A (directional LRA) or Concept C (piezo sweep) only on the index finger and thumb. Advance to all fingers only if directional/sweep accuracy materially exceeds the simpler intensity interface and the added electronics remain within the glove's mass, power, and safety budgets.


## Critical sensor-interference risk

An LRA, ERM, or piezo actuator deliberately produces acceleration. The glove's
IMU measures acceleration and angular velocity, so haptic actuation may appear
inside the same signal used for gesture recognition. Mechanical coupling may
also vary with strap tightness and hand posture.

Before enabling feedback during a sign, collect these conditions at every
candidate placement and intensity:

1. glove stationary, haptics off;
2. glove stationary, each haptic pattern on;
3. repeatable wrist motion, haptics off;
4. the same motion, each haptic pattern on; and
5. normal BLE streaming while haptic commands are repeatedly triggered.

Compare raw accelerometer/gyroscope traces, packet rate, sequence gaps, and the
noise spectrum. Haptic-active samples must carry a marker in future recordings.
Until interference is characterized, the safest teaching flow is to trigger a
cue after a gesture window or exclude/gate haptic-active samples from model
input. Real-time mid-gesture correction remains a research objective rather
than an assumed capability.

## Draft haptic pattern library

These are deliberately simple starting patterns for a perception experiment.
They are **not validated tactons** and their timing must be tuned for the chosen
actuator and wearer population.

| Logical effect | Preferred zone | Draft temporal signature | Meaning |
|---|---|---|---|
| `success` | hand | two short pulses with one short gap | Gesture accepted |
| `orientation_correction` | wrist | three short pulses with equal gaps | Wrist orientation needs correction |
| `posture_correction` | hand | one clearly longer pulse | Finger/hand posture needs correction |
| `system_attention` | wrist | one short pulse, longer gap, one long pulse | Connection, calibration, or non-gesture issue |

The application command should select a named effect, zone, and normalized
intensity. Firmware/driver configuration should translate that request into an
actuator-specific waveform. For LRA hardware, a pattern should not ask the app
to choose an arbitrary vibration frequency. The initial experiment must test:

- recognition accuracy for every pattern, including a confusion matrix;
- false/no-response rate;
- static-hand versus signing-motion conditions;
- at least two intensities that remain within component limits;
- comfort after repeated trials; and
- whether spatial zone plus timing is easier to identify than timing alone.

If patterns are confused, make timing signatures more different before adding
more locations or complex frequency cues.

## Proposed BLE command contract

Use the existing RX characteristic for commands and keep the current TX sensor
packet format intact. Add a message router rather than interpreting every
notification as sensor telemetry. A compact, human-readable first protocol is:

```text
type=haptic_cmd,v=1,id=42,zone=wrist,effect=orientation_correction,intensity=70
type=haptic_ack,v=1,id=42,status=started,t_rx_ms=123456,t_drive_ms=123458
type=haptic_ack,v=1,id=42,status=complete,t_done_ms=123710
```

A per-finger extension should add an explicit target such as `finger=index`
and retain `id`, `v`, effect, and bounded intensity. Directional prototypes
should use named effects such as `finger_open` and `finger_close`, rather than
overloading a signed intensity whose interpretation could be ambiguous.

Required behavior:

- `id` is unique enough to match acknowledgements and suppress duplicates;
- `v` is the protocol version;
- unsupported versions, zones, effects, or intensities return an error;
- firmware clamps intensity and total activation time to limits derived from
  the selected hardware;
- a new correction may preempt a lower-priority success cue;
- disconnect, watchdog timeout, or driver fault turns the actuator off;
- firmware exposes `haptic_active` and the current command ID in telemetry so
  sensor samples can be marked; and
- Flutter records phone send/ack timestamps and presents failure without
  blocking the sensor subscription.

This protocol is only a proposal. Neither the ESP32 nor Flutter app currently
implements these messages.

## Latency validation

Bluetooth LE communication occurs at scheduled connection events, so the
connection interval and peripheral latency affect when a command can be
delivered [25]. Driver start-up time is only one part of the path. The Issue #6
sub-50 ms objective must be measured end to end:

```text
ML/app decision
  -> Flutter write request
  -> BLE connection event
  -> ESP32 RX callback and command validation
  -> I2C/driver trigger
  -> actuator mechanical onset at the skin
```

For each command, log a phone monotonic send time, firmware receive time,
driver-trigger time, and acknowledgement time. For physical onset, toggle a
test GPIO at the driver command and measure it alongside an accelerometer
attached to the actuator using an oscilloscope or logic/DAQ setup. Report the
median, 95th percentile, worst observed latency, sample count, phone model, OS,
BLE connection parameters, firmware revision, pattern, actuator, mounting, and
battery state. An acknowledgement alone does not prove that vibration reached
the user.

## Power, thermal, and mechanical validation

For every actuator/pattern/intensity combination, record:

- supply voltage;
- idle, peak, and average current;
- complete pulse duration and repetition duty cycle;
- estimated charge/energy per cue;
- battery capacity and regulator efficiency assumptions;
- surface temperature during a repeated worst-case sequence;
- audible noise;
- actuator and carrier dimensions/mass; and
- any restriction, pressure point, slipping, or wire fatigue.

Battery-life estimates should use the measured distribution of cues in a
realistic teaching session, not continuous current alone. Generic data from
TI and actuator vendors is useful for screening, but mounting and drive setup
materially affect response and consumption [18][19].

## Flexible-actuator findings and limits

Recent research demonstrates very thin alternatives. One 2026 paper reports a
260 micrometer, 65 mg shape-morphing flexible actuator [26]. Another reports a
20 V flexible electroosmotic actuator and a fingertip research patch with 3 mm
spacing [27]. These results demonstrate possibilities, not drop-in parts. The
3 mm fingertip result is specific to that electroosmotic device and task; it
must not be used as the spacing rule for coin LRAs on the hand or wrist.

Commercial piezo suppliers also describe thin, individually addressable smart
tactor arrays, but those statements are vendor material and availability,
driver voltage, cost, durability, and exact specifications must be confirmed
with a current datasheet and sample [28][29]. Piezo remains a useful second
prototype only if an LRA carrier cannot satisfy thickness, weight, or pattern
requirements.

## Experiment sequence and acceptance gates

### Phase 1: bench screening

- Obtain at least one LRA, one ERM control, a DRV2605L evaluation/breakout
  setup, and current-measurement access.
- Verify safe rated-voltage and overdrive configuration from each actuator
  datasheet.
- Measure mechanical onset/stop, current, noise, and repeatability on a
  consistent test mass.
- Reject any configuration that overheats, cannot be hard-stopped, or
  intermittently resets/corrupts the ESP32 sensor stream.

### Phase 2: wearable engineering test

- Compare dorsal-hand and dorsal-wrist mounting at rest and during signing.
- Quantify IMU contamination and BLE packet loss/order while haptics run.
- Verify that the carrier does not cross flex-sensor paths or restrict range of
  motion.
- Select no more than two hand/wrist zones for the first integrated prototype,
  then perform a separate single-finger fit/perception gate before constructing
  any five-finger array.

### Phase 3: pattern pilot

- Randomize blinded cue presentations.
- Record requested pattern, delivered pattern, participant response, motion
  condition, placement, intensity, misses, and response time.
- Produce recognition accuracy and a pattern confusion matrix.
- Revise confusing patterns before evaluating learning outcomes.

### Phase 4: learning comparison

- Define a visual-only control and a visual-plus-haptic condition.
- Predefine learning and retention measures, sample size rationale, exclusions,
  and analysis before collecting results.
- Follow instructor and institutional requirements for consent and
  human-subject research before recruiting participants.

### Phase 5: integration specification

- Freeze actuator, driver, schematic, zone layout, connector, protocol, safety
  bounds, power budget, measured latency distribution, and fault behavior.
- Document the exact firmware/app versions and the data used to support every
  performance claim.

## Research conclusions

1. **Evaluate LRA first.** A discrete LRA on a flexible carrier with a
   closed-loop driver is the best-supported MVP direction, but it is not yet a
   validated selection.
2. **Keep ERM as a comparison/fallback.** Its lower cost and simpler drive are
   useful for benchmarking, despite less precise dynamics.
3. **Treat piezo as a second-stage option.** It is attractive for thinness and
   waveform fidelity, but higher-voltage drive and integration complexity must
   be resolved first.
4. **Stage spatial complexity.** Validate one or two clearly separated
   hand/wrist zones first. If per-finger correction is required, evaluate the
   one-LRA-per-finger intensity concept before a two-LRA directional array.
   Existing studies do not establish that closely spaced finger tactors will
   be distinguishable during signing.
5. **Measure during motion.** Static perception results do not establish that a
   cue will be recognized while signing.
6. **Protect the ML signal.** Haptic-active telemetry markers and an explicit
   gating/contamination strategy are requirements, not optional refinements.
7. **Do not claim sub-50 ms yet.** Measure the complete path through Flutter,
   BLE, firmware, driver, actuator, mounting, and mechanical onset.

## Issue #6 progress checklist

- [x] Initial actuator-technology comparison documented.
- [x] Placement and motion-perception literature summarized.
- [x] Draft correction-pattern library proposed.
- [x] BLE command/acknowledgement contract proposed.
- [x] Power, latency, ergonomic, and IMU-interference test plan documented.
- [x] One-actuator intensity and two-actuator directional finger concepts
  documented with prototype gates.
- [ ] Candidate part numbers and current supplier availability verified.
- [ ] Actuators and driver hardware acquired.
- [ ] Bench comparison completed with raw measurements.
- [ ] Wearable placement and sensor-interference tests completed.
- [ ] Driver board and safety/fault behavior implemented.
- [ ] Flutter and ESP32 haptic protocol implemented and measured.
- [ ] Pattern-recognition pilot completed.
- [ ] Haptic-versus-visual learning study completed.
- [ ] Final hardware/software integration specification published.

## Source-quality and claim audit

- Official TI datasheets/application notes support the electrical-driver and
  general actuator comparisons [18]-[21], but their example parts and fixtures
  do not establish Helping Hand performance.
- The placement and perception statements come from peer-reviewed studies
  [22]-[24]. They are hypotheses for this glove, not transferable accuracy
  claims.
- The flexible-actuator papers [26][27] describe laboratory devices and are not
  evidence of commercial availability.
- Piezo.com and TITAN Haptics pages [28]-[30] are manufacturer/vendor
  background. They are useful for terminology and candidate discovery but are
  not independent product comparisons.
- The tactile-display patent [31] documents an implementation and terminology;
  it is not peer-reviewed evidence of perception accuracy. The related CHI
  paper and surface-haptics review [32][34] support the general illusion, not
  transfer to closely spaced finger-mounted LRAs.
- The 2025 directional-cue study [33] tested vibrotactile and electrotactile
  funneling on the trunk and shank. It supports feasibility and parameter
  testing, but it is not direct evidence for fingers or active signing.
- The supplied patent link, US 12,343,761, was not used as proof of general
  latency or energy performance. The more direct TI test data is retained with
  its device-specific limitations [18].
- The originally supplied ScienceDirect identifier
  `S092442472401032X` did not match the cited 260 micrometer/65 mg claim. The
  matching published article uses DOI `10.1016/j.sna.2025.117233` [26].

Full source records are maintained in `research/LINKS.md`.
