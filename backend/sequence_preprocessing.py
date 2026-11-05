"""Versioned raw-sensor preprocessing contract shared with Flutter.

No orientation fusion or calibration is implied by selecting a feature layout.
"""
from __future__ import annotations

from dataclasses import dataclass
import math

try:
    from .word_data import FEATURE_COLUMNS
except ImportError:
    from word_data import FEATURE_COLUMNS

PREPROCESSING_SCHEMA = "sequence-preprocessing-v1"
FEATURE_SETS = {
    "flex_imu6": tuple(FEATURE_COLUMNS),
    "flex_imu9": tuple(FEATURE_COLUMNS) + ("mx_ut", "my_ut", "mz_ut"),
}
WINDOW_POLICIES = ("center_trim_edge_pad", "reject_overlength_edge_pad")


@dataclass(frozen=True)
class SequencePreprocessing:
    window_samples: int = 96
    target_rate_hz: float = 40
    feature_set: str = "flex_imu6"
    window_policy: str = "center_trim_edge_pad"

    def __post_init__(self):
        if type(self.window_samples) is not int or not 4 <= self.window_samples <= 400:
            raise ValueError("window_samples must be an integer from 4 through 400")
        if not math.isfinite(self.target_rate_hz) or not 25 <= self.target_rate_hz <= 50:
            raise ValueError("target_rate_hz must be from 25 through 50")
        if self.feature_set not in FEATURE_SETS or self.window_policy not in WINDOW_POLICIES:
            raise ValueError("unsupported feature set or window policy")

    @property
    def feature_columns(self):
        return FEATURE_SETS[self.feature_set]

    def check_capture_length(self, count: int) -> None:
        if count > math.floor(self.target_rate_hz * 10):
            raise ValueError("gesture recording exceeds the runtime preparation limit")

    def to_dict(self):
        return {"schema_version": PREPROCESSING_SCHEMA,
                "window_samples": self.window_samples, "target_rate_hz": self.target_rate_hz,
                "feature_set": self.feature_set, "window_policy": self.window_policy}

    @classmethod
    def from_metadata(cls, metadata):
        value = metadata.get("preprocessing")
        if value is None:
            config = cls(window_samples=metadata["window_samples"],
                         target_rate_hz=metadata["target_rate_hz"])
        else:
            if not isinstance(value, dict) or value.get("schema_version") != PREPROCESSING_SCHEMA:
                raise ValueError("unsupported preprocessing schema")
            config = cls(**{key: value[key] for key in
                         ("window_samples", "target_rate_hz", "feature_set", "window_policy")})
        if (config.window_samples != metadata["window_samples"] or
                config.target_rate_hz != metadata["target_rate_hz"] or
                list(config.feature_columns) != metadata["feature_columns"] or
                list(config.feature_columns) != metadata["standardizer"]["feature_columns"]):
            raise ValueError("preprocessing conflicts with bundle shape, rate or feature order")
        return config
