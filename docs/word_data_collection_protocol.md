# Word-level sign data collection protocol

Status: collection tooling foundation implemented; physical-phone validation and
the first immutable vocabulary are still pending.

This protocol is for pilot recordings from the Helping Hand glove. It does not
authorize collecting personally identifying information, and it does not turn a
pilot recording into model-performance evidence. Final accuracy claims must use
consented, real recordings and documented trial-level splits.

## Before collecting

1. Obtain the participant's consent under the team's approved process. Use a
   pseudonymous ID such as `signer_01`; do not enter a name or email address.
2. Flash firmware built with a collection rate from 25–50 Hz. The default is
   40 Hz (`HH_SENSOR_RATE_HZ=40`). This is only a configured target until the
   observed phone-side rate, loss, and ordering have been measured.
3. Connect in **Record Signs** and wait until a complete packet is marked valid.
   Verify that the live rate is stable and close to 40 Hz.
4. Check that all five raw flex values and all six accel/gyro values respond to
   controlled movement. Do not infer magnetometer availability from
   `WHO_AM_I=0x70`.
5. Decide where the exported CSV/JSON pair will be backed up. Raw recordings are
   participant data and must not be committed to Git without explicit approval.

The initial vocabulary checkpoint (D1) is not decided. Until it is, use the
`words-draft` vocabulary version only for tooling pilots and enter labels in
lowercase snake_case, such as `thank_you`. Once the team approves 6–10 words,
publish the exact list under an immutable version such as `words-v1`; never
silently change the list for that version.

## Trial metadata

Every trial requires:

- word label and vocabulary version;
- pseudonymous signer ID beginning with `signer_`;
- unique trial ID within the session, such as `trial_001`;
- one orientation condition: `neutral`, `pitch_up`, `roll_left`, or
  `yaw_right`.

Use comfortable, repeatable wrist changes rather than forcing an exact angle.
Stop immediately if a movement is uncomfortable. Add mirrored directions only
after the four-condition pilot is reliable.

## Recording one trial

1. Select the word and trial metadata before starting.
2. Adopt the selected orientation and hold the agreed starting pose still for
   about one second.
3. Start recording, retain a short still lead-in, perform one complete sign at a
   natural pace, then hold the ending pose still for about one second.
4. Stop recording. Check elapsed time, packet count, valid count, observed rate,
   and quality warnings.
5. Save a clean trial. Otherwise discard it with a reason (`bad_sign`,
   `BLE_drop`, `wrong_label`, `interrupted`, or `other`) and repeat that trial ID.
6. Rest briefly before the next repetition to avoid merging gestures.

The app warns below 20 packets, below 25 Hz, on malformed packets, and on device
sequence gaps. These are pilot safeguards, not a final activity-window policy.
Do not hand-edit suspicious trials into looking valid; the backend validator
must report them and the exclusion decision must be recorded.

## Ending and exporting a session

Each saved trial updates app-private local files under
`recordings/raw/<session_id>/`. Use **Export session CSV + JSON** to open the
platform share/save sheet and export both `trials.csv` and `manifest.json`.
Keep the pair together, verify the copied files open, and back them up to the
team-approved restricted location.

Before using an export, run:

```text
python backend/prepare_word_sequences.py path/to/trials.csv
```

Review every error and warning. A successful validator run is necessary but
does not establish adequate signer coverage, consent, sign correctness, or
model readiness.

## Pilot acceptance checklist

- The phone received one complete CSV row per notification without truncation.
- `device_sequence` increases and gaps match the validator report.
- device and receive timestamps are monotonic.
- the observed delivered rate remains in the 25–50 Hz collection range.
- each row contains five raw flex values, six finite IMU values, and `who`.
- the CSV/manifest pair survives export and validates without hand editing.
- the exact IMU/module marking and optional diagnostic result are recorded
  separately; no magnetometer capability is assumed.
