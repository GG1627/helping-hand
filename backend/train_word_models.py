"""Train identical-split TCN, CNN-GRU, and CNN-LSTM word candidates.

The command is ready for future approved real recordings. Synthetic fixtures
require an explicit flag and produce smoke-only, non-reportable evaluations.
No training is performed merely by importing this module.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Sequence

import tensorflow as tf
from tensorflow import keras

try:
    from .evaluate_word_models import (
        MODEL_BUNDLE_SCHEMA_VERSION,
        evaluate_probabilities,
    )
    from .word_data import DEFAULT_TARGET_RATE_HZ, load_recordings
    from .word_dataset import (
        SPLIT_NAMES,
        SPLIT_STRATEGIES,
        SequenceExample,
        SequenceStandardizer,
        SplitManifest,
        create_split_manifest,
        examples_by_split,
        model_arrays,
        prepare_examples,
        resolve_vocabulary,
        validate_split_manifest,
    )
    from .word_models import (
        ARCHITECTURES,
        WordModelConfig,
        build_word_model,
        convert_to_tflite,
    )
except ImportError:  # Direct execution from backend/.
    from evaluate_word_models import (  # type: ignore[no-redef]
        MODEL_BUNDLE_SCHEMA_VERSION,
        evaluate_probabilities,
    )
    from word_data import (  # type: ignore[no-redef]
        DEFAULT_TARGET_RATE_HZ,
        load_recordings,
    )
    from word_dataset import (  # type: ignore[no-redef]
        SPLIT_NAMES,
        SPLIT_STRATEGIES,
        SequenceExample,
        SequenceStandardizer,
        SplitManifest,
        create_split_manifest,
        examples_by_split,
        model_arrays,
        prepare_examples,
        resolve_vocabulary,
        validate_split_manifest,
    )
    from word_models import (  # type: ignore[no-redef]
        ARCHITECTURES,
        WordModelConfig,
        build_word_model,
        convert_to_tflite,
    )


def _load_vocabulary(path: Path | None) -> tuple[str, ...] | None:
    if path is None:
        return None
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() == ".json":
        value = json.loads(text)
        if isinstance(value, dict):
            value = value.get("vocabulary")
        if not isinstance(value, list) or not all(
            isinstance(item, str) for item in value
        ):
            raise ValueError(
                "JSON vocabulary must be a list or an object with a vocabulary list"
            )
        return tuple(value)
    return tuple(
        line.strip()
        for line in text.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _origin(examples: Sequence[SequenceExample]) -> str:
    origins = {example.data_origin for example in examples}
    if len(origins) != 1:
        raise ValueError("training cannot mix real recordings and synthetic fixtures")
    return next(iter(origins))


def _require_usable_splits(
    grouped: dict[str, tuple[SequenceExample, ...]],
    vocabulary: Sequence[str],
) -> None:
    for split in SPLIT_NAMES:
        if not grouped[split]:
            raise ValueError(
                f"the {split} split is empty; collect more independent trials/signers"
            )
    train_labels = {example.word for example in grouped["train"]}
    missing = set(vocabulary) - train_labels
    if missing:
        raise ValueError(
            f"training split has no examples for labels: {sorted(missing)!r}"
        )


def _training_callbacks(
    output_directory: Path, patience: int
) -> list[keras.callbacks.Callback]:
    return [
        keras.callbacks.ModelCheckpoint(
            output_directory / "model.keras",
            monitor="val_loss",
            save_best_only=True,
            verbose=0,
        ),
        keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=patience,
            restore_best_weights=True,
            verbose=0,
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=max(2, patience // 3),
            min_lr=1e-6,
            verbose=0,
        ),
    ]


def _json_history(history: keras.callbacks.History) -> dict[str, list[float]]:
    return {
        name: [float(value) for value in values]
        for name, values in history.history.items()
    }


def _train_candidate(
    *,
    architecture: str,
    grouped: dict[str, tuple[SequenceExample, ...]],
    vocabulary: Sequence[str],
    standardizer: SequenceStandardizer,
    split_manifest: SplitManifest,
    source_csvs: Sequence[Path],
    output_directory: Path,
    target_rate_hz: float,
    window_samples: int,
    data_origin: str,
    seed: int,
    epochs: int,
    batch_size: int,
    patience: int,
    conv_filters: int,
    recurrent_units: int,
    dense_units: int,
    dropout: float,
    l2_regularization: float,
    learning_rate: float,
    verbose: int,
) -> dict[str, object]:
    output_directory.mkdir(parents=True, exist_ok=False)
    arrays = {
        split: model_arrays(examples, vocabulary, standardizer)
        for split, examples in grouped.items()
    }
    model_config = WordModelConfig(
        architecture=architecture,
        window_samples=window_samples,
        num_classes=len(vocabulary),
        feature_count=arrays["train"][0].shape[-1],
        conv_filters=conv_filters,
        recurrent_units=recurrent_units,
        dense_units=dense_units,
        dropout=dropout,
        l2_regularization=l2_regularization,
        learning_rate=learning_rate,
    )
    keras.utils.set_random_seed(seed)
    model = build_word_model(model_config)
    history = model.fit(
        arrays["train"][0],
        arrays["train"][1],
        validation_data=arrays["validation"],
        epochs=epochs,
        batch_size=batch_size,
        callbacks=_training_callbacks(output_directory, patience),
        verbose=verbose,
        shuffle=True,
    )
    best_model = keras.models.load_model(output_directory / "model.keras")
    reports: dict[str, dict[str, object]] = {}
    for split in ("validation", "test"):
        probabilities = best_model.predict(arrays[split][0], verbose=0)
        reports[split] = evaluate_probabilities(
            arrays[split][1],
            probabilities,
            vocabulary=vocabulary,
            examples=grouped[split],
            split_name=split,
            data_origin=data_origin,
        )
        (output_directory / f"evaluation_{split}.json").write_text(
            json.dumps(reports[split], indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    tflite_bytes = convert_to_tflite(best_model, temporary_parent=output_directory)
    (output_directory / "model.tflite").write_bytes(tflite_bytes)
    history_json = _json_history(history)
    (output_directory / "training_history.json").write_text(
        json.dumps(history_json, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    split_manifest.write(output_directory / "split_manifest.json")

    metadata = {
        "schema_version": MODEL_BUNDLE_SCHEMA_VERSION,
        "architecture": architecture,
        "trained": True,
        "data_origin": data_origin,
        "accuracy_reporting_allowed": data_origin == "real",
        "final_accuracy_claim_ready": False,
        "final_accuracy_claim_status": "requires_dataset_protocol_and_split_review",
        "synthetic_fixture_smoke_only": data_origin == "synthetic_fixture",
        "data_version": split_manifest.data_version,
        "vocabulary_version": split_manifest.vocabulary_version,
        "vocabulary": list(vocabulary),
        "target_rate_hz": target_rate_hz,
        "window_samples": window_samples,
        "feature_columns": list(standardizer.feature_columns),
        "standardizer": standardizer.to_dict(),
        "split_manifest": split_manifest.to_dict(),
        "model_config": model_config.to_dict(),
        "training": {
            "seed": seed,
            "epochs_requested": epochs,
            "epochs_completed": len(history.epoch),
            "batch_size": batch_size,
            "early_stopping_patience": patience,
        },
        "source_files": [
            {"name": path.name, "sha256": _sha256(path)} for path in source_csvs
        ],
        "artifacts": {
            "keras": "model.keras",
            "tflite": "model.tflite",
            "parameter_count": int(best_model.count_params()),
            "tflite_size_bytes": len(tflite_bytes),
            "quantization": "none_requires_representative_real_data",
        },
        "latency_ms": None,
        "latency_status": "requires_target_device_measurement",
        "tensorflow_version": tf.__version__,
    }
    (output_directory / "model_metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return {
        "architecture": architecture,
        "directory": str(output_directory),
        "parameter_count": metadata["artifacts"]["parameter_count"],
        "tflite_size_bytes": len(tflite_bytes),
        "test_result_scope": reports["test"]["result_scope"],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", nargs="+", type=Path)
    parser.add_argument(
        "--vocabulary",
        type=Path,
        help="Required for real data; newline-delimited or JSON label order",
    )
    parser.add_argument("--data-version", required=True)
    parser.add_argument("--output-directory", required=True, type=Path)
    parser.add_argument(
        "--architectures",
        nargs="+",
        choices=ARCHITECTURES,
        default=list(ARCHITECTURES),
    )
    parser.add_argument("--window-samples", required=True, type=int)
    parser.add_argument("--target-rate-hz", type=float, default=DEFAULT_TARGET_RATE_HZ)
    parser.add_argument("--split-manifest", type=Path)
    parser.add_argument(
        "--split-strategy", choices=SPLIT_STRATEGIES, default="user_dependent"
    )
    parser.add_argument("--validation-fraction", type=float, default=0.2)
    parser.add_argument("--test-fraction", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--patience", type=int, default=15)
    parser.add_argument("--conv-filters", type=int, default=32)
    parser.add_argument("--recurrent-units", type=int, default=32)
    parser.add_argument("--dense-units", type=int, default=32)
    parser.add_argument("--dropout", type=float, default=0.25)
    parser.add_argument("--l2-regularization", type=float, default=1e-4)
    parser.add_argument("--learning-rate", type=float, default=1e-3)
    parser.add_argument(
        "--allow-synthetic-smoke",
        action="store_true",
        help="Permit fixture training; metrics remain explicitly non-reportable",
    )
    parser.add_argument("--verbose", type=int, choices=(0, 1, 2), default=1)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.epochs < 1 or args.batch_size < 1 or args.patience < 1:
        print("Training error: epochs, batch-size, and patience must be positive")
        return 2
    if args.output_directory.exists():
        print(
            "Training error: output directory already exists; "
            "use a new versioned directory"
        )
        return 2
    try:
        supplied_vocabulary = _load_vocabulary(args.vocabulary)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"Vocabulary error: {exc}")
        return 2

    recordings = load_recordings(args.csv, expected_labels=supplied_vocabulary)
    if any(not recording.report.is_valid for recording in recordings):
        print(
            json.dumps(
                {
                    "error": "recording_validation_failed",
                    "recordings": [
                        recording.report.to_dict() for recording in recordings
                    ],
                },
                indent=2,
                sort_keys=True,
            )
        )
        return 2
    try:
        examples = prepare_examples(
            recordings,
            window_samples=args.window_samples,
            target_rate_hz=args.target_rate_hz,
        )
        data_origin = _origin(examples)
        if data_origin == "real" and supplied_vocabulary is None:
            raise ValueError(
                "real-data training requires an approved --vocabulary file"
            )
        if data_origin == "synthetic_fixture" and not args.allow_synthetic_smoke:
            raise ValueError(
                "synthetic fixture training requires --allow-synthetic-smoke"
            )
        vocabulary = resolve_vocabulary(examples, supplied_vocabulary)
        if args.split_manifest is None:
            split_manifest = create_split_manifest(
                examples,
                data_version=args.data_version,
                strategy=args.split_strategy,
                seed=args.seed,
                validation_fraction=args.validation_fraction,
                test_fraction=args.test_fraction,
            )
        else:
            split_manifest = SplitManifest.read(args.split_manifest)
            if split_manifest.data_version != args.data_version:
                raise ValueError(
                    "split manifest data_version does not match --data-version"
                )
            problems = validate_split_manifest(split_manifest, examples)
            if problems:
                raise ValueError("invalid split manifest: " + "; ".join(problems))
        grouped = examples_by_split(examples, split_manifest)
        _require_usable_splits(grouped, vocabulary)
        standardizer = SequenceStandardizer.fit(grouped["train"])
    except ValueError as exc:
        print(f"Dataset error: {exc}")
        return 2

    args.output_directory.mkdir(parents=True)
    split_manifest.write(args.output_directory / "split_manifest.json")
    (args.output_directory / "quality_reports.json").write_text(
        json.dumps(
            [recording.report.to_dict() for recording in recordings],
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    try:
        tf.config.experimental.enable_op_determinism()
    except (AttributeError, RuntimeError):
        # TensorFlow rejects changing this after runtime initialization. Seeded
        # model construction still applies; metadata keeps the requested seed.
        pass

    summaries: list[dict[str, object]] = []
    for architecture in dict.fromkeys(args.architectures):
        try:
            summaries.append(
                _train_candidate(
                    architecture=architecture,
                    grouped=grouped,
                    vocabulary=vocabulary,
                    standardizer=standardizer,
                    split_manifest=split_manifest,
                    source_csvs=args.csv,
                    output_directory=args.output_directory / architecture,
                    target_rate_hz=args.target_rate_hz,
                    window_samples=args.window_samples,
                    data_origin=data_origin,
                    seed=args.seed,
                    epochs=args.epochs,
                    batch_size=args.batch_size,
                    patience=args.patience,
                    conv_filters=args.conv_filters,
                    recurrent_units=args.recurrent_units,
                    dense_units=args.dense_units,
                    dropout=args.dropout,
                    l2_regularization=args.l2_regularization,
                    learning_rate=args.learning_rate,
                    verbose=args.verbose,
                )
            )
        except (OSError, RuntimeError, TypeError, ValueError) as exc:
            print(f"Training error for {architecture}: {exc}")
            return 2

    summary = {
        "data_origin": data_origin,
        "accuracy_reporting_allowed": data_origin == "real",
        "final_accuracy_claim_ready": False,
        "final_accuracy_claim_status": "requires_dataset_protocol_and_split_review",
        "data_version": args.data_version,
        "vocabulary_version": examples[0].vocabulary_version,
        "vocabulary": list(vocabulary),
        "split_manifest": str(args.output_directory / "split_manifest.json"),
        "candidates": summaries,
        "selection_status": "not_selected_requires_same_split_real_data_comparison",
    }
    rendered = json.dumps(summary, indent=2, sort_keys=True)
    (args.output_directory / "training_summary.json").write_text(
        rendered + "\n", encoding="utf-8"
    )
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
