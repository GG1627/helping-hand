"""Model-ready word sequences, deterministic splits, and train-only scaling.

This module turns validated complete trials into fixed-size arrays. It keeps the
trial as the indivisible split unit and records signer/orientation metadata for
later evaluation. Synthetic fixtures are permitted for tests and smoke runs,
but cannot be mixed with real recordings.
"""

from __future__ import annotations

import hashlib
import json
import math
import random
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Mapping, Sequence

import numpy as np

try:
    from .word_data import (
        DEFAULT_TARGET_RATE_HZ,
        FEATURE_COLUMNS,
        LoadedRecording,
        fixed_window,
        resample_trial,
    )
except ImportError:  # Direct execution from backend/.
    from word_data import (  # type: ignore[no-redef]
        DEFAULT_TARGET_RATE_HZ,
        FEATURE_COLUMNS,
        LoadedRecording,
        fixed_window,
        resample_trial,
    )


SPLIT_SCHEMA_VERSION = "word-split-v1"
SPLIT_NAMES = ("train", "validation", "test")
SPLIT_STRATEGIES = ("user_dependent", "user_independent")


@dataclass(frozen=True)
class SequenceExample:
    """One complete, fixed-size trial plus evaluation metadata."""

    session_id: str
    trial_id: str
    word: str
    signer_id: str
    orientation_condition: str
    schema_version: str
    vocabulary_version: str
    data_origin: str
    target_rate_hz: float
    feature_columns: tuple[str, ...]
    values: np.ndarray
    source_sample_count: int
    valid_sample_count: int
    resampled_sample_count: int
    trimmed_samples: int
    padded_samples: int

    @property
    def trial_key(self) -> str:
        return f"{self.session_id}/{self.trial_id}"


@dataclass(frozen=True)
class SplitAssignment:
    """A deterministic assignment for one complete trial."""

    session_id: str
    trial_id: str
    word: str
    signer_id: str
    orientation_condition: str
    split: str

    @property
    def trial_key(self) -> str:
        return f"{self.session_id}/{self.trial_id}"


@dataclass(frozen=True)
class SplitManifest:
    """Versioned trial assignments used by every model candidate."""

    schema_version: str
    data_version: str
    vocabulary_version: str
    strategy: str
    seed: int
    validation_fraction: float
    test_fraction: float
    assignments: tuple[SplitAssignment, ...]

    def to_dict(self) -> dict[str, object]:
        split_counts = {
            name: sum(item.split == name for item in self.assignments)
            for name in SPLIT_NAMES
        }
        return {
            "schema_version": self.schema_version,
            "data_version": self.data_version,
            "vocabulary_version": self.vocabulary_version,
            "strategy": self.strategy,
            "seed": self.seed,
            "validation_fraction": self.validation_fraction,
            "test_fraction": self.test_fraction,
            "trial_count": len(self.assignments),
            "split_counts": split_counts,
            "assignments": [asdict(item) for item in self.assignments],
        }

    def write(self, path: str | Path) -> Path:
        output = Path(path)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(self.to_dict(), indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        return output

    @classmethod
    def from_dict(cls, value: Mapping[str, object]) -> "SplitManifest":
        raw_assignments = value.get("assignments")
        if not isinstance(raw_assignments, list):
            raise ValueError("split manifest assignments must be a list")
        assignments: list[SplitAssignment] = []
        for raw in raw_assignments:
            if not isinstance(raw, dict):
                raise ValueError("each split assignment must be an object")
            try:
                assignments.append(
                    SplitAssignment(
                        session_id=str(raw["session_id"]),
                        trial_id=str(raw["trial_id"]),
                        word=str(raw["word"]),
                        signer_id=str(raw["signer_id"]),
                        orientation_condition=str(raw["orientation_condition"]),
                        split=str(raw["split"]),
                    )
                )
            except KeyError as exc:
                raise ValueError(
                    f"split assignment is missing {exc.args[0]!r}"
                ) from exc
        try:
            manifest = cls(
                schema_version=str(value["schema_version"]),
                data_version=str(value["data_version"]),
                vocabulary_version=str(value["vocabulary_version"]),
                strategy=str(value["strategy"]),
                seed=int(value["seed"]),
                validation_fraction=float(value["validation_fraction"]),
                test_fraction=float(value["test_fraction"]),
                assignments=tuple(assignments),
            )
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError(f"invalid split manifest header: {exc}") from exc
        _validate_manifest_header(manifest)
        return manifest

    @classmethod
    def read(cls, path: str | Path) -> "SplitManifest":
        try:
            value = json.loads(Path(path).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ValueError(f"cannot read split manifest: {exc}") from exc
        if not isinstance(value, dict):
            raise ValueError("split manifest root must be an object")
        return cls.from_dict(value)


@dataclass(frozen=True)
class SequenceStandardizer:
    """Per-feature standardization fitted on training sequences only."""

    feature_columns: tuple[str, ...]
    mean: tuple[float, ...]
    scale: tuple[float, ...]
    fitted_split: str = "train"

    @classmethod
    def fit(
        cls,
        examples: Sequence[SequenceExample],
        *,
        minimum_scale: float = 1e-6,
    ) -> "SequenceStandardizer":
        if not examples:
            raise ValueError("cannot fit a standardizer without training examples")
        if not math.isfinite(minimum_scale) or minimum_scale <= 0:
            raise ValueError("minimum_scale must be finite and positive")
        feature_columns = examples[0].feature_columns
        arrays = []
        for example in examples:
            if example.feature_columns != feature_columns:
                raise ValueError("all examples must use the same feature order")
            arrays.append(_validated_values(example.values, feature_columns))
        stacked = np.stack(arrays).astype(np.float64, copy=False)
        mean = np.mean(stacked, axis=(0, 1))
        standard_deviation = np.std(stacked, axis=(0, 1))
        scale = np.where(standard_deviation < minimum_scale, 1.0, standard_deviation)
        return cls(
            feature_columns=feature_columns,
            mean=tuple(float(value) for value in mean),
            scale=tuple(float(value) for value in scale),
        )

    def transform(self, values: np.ndarray) -> np.ndarray:
        array = _validated_values(values, self.feature_columns)
        mean = np.asarray(self.mean, dtype=np.float32)
        scale = np.asarray(self.scale, dtype=np.float32)
        if mean.shape != (array.shape[-1],) or scale.shape != mean.shape:
            raise ValueError("standardizer statistics do not match the feature count")
        return ((array - mean) / scale).astype(np.float32, copy=False)

    def to_dict(self) -> dict[str, object]:
        return {
            "method": "per_feature_standardization",
            "fitted_split": self.fitted_split,
            "feature_columns": list(self.feature_columns),
            "mean": list(self.mean),
            "scale": list(self.scale),
        }

    @classmethod
    def from_dict(cls, value: Mapping[str, object]) -> "SequenceStandardizer":
        if value.get("method") != "per_feature_standardization":
            raise ValueError("unsupported standardization method")
        raw_features = value.get("feature_columns")
        raw_mean = value.get("mean")
        raw_scale = value.get("scale")
        if not isinstance(raw_features, list) or not all(
            isinstance(item, str) for item in raw_features
        ):
            raise ValueError("standardizer feature_columns must be a string list")
        if not isinstance(raw_mean, list) or not isinstance(raw_scale, list):
            raise ValueError("standardizer mean and scale must be lists")
        try:
            feature_columns = tuple(raw_features)
            mean = tuple(float(item) for item in raw_mean)
            scale = tuple(float(item) for item in raw_scale)
        except (TypeError, ValueError) as exc:
            raise ValueError("invalid standardizer metadata") from exc
        if (
            not feature_columns
            or len(mean) != len(feature_columns)
            or len(scale) != len(mean)
        ):
            raise ValueError("standardizer metadata lengths do not match")
        if any(not math.isfinite(item) for item in (*mean, *scale)):
            raise ValueError("standardizer statistics must be finite")
        if any(item <= 0 for item in scale):
            raise ValueError("standardizer scales must be positive")
        return cls(
            feature_columns=feature_columns,
            mean=mean,
            scale=scale,
            fitted_split=str(value.get("fitted_split", "train")),
        )


def _validated_values(values: np.ndarray, feature_columns: Sequence[str]) -> np.ndarray:
    array = np.asarray(values, dtype=np.float32)
    if array.ndim != 2:
        raise ValueError("sequence values must have shape [timesteps, features]")
    if array.shape[1] != len(feature_columns):
        raise ValueError("sequence feature count does not match feature_columns")
    if array.shape[0] < 1 or not np.all(np.isfinite(array)):
        raise ValueError("sequence values must be non-empty and finite")
    return array


def _recording_origin(recording: LoadedRecording) -> str:
    if recording.manifest is None:
        return "unknown"
    origin = recording.manifest.get("data_origin")
    return str(origin) if origin in {"real", "synthetic_fixture"} else "unknown"


def prepare_examples(
    recordings: Iterable[LoadedRecording],
    *,
    window_samples: int,
    target_rate_hz: float = DEFAULT_TARGET_RATE_HZ,
) -> tuple[SequenceExample, ...]:
    """Convert validated recordings into fixed windows without crossing trials."""

    if window_samples < 1:
        raise ValueError("window_samples must be positive")
    if not math.isfinite(target_rate_hz) or target_rate_hz <= 0:
        raise ValueError("target_rate_hz must be finite and positive")

    prepared: list[SequenceExample] = []
    origins: set[str] = set()
    seen_trials: set[str] = set()
    for recording in recordings:
        if not recording.report.is_valid:
            raise ValueError(
                f"recording {recording.csv_path} has validation errors; "
                "refusing model preparation"
            )
        origin = _recording_origin(recording)
        if origin == "unknown":
            raise ValueError(
                f"recording {recording.csv_path} has no recognized "
                "data_origin manifest value"
            )
        origins.add(origin)
        for samples in recording.trials().values():
            resampled = resample_trial(samples, target_rate_hz=target_rate_hz)
            window = fixed_window(resampled, window_size=window_samples)
            first = samples[0]
            trial_key = f"{first.session_id}/{first.trial_id}"
            if trial_key in seen_trials:
                raise ValueError(f"duplicate trial identity {trial_key!r}")
            seen_trials.add(trial_key)
            prepared.append(
                SequenceExample(
                    session_id=first.session_id,
                    trial_id=first.trial_id,
                    word=first.word,
                    signer_id=first.signer_id,
                    orientation_condition=first.orientation_condition,
                    schema_version=first.schema_version,
                    vocabulary_version=first.vocabulary_version,
                    data_origin=origin,
                    target_rate_hz=target_rate_hz,
                    feature_columns=tuple(FEATURE_COLUMNS),
                    values=np.asarray(window.values, dtype=np.float32),
                    source_sample_count=len(samples),
                    valid_sample_count=sum(sample.packet_valid for sample in samples),
                    resampled_sample_count=len(resampled.values),
                    trimmed_samples=window.trimmed_samples,
                    padded_samples=window.padded_samples,
                )
            )

    if not prepared:
        raise ValueError("no trials were available for model preparation")
    if len(origins) != 1:
        raise ValueError("real recordings and synthetic fixtures must never be mixed")
    vocabulary_versions = {item.vocabulary_version for item in prepared}
    if len(vocabulary_versions) != 1:
        raise ValueError("all examples must use one vocabulary_version")
    return tuple(sorted(prepared, key=lambda item: item.trial_key))


def resolve_vocabulary(
    examples: Sequence[SequenceExample], labels: Iterable[str] | None = None
) -> tuple[str, ...]:
    """Resolve a stable output order and require coverage of every class."""

    observed = {example.word for example in examples}
    if labels is None:
        resolved = tuple(sorted(observed))
    else:
        resolved = tuple(label.strip() for label in labels if label.strip())
    if len(resolved) < 2:
        raise ValueError("word recognition requires at least two vocabulary labels")
    if len(set(resolved)) != len(resolved):
        raise ValueError("vocabulary labels must be unique")
    missing = set(resolved) - observed
    unknown = observed - set(resolved)
    if missing:
        raise ValueError(f"dataset has no examples for labels: {sorted(missing)!r}")
    if unknown:
        raise ValueError(
            f"dataset contains labels outside the vocabulary: {sorted(unknown)!r}"
        )
    return resolved


def _validate_manifest_header(manifest: SplitManifest) -> None:
    if manifest.schema_version != SPLIT_SCHEMA_VERSION:
        raise ValueError(f"split schema_version must be {SPLIT_SCHEMA_VERSION!r}")
    if manifest.strategy not in SPLIT_STRATEGIES:
        raise ValueError(f"unsupported split strategy {manifest.strategy!r}")
    if not manifest.data_version or not manifest.vocabulary_version:
        raise ValueError("data_version and vocabulary_version are required")
    if (
        not math.isfinite(manifest.validation_fraction)
        or not math.isfinite(manifest.test_fraction)
        or manifest.validation_fraction < 0
        or manifest.test_fraction < 0
        or manifest.validation_fraction + manifest.test_fraction >= 1
    ):
        raise ValueError(
            "validation/test fractions must be nonnegative and sum below one"
        )


def _allocation_counts(
    count: int, validation_fraction: float, test_fraction: float
) -> dict[str, int]:
    fractions = {
        "train": 1.0 - validation_fraction - test_fraction,
        "validation": validation_fraction,
        "test": test_fraction,
    }
    exact = {name: count * fraction for name, fraction in fractions.items()}
    result = {name: int(math.floor(value)) for name, value in exact.items()}
    remaining = count - sum(result.values())
    priority = {"train": 0, "validation": 1, "test": 2}
    order = sorted(
        SPLIT_NAMES,
        key=lambda name: (-(exact[name] - result[name]), priority[name]),
    )
    for name in order[:remaining]:
        result[name] += 1

    active = [name for name in SPLIT_NAMES if fractions[name] > 0]
    if count >= len(active):
        for empty in (name for name in active if result[name] == 0):
            donors = sorted(
                (name for name in active if result[name] > 1),
                key=lambda name: (-result[name], priority[name]),
            )
            if donors:
                result[donors[0]] -= 1
                result[empty] += 1
    return result


def _stable_shuffle(
    examples: Sequence[SequenceExample], *, seed: int, context: str
) -> list[SequenceExample]:
    ordered = sorted(examples, key=lambda item: item.trial_key)
    digest = hashlib.sha256(f"{seed}:{context}".encode("utf-8")).digest()
    rng = random.Random(int.from_bytes(digest[:8], "big"))
    rng.shuffle(ordered)
    return ordered


def create_split_manifest(
    examples: Sequence[SequenceExample],
    *,
    data_version: str,
    strategy: str,
    seed: int = 7,
    validation_fraction: float = 0.2,
    test_fraction: float = 0.2,
) -> SplitManifest:
    """Create deterministic trial- or signer-grouped split assignments."""

    if not examples:
        raise ValueError("cannot split an empty dataset")
    vocabulary_versions = {item.vocabulary_version for item in examples}
    if len(vocabulary_versions) != 1:
        raise ValueError("all examples must use one vocabulary_version")
    manifest = SplitManifest(
        schema_version=SPLIT_SCHEMA_VERSION,
        data_version=data_version,
        vocabulary_version=next(iter(vocabulary_versions)),
        strategy=strategy,
        seed=seed,
        validation_fraction=validation_fraction,
        test_fraction=test_fraction,
        assignments=(),
    )
    _validate_manifest_header(manifest)

    split_by_key: dict[str, str] = {}
    if strategy == "user_dependent":
        groups: dict[tuple[str, str], list[SequenceExample]] = defaultdict(list)
        for example in examples:
            groups[(example.signer_id, example.word)].append(example)
        for (signer_id, word), group in sorted(groups.items()):
            counts = _allocation_counts(len(group), validation_fraction, test_fraction)
            ordered = _stable_shuffle(group, seed=seed, context=f"{signer_id}:{word}")
            offset = 0
            for split in SPLIT_NAMES:
                for example in ordered[offset : offset + counts[split]]:
                    split_by_key[example.trial_key] = split
                offset += counts[split]
    else:
        by_signer: dict[str, list[SequenceExample]] = defaultdict(list)
        for example in examples:
            by_signer[example.signer_id].append(example)
        signer_count = len(by_signer)
        active_split_count = 1 + int(validation_fraction > 0) + int(test_fraction > 0)
        if signer_count < active_split_count:
            raise ValueError(
                "user-independent splitting needs at least one signer per active split"
            )
        counts = _allocation_counts(signer_count, validation_fraction, test_fraction)
        signers = sorted(by_signer)
        digest = hashlib.sha256(f"{seed}:signers".encode("utf-8")).digest()
        random.Random(int.from_bytes(digest[:8], "big")).shuffle(signers)
        offset = 0
        for split in SPLIT_NAMES:
            for signer_id in signers[offset : offset + counts[split]]:
                for example in by_signer[signer_id]:
                    split_by_key[example.trial_key] = split
            offset += counts[split]

    assignments = tuple(
        SplitAssignment(
            session_id=example.session_id,
            trial_id=example.trial_id,
            word=example.word,
            signer_id=example.signer_id,
            orientation_condition=example.orientation_condition,
            split=split_by_key[example.trial_key],
        )
        for example in sorted(examples, key=lambda item: item.trial_key)
    )
    completed = SplitManifest(
        schema_version=manifest.schema_version,
        data_version=manifest.data_version,
        vocabulary_version=manifest.vocabulary_version,
        strategy=manifest.strategy,
        seed=manifest.seed,
        validation_fraction=manifest.validation_fraction,
        test_fraction=manifest.test_fraction,
        assignments=assignments,
    )
    problems = validate_split_manifest(completed, examples)
    if problems:
        raise ValueError("invalid generated split manifest: " + "; ".join(problems))
    return completed


def validate_split_manifest(
    manifest: SplitManifest, examples: Sequence[SequenceExample]
) -> tuple[str, ...]:
    """Return leakage, coverage, and metadata problems without altering a split."""

    problems: list[str] = []
    try:
        _validate_manifest_header(manifest)
    except ValueError as exc:
        problems.append(str(exc))
    expected = {example.trial_key: example for example in examples}
    actual: dict[str, SplitAssignment] = {}
    for assignment in manifest.assignments:
        if assignment.trial_key in actual:
            problems.append(f"duplicate assignment for {assignment.trial_key}")
            continue
        actual[assignment.trial_key] = assignment
        if assignment.split not in SPLIT_NAMES:
            problems.append(
                f"unsupported split {assignment.split!r} for {assignment.trial_key}"
            )
        example = expected.get(assignment.trial_key)
        if example is not None:
            for name in ("word", "signer_id", "orientation_condition"):
                if getattr(assignment, name) != getattr(example, name):
                    problems.append(f"{name} mismatch for {assignment.trial_key}")
    missing = set(expected) - set(actual)
    extra = set(actual) - set(expected)
    if missing:
        problems.append(f"missing trial assignments: {sorted(missing)!r}")
    if extra:
        problems.append(f"unknown trial assignments: {sorted(extra)!r}")
    if examples:
        versions = {item.vocabulary_version for item in examples}
        if versions != {manifest.vocabulary_version}:
            problems.append("split vocabulary_version does not match the examples")
    if manifest.strategy == "user_independent":
        signer_splits: dict[str, set[str]] = defaultdict(set)
        for assignment in manifest.assignments:
            signer_splits[assignment.signer_id].add(assignment.split)
        leaking = {
            signer: sorted(splits)
            for signer, splits in signer_splits.items()
            if len(splits) > 1
        }
        if leaking:
            problems.append(f"signers cross user-independent splits: {leaking!r}")
    return tuple(problems)


def examples_by_split(
    examples: Sequence[SequenceExample], manifest: SplitManifest
) -> dict[str, tuple[SequenceExample, ...]]:
    """Apply a validated manifest and return examples grouped by split."""

    problems = validate_split_manifest(manifest, examples)
    if problems:
        raise ValueError("invalid split manifest: " + "; ".join(problems))
    assignment_by_key = {
        assignment.trial_key: assignment.split for assignment in manifest.assignments
    }
    grouped: dict[str, list[SequenceExample]] = {name: [] for name in SPLIT_NAMES}
    for example in examples:
        grouped[assignment_by_key[example.trial_key]].append(example)
    return {
        name: tuple(sorted(items, key=lambda item: item.trial_key))
        for name, items in grouped.items()
    }


def model_arrays(
    examples: Sequence[SequenceExample],
    vocabulary: Sequence[str],
    standardizer: SequenceStandardizer,
) -> tuple[np.ndarray, np.ndarray]:
    """Stack standardized sequences and encode labels using a fixed order."""

    if not examples:
        raise ValueError("cannot build model arrays from an empty split")
    label_indexes = {label: index for index, label in enumerate(vocabulary)}
    try:
        labels = np.asarray(
            [label_indexes[example.word] for example in examples], dtype=np.int64
        )
    except KeyError as exc:
        raise ValueError(f"label {exc.args[0]!r} is not in the vocabulary") from exc
    values = np.stack(
        [standardizer.transform(example.values) for example in examples]
    ).astype(np.float32, copy=False)
    return values, labels
