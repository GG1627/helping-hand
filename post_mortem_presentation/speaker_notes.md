# Helping Hand post-mortem speaker notes

November 19, 2026. **6:45 planned within seven minutes**, then two minutes for questions. That leaves 15 seconds for handoffs or interruptions. The written P3 prompt also anticipates questions throughout.

| Time | Slides | Suggested roles |
| --- | --- | --- |
| 0:00–1:00 | 1–3 · introduction, problem, system | Introduction and system speaker |
| 1:00–2:15 | 4–6 · models, hardware, app | Technical and app speakers |
| 2:15–4:15 | 7 · live practice | Narrator, wearer, and phone operator |
| 4:15–6:45 | 8–10 · successes, challenges, close | Reflection and closing speakers |
| 6:45–7:00 | Handoff or question buffer | Closing speaker |

Confirm names and who advances the slides during rehearsal. Use these notes on a separate device during projection. The HTML notes contain the same slide narration.

## 1. Helping Hand

**0:00–0:15 · 15 seconds.** Introduce the team and point to the glove and phone.

“Helping Hand is a glove and Android app for practicing American Sign Language with haptic feedback. We’ll show you what we built, how someone uses it, and what we learned.”

## 2. The problem

**0:15–0:35 · 20 seconds.** Point to the learner comparing their hand to the reference.

“Beginners can learn what a sign looks like from a video or a printed reference. When they practice alone, they still have to judge their own handshape and movement. We built Helping Hand to give feedback on the attempt they actually make.”

## 3. System architecture

**0:35–1:00 · 25 seconds.** Point from left to right, then follow the return arrow.

“The flex strips measure finger bend, and the motion sensor measures how the hand moves. The ESP32 recognizes signs you hold steady. Bluetooth sends its predictions and sensor readings to the Android app. The app recognizes moving signs, shows the result, and saves progress. During the demo, it also sends haptic commands back to the glove.”

## 4. How we recognize signs

**1:00–1:25 · 25 seconds.** Point to the five bars, then follow the trace on the right.

“For G, we can look at one set of finger-bend readings. The glove’s multilayer perceptron classifies that handshape. For Z, the order of the motion matters. A temporal convolutional network looks for patterns across successive readings. The phone runs one for J and Z and another for Hello, Please, and Yes.”

## 5. Glove hardware

**1:25–1:50 · 25 seconds.** Point to the actual glove, then the prototype PCB.

“This is the glove we’re using today. At the cuff, the ESP32 and wiring sit on perfboard. The flex strips and the calibrated ICM-20948 are the inputs. Five buzzers sit by the fingers, and five form a plus on the back of the hand. The photo beside it shows our earlier PCB. Today we’re using USB power.”

## 6. App features and live results

**1:50–2:15 · 25 seconds.** Point to the sign reference, saved Words rows, and live test counts.

“The app offers letter, number, and word lessons, with on-screen feedback and saved progress. Eight word lessons are listed, and the model recognizes three. In one live check, six signs passed three of three attempts each. K and X passed one of three each. Now we’ll show what that practice looks like.”

## 7. Live ASL practice demo

**2:15–4:15 · 120 seconds.** Use the projected phone. Start signed in, connected, and in Developer Mode. The run sheet gives the individual time limits and recovery actions.

**G.** “I’ll hold G steady. Watch for the match and hold indicator. This prediction comes from the glove.”

**Z.** “I’ll start an attempt, trace Z, and finish it. The phone recognizes the sequence.” Describe the actual outcome. Try one quick recovery if useful, then move on. I is the rehearsed spare held pose.

**3.** “I’m curling the middle finger on purpose. Watch which finger lights up, then the dots move from bottom to center to top. That means straighten. I’ll correct the finger and show what the app does.”

**Hello and Please.** “For Hello I tap Start and Finish. After a match, the glove can replay a preset cue from left to center to right. Please uses a loop around the back of the hand.” Show Please if time permits and describe any output as observed.

**Progress.** “A green row and checkmark mean that lesson was saved.” Call out a change only if a new row turns green during the demo. Finish on Words and return to slide 8.

## 8. Project successes

**4:15–5:25 · 70 seconds.** Give each story about 20–23 seconds.

**Saved practice progress.** “A prediction by itself gave the learner no record of their practice. We tied a match to the lesson they picked, so completion was visible and saved to the right place. During rehearsal we closed and reopened the app and could still see the completed signs.”

**Recognition for moving signs.** “We recorded whole attempts so the model could use the order of the motion. After rebuilding the glove, we collected more recordings and extended the input window. The updated word model accepted five of five matching recordings in offline replay. Hello, Please, and Yes also completed in the live check.”

**Haptic correction for 3.** “We could trigger individual buzzers, but the cue needed to respond to the learner. We used measured bend ranges for the middle and pinky. The app chooses a pulse pattern and highlights the outputs the glove confirms. That automatic cue worked during an on-glove rehearsal.”

## 9. Challenges and lessons

**5:25–6:30 · 65 seconds.** Explain the failure, its impact, and one next step per example.

**Unreliable connections.** “The custom PCB broke and the conductive-thread assembly lost sensor readings as the glove moved. We suspected shorts and switched to discrete wires. Next time we’d check continuity while flexing the assembly and add strain relief before mounting it.”

**Damaged flex sensors.** “The thumb and index readings barely changed when the fingers bent, which made some attempts look wrong. The raw channels exposed the damaged sensors. We’d check each channel early, then recalibrate and repeat a few known signs after every hardware change.”

**Word recognition after the rebuild.** “The earlier model missed all nine matching recordings from the rebuilt glove in offline replay. We retrained, but our tests still covered few wearers and targets. Next time we’d reserve fresh attempts from more wearers and test signs the models could confuse.”

## 10. Main lesson and next steps

**6:30–6:45 · 15 seconds.** Leave this slide up for the question period.

“Our main lesson was to test the glove and app together, through recognition, feedback, and saved progress. Next we’d test with more wearers to see which signs work consistently and whether users can interpret the cues.”

## Backup 1. Original goals and final features

**Question period.** The slide distinguishes the original scope from the build being shown. The original design proposed a mounted PCB, battery operation, broader word recognition, and general corrective feedback. The working app includes J/Z and the scoped haptic demos. The written reports describe the earlier release snapshot. Displayed lesson counts and recognition model labels describe different parts of the app.

The demo uses the wired perfboard glove, USB power, a signed-in Android phone, Flutter app version 1.0.1+2 from the `gael` working copy, and the `piezo_demo` ESP32 environment. The review base was `c72ad4f` with local app changes. Record the actual running revision, phone/OS, and firmware during rehearsal. Current-device cloud readback, battery runtime, and broad wearer validation are open. The single glove has limited ability to distinguish finger spread or infer hand location relative to the body.

The app also has developer tools for BLE diagnostics, recording and exporting labeled attempts, and manually testing the piezo outputs. These tools support setup and development. The learner demonstration uses Alphabet, Numbers, and Words.

## Backup 2. Recognition and haptic test results

**Question period.** Live counts came from one wearer and selected targets on the glove and app. Offline J/Z replay accepted two J and two Z attempts and rejected 36 unrelated recordings. Some were examined earlier in development. The word replay used five matching recordings and 25 wrong-target checks drawn from reused recordings. The design draft’s approximately 90% accuracy figure was a goal. The available trial counts describe the specific conditions shown.

The Number 3 automatic cue has a live operator report. Hello and Please pulse order and cancellation were checked in Flutter with simulated responses. The operator described faint vibration in the separate manual output check. Phone latency and wearer interpretation of cues have yet to be measured. Firebase rules were updated for word completion IDs. The post-fix cloud readback has not been run.
