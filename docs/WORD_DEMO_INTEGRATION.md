# TCN word practice integration

Implemented October 5, 2026. Flutter now packages the selected real-recording
TCN and supports user-delimited attempts for **Hello, Please, and Yes**.
This is isolated-word practice, not continuous signing or sentence translation.
See [the training record](WORD_MODEL_DEMO_TRAINING.md) for the 15-trial dataset
and its limited evaluation scope.

## What runs where

ESP32 continues streaming raw flex ADC values and accelerometer/gyroscope data
over BLE while retaining its static MLP classification. Flutter performs word
inference locally with `tflite_flutter` 0.12.1. A background isolate owns and
closes its interpreter for each attempt, keeping native pointers out of shared
route state. It needs no inference server or inference internet connection.
Account sign-in and cloud synchronization retain their existing network needs.

The bundled assets are `flutter_app/assets/models/words_tcn/model.tflite` and
`model_metadata.json`. The TFLite file is 48,324 bytes with SHA-256
`7664ceacd04b488fc896b04210490e4c0908d852050ad22ed4dc2b80fe561a8a`.
Metadata and runtime tensor checks enforce TCN, class order `hello, please, yes`,
float32 `[1,96,11]` input, and `[1,3]` output.

Each attempt uses **five raw flex ADC channels** followed by `ax,ay,az,gx,gy,gz`.
Device-clock linear interpolation at 40 Hz, symmetric edge padding or center
trimming to 96 samples, and float32 training-only standardization match Python.
The static thumb/index correction is not applied to word inputs. There is no
quaternion fusion or orientation normalization in this demo model.

## Learner flow and completion

1. Connect the glove through Developer Mode > BLE Testing. Open Words and
   choose Hello, Please, or Yes; these rows say recognition is available.
2. Prepare the hand as in the recorded attempt. Tap **Start attempt**, perform
   the entire sign at the recorded pace, then immediately tap **Finish sign**.
   A teammate can handle the phone while the recorded wearer signs.
3. The app shows the actual highest-probability model word and its confidence.
   It completes the lesson only if that word equals the selected target and
   confidence is at least **80%**. This threshold is an acceptance rule, not
   measured recognition accuracy. Static hold rules are not used for words.
4. **Try again** clears the previous sequence and result. Completion is stored
   in the existing UID-scoped progress repository and can be repeated without
   adding duplicate progress. Words and Home show saved word completion.

Other starter words remain navigable and state that recognition is unavailable.
There is no target-conditioned output, simulated sensor source, or automatic
success based on elapsed time in the production path.

Capture rejects missing/invalid motion or flex fields, nonincreasing device
timestamps/sequence numbers, stale receive times, and receive/device gaps over
250 ms. Disconnect, leaving the route, or backgrounding the app discards an
incomplete attempt; late inference results cannot award completion after
cancellation. An attempt needs at least 20 packets and 750 ms of device data,
and times out after 8 seconds. These bounds protect capture integrity and do
not establish a gesture-quality test.

Word completion uses `word_prediction_<word>` identifiers in the existing
`completed_exercises` field. The progress schema remains version 1; existing
local/Firebase read, write, reset, and account isolation paths are reused.
Live cloud synchronization of the new completion path is **Not run**.

## Running and verification

Because a native inference dependency was added, stop the previous Flutter
process and start a fresh run rather than relying on hot reload:

```powershell
cd flutter_app
flutter run
```

Choose the actual Android phone if multiple devices are listed. This integration
does not require an additional ESP32 firmware change; the glove must already
stream complete raw flex and IMU packets. Use the existing firmware upload
procedure if its previously prepared static-model update has not been flashed.

Repackage the fixed selected bundle and software replay fixtures with:

```powershell
python backend/export_word_demo_bundle.py
```

Software checks include Python-to-Dart input parity on three already evaluated
recordings, interpolation/padding edge cases, completion/cancellation rules,
static and progress regression, and word-page widget checks. Recorded replay
is not new held-out accuracy evidence or live BLE validation.

Native Android replay check, with an Android emulator/device available:

```powershell
cd flutter_app
flutter test integration_test/word_model_test.dart -d <device-id>
```

The test creates complete attempts from recorded packets with the real packaged
TCN; it does not sign into Firebase or connect to a physical glove.

| Verification | Status |
| --- | --- |
| Python/Dart parity, controller/static/progress and word-page checks | **Passed: 42 tests** |
| Word page interaction and 375 px layout; trained/untrained large-text/reduced-motion layouts | Passed |
| Native Android TCN recorded replay | **Passed: 3 checks** on Pixel 8 API 36 emulator |
| Normal Android demo APK build | **Passed**, target `lib/main.dart`; packaged model/scaler and ARM runtime checks passed |
| Fresh live glove/phone recognition and intended-phone latency | **Not run** |
| Live Firebase word sync, restart, other account, cross-device checks | **Not run** |

DM Sans interface weights are bundled with their license so first-open text
does not depend on downloading those fonts. Visual test screenshots use mocked
prediction outcomes and are UI checks only.

The three native emulator replay predictions matched Python within 0.02
percentage points. One attempt-owned worker load/invoke/output-copy timing per
word was 567.035, 192.265, and 91.874 ms respectively; these include model
creation, exclude isolate startup and preprocessing, and are not a repeated
latency benchmark or physical-phone measurement.

Normal debug APK: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`,
227,930,701 bytes, SHA-256
`eaa03fab8ccc44f03675530e084cb3df62c0142538adbb3ba806115536da888c`.
It contains the selected TCN and metadata, and does not package replay fixtures.
Targeted Flutter analysis reported no issues. The emulator used for software
checks was stopped; no physical phone was attached or updated in this session.

## Rehearsal remaining

Use the recorded wearer, current glove placement, and the same sign motion.
Recorded durations were approximately Hello 1.85–2.25 seconds, Please 2.3–3.2
seconds, and Yes 3.3–5.3 seconds. Do not add a long idle interval before or after
the gesture: longer attempts are center-cropped and timing affects the input.
The 96-sample model window describes preprocessing, not a fixed recording timer.

Run fresh attempts for all three words, including retries, a wrong trained word,
IMU interruption, disconnect/reconnect, Back, and restart after saving progress.
Pick the two demo words based on these new results. Record phone/OS, glove and
firmware, observed predictions/confidence, success counts, and failure cases.
Measure latency on that phone; desktop/emulator measurements do not establish
physical-device performance.

The model has only three classes and **no rest/unknown class**. Unrelated motion
or even a stationary attempt may receive a confident word label. Explicit
start/finish limits when recognition is attempted; it does not solve unknown
gesture rejection. Wrist-angle variation and other wearers remain unvalidated.
Repaired sensors may change the input distribution and require new calibration,
recordings, and retraining. Current offline scores must not be presented as
general ASL recognition accuracy.
