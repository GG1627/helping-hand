# Haptic engineering handoff

Prepared November 16, 2026 with Codex assistance. This session adds isolated
offline design tooling and tests. It does not establish electrical suitability,
useful tactile output, recognition accuracy, or learning outcomes. No production
report, presentation, firmware, Flutter implementation, model, inference
preprocessing, or completion threshold was changed. Do not commit or push this
session's work until the user explicitly requests it.

## November 18 demonstration controls

Flutter **Developer → Piezo Outputs** has a white 2D hand with five finger
markers and a five-position plus on the back of the hand. Its live highlight
uses the ESP32's reported output state. The painter order is intentionally
mapped from the firmware slot names. The last confirmed output remains
visible as text after the active highlight clears.

The `piezo_demo` PlatformIO environment keeps the normal glove runtime and
opts into the manual BLE preset shared with the serial `piezo_test` default.
Use this environment only on the reviewed demo setup with the corresponding
bench settings checked. The normal build keeps BLE output disabled.

```powershell
pio run --project-dir ESP32 -e piezo_demo -t upload
cd flutter_app
flutter run
```

In the app, connect in **BLE Testing**, open **Piezo Outputs**, enable
outputs, select a location, and tap **Pulse output**. Verify the highlighted
point matches the output on the glove. Check **Stop outputs** and disconnect.
The firmware permits one short pulse at a time. The phone disables outputs
when leaving the page or backgrounding. Reconnection requires enabling again.

The manual path uses a short `HP1` message family on the existing RX/TX
characteristics. The Flutter receiver routes these responses outside the
sensor packet stream. The BLE callback queues at most one command. The main
Arduino loop drives the output and reports start/end. The configured limits
are the preset settings, not measurement results on a connected phone.

Word practice in Developer Mode shows a **Haptic demo preview**. The center
dot briefly highlights after a matching word, with no BLE output request.
The preview and the live test page demonstrate separate behavior.

All 68 Flutter tests, the Android debug build, and the standard,
`piezo_demo`, and `piezo_test` firmware builds passed. The Flutter tests
used simulated output responses.
Physical BLE output, precise marker placement, and wearer perception on
the new demo path still require a glove rehearsal.

## Scope and current state

Read [the glove/model handoff](GLOVE_MODEL_SESSION_HANDOFF.md),
[developer calibration](DEVELOPER_CALIBRATION.md), and
[the IMU reference](../research/ICM20948_INTEGRATION_REFERENCE.md) before changing
sensor processing or models. Their November 6 selected-sign demo scope is
historical: the user's intended final scope is A-Z, 0-9, and all eight app words.
That intention does not establish implementation or validation of that scope.

The actual word list is `hello, thank_you, please, sorry, yes, no, eat, drink`.
The deployed TCN supports only `hello, please, yes`. The default static model has
34 classes excluding J/Z; retain it, the original 36-class baseline, and the word
bundle unchanged. Classification confidence does not identify a correction.

| Area | Inspected implementation | Limit |
| --- | --- | --- |
| Piezo output | `ESP32/src/piezo.cpp`: one LEDC channel routed to one of ten outputs; bounded tone; main-loop update | No coordinated patterns, application triggers, or verified drive settings |
| BLE RX | `ESP32/src/ble_transport.cpp`: logs writes | No haptic parser, acknowledgement, mailbox, or disconnect cancellation |
| Flutter BLE | Shared connection and packet stream; requests MTU 512 | No haptic writes; every notification currently goes through the sensor parser |
| Sensor transport | Target 40 Hz, CSV-style `seq`, `t_ms`, five raw/normalized flex channels, motion axes, predictions, optional magnetic data | Delivered rate and integrity need physical checks; normalized flex is raw/4095, not developer-profile calibration |
| Static practice | App-shell stable prediction tracker and progress repository | Static target may remain active after leaving its practice page |
| Word practice | Explicit Start/Finish; cancellation for disconnects, stale streams, backgrounding, disposal | No haptic guidance; preserve current acceptance and persistence behavior |
| Orientation | Raw acceleration/gyro/magnetic vectors; a smoothed accelerometer roll display | No calibrated quaternion fusion, verified hand-frame transform, or absolute position |

## Electrical and mounting blockers

The saved `pcb/pcb.kicad_pcb` is an empty 51-byte placeholder; the three saved
backup layouts are also empty. The schematic contains ten 1 kOhm branches whose
actuator-side labels are all **PIEZO PIN**. In-memory inspection of labels,
wires, and resistor endpoints confirmed they share one net. Matching local net
labels connect on the same sheet, as described in
[KiCad's documentation](https://docs.kicad.org/9.0/en/eeschema/eeschema.html).
Independent actuators need independent signal nets. The saved schematic does not
provide complete actuator returns, driver/protection circuits, or a routed PCB.
This finding does not prove how the actual perfboard is wired. Inspect it.

| Slot | Firmware name | Signal / GPIO | Physical meaning |
| --- | --- | --- | --- |
| 0 | Thumb | A5 / 8 | Intended thumb; actual placement unverified |
| 1 | Index | D5 / 5 | Intended index; actual placement unverified |
| 2 | Middle | D6 / 6 | Intended middle; actual placement unverified |
| 3 | Ring | D9 / 9 | Intended ring; actual placement unverified |
| 4 | Pinky | D10 / 10 | Intended pinky; actual placement unverified |
| 5 | HandLeft | SCK / 36 | X position unassigned |
| 6 | HandRight | MISO / 37 | X position unassigned |
| 7 | HandCenter | D12 / 12 | X position unassigned |
| 8 | HandUp | D11 / 11 | X position unassigned |
| 9 | HandDown | MOSI / 35 | X position unassigned |

GPIO aliases were checked against the locally installed
`framework-arduinoespressif32/variants/adafruit_feather_esp32s3/pins_arduino.h`.
This verifies software aliases, not actual wiring. Record handedness and the
center/four corners relative to fingers, wrist, thumb side, and pinky side;
do not assign a diagonal corner from a name such as HandLeft. The
[blank inventory](../tools/haptics/hardware_inventory.template.json) records
these unknowns without choosing actuator settings.

The team confirmed the received parts match TIMESETL pickup discs, ASIN
[B077YJ3H6R](https://www.amazon.com/dp/B077YJ3H6R), previously described by the
seller as 27 mm discs. The Amazon page returned an access error in this session;
the purchase match is repository/team provenance. No identifiable manufacturer
datasheet establishing these parts' ratings was found. Drive voltage, useful
frequency, capacitance, current demand, mounting, and tactile localization remain
unverified. Receipt and audible output do not demonstrate useful haptics.

[Murata's drive guidance](https://www.murata.com/en-global/support/faqs/sound/diaphragm/char/sch0001)
describes direct and buffered drive arrangements for suitable diaphragms, series
resistance, protection, discharge considerations, and avoiding prolonged DC.
[Its voltage guidance](https://www.murata.com/en-global/support/faqs/sound/diaphragm/char/dch0001)
states that suitability depends on the part, fixing, and waveform. These are
general manufacturer references, not ratings for the TIMESETL discs. Do not
transfer generic 50-105 V piezo statements from older research to these parts.
Do not automatically energize them or select a boost driver from that assumption.

PWM availability is separate from electrical suitability. The ESP32-S3 provides
[eight LEDC channels](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/ledc.html).
One channel is enough for sequential single-output patterns. Overlap requires
new output/channel management and measurement; ten independent waveforms cannot
be assumed. The installed Arduino framework uses the existing 2.x LEDC API;
check version compatibility before adopting examples for later APIs.

Measure driver supply and peak/average current. Capacitive loading, frequency,
waveform, and mounting matter; no load or runtime estimate is justified yet.
[Adafruit specifies a 500 mA peak regulator](https://learn.adafruit.com/adafruit-esp32-s3-feather/power-management),
shared with the electronics, rather than a spare continuous haptic allowance.
Compare battery and USB; neither supply establishes actuator suitability.

If a correctly specified, driven, and mounted disc fails the tactile test,
compare a documented LRA and matching driver, or a purpose-designed piezo haptic
actuator. [TI's DRV2605L](https://www.ti.com/product/DRV2605L) supports ERM/LRA
actuators, not these piezo discs. Multiple independent DRV2605L channels require
address isolation/multiplexing; consult the
[TI multi-driver guide](https://www.ti.com/lit/ug/slou400/slou400.pdf).
No replacement purchase or driver design is selected by this handoff.

## Feedback recommendation

For static correction, begin with one finger-identification pulse, a pause, and
three sequential dorsal activations. Test the reverse sequence for the opposite
instruction. Treat bend/straighten meanings as a learned cue language. Frequency,
strength, spacing, duration, and overlap remain measurement questions.

Primary research gives conditional support rather than a universal mapping:

- [Shah et al., 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC6640119/) found
  better sequential than simultaneous intensity discrimination in their arm
  experiments. That task does not validate our finger-plus-dorsal cue.
- [Marquardt et al., 2018, TactaGuide](https://vvise.iat.sfu.ca/user/data/papers/tactaguide.pdf)
  found task-dependent effects and diverse interpretations of some hand cues.
  Its results do not support assuming a dorsal cue has one intuitive meaning.
- [Tajdari et al., published online 2024](https://journals.sagepub.com/doi/10.1177/00187208241275734)
  report reduced vibrotactile perception during hand motion. Stationary testing
  must therefore be followed by testing during actual signing.

For motion, use a separate **feel the demonstration, then attempt** experiment.
The three-second offline fixture is an abstract timing example, not a validated
ASL motion demonstration. Keep real playback and its measured settling interval
outside recognition/collection windows initially. Playback does not detect errors.

Live guidance remains separate research. Verify sensor-to-hand axes and
calibrated orientation, then compare complete recorded templates with constrained
timing alignment offline. Evaluate ambiguity, different signing speeds, causal
latency, and negative motions before attempting live alignment. Offline alignment
can use future samples unavailable to a live system. Keep hand-relative movement,
orientation, and body-relative position distinct. A wrist IMU does not establish
head/chest/stomach location; see [x-io's position FAQ](https://x-io.co.uk/contact/).

## What the offline prototype implements

See [usage instructions](../tools/haptics/README.md). The Python standard-library
prototype is outside the ESP32 and Flutter build paths. It generates bounded
trace events, has no Bluetooth/GPIO/serial adapter, and never awards progress.
It is an executable design reference for later ESP32/Dart implementations;
passing these tests does not test either deployed runtime.

`control.py` implements one active sequential pattern, silent gaps, no queued
playback, duplicate/out-of-order rejection, connection/context invalidation,
STOP priority, disabled-by-default traces, absolute expiration, and a separate
short start-freshness check. Trace history is a 256-event ring. A late tick
cancels instead of rapidly replaying overdue steps. Tick times use unsigned
32-bit modular arithmetic, including rollover; detected clock regression
cancels and disables. All methods assume serialized calls by one owner.

The provisional limits are 32 patterns, 16 steps per pattern, 1-1000 ms per step,
and at most 5000 ms per pattern/lifetime. Default maximum start delay is 100 ms
and tolerated scheduling lateness is 50 ms. These are bounded software experiment
values, not validated perception, drive, responsiveness, or safety settings.
There is no drive frequency or amplitude default.

### Draft command layout

This codec is local tooling only. The firmware does not recognize it today.
All multi-byte fields are unsigned little-endian; exact payload length is 20.

| Offset | Field | Size | Rule |
| --- | --- | --- | --- |
| 0 | Magic | 2 | ASCII HH |
| 2 | Version | 1 | 1 |
| 3 | Opcode | 1 | 0 STOP; 1 PLAY |
| 4 | Session/context token | 4 | Current nonzero token |
| 8 | Request ID | 4 | Nonzero; PLAY IDs strictly increase within a context |
| 12 | Pattern ID | 2 | Registered nonzero ID for PLAY; zero for STOP |
| 14 | Lifetime | 2 | 1-5000 ms for PLAY; zero for STOP |
| 16 | Absolute deadline | 4 | Device-clock deadline for entire cue; zero for STOP |

For PLAY, issuance/source time is `deadline - lifetime`, modulo 2^32. Reject a
future issuance, expired deadline, start older than the configured start bound,
or a pattern that cannot finish within the remaining lifetime. Use the lower
32 bits of device `t_ms` in a future adapter, not the phone's wall clock. Form
correction commands from the latest valid source frame; app-side freshness is
also required. A long demonstration lifetime does not permit starting an old
correction. Never wrap/reuse request IDs within a context.

STOP ignores enable, busy, and PLAY ordering rules, but requires the current
session. It cancels before advancing a due step and rotates the context token.
Disconnect, practice exit, target changes, background/resume, and disable also
rotate the token. Resume/reconnect never automatically enable playback. The
prototype seeds its counter randomly; a firmware implementation must establish
fresh boot/connection/context tokens and synchronize them with the app. Tokens
are replay-control identifiers, not authentication or a security boundary.

Local acknowledgements distinguish malformed requests, wrong context, disabled,
busy, unknown pattern, stale/expired requests, insufficient lifetime, and dry-run
start/stop. Completion/cancellation appear in trace events. No on-wire response
codec, capability handshake, pairing policy, BLE callback mailbox, or notification
demultiplexer has been implemented. Do not send draft frames to the glove and
interpret existing GATT write success as a haptic acknowledgement.

### Static correction evaluator

`correction.py` requires explicit glove/mount/calibration/target IDs, capture
references, five per-channel straight/bent endpoints and measured health bands,
one to eight complete pose variants, and explicit noise/timing policy. It has no
real sign defaults. Synthetic references require an explicit offline opt-in.
The `reviewed_measurements` provenance label is an operator declaration, not
automatic verification of the referenced captures.

Signed bend is `(raw - straight) / (bent - straight)`, supporting both raw
polarities. Check health before using it; do not clamp away faults. Accept any
complete variant within release tolerance, but do not combine independent fingers
from incompatible variants. Otherwise select a complete variant by scaled error,
retain it while correcting, prioritize one finger, and keep that finger until
release or direction reversal. Entry/release margins, persistence, and global
cooldown prevent rapid alternation. A reversed direction must persist anew.

Missing, saturated, out-of-health-band or explicitly unusable channels suppress
all cues. Duplicate/reordered samples, sequence/time gaps, stale/future samples,
and identity mismatch clear pending persistence. Device restart requires an
explicit evaluator reset. Host clock regression latches a fault until reset.
Use monotonic receive/decision times in a future adapter; received-at freshness
alone does not prove acquisition freshness when packets were buffered.

Outputs identify a finger, bend/straighten, selected variant, and whether an
experimental correction is due. A coordinator must cancel a playing correction
when its evidence becomes invalid, changes direction, or no longer requests that
correction. That coordinator is not implemented. There is no mapping from these
semantic directions to unverified X positions, and no automatic pose learning,
signal smoothing, or diagnosis of every possible damaged/stuck sensor.

## Integration work still required

1. Keep real output disabled until the circuit, actuator ratings, physical map,
   and mounting have been reviewed. Use validated profiles rather than arbitrary
   app-selected voltages/frequencies. Retain a dry-run mode on both platforms.
2. Implement/version the agreed codec, capability/context handshake, responses,
   and strict bounded callback mailbox. Give STOP/disconnect a separate priority
   path that invalidates pending PLAYs. Keep output calls in their owning task.
3. The current IMU recovery path has blocking initialization delays. Stop cues
   before recovery and measure owner-loop stalls. If deadlines require it, move
   all output ownership to a suitable dedicated task and provide an independently
   bounded cutoff. The offline scheduler cannot guarantee hardware shutdown if
   its owner task stops running.
4. Add the phone command service with at most one outstanding request, no replay
   on reconnect, state-response handling separate from sensor packets, and
   prompt cancellation on page exit/coverage, background, disable, or target
   change. Bound response traffic without reducing sensor telemetry delivery.
5. Resolve explicit practice ownership. The existing static lifecycle bug is
   recorded above; never inherit it for haptics. Reset the evaluator on context
   changes and cancel when evidence becomes stale. Preserve model thresholds
   and progress rules; a reference-band match must not award lesson completion.
6. Add haptic-active/settling markers and an explicit contamination policy for
   recordings and model windows. The current near-capacity telemetry packet
   needs a size/MTU review before adding fields. Do not silently discard samples,
   alter inference preprocessing, or claim sensor interference is solved.
7. Port and test these rules against actual ESP32 and Flutter code; verify
   builds, callback/task races, notification routing, phone lifecycle, and saved
   progress. Host prototype tests are not substitutes for those checks.

## Measurements and assembly handoff

Ask the assembler to retain photographs, markings, connection IDs, mounting
positions, and the actual perfboard/circuit diagram before sealing the glove.
Confirm each piezo's two terminals, electrical return/protection path, actual
GPIO, and independence from other outputs. Inspect the shared-net issue first.
Record battery model/capacity and whether any required supply exists on battery.
Do not assume the USB rail is available when running from the battery.

After the assembled glove returns:

1. Verify wiring and actuator/driver specifications while unpowered. Resolve
   missing ratings rather than choosing a generic high-voltage piezo setting.
2. Characterize one element with appropriate protected bench circuitry before
   connecting ten elements or wearing them. Record capacitance if measurable,
   terminal waveform/voltage, frequency, current, mounting, sound, and sensation.
3. Expand only after the first element passes a predeclared tactile criterion.
   Test each slot separately; record actual X coordinates and handedness.
4. Run the developer calibration workflow and export profile plus captures.
   It measures equipment and does not automatically calibrate inference.
5. Capture reviewed correct target poses across repetitions/re-donning and
   acceptable variants, including confusable/incorrect examples. Derive health
   bands, sign bands, polarity, noise margins, persistence, and cooldown from
   those measurements. Keep separate captures for validation. Do not use
   synthetic training data or endpoint interpolation as correct-sign evidence.
6. Validate the cue vocabulary before enabling automatic static guidance. Start
   with a small measured vocabulary while retaining the full intended scope.

Before each physical test, specify the pass criterion, repetitions, equipment
revision, supply, raw recording/log locations, and how failures are retained.
Use these fields for a result row:
`test_id, slot/pattern, glove/mount/driver revision, supply, parameters,
criterion, repetitions, observed result, evidence path, status`.

| Physical procedure | Evidence to retain | Status |
| --- | --- | --- |
| Circuit/identity/map review | Unpowered continuity results, datasheet, photographs, corrected schematic revision | Not run |
| Each actuator alone | Terminal waveform, current, location response, thermal observations | Not run |
| Direction discrimination | Randomized forward/reverse trials and confusion matrix; control audible clues | Not run |
| Finger plus bend/straighten | Five fingers x two instructions, catch trials, response errors and latency | Not run |
| Perception while signing | Cue recognition during actual signs, restriction/comfort observations | Not run |
| Sensor interference | Paired haptics-off/on raw flex, IMU/magnetic data and settling measurements | Not run |
| BLE/sampling under cues | Delivered rate, sequence gaps, packet integrity, command/physical onset latency | Not run |
| STOP/lifecycle on glove | Disconnect/background/exit/target-change traces and measured cessation | Not run |
| Battery versus USB | Boot, advertising, current peaks, rail sag, temperature, repeat operation/runtime | Not run |
| On-glove cue pilot | Comfort, acoustic output, distinguishability, failures, mounting durability | Not run |

## Software verification record

November 16, 2026, Python 3.13.5:

```powershell
python -m unittest discover -s tools/haptics/tests -v
python -m tools.haptics.dry_run
```

- **44 offline tests passed.** Coverage includes malformed lengths/headers,
  invalid bounds, pattern validation, timing/gaps, priority stop, duplicate and
  expired/stale commands, context cancellation, rollover/regression, 10,000 busy
  requests without queued playback, and 2,000 deterministic random malformed
  payloads. Correction checks cover both polarities, deadband/hysteresis,
  persistence/cooldown, one-finger priority, complete variants, unhealthy/stale
  channels, stream discontinuity, and context reset.
- The CLI completed its three-second abstract trace and rejected an old-context
  command. Its invented static example produced a bend request, cleared when
  the invented pose entered range, and rejected stale input.
- **36 existing Flutter tests passed** across packet parsing, stable static
  predictions, word-practice controller/widget behavior, and progress repository
  persistence. This checks existing behavior; no production haptic integration
  was introduced or exercised.
- ESP32/Flutter haptic integration builds/tests: **Not run; integration absent**.
- Bench and on-glove procedures: **Not run**. No physical actuation occurred.

The Flutter command, run from `flutter_app`, was:

```powershell
flutter.bat test --no-pub test/ble_packet_test.dart test/stable_prediction_tracker_test.dart test/word_practice_controller_test.dart test/word_practice_card_test.dart test/progress_repository_test.dart
```

The first sandboxed Flutter attempt stalled at the SDK cache lock outside the
workspace and was stopped; it was not a test failure. The retry with approved
SDK-cache access passed. No SDK upgrade or dependency change was performed.
