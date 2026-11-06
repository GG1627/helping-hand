"""Bounded raw-feature perturbations for descendants of training trials only.

Never writes recordings or estimates limits from validation/test data. No motion
warping, axis rotation, label synthesis, calibration, or missing-channel filling.
"""
from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import math
from pathlib import Path
from types import MappingProxyType
from typing import Mapping, Sequence

import numpy as np

SCHEMA = "training-augmentation-v1"


@dataclass(frozen=True)
class AugmentationConfig:
    copies_per_trial: int = 0
    seed: int = 7
    noise_bounds: Mapping[str, float] = field(default_factory=dict)
    offset_bounds: Mapping[str, float] = field(default_factory=dict)
    measurement_reference: str = ""

    def __post_init__(self):
        if type(self.copies_per_trial) is not int or not 0 <= self.copies_per_trial <= 8:
            raise ValueError("copies_per_trial must be an integer from 0 through 8")
        if type(self.seed) is not int or not 0 <= self.seed < 2**32:
            raise ValueError("augmentation seed must be an unsigned 32-bit integer")
        for name in ("noise_bounds", "offset_bounds"):
            raw = getattr(self, name)
            if not isinstance(raw, Mapping) or not all(
                isinstance(key, str) and isinstance(value, (int, float)) and not isinstance(value, bool)
                and math.isfinite(value) and value >= 0 for key, value in raw.items()
            ):
                raise ValueError(f"{name} must map feature names to finite nonnegative limits")
            object.__setattr__(self, name, MappingProxyType({key: float(value) for key, value in raw.items()}))
        if not isinstance(self.measurement_reference, str):
            raise ValueError("measurement_reference must be text")
        if self.copies_per_trial and (not self.measurement_reference.strip() or
                not any(v > 0 for v in (*self.noise_bounds.values(), *self.offset_bounds.values()))):
            raise ValueError("enabled augmentation needs explicit nonzero limits and a measurement_reference")

    def to_dict(self):
        return {"schema_version": SCHEMA, "copies_per_trial": self.copies_per_trial,
                "seed": self.seed, "noise_bounds": dict(self.noise_bounds),
                "offset_bounds": dict(self.offset_bounds), "measurement_reference": self.measurement_reference}

    @classmethod
    def read(cls, path: Path | None):
        if path is None:
            return cls()
        value = json.loads(path.read_text(encoding="utf-8"))
        allowed = {"schema_version", "copies_per_trial", "seed", "noise_bounds", "offset_bounds", "measurement_reference"}
        if not isinstance(value, dict) or value.get("schema_version") != SCHEMA or set(value) - allowed:
            raise ValueError("unsupported augmentation configuration")
        return cls(**{key: value[key] for key in allowed - {"schema_version"} if key in value})


@dataclass(frozen=True)
class TrainingTrial:
    key: str
    label: str
    values: np.ndarray
    padded_samples: int = 0


@dataclass(frozen=True)
class TrainingDescendant:
    parent_key: str
    label: str
    copy_index: int
    values: np.ndarray
    weight_multiplier: float


def augment_training_trials(
    trials: Sequence[TrainingTrial], *, feature_columns: Sequence[str],
    split_assignments: Mapping[str, str], config: AugmentationConfig,
    data_origin: str,
) -> tuple[tuple[TrainingDescendant, ...], dict]:
    """Generate only from explicitly train-assigned parents, retaining originals.

    Stable per-parent seeds make candidates/orderings reproducible. Edge padding
    is stripped before perturbation and recreated afterward, not independently
    jittered into a synthetic motion tail. Parent total weight is conserved.
    """
    if data_origin not in {"real", "synthetic_fixture"}:
        raise ValueError("declare parent recording origin")
    columns = tuple(feature_columns)
    if not trials or not columns or len(set(columns)) != len(columns):
        raise ValueError("training trials and unique feature names are required")
    if (set(config.noise_bounds) | set(config.offset_bounds)) - set(columns):
        raise ValueError("augmentation limits name features outside this model layout")
    if len({trial.key for trial in trials}) != len(trials):
        raise ValueError("duplicate augmentation parent identity")
    noise = np.array([config.noise_bounds.get(key, 0) for key in columns], dtype=np.float64)
    offset = np.array([config.offset_bounds.get(key, 0) for key in columns], dtype=np.float64)
    descendants, records = [], []
    for trial in trials:
        if split_assignments.get(trial.key) != "train":
            raise ValueError(f"{trial.key}: only training parents may be augmented")
        values = np.array(trial.values, dtype=np.float32, copy=True)
        if (values.ndim != 2 or values.shape[1] != len(columns) or not len(values)
                or not np.isfinite(values).all()):
            raise ValueError("training features must be finite complete matrices")
        if type(trial.padded_samples) is not int or not 0 <= trial.padded_samples < len(values):
            raise ValueError("invalid padding provenance")
        left = trial.padded_samples // 2
        right = trial.padded_samples - left
        observed = values[left:len(values) - right if right else len(values)]
        if ((left and not np.all(values[:left] == observed[0])) or
                (right and not np.all(values[-right:] == observed[-1]))):
            raise ValueError("padding provenance does not match edge-padded observations")
        source_digest = hashlib.sha256(values.astype('<f4').tobytes()).hexdigest()
        for index in range(config.copies_per_trial + 1):
            seed_digest = hashlib.sha256(json.dumps([SCHEMA, config.seed, trial.key, index]).encode()).hexdigest()
            if index:
                rng = np.random.default_rng(int(seed_digest[:16], 16))
                perturbed = observed.astype(np.float64) + rng.uniform(-offset, offset)
                perturbed += rng.uniform(-noise, noise, size=observed.shape)
                generated = np.pad(perturbed.astype(np.float32), ((left, right), (0, 0)), mode='edge')
            else:
                generated = values.copy()
            if not np.isfinite(generated).all():
                raise ValueError("augmentation produced nonfinite inputs; reduce limits")
            for f, name in enumerate(columns):
                if name.startswith('flex_') and name.endswith('_raw') and (
                        (generated[:, f] < 0).any() or (generated[:, f] > 4095).any()):
                    raise ValueError(f"{trial.key}: augmentation leaves the 12-bit ADC range; reduce limits")
            generated.flags.writeable = False
            multiplier = 1 / (config.copies_per_trial + 1)
            descendants.append(TrainingDescendant(trial.key, trial.label, index, generated, multiplier))
            records.append({"parent_trial": trial.key, "label": trial.label, "copy_index": index,
                            "origin": "augmented_training" if index else data_origin,
                            "parent_split": "train", "seed_digest": seed_digest if index else None,
                            "parent_matrix_sha256": source_digest,
                            "matrix_sha256": hashlib.sha256(generated.astype('<f4').tobytes()).hexdigest(),
                            "rows": len(generated), "padded_samples": trial.padded_samples,
                            "weight_multiplier": multiplier})
    manifest = {"schema_version": "training-augmentation-manifest-v1", "config": config.to_dict(),
                "enabled": bool(config.copies_per_trial),
                "limits_status": "operator_declared_requires_real_capture_validation",
                "feature_columns": list(columns), "parent_data_origin": data_origin,
                "independent_training_trials": len(trials), "generated_training_descendants": len(trials) * config.copies_per_trial,
                "validation_or_test_augmented": False, "scaler_fit": "original_training_only",
                "independent_evaluation_evidence_added": False, "records": records}
    return tuple(descendants), manifest
