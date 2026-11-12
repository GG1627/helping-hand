"""Compare recorded-data and preserved static baseline on frozen held-out trials.

Confidence and hold compatibility here use recorded device timestamps, not a
physical phone/BLE run. This evaluation never changes model weights or splits.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

from train_static_recorded import ROOT, FEATURES, calibrate, save_json


def run_model(path: Path, values: np.ndarray) -> np.ndarray:
    runtime = tf.lite.Interpreter(model_path=str(path), num_threads=1)
    runtime.allocate_tensors()
    input_info, output_info = runtime.get_input_details()[0], runtime.get_output_details()[0]
    results = []
    for sample in values.astype(np.float32):
        runtime.set_tensor(input_info["index"], sample[None])
        runtime.invoke()
        results.append(runtime.get_tensor(output_info["index"])[0])
    return np.asarray(results)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_directory", type=Path)
    args = parser.parse_args()
    metadata = json.loads((args.run_directory / "metadata.json").read_text())
    splits = json.loads((args.run_directory / "split_manifest.json").read_text())["assignments"]
    source_frames = [pd.read_csv(ROOT / source["path"]) for source in metadata["sources"]]
    data = pd.concat(source_frames, ignore_index=True)
    data["group"] = data.session_id + "/" + data.trial_id
    data["split"] = data.group.map(splits)
    data = data.loc[data.split.isin(["validation", "test"])].reset_index(drop=True)
    values = calibrate(data[FEATURES].to_numpy(), metadata["calibration"])
    labels = metadata["classes"]
    probabilities = run_model(args.run_directory / "model.tflite",
                              (values - np.float32(metadata["mean"])) / np.float32(metadata["scale"]))
    baseline = json.loads((ROOT / "backend/models/scaler_params.json").read_text())
    baseline_probabilities = run_model(ROOT / "backend/models/asl_model.tflite",
                                      (values - np.float32(baseline["mean"])) / np.float32(baseline["scale"]))
    results = []
    for group in sorted(data.group.unique()):
        indices = np.flatnonzero(data.group.eq(group).to_numpy())
        frame = data.iloc[indices].sort_values("sample_index")
        indices = frame.index.to_numpy()
        target = str(frame.word.iloc[0]).upper()
        scores = probabilities[indices]
        prediction = np.array(labels)[scores.argmax(axis=1)]
        category_indices = [i for i, label in enumerate(labels) if label.isalpha() == target.isalpha()]
        category_scores = scores[:, category_indices]
        category_predictions = np.array(labels)[np.array(category_indices)[category_scores.argmax(axis=1)]]
        confidence = np.round(category_scores.max(axis=1) * 100, 1)
        eligible = (category_predictions == target) & (confidence >= 80)
        timestamps = frame.device_timestamp_ms.to_numpy(dtype=np.int64)
        first, previous, count, longest, can_complete = None, None, 0, 0, False
        for ok, timestamp in zip(eligible, timestamps):
            if not ok:
                first, previous, count = None, None, 0
                continue
            if previous is None or timestamp < previous or timestamp - previous > 250:
                first, count = timestamp, 0
            previous = timestamp
            count += 1
            longest = max(longest, int(timestamp - first))
            can_complete |= timestamp - first >= 750 and count >= 5
        baseline_scores = baseline_probabilities[indices]
        baseline_prediction = np.array(baseline["classes"])[baseline_scores.argmax(axis=1)]
        results.append({"group": group, "split": frame.split.iloc[0], "label": target,
                        "frames": len(frame), "candidate_top1": float(np.mean(prediction == target)),
                        "baseline_top1_with_current_calibration": float(np.mean(baseline_prediction == target)),
                        "category_confidence_min_percent": float(confidence.min()),
                        "category_confidence_median_percent": float(np.median(confidence)),
                        "category_correct_and_confident_fraction": float(eligible.mean()),
                        "longest_recorded_eligible_hold_ms": longest,
                        "recorded_hold_can_complete": bool(can_complete)})
    result = {"scope": "Frozen trial-held-out recordings; device timestamps approximate hold eligibility. Physical app/BLE validation Not run.",
              "baseline_note": "Preserved synthetic MLP using the same current live calibration, then its original scaler.",
              "trial_results": results}
    save_json(args.run_directory / "demo_readiness.json", result)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
