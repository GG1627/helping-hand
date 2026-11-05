"""Generate synthetic software-parity fixtures; never recognition evidence."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np

try:
    from .sequence_preprocessing import SequencePreprocessing
    from .word_data import WordSample, resample_trial, fixed_window
except ImportError:
    from sequence_preprocessing import SequencePreprocessing
    from word_data import WordSample, resample_trial, fixed_window


def fixture_cases():
    cases = []
    for name, config, times in [
        ("legacy_trim", SequencePreprocessing(96), list(range(0, 3325, 25))),
        ("longer_complete", SequencePreprocessing(224, window_policy="reject_overlength_edge_pad"), list(range(0, 3325, 25))),
        ("magnetic_irregular", SequencePreprocessing(16, feature_set="flex_imu9", window_policy="reject_overlength_edge_pad"), [0, 30, 80, 120, 200]),
    ]:
        samples, frames = [], []
        for i, timestamp in enumerate(times):
            flex = [400 + (i % 31) * 2 + f for f in range(5)]
            motion = [((i * (f + 1)) % 29 - 14) / 10 for f in range(6)]
            magnetic = [0.0, -12.5 + i / 10, 31.2 - i / 20]
            sample = WordSample("word-sequence-v1", "fixture_session", name, i,
                i + 1, timestamp, timestamp, "hello", "fixture-v1", "signer_fixture", "neutral", "0xEA",
                *motion, *flex, "synthetic parity fixture", True,
                mag_status="ok", mx_ut=magnetic[0], my_ut=magnetic[1], mz_ut=magnetic[2])
            samples.append(sample)
            frames.append({"t_ms": timestamp, "seq": i + 1, "values": [*flex, *motion],
                           "magnetic": magnetic if config.feature_set == "flex_imu9" else None})
        resampled = resample_trial(samples, feature_columns=config.feature_columns)
        window = fixed_window(resampled, window_size=config.window_samples, window_policy=config.window_policy)
        mean = np.arange(len(config.feature_columns), dtype=np.float32) + .25
        scale = np.arange(len(config.feature_columns), dtype=np.float32) + 1.5
        expected = ((np.asarray(window.values, dtype=np.float32) - mean) / scale).tolist()
        metadata = {"architecture": "tcn", "trained": True, "vocabulary": ["hello", "please", "yes"],
                    "window_samples": config.window_samples, "target_rate_hz": 40,
                    "feature_columns": list(config.feature_columns), "preprocessing": config.to_dict(),
                    "standardizer": {"method": "per_feature_standardization", "fitted_split": "train",
                                     "feature_columns": list(config.feature_columns),
                                     "mean": mean.tolist(), "scale": scale.tolist()}}
        cases.append({"name": name, "metadata": metadata, "frames": frames, "expected_input": expected,
                      "trimmed_samples": window.trimmed_samples, "padded_samples": window.padded_samples})
    return {"data_origin": "synthetic_fixture", "accuracy_reporting_allowed": False, "cases": cases}


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[1] / "flutter_app/test/fixtures/sequence_preprocessing_v1.json"
    target.write_text(json.dumps(fixture_cases(), separators=(",", ":"), allow_nan=False) + "\n", encoding="utf-8")
    print(f"Wrote software-only preprocessing fixture: {target}")
