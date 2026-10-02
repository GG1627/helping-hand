# Our Findings from the ASL Glove Demos

We’re using these conversations to figure out how the glove feels during real signing, how helpful the app is for learning, and what we should improve next.

**Date:** [9/18/2026, TBA]
**Who we talked to:** [ND ASL Club Exec, TBA]
**Who tried the glove:** [Remote Walkthrough, TBA]

## What we wanted to learn

- Can the glove pick up the differences between the signs we’re testing?
- Can people sign naturally while wearing it?
- Does the app make it clear what they’re doing well and what to change?
- Does the lesson pacing feel right, and does the progression make sense for learning ASL?


## What we asked
- Hardware & Sensor Compatibility: Do 5 flex sensors combined with IMU roll/acceleration/gyro metrics capture the nuance of real ASL words? Where does the setup fall short regarding palm orientation, movement trajectories, or subtle finger bends?

- Wearability & Ergonomics: Is the glove non-restrictive during natural signing, or does the hardware impede fluid hand movements during long testing sessions?

- Educational Intuitiveness: Is visualizer feedback clear to beginners, and does the learning progression match natural ASL grammar?


## What we tried

[ND ASL Club: Showed our project pitch videos, showed a video demo of our glove and images of our glove and app. Explained the ML model and the hardware of the glove.]

[UF ASL Club: TBA]

## What we heard

### Notre Dame ASL Club — South Bend

**Who we talked to and their ASL experience:** [Hannahlaura Schuchhardt - 2nd year of learning ASL , Francesca Granieri - Deaf Cousin, 3rd year of learning ASL]

**What they noticed about recognition and natural signing:** [Really liked the 6 axis IMU and 5 flex sensors for gathering sign data from the user. Noted that the glove would be comfortable and would not inhibit the user from making any signs, no components at joints that move minus the flex sensors which are bendable. Some signs are repeats of others, such as eating being a repeat of food. We would have to account for that.]

**What they thought about the lessons and pacing:** [Helpful to start from A-Z and 0-9, recommended we start with phrases or colros for beginning of word lessons. Recommended this site to look for lesson ideas: https://www.lifeprint.com/]

**Suggestions we want to follow up on:** [Finding alternate one hand signs for words, such as "name" which is a two handed sign. Haptic Feedback (buzzers). Orientating the glove calibration. Sign orientation matters because orienting signs near the face makes it easier for people to maintain eye contact while signing. Calibration helps to determine signs, orientation matters where signs are.]

### UF ASL Club — Florida

**Who we talked to and their ASL experience:** [Add notes]

**What they noticed about the glove and app:** [Add notes]

**What they thought about learning from it:** [Add notes]

**Suggestions we want to follow up on:** [Add notes]

## Our hardware findings

For each finding, add a specific sign or moment from the demo and who pointed it out. These are areas to check, not confirmed problems yet.

| What we looked at | What we noticed | Example or participant comment | What we could try next |
| --- | --- | --- | --- |
| Finger bends — do the five flex sensors pick up subtle differences? | [Yes] | [Our ML Model] | [N/A] |
| Palm orientation — do the IMU readings capture the direction the palm faces? | [Yes] | [6-Axis] | [Calibration!!!] |
| Movement — can we track trajectories and transitions between signs? | [Yes] | [6 Axis IMU and 5 Flex Sensors] | [N/A] |
| Comfort — did the glove, sensors, or wires restrict movement over time? | [No] | [N/A] | [N/A] |
| Missing information — did a sign depend on something our setup didn’t capture? | [Yes] | [Facial Expressions/2nd Hand to sign with] | [Add another hand 3D model to the app to show what you should do with the other hand that does not have a glove, mention facial expressions to keep in mind in the app] |

## Our app and learning findings

**What worked well:**  
[What could someone understand or complete without help?]

**Where people got stuck:**  
[Which screen, instruction, or feedback message caused confusion?]

**Visualizer feedback:**  
[Could someone tell what to change after a missed sign?]

**Lesson pacing:**  
[Where did we need slower examples, more practice, or less repetition?]

**ASL accuracy and progression:**  
[What did the SME say about authentic execution, grammar, and the order of the lessons?]

## What we’re changing next

Use **High** for changes that block natural signing or teach something incorrectly, **Medium** for recurring usability issues, and **Low** for smaller improvements. Set priorities once we’ve reviewed the feedback.

| Priority | Hardware or app change | Why it matters and where we heard it | Who’s taking it | How we’ll check it worked |
| --- | --- | --- | --- | --- |
| [High / Medium / Low] | [Add change] | [Link to finding] | [Name] | [Add follow-up test] |
| [High / Medium / Low] | [Add change] | [Link to finding] | [Name] | [Add follow-up test] |
| [High / Medium / Low] | [Add change] | [Link to finding] | [Name] | [Add follow-up test] |

## What we still need to figure out

- [Question or finding we need to test again]
- [Feedback that differed between participants]
- [Anything we need an ASL SME to review]
- [Ask deaf people for their feedback, even though our end users are hearing people who want to learn ASL]

## Our next steps

- [ ] Gather UF ASL Club feedback.
- [ ] Add the Indiana and Florida findings to the repo.
- [ ] Agree on the most important hardware and app updates and assign issues.
- [ ] Test the changes and add what we learned.
