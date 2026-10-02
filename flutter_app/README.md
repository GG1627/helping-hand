# Helping Hand Flutter app

The app provides Firebase account authentication, Home, Alphabet, Numbers,
Words, learner practice, and developer tools for glove diagnostics/recording.

## Learning navigation

- Open Alphabet, Numbers, or Words from Home or the bottom navigation.
- Choose a letter, number, or word to open its separate live-practice page.
- Use Back to return to the picker. Practice is not embedded in the grids.
- Letter/number practice uses the existing BLE static-prediction tracker and
  UID-scoped local-first progress repository. Words share the practice UI but
  do not yet have dynamic recognition or saved completion.
- Developer Mode in account settings exposes Record Signs and BLE Testing.

`MainShell` owns BLE and recognition state. `LearningScreen` hosts the passed
practice widget; a shell-owned notifier and BLE notifications refresh that
widget independently of the picker route. The shared Helping Hand theme and
learning components provide consistent responsive layouts.

## Local development

From this directory:

```powershell
flutter pub get
flutter run
```

Use the existing Firebase project/configuration and connected Android setup.
For validation, run Flutter analysis and the relevant tests/build for the
change being reviewed. Real glove, Firebase, and Android results must be
recorded separately from widget or web checks.

## Beta documentation

- [Build status and known limitations](../docs/BETA_BUILD_STATUS.md)
- [App experience plan](../docs/BETA_APP_EXPERIENCE_PLAN.md)
- [Test procedures and evidence](../docs/BETA_TEST_PLAN_WORKING_NOTES.md)
- [Design guide](../docs/APP_DESIGN_GUIDE.md)

No dynamic word recognition, target-specific instructional media, or fresh
physical-device regression is claimed by the current navigation change.
