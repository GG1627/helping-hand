"""Evaluate a word model with trial metadata and explicit data provenance.

Synthetic-fixture output is a software smoke result only. It is always marked
as unsuitable for accuracy reporting.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

import numpy as np
from sklearn.metrics import confusion_matrix, f1_score

try:
    from .word_data import load_recordings
    from .word_dataset import (
        SPLIT_NAMES,
        SequenceExample,
        SequenceStandardizer,
        SplitManifest,
        examples_by_split,
        model_arrays,
        prepare_examples,
    )
except ImportError:  # Direct execution from backend/.
    from word_data import load_recordings  # type: ignore[no-redef]
    from word_dataset import (  # type: ignore[no-redef]
        SPLIT_NAMES,
        SequenceExample,
        SequenceStandardizer,
        SplitManifest,
        examples_by_split,
        model_arrays,
        prepare_examples,
    )


EVALUATION_SCHEMA_VERSION = "word-evaluation-v1"
MODEL_BUNDLE_SCHEMA_VERSION = "word-model-bundle-v1"


def _top_k_accuracy(
    expected: np.ndarray, probabilities: np.ndarray, *, k: int
) -> float:
    top_k = np.argpartition(probabilities, -k, axis=1)[:, -k:]
    matches = np.any(top_k == expected[:, np.newaxis], axis=1)
    return float(np.mean(matches))


def _group_metrics(
    expected: np.ndarray,
    probabilities: np.ndarray,
    *,
    num_classes: int,
) -> dict[str, object]:
    predicted = np.argmax(probabilities, axis=1)
    return {
        "sample_count": int(len(expected)),
        "top_1_accuracy": float(np.mean(predicted == expected)),
        "macro_f1": float(
            f1_score(
                expected,
                predicted,
                labels=np.arange(num_classes),
                average="macro",
                zero_division=0,
            )
        ),
    }


def evaluate_probabilities(
    expected: np.ndarray,
    probabilities: np.ndarray,
    *,
    vocabulary: Sequence[str],
    examples: Sequence[SequenceExample],
    split_name: str,
    data_origin: str,
) -> dict[str, object]:
    """Calculate consistent overall, signer, and orientation metrics."""

    labels = tuple(vocabulary)
    expected = np.asarray(expected, dtype=np.int64)
    probabilities = np.asarray(probabilities, dtype=np.float64)
    if expected.ndim != 1 or not len(expected):
        raise ValueError("expected labels must be a non-empty one-dimensional array")
    if probabilities.shape != (len(expected), len(labels)):
        raise ValueError("probabilities must have shape [samples, vocabulary_size]")
    if len(examples) != len(expected):
        raise ValueError("example metadata count must match predictions")
    if len(labels) < 2 or len(set(labels)) != len(labels):
        raise ValueError("vocabulary must contain at least two unique labels")
    if np.any(expected < 0) or np.any(expected >= len(labels)):
        raise ValueError("expected labels contain an out-of-range class index")
    if not np.all(np.isfinite(probabilities)):
        raise ValueError("probabilities must be finite")
    if np.any(probabilities < 0) or not np.allclose(
        np.sum(probabilities, axis=1), 1.0, atol=1e-4
    ):
        raise ValueError("model output must contain normalized probabilities")
    if split_name not in SPLIT_NAMES:
        raise ValueError(f"split_name must be one of {SPLIT_NAMES}")
    if data_origin not in {"real", "synthetic_fixture"}:
        raise ValueError("data_origin must be real or synthetic_fixture")

    predicted = np.argmax(probabilities, axis=1)
    overall = _group_metrics(expected, probabilities, num_classes=len(labels))
    if len(labels) >= 5:
        overall["top_5_accuracy"] = _top_k_accuracy(expected, probabilities, k=5)
        overall["top_5_status"] = "computed"
    else:
        overall["top_5_accuracy"] = None
        overall["top_5_status"] = "not_applicable_vocabulary_has_fewer_than_5_labels"

    def summarize_groups(attribute: str) -> dict[str, dict[str, object]]:
        grouped: dict[str, list[int]] = {}
        for index, example in enumerate(examples):
            grouped.setdefault(str(getattr(example, attribute)), []).append(index)
        return {
            name: _group_metrics(
                expected[indexes],
                probabilities[indexes],
                num_classes=len(labels),
            )
            for name, indexes in sorted(grouped.items())
        }

    accuracy_allowed = data_origin == "real"
    report: dict[str, object] = {
        "schema_version": EVALUATION_SCHEMA_VERSION,
        "data_origin": data_origin,
        "accuracy_reporting_allowed": accuracy_allowed,
        "final_accuracy_claim_ready": False,
        "final_accuracy_claim_status": "requires_dataset_protocol_and_split_review",
        "result_scope": (
            "real_recording_evaluation"
            if accuracy_allowed
            else "synthetic_fixture_software_smoke_only"
        ),
        "split": split_name,
        "vocabulary": list(labels),
        "overall": overall,
        "confusion_matrix": {
            "labels": list(labels),
            "rows_expected_columns_predicted": confusion_matrix(
                expected, predicted, labels=np.arange(len(labels))
            ).tolist(),
        },
        "by_signer": summarize_groups("signer_id"),
        "by_orientation": summarize_groups("orientation_condition"),
        "latency_ms": None,
        "latency_status": "requires_target_device_measurement",
    }
    if not accuracy_allowed:
        report["warning"] = (
            "Synthetic fixture metrics only verify software execution and must not "
            "be reported as model accuracy."
        )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle_directory", type=Path)
    parser.add_argument("csv", nargs="+", type=Path)
    parser.add_argument("--split", choices=SPLIT_NAMES, default="test")
    parser.add_argument(
        "--allow-synthetic-smoke",
        action="store_true",
        help="Permit fixture execution; output remains non-reportable",
    )
    parser.add_argument("--output-json", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    metadata_path = args.bundle_directory / "model_metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        if not isinstance(metadata, dict):
            raise ValueError("model metadata root must be an object")
        if metadata.get("schema_version") != MODEL_BUNDLE_SCHEMA_VERSION:
            raise ValueError("unsupported model bundle schema")
        vocabulary = tuple(str(item) for item in metadata["vocabulary"])
        target_rate_hz = float(metadata["target_rate_hz"])
        window_samples = int(metadata["window_samples"])
        standardizer = SequenceStandardizer.from_dict(metadata["standardizer"])
        split_manifest = SplitManifest.from_dict(metadata["split_manifest"])
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
        print(f"Model metadata error: {exc}")
        return 2

    recordings = load_recordings(args.csv, expected_labels=vocabulary)
    try:
        examples = prepare_examples(
            recordings,
            window_samples=window_samples,
            target_rate_hz=target_rate_hz,
        )
        origins = {example.data_origin for example in examples}
        if len(origins) != 1:
            raise ValueError("model evaluation cannot mix data origins")
        data_origin = next(iter(origins))
        if data_origin == "synthetic_fixture" and not args.allow_synthetic_smoke:
            raise ValueError(
                "synthetic fixture evaluation requires --allow-synthetic-smoke"
            )
        selected = examples_by_split(examples, split_manifest)[args.split]
        x_values, expected = model_arrays(selected, vocabulary, standardizer)
    except ValueError as exc:
        print(f"Dataset error: {exc}")
        return 2

    try:
        from tensorflow import keras

        model = keras.models.load_model(args.bundle_directory / "model.keras")
        probabilities = model.predict(x_values, verbose=0)
        report = evaluate_probabilities(
            expected,
            probabilities,
            vocabulary=vocabulary,
            examples=selected,
            split_name=args.split,
            data_origin=data_origin,
        )
    except (OSError, TypeError, ValueError) as exc:
        print(f"Evaluation error: {exc}")
        return 2

    rendered = json.dumps(report, indent=2, sort_keys=True)
    print(rendered)
    if args.output_json is not None:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(rendered + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
