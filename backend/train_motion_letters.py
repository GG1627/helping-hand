"""Train the separate J/Z motion TCN from real glove exports."""

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import tensorflow as tf

from .word_data import FEATURE_COLUMNS, fixed_window, load_recording, resample_trial
from .word_models import WordModelConfig, build_word_model, convert_to_tflite

LABELS = ("j", "z", "other")
IMU_COLUMNS = FEATURE_COLUMNS[5:]
WINDOW = 160
RATE_HZ = 40
THRESHOLD = 0.80
FOLLOWUP_WORD_SPLITS = {
    "train": {
        "word_thank_you_0001",
        "word_hello_0004",
        "word_hello_0005",
        "word_yes_0008",
        "word_yes_0009",
    },
    "validation": {"word_thank_you_0002", "word_hello_0006", "word_yes_0010"},
}


def load_source(csv_path, manifest_path):
    recording = load_recording(csv_path, manifest_path=manifest_path)
    if not recording.report.is_valid or recording.manifest.get("data_origin") != "real":
        raise ValueError(f"A matched real export is required: {csv_path}")
    return recording.trials()


def split_trials(current, earlier, words, more_words):
    by_label = defaultdict(list)
    for key, packets in current.items():
        by_label[packets[0].word].append((key, packets))
    groups = {split: [] for split in ("train", "validation", "held_out")}
    for label, trials in by_label.items():
        trials.sort()
        if label == "j":
            # Keep a fast and a slower J in the held-out group.
            held_indices = {2, 4}
        else:
            held_indices = {len(trials) - 2, len(trials) - 1}
        for index, trial in enumerate(trials):
            group = "held_out" if index in held_indices else "train"
            # The first I and O holds each contain substantial movement.
            if label == "i" and index == 0:
                group = "validation"
            elif label == "o" and index == 0:
                group = "held_out"
            groups[group].append(trial)
    groups["validation"].extend(
        (key, packets)
        for key, packets in earlier.items()
        if packets[0].word in LABELS[:2]
    )
    for key, packets in words.items():
        group = "validation" if packets[0].signer_id == "signer_53" else "train"
        groups[group].append((key, packets))
    for key, packets in more_words.items():
        group = next(
            (name for name, ids in FOLLOWUP_WORD_SPLITS.items() if key[1] in ids),
            "held_out",
        )
        groups[group].append((key, packets))
    return groups


def prepare(trials):
    values = []
    labels = []
    for _, packets in trials:
        if not all(packet.packet_valid for packet in packets):
            raise ValueError(f"Incomplete motion trial: {packets[0].trial_id}")
        window = fixed_window(
            resample_trial(packets, target_rate_hz=RATE_HZ), window_size=WINDOW
        )
        values.append(np.asarray(window.values, dtype=np.float32)[:, 5:])
        label = packets[0].word
        labels.append(LABELS.index(label) if label in LABELS[:2] else 2)
    return np.stack(values), np.asarray(labels)


def evaluate(trials, probabilities):
    results = []
    for ((session, trial_id), packets), scores in zip(
        trials, probabilities, strict=True
    ):
        index = int(np.argmax(scores))
        label = packets[0].word
        accepted = LABELS[index] if index != 2 and scores[index] >= THRESHOLD else None
        results.append(
            {
                "session_id": session,
                "trial_id": trial_id,
                "recorded_label": label,
                "accepted": accepted,
                "scores": dict(zip(LABELS, map(float, scores))),
            }
        )
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for group in ("current", "earlier", "words", "more-words"):
        parser.add_argument(
            f"--{group}", required=True, nargs=2, type=Path, metavar=("CSV", "MANIFEST")
        )
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    sources = (args.current, args.earlier, args.words, args.more_words)
    groups = split_trials(*(load_source(*paths) for paths in sources))
    train_x, train_y = prepare(groups["train"])
    val_x, val_y = prepare(groups["validation"])
    held_x, _ = prepare(groups["held_out"])
    mean = train_x.mean(axis=(0, 1))
    scale = np.maximum(train_x.std(axis=(0, 1)), 1e-6)
    train_x = (train_x - mean) / scale
    val_x = (val_x - mean) / scale
    held_x = (held_x - mean) / scale

    # Offset recorded sequences without changing the motion or mixing trials.
    shifts = (-12, 0, 12)
    positions = np.arange(WINDOW)
    train_x = np.concatenate(
        [train_x[:, np.clip(positions - shift, 0, WINDOW - 1)] for shift in shifts]
    )
    train_y = np.tile(train_y, len(shifts))
    counts = np.bincount(train_y, minlength=len(LABELS))
    weights = (len(train_y) / (len(LABELS) * counts[train_y])).astype(np.float32)
    tf.keras.utils.set_random_seed(57)
    tf.config.threading.set_intra_op_parallelism_threads(2)
    tf.config.threading.set_inter_op_parallelism_threads(2)
    model = build_word_model(
        WordModelConfig(
            "tcn",
            WINDOW,
            len(LABELS),
            feature_count=len(IMU_COLUMNS),
            conv_filters=16,
            dense_units=16,
            learning_rate=0.002,
            dropout=0.2,
        )
    )
    best = None
    for epoch in range(1, 141):
        model.train_on_batch(train_x, train_y, sample_weight=weights)
        probabilities = model(val_x, training=False).numpy()
        scores = probabilities[np.arange(len(val_y)), val_y]
        accepted = (probabilities.argmax(axis=1) != 2) & (
            probabilities.max(axis=1) >= THRESHOLD
        )
        correct = np.count_nonzero(accepted & (val_y != 2) & (scores >= THRESHOLD))
        incorrect = np.count_nonzero(accepted) - correct
        key = (int(correct - 2 * incorrect), int(correct), float(np.mean(scores)))
        if best is None or key > best[0]:
            best = (key, epoch, model.get_weights())
    _, epoch, best_weights = best
    model.set_weights(best_weights)

    args.output.mkdir(parents=True, exist_ok=True)
    payload = convert_to_tflite(model, temporary_parent=args.output)
    interpreter = tf.lite.Interpreter(model_content=payload, num_threads=1)
    interpreter.allocate_tensors()

    def lite_scores(windows):
        input_index = interpreter.get_input_details()[0]["index"]
        output_index = interpreter.get_output_details()[0]["index"]
        scores = []
        for window in windows:
            interpreter.set_tensor(input_index, window[None, ...])
            interpreter.invoke()
            scores.append(interpreter.get_tensor(output_index)[0])
        return np.stack(scores)

    held_scores = lite_scores(held_x)
    np.testing.assert_allclose(
        held_scores, model(held_x, training=False), rtol=0.002, atol=0.0001
    )
    results = evaluate(groups["held_out"], held_scores)
    metadata = {
        "schema_version": "word-model-bundle-v1",
        "architecture": "tcn",
        "trained": True,
        "data_origin": "real_with_train_only_timing_offsets",
        "vocabulary": LABELS,
        "feature_columns": IMU_COLUMNS,
        "window_samples": WINDOW,
        "target_rate_hz": RATE_HZ,
        "preprocessing": {
            "schema_version": "sequence-preprocessing-v1",
            "feature_set": "imu6",
            "window_samples": WINDOW,
            "target_rate_hz": RATE_HZ,
            "window_policy": "center_trim_edge_pad",
        },
        "standardizer": {
            "method": "per_feature_standardization",
            "fitted_split": "train",
            "feature_columns": IMU_COLUMNS,
            "mean": mean.tolist(),
            "scale": scale.tolist(),
        },
        "tflite_sha256": hashlib.sha256(payload).hexdigest(),
        "source_sha256": {
            path.name: hashlib.sha256(path.read_bytes()).hexdigest()
            for pair in sources
            for path in pair
        },
        "threshold": THRESHOLD,
        "selected_epoch": epoch,
    }
    (args.output / "model.tflite").write_bytes(payload)
    (args.output / "model_metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    report = {
        "scope": (
            "Offline, whole-trial split. Some held-out trials were examined in the initial model experiment. "
            "Same wearer is not ruled out across sources."
        ),
        "training_shifts_samples": shifts,
        "groups": {
            name: [
                {"session_id": key[0], "trial_id": key[1], "label": packets[0].word}
                for key, packets in trials
            ]
            for name, trials in groups.items()
        },
        "validation": evaluate(groups["validation"], lite_scores(val_x)),
        "held_out": results,
    }
    (args.output / "evaluation.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(
        "Trial counts",
        {
            name: dict(
                Counter(
                    packets[0].word if packets[0].word in LABELS[:2] else "other"
                    for _, packets in trials
                )
            )
            for name, trials in groups.items()
        },
    )
    print(
        "Held-out motion",
        [
            (r["recorded_label"], r["accepted"])
            for r in results
            if r["recorded_label"] in LABELS[:2]
        ],
    )
    print(
        "False accepts",
        [
            (r["trial_id"], r["accepted"])
            for r in results
            if r["accepted"] is not None and r["accepted"] != r["recorded_label"]
        ],
    )


if __name__ == "__main__":
    main()
