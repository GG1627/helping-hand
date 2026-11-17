"""Offline static-finger correction experiment, independent of ML inference.

No real sign reference values are supplied. References must describe complete
pose variants and the matching physical glove/mount/calibration. Noise and
timing parameters must be chosen from measurements before any live use.
"""

from dataclasses import dataclass
import math


def finite(value):
    return type(value) in (int, float) and math.isfinite(value)


@dataclass(frozen=True)
class Band:
    low: float
    high: float

    def __post_init__(self):
        if not finite(self.low) or not finite(self.high) or self.low > self.high:
            raise ValueError("invalid band")

    def error(self, value):
        # Positive asks for more bend; negative asks for less bend.
        return self.low - value if value < self.low else self.high - value if value > self.high else 0.0


@dataclass(frozen=True)
class Channel:
    straight_raw: float
    bent_raw: float
    healthy_raw: Band

    def __post_init__(self):
        if not all(finite(v) and 0 < v < 4095 for v in (self.straight_raw, self.bent_raw)):
            raise ValueError("invalid endpoint")
        if self.straight_raw == self.bent_raw or not isinstance(self.healthy_raw, Band):
            raise ValueError("missing span or health band")
        if not 0 < self.healthy_raw.low <= min(self.straight_raw, self.bent_raw):
            raise ValueError("health band excludes endpoint")
        if not max(self.straight_raw, self.bent_raw) <= self.healthy_raw.high < 4095:
            raise ValueError("health band excludes endpoint")

    def bend(self, raw):
        return (raw - self.straight_raw) / (self.bent_raw - self.straight_raw)


@dataclass(frozen=True)
class Reference:
    target: str
    glove_id: str
    mount_id: str
    calibration_id: str
    provenance: str
    capture_ids: tuple[str, ...]
    channels: tuple[Channel, ...]
    variants: tuple[tuple[Band, ...], ...]

    def __post_init__(self):
        if not all(isinstance(v, str) and v.strip() for v in
                   (self.target, self.glove_id, self.mount_id, self.calibration_id)):
            raise ValueError("missing reference identity")
        if self.provenance not in ("synthetic_fixture", "reviewed_measurements"):
            raise ValueError("invalid provenance")
        if type(self.capture_ids) is not tuple or not self.capture_ids or not all(
                isinstance(v, str) and v.strip() for v in self.capture_ids):
            raise ValueError("missing source captures")
        if type(self.channels) is not tuple or len(self.channels) != 5 or not all(
                isinstance(v, Channel) for v in self.channels):
            raise ValueError("five calibrated channels required")
        if type(self.variants) is not tuple or not 1 <= len(self.variants) <= 8:
            raise ValueError("invalid variant count")
        for variant in self.variants:
            if type(variant) is not tuple or len(variant) != 5 or not all(
                    isinstance(b, Band) and 0 <= b.low <= b.high <= 1 for b in variant):
                raise ValueError("each variant needs five bend bands in [0, 1]")

    @property
    def identity(self):
        return (self.target, self.glove_id, self.mount_id, self.calibration_id)


@dataclass(frozen=True)
class Policy:
    enter_margin: float
    exit_margin: float
    persistence_ms: int
    cooldown_ms: int
    maximum_age_ms: int
    maximum_gap_ms: int
    minimum_span_raw: float
    error_scales: tuple[float, ...]

    def __post_init__(self):
        if not all(finite(v) for v in (self.enter_margin, self.exit_margin, self.minimum_span_raw)):
            raise ValueError("invalid margin or span")
        if not 0 <= self.exit_margin < self.enter_margin <= 1 or self.minimum_span_raw <= 0:
            raise ValueError("invalid hysteresis or span")
        for value in (self.persistence_ms, self.cooldown_ms, self.maximum_age_ms, self.maximum_gap_ms):
            if type(value) is not int or value <= 0:
                raise ValueError("positive integer timing required")
        if type(self.error_scales) is not tuple or len(self.error_scales) != 5 or not all(
                finite(v) and v > 0 for v in self.error_scales):
            raise ValueError("five positive error scales required")


@dataclass(frozen=True)
class Observation:
    identity: tuple[str, str, str, str]
    sequence: int
    device_ms: int
    received_ms: int
    raw: tuple[int | None, ...]
    channel_usable: tuple[bool, ...]


@dataclass(frozen=True)
class Decision:
    reason: str
    finger: int | None = None
    direction: str | None = None
    emit: bool = False
    variant: int | None = None


class StaticEvaluator:
    def __init__(self, reference, policy, *, allow_synthetic=False):
        if not isinstance(reference, Reference) or not isinstance(policy, Policy):
            raise ValueError("explicit reference and policy required")
        if reference.provenance == "synthetic_fixture" and not allow_synthetic:
            raise ValueError("synthetic references require explicit offline opt-in")
        if any(abs(c.bent_raw - c.straight_raw) < policy.minimum_span_raw for c in reference.channels):
            raise ValueError("insufficient calibrated span")
        self.reference = reference
        self.policy = policy
        self.reset()

    def reset(self):
        """Explicit new stream/practice context; never apply this to model inputs."""
        self._sequence = self._device_ms = self._received_ms = self._now = None
        self._last_cue_ms = None
        self._clock_fault = False
        self._clear_candidate()

    def _clear_candidate(self):
        self._candidate = self._since = self._variant = None

    def _reject(self, reason):
        self._clear_candidate()
        return Decision(reason)

    def evaluate(self, sample, now_ms):
        p = self.policy
        if type(now_ms) is not int or now_ms < 0:
            return self._reject("invalid_clock")
        if self._now is not None and now_ms < self._now:
            self._clock_fault = True
        if self._clock_fault:
            return self._reject("clock_reset_requires_reset")
        self._now = now_ms
        if not isinstance(sample, Observation):
            return self._reject("invalid_observation")
        if sample.identity != self.reference.identity:
            return self._reject("reference_context_mismatch")
        if not all(type(v) is int and v >= 0 for v in
                   (sample.sequence, sample.device_ms, sample.received_ms)):
            return self._reject("invalid_sample_clock")
        if not 0 <= now_ms - sample.received_ms <= p.maximum_age_ms:
            return self._reject("stale_or_future_sample")
        if type(sample.raw) is not tuple or type(sample.channel_usable) is not tuple:
            return self._reject("unusable_channels")
        if len(sample.raw) != 5 or len(sample.channel_usable) != 5 or any(
                v is not True for v in sample.channel_usable):
            return self._reject("unusable_channels")
        for raw, channel in zip(sample.raw, self.reference.channels):
            if type(raw) is not int or not 0 < raw < 4095:
                return self._reject("missing_or_saturated_channel")
            if not channel.healthy_raw.low <= raw <= channel.healthy_raw.high:
                return self._reject("outside_measured_health_band")
        if self._sequence is not None:
            if (sample.sequence <= self._sequence or sample.device_ms <= self._device_ms
                    or sample.received_ms < self._received_ms):
                return self._reject("duplicate_or_reordered_sample")
            gap = (sample.sequence != self._sequence + 1
                   or sample.device_ms - self._device_ms > p.maximum_gap_ms
                   or sample.received_ms - self._received_ms > p.maximum_gap_ms)
        else:
            gap = False
        self._sequence, self._device_ms, self._received_ms = (
            sample.sequence, sample.device_ms, sample.received_ms)
        if gap:
            return self._reject("stream_gap")
        bends = [c.bend(raw) for c, raw in zip(self.reference.channels, sample.raw)]
        errors = [tuple(b.error(v) for b, v in zip(variant, bends))
                  for variant in self.reference.variants]
        # Any complete acceptable variant wins. Never combine individual fingers
        # from incompatible variants into an invented acceptable pose.
        if any(all(abs(e) <= p.exit_margin for e in variant) for variant in errors):
            return self._reject("within_reference")
        if self._variant is None:
            self._variant = min(range(len(errors)), key=lambda i: sum(
                (e / scale) ** 2 for e, scale in zip(errors[i], p.error_scales)))
        current = errors[self._variant]
        candidate = self._candidate
        if candidate is not None:
            finger, direction = candidate
            e = current[finger]
            if abs(e) <= p.exit_margin or (e > 0) != (direction == "bend"):
                candidate = None
        if candidate is None:
            eligible = [i for i, e in enumerate(current) if abs(e) > p.enter_margin]
            if not eligible:
                return self._reject("deadband")
            finger = max(eligible, key=lambda i: abs(current[i]) / p.error_scales[i])
            candidate = (finger, "bend" if current[finger] > 0 else "straighten")
        if candidate != self._candidate:
            self._candidate, self._since = candidate, sample.received_ms
        finger, direction = candidate
        if sample.received_ms - self._since < p.persistence_ms:
            return Decision("persisting", finger, direction, variant=self._variant)
        if self._last_cue_ms is not None and now_ms - self._last_cue_ms < p.cooldown_ms:
            return Decision("cooldown", finger, direction, variant=self._variant)
        self._last_cue_ms = now_ms
        return Decision("correction", finger, direction, True, self._variant)
