"""Compare three word architectures on the approved 15-trial demo dataset.

Selection uses validation accuracy/F1, then TFLite size, then desktop latency.
Only the selected candidate is evaluated on the reserved test trials.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict
import faulthandler
import hashlib
import json
from pathlib import Path
import random
import time

import numpy as np
import tensorflow as tf

from evaluate_word_models import evaluate_probabilities
from train_word_models import _train_candidate
from word_data import load_recording
from word_dataset import (SequenceStandardizer, SplitAssignment, SplitManifest,
                          examples_by_split, model_arrays, prepare_examples)
from word_models import ARCHITECTURES

ROOT = Path(__file__).resolve().parents[1]
VOCABULARY = ("hello", "please", "yes")


def save_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def tflite_predictions(model_path: Path, values: np.ndarray) -> tuple[np.ndarray, dict]:
    runtime = tf.lite.Interpreter(model_path=str(model_path), num_threads=1)
    runtime.allocate_tensors()
    inp, out = runtime.get_input_details()[0], runtime.get_output_details()[0]
    if inp["shape"].tolist() != [1, *values.shape[1:]]:
        raise ValueError(f"Unexpected TFLite shape: {inp['shape']}")
    if inp["dtype"] != np.float32 or out["dtype"] != np.float32:
        raise ValueError("Demo export must use float32 tensors")

    def predict(sample):
        runtime.set_tensor(inp["index"], sample[None].astype(np.float32))
        runtime.invoke()
        return runtime.get_tensor(out["index"])[0]

    probabilities = np.stack([predict(sample) for sample in values])
    for i in range(10):
        predict(values[i % len(values)])
    times = []
    for i in range(100):
        start = time.perf_counter()
        predict(values[i % len(values)])
        times.append((time.perf_counter() - start) * 1000)
    return probabilities, {
        "scope": "Windows desktop CPU, one TFLite thread; tensor copy + invoke + output copy; not Android latency",
        "warmup_runs": 10, "measured_runs": 100,
        "median_ms": float(np.median(times)), "p95_ms": float(np.percentile(times, 95)),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--window-samples", type=int, default=96)
    parser.add_argument("--epochs", type=int, default=150)
    parser.add_argument("--seed", type=int, default=7)
    args = parser.parse_args()
    if args.epochs < 1 or args.window_samples < 4:
        raise ValueError("Epoch count must be positive and the window must contain >=4 samples")
    if args.output_directory.exists():
        raise ValueError("Use a new run directory")
    faulthandler.dump_traceback_later(120, repeat=True)
    tf.config.threading.set_inter_op_parallelism_threads(2)
    tf.config.threading.set_intra_op_parallelism_threads(2)
    tf.config.experimental.enable_op_determinism()
    csv = ROOT / "backend/recorded_data/trials_1.csv"
    manifest_path = ROOT / "backend/recorded_data/manifest_1.json"
    recording = load_recording(csv, manifest_path=manifest_path, expected_labels=VOCABULARY)
    if not recording.report.is_valid:
        raise ValueError(json.dumps(recording.report.to_dict()))
    examples = prepare_examples([recording], window_samples=args.window_samples, target_rate_hz=40)
    rng = random.Random(args.seed)
    assignments = []
    for word in VOCABULARY:
        trials = sorted((item for item in examples if item.word == word), key=lambda item: item.trial_key)
        if len(trials) != 5:
            raise ValueError(f"Expected five real trials for {word}, got {len(trials)}")
        rng.shuffle(trials)
        for index, example in enumerate(trials):
            assignments.append(SplitAssignment(
                example.session_id, example.trial_id, example.word, example.signer_id,
                example.orientation_condition, "train" if index < 3 else "validation" if index == 3 else "test"))
    split = SplitManifest("word-split-v1", "words-demo-real-v1", "words-draft",
                          "user_dependent", args.seed, .2, .2, tuple(assignments))
    grouped = examples_by_split(examples, split)
    standardizer = SequenceStandardizer.fit(grouped["train"])
    args.output_directory.mkdir(parents=True)
    split.write(args.output_directory / "split_manifest.json")
    preparation = {
        "data_origin": "real", "vocabulary": VOCABULARY,
        "source_csv": str(csv.relative_to(ROOT)), "source_sha256": hashlib.sha256(csv.read_bytes()).hexdigest(),
        "source_manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
        "split_scope": "Whole-trial demo comparison; per-trial signer IDs retained but not treated as verified independent people. User reports the demo wearer supplied the data.",
        "preprocessing": f"Device-clock linear resampling at 40Hz; center-trim or symmetric edge-pad to {args.window_samples} samples; training-only per-feature standardization; raw flex ADC plus six-axis IMU, independently of the static MLP calibration.",
        "orientation": "neutral only; no quaternion fusion or orientation-invariance claim",
        "standardizer": standardizer.to_dict(), "quality": recording.report.to_dict(),
        "trials": [{key: value for key, value in asdict(item).items() if key != "values"} for item in examples],
        "selection_policy": "Highest validation top-1, then macro F1; ties use smallest exported TFLite, then lowest desktop median latency. No test predictions before selection.",
    }
    save_json(args.output_directory / "preparation.json", preparation)
    validation_x, validation_y = model_arrays(grouped["validation"], VOCABULARY, standardizer)
    results = []
    for architecture in ARCHITECTURES:
        print(f"Training {architecture} on 9 whole trials; validation has 3 trials.", flush=True)
        directory = args.output_directory / architecture
        _train_candidate(
            architecture=architecture, grouped=grouped, vocabulary=VOCABULARY,
            standardizer=standardizer, split_manifest=split, source_csvs=[csv],
            output_directory=directory, target_rate_hz=40, window_samples=args.window_samples,
            data_origin="real", seed=args.seed, epochs=args.epochs, batch_size=3, patience=20,
            conv_filters=16, recurrent_units=16, dense_units=16, dropout=.25,
            l2_regularization=1e-4, learning_rate=1e-3, verbose=2, defer_test=True)
        metadata = json.loads((directory / "model_metadata.json").read_text())
        probabilities, latency = tflite_predictions(directory / "model.tflite", validation_x)
        keras_model = tf.keras.models.load_model(directory / "model.keras")
        keras_probabilities = keras_model(validation_x, training=False).numpy()
        error = float(np.max(np.abs(probabilities - keras_probabilities)))
        if error > 1e-4:
            raise ValueError(f"TFLite parity failed for {architecture}: {error}")
        report = evaluate_probabilities(validation_y, probabilities, vocabulary=VOCABULARY,
            examples=grouped["validation"], split_name="validation", data_origin="real")
        save_json(directory / "evaluation_validation_tflite.json", report)
        save_json(directory / "desktop_latency.json", latency)
        result = {"architecture": architecture, "validation": report["overall"],
                  "validation_trials": [{"trial": item.trial_key, "expected": item.word,
                                        "predicted": VOCABULARY[int(probabilities[i].argmax())],
                                        "probabilities": probabilities[i].tolist()}
                                       for i, item in enumerate(grouped["validation"])],
                  "tflite_size_bytes": metadata["artifacts"]["tflite_size_bytes"],
                  "parameter_count": metadata["artifacts"]["parameter_count"],
                  "epochs_completed": metadata["training"]["epochs_completed"],
                  "desktop_latency": latency, "keras_tflite_max_error": error}
        results.append(result)
        save_json(args.output_directory / "comparison_progress.json", results)
        print(json.dumps(result, indent=2), flush=True)
        del keras_model
        tf.keras.backend.clear_session()
    ranked = sorted(results, key=lambda item: (-item["validation"]["top_1_accuracy"],
                    -item["validation"]["macro_f1"], item["tflite_size_bytes"], item["desktop_latency"]["median_ms"]))
    selected = ranked[0]["architecture"]
    print(f"Selected {selected} using validation and deployment criteria; evaluating reserved test trials.", flush=True)
    test_x, test_y = model_arrays(grouped["test"], VOCABULARY, standardizer)
    test_probabilities, _ = tflite_predictions(args.output_directory / selected / "model.tflite", test_x)
    test_report = evaluate_probabilities(test_y, test_probabilities, vocabulary=VOCABULARY,
        examples=grouped["test"], split_name="test", data_origin="real")
    save_json(args.output_directory / selected / "evaluation_test.json", test_report)
    selected_metadata_path = args.output_directory / selected / "model_metadata.json"
    selected_metadata = json.loads(selected_metadata_path.read_text())
    selected_metadata["test_evaluation_status"] = "evaluated_after_model_selection"
    selected_metadata["selection_status"] = "selected_demo_candidate_pending_live_validation"
    selected_metadata["window_preprocessing"] = preparation["preprocessing"]
    selected_metadata["evaluation_scope"] = preparation["split_scope"]
    save_json(selected_metadata_path, selected_metadata)
    test_trials = [{"trial": item.trial_key, "expected": item.word,
                   "predicted": VOCABULARY[int(test_probabilities[i].argmax())],
                   "probabilities": test_probabilities[i].tolist()} for i, item in enumerate(grouped["test"])]
    selection = {"schema_version": "demo-word-comparison-v1", "vocabulary": VOCABULARY,
                 "data_origin": "real", "selected_architecture": selected,
                 "selection_policy": preparation["selection_policy"], "candidates": results,
                 "selected_test": test_report["overall"], "selected_test_trials": test_trials,
                 "hardware_latency_ms": None, "hardware_validation": "Not run",
                 "final_accuracy_claim_ready": False, "integration_status": "trained candidate; not connected to Flutter live word practice"}
    save_json(args.output_directory / "selection.json", selection)
    faulthandler.cancel_dump_traceback_later()
    print(json.dumps(selection, indent=2), flush=True)


if __name__ == "__main__":
    main()
