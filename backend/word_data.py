"""Loading, validation, and deterministic preprocessing for word recordings.

This module does not train a model.  It preserves complete trials as the unit of
validation/preprocessing and treats synthetic fixtures as test data only.
"""

from __future__ import annotations

import csv
import json
import math
import re
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable, Mapping, Sequence


SCHEMA_VERSION = "word-sequence-v1"
DEFAULT_TARGET_RATE_HZ = 40.0
DEFAULT_MIN_PACKET_COUNT = 20
ALLOWED_ORIENTATIONS = frozenset(
    {"neutral", "pitch_up", "roll_left", "yaw_right"}
)
FEATURE_COLUMNS = (
    "flex_thumb_raw",
    "flex_index_raw",
    "flex_middle_raw",
    "flex_ring_raw",
    "flex_pinky_raw",
    "ax",
    "ay",
    "az",
    "gx",
    "gy",
    "gz",
)
REQUIRED_COLUMNS = (
    "schema_version",
    "session_id",
    "trial_id",
    "sample_index",
    "device_sequence",
    "device_timestamp_ms",
    "receive_timestamp_ms",
    "word",
    "vocabulary_version",
    "signer_id",
    "orientation_condition",
    "who",
    "ax",
    "ay",
    "az",
    "gx",
    "gy",
    "gz",
    "flex_thumb_raw",
    "flex_index_raw",
    "flex_middle_raw",
    "flex_ring_raw",
    "flex_pinky_raw",
    "raw_packet",
    "packet_valid",
)

_WORD_RE = re.compile(r"^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$")
_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")
_SIGNER_RE = re.compile(r"^signer_[A-Za-z0-9][A-Za-z0-9_-]*$")
_WHO_RE = re.compile(r"^0x[0-9A-Fa-f]{2}$")


@dataclass(frozen=True)
class QualityIssue:
    """One actionable validation finding."""

    severity: str
    code: str
    message: str
    row_number: int | None = None
    session_id: str | None = None
    trial_id: str | None = None


@dataclass(frozen=True)
class WordSample:
    """One parsed packet row from the word recording CSV."""

    schema_version: str
    session_id: str
    trial_id: str
    sample_index: int
    device_sequence: int
    device_timestamp_ms: int
    receive_timestamp_ms: int
    word: str
    vocabulary_version: str
    signer_id: str
    orientation_condition: str
    who: str
    ax: float
    ay: float
    az: float
    gx: float
    gy: float
    gz: float
    flex_thumb_raw: int
    flex_index_raw: int
    flex_middle_raw: int
    flex_ring_raw: int
    flex_pinky_raw: int
    raw_packet: str
    packet_valid: bool

    @property
    def features(self) -> tuple[float, ...]:
        return tuple(float(getattr(self, name)) for name in FEATURE_COLUMNS)


@dataclass(frozen=True)
class TrialSummary:
    """Quality statistics for a complete trial."""

    session_id: str
    trial_id: str
    word: str
    signer_id: str
    orientation_condition: str
    packet_count: int
    valid_packet_count: int
    duration_ms: int
    observed_rate_hz: float | None
    sensor_ranges: Mapping[str, tuple[float, float]]


@dataclass
class ValidationReport:
    """Validation issues and per-trial summaries."""

    source: str
    row_count: int = 0
    parsed_row_count: int = 0
    issues: list[QualityIssue] = field(default_factory=list)
    trials: list[TrialSummary] = field(default_factory=list)

    @property
    def is_valid(self) -> bool:
        return not any(issue.severity == "error" for issue in self.issues)

    @property
    def error_count(self) -> int:
        return sum(issue.severity == "error" for issue in self.issues)

    @property
    def warning_count(self) -> int:
        return sum(issue.severity == "warning" for issue in self.issues)

    def add(
        self,
        severity: str,
        code: str,
        message: str,
        *,
        row_number: int | None = None,
        session_id: str | None = None,
        trial_id: str | None = None,
    ) -> None:
        self.issues.append(
            QualityIssue(
                severity=severity,
                code=code,
                message=message,
                row_number=row_number,
                session_id=session_id,
                trial_id=trial_id,
            )
        )

    def to_dict(self) -> dict[str, object]:
        return {
            "source": self.source,
            "is_valid": self.is_valid,
            "row_count": self.row_count,
            "parsed_row_count": self.parsed_row_count,
            "error_count": self.error_count,
            "warning_count": self.warning_count,
            "issues": [asdict(issue) for issue in self.issues],
            "trials": [asdict(trial) for trial in self.trials],
        }


@dataclass(frozen=True)
class LoadedRecording:
    csv_path: Path
    manifest: Mapping[str, object] | None
    samples: tuple[WordSample, ...]
    report: ValidationReport

    def trials(self) -> dict[tuple[str, str], tuple[WordSample, ...]]:
        grouped: dict[tuple[str, str], list[WordSample]] = defaultdict(list)
        for sample in self.samples:
            grouped[(sample.session_id, sample.trial_id)].append(sample)
        return {key: tuple(value) for key, value in grouped.items()}


@dataclass(frozen=True)
class ResampledSequence:
    """A trial interpolated onto a fixed device-time clock."""

    session_id: str
    trial_id: str
    word: str
    schema_version: str
    vocabulary_version: str
    signer_id: str
    orientation_condition: str
    target_rate_hz: float
    relative_timestamps_ms: tuple[float, ...]
    values: tuple[tuple[float, ...], ...]


@dataclass(frozen=True)
class FixedWindowSequence:
    """A fixed-size sequence plus explicit trim/pad provenance."""

    sequence: ResampledSequence
    values: tuple[tuple[float, ...], ...]
    window_size: int
    trimmed_samples: int
    padded_samples: int


def _load_manifest(
    manifest_path: Path | None, report: ValidationReport
) -> Mapping[str, object] | None:
    if manifest_path is None:
        return None
    if not manifest_path.exists():
        report.add(
            "warning",
            "manifest_missing",
            f"Manifest not found at {manifest_path}.",
        )
        return None
    try:
        value = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        report.add("error", "manifest_invalid", f"Cannot read manifest: {exc}")
        return None
    if not isinstance(value, dict):
        report.add("error", "manifest_invalid", "Manifest root must be a JSON object.")
        return None
    return value


def _parse_int(
    row: Mapping[str, str],
    name: str,
    report: ValidationReport,
    row_number: int,
) -> int | None:
    raw = (row.get(name) or "").strip()
    try:
        return int(raw)
    except ValueError:
        report.add(
            "error",
            "invalid_numeric",
            f"{name} must be an integer; got {raw!r}.",
            row_number=row_number,
            session_id=row.get("session_id") or None,
            trial_id=row.get("trial_id") or None,
        )
        return None


def _parse_float(
    row: Mapping[str, str],
    name: str,
    report: ValidationReport,
    row_number: int,
) -> float | None:
    raw = (row.get(name) or "").strip()
    try:
        value = float(raw)
    except ValueError:
        value = math.nan
    if not math.isfinite(value):
        report.add(
            "error",
            "invalid_numeric",
            f"{name} must be a finite number; got {raw!r}.",
            row_number=row_number,
            session_id=row.get("session_id") or None,
            trial_id=row.get("trial_id") or None,
        )
        return None
    return value


def _parse_bool(
    row: Mapping[str, str], report: ValidationReport, row_number: int
) -> bool | None:
    raw = (row.get("packet_valid") or "").strip().lower()
    if raw in {"true", "1"}:
        return True
    if raw in {"false", "0"}:
        return False
    report.add(
        "error",
        "invalid_boolean",
        f"packet_valid must be true/false or 1/0; got {raw!r}.",
        row_number=row_number,
        session_id=row.get("session_id") or None,
        trial_id=row.get("trial_id") or None,
    )
    return None


def _validate_text_fields(
    row: Mapping[str, str],
    report: ValidationReport,
    row_number: int,
    expected_labels: frozenset[str] | None,
    allowed_orientations: frozenset[str],
) -> None:
    session_id = (row.get("session_id") or "").strip()
    trial_id = (row.get("trial_id") or "").strip()
    word = (row.get("word") or "").strip()
    signer_id = (row.get("signer_id") or "").strip()
    orientation = (row.get("orientation_condition") or "").strip()
    vocabulary_version = (row.get("vocabulary_version") or "").strip()
    who = (row.get("who") or "").strip()

    for name, value in (
        ("session_id", session_id),
        ("trial_id", trial_id),
        ("vocabulary_version", vocabulary_version),
    ):
        if not value or not _ID_RE.fullmatch(value):
            report.add(
                "error",
                "invalid_metadata",
                f"{name} is empty or contains unsupported characters: {value!r}.",
                row_number=row_number,
                session_id=session_id or None,
                trial_id=trial_id or None,
            )

    if not _WORD_RE.fullmatch(word):
        report.add(
            "error",
            "invalid_label",
            "word must be lowercase snake_case (for example, thank_you).",
            row_number=row_number,
            session_id=session_id or None,
            trial_id=trial_id or None,
        )
    elif expected_labels is not None and word not in expected_labels:
        report.add(
            "error",
            "unknown_label",
            f"word {word!r} is not in the supplied vocabulary.",
            row_number=row_number,
            session_id=session_id or None,
            trial_id=trial_id or None,
        )

    if not _SIGNER_RE.fullmatch(signer_id):
        report.add(
            "error",
            "invalid_signer_id",
            "signer_id must be pseudonymous and begin with 'signer_'.",
            row_number=row_number,
            session_id=session_id or None,
            trial_id=trial_id or None,
        )
    if orientation not in allowed_orientations:
        report.add(
            "error",
            "invalid_orientation",
            f"orientation_condition {orientation!r} is not allowed.",
            row_number=row_number,
            session_id=session_id or None,
            trial_id=trial_id or None,
        )
    if not _WHO_RE.fullmatch(who):
        report.add(
            "error",
            "invalid_who",
            f"who must use the firmware form 0xNN; got {who!r}.",
            row_number=row_number,
            session_id=session_id or None,
            trial_id=trial_id or None,
        )


def _sample_from_row(
    row: Mapping[str, str], report: ValidationReport, row_number: int
) -> WordSample | None:
    integer_names = (
        "sample_index",
        "device_sequence",
        "device_timestamp_ms",
        "receive_timestamp_ms",
        "flex_thumb_raw",
        "flex_index_raw",
        "flex_middle_raw",
        "flex_ring_raw",
        "flex_pinky_raw",
    )
    float_names = ("ax", "ay", "az", "gx", "gy", "gz")
    integers = {
        name: _parse_int(row, name, report, row_number) for name in integer_names
    }
    floats = {
        name: _parse_float(row, name, report, row_number) for name in float_names
    }
    packet_valid = _parse_bool(row, report, row_number)
    if any(value is None for value in integers.values()):
        return None
    if any(value is None for value in floats.values()) or packet_valid is None:
        return None

    for name in FEATURE_COLUMNS[:5]:
        value = integers[name]
        assert value is not None
        if not 0 <= value <= 4095:
            report.add(
                "warning",
                "flex_out_of_range",
                f"{name}={value} is outside the expected 12-bit ADC range.",
                row_number=row_number,
                session_id=row.get("session_id") or None,
                trial_id=row.get("trial_id") or None,
            )

    if not packet_valid:
        report.add(
            "warning",
            "invalid_packet",
            "The app marked this received packet invalid.",
            row_number=row_number,
            session_id=row.get("session_id") or None,
            trial_id=row.get("trial_id") or None,
        )

    return WordSample(
        schema_version=(row.get("schema_version") or "").strip(),
        session_id=(row.get("session_id") or "").strip(),
        trial_id=(row.get("trial_id") or "").strip(),
        sample_index=integers["sample_index"],  # type: ignore[arg-type]
        device_sequence=integers["device_sequence"],  # type: ignore[arg-type]
        device_timestamp_ms=integers["device_timestamp_ms"],  # type: ignore[arg-type]
        receive_timestamp_ms=integers["receive_timestamp_ms"],  # type: ignore[arg-type]
        word=(row.get("word") or "").strip(),
        vocabulary_version=(row.get("vocabulary_version") or "").strip(),
        signer_id=(row.get("signer_id") or "").strip(),
        orientation_condition=(row.get("orientation_condition") or "").strip(),
        who=(row.get("who") or "").strip(),
        ax=floats["ax"],  # type: ignore[arg-type]
        ay=floats["ay"],  # type: ignore[arg-type]
        az=floats["az"],  # type: ignore[arg-type]
        gx=floats["gx"],  # type: ignore[arg-type]
        gy=floats["gy"],  # type: ignore[arg-type]
        gz=floats["gz"],  # type: ignore[arg-type]
        flex_thumb_raw=integers["flex_thumb_raw"],  # type: ignore[arg-type]
        flex_index_raw=integers["flex_index_raw"],  # type: ignore[arg-type]
        flex_middle_raw=integers["flex_middle_raw"],  # type: ignore[arg-type]
        flex_ring_raw=integers["flex_ring_raw"],  # type: ignore[arg-type]
        flex_pinky_raw=integers["flex_pinky_raw"],  # type: ignore[arg-type]
        raw_packet=row.get("raw_packet") or "",
        packet_valid=packet_valid,
    )


def _check_manifest(
    manifest: Mapping[str, object] | None,
    samples: Sequence[WordSample],
    report: ValidationReport,
) -> None:
    if manifest is None:
        return
    if manifest.get("schema_version") != SCHEMA_VERSION:
        report.add(
            "error",
            "manifest_schema_mismatch",
            f"Manifest schema_version must be {SCHEMA_VERSION!r}.",
        )
    session_ids = {sample.session_id for sample in samples}
    manifest_session = manifest.get("session_id")
    if manifest_session is not None and session_ids and session_ids != {manifest_session}:
        report.add(
            "error",
            "manifest_session_mismatch",
            "Manifest session_id does not match every CSV row.",
        )
    data_origin = manifest.get("data_origin")
    if data_origin not in {"real", "synthetic_fixture"}:
        report.add(
            "warning",
            "data_origin_missing",
            "Manifest should identify data_origin as 'real' or 'synthetic_fixture'.",
        )


def _summarize_trials(
    samples: Sequence[WordSample],
    report: ValidationReport,
    min_packet_count: int,
    target_rate_hz: float,
    raw_trial_counts: Mapping[tuple[str, str], int],
) -> None:
    grouped: dict[tuple[str, str], list[WordSample]] = defaultdict(list)
    for sample in samples:
        grouped[(sample.session_id, sample.trial_id)].append(sample)

    metadata_names = (
        "schema_version",
        "word",
        "vocabulary_version",
        "signer_id",
        "orientation_condition",
        "who",
    )
    for (session_id, trial_id), trial in grouped.items():
        first = trial[0]
        for name in metadata_names:
            values = {getattr(sample, name) for sample in trial}
            if len(values) != 1:
                report.add(
                    "error",
                    "inconsistent_trial_metadata",
                    f"{name} changes within a trial: {sorted(values)!r}.",
                    session_id=session_id,
                    trial_id=trial_id,
                )

        sample_indexes = [sample.sample_index for sample in trial]
        if sample_indexes != list(range(len(trial))):
            report.add(
                "error",
                "sample_index_not_contiguous",
                "sample_index must start at zero and increase by one in CSV order.",
                session_id=session_id,
                trial_id=trial_id,
            )

        for previous, current in zip(trial, trial[1:]):
            if current.device_sequence <= previous.device_sequence:
                report.add(
                    "error",
                    "device_sequence_not_monotonic",
                    "device_sequence must increase strictly within a trial.",
                    session_id=session_id,
                    trial_id=trial_id,
                )
                break
            if current.device_sequence > previous.device_sequence + 1:
                report.add(
                    "warning",
                    "device_sequence_gap",
                    f"Missing {current.device_sequence - previous.device_sequence - 1} device packet(s).",
                    session_id=session_id,
                    trial_id=trial_id,
                )

        for field_name in ("device_timestamp_ms", "receive_timestamp_ms"):
            values = [getattr(sample, field_name) for sample in trial]
            if any(current < previous for previous, current in zip(values, values[1:])):
                report.add(
                    "error",
                    "timestamp_not_monotonic",
                    f"{field_name} moves backwards within the trial.",
                    session_id=session_id,
                    trial_id=trial_id,
                )
            elif any(current == previous for previous, current in zip(values, values[1:])):
                report.add(
                    "warning",
                    "duplicate_timestamp",
                    f"{field_name} contains equal adjacent values.",
                    session_id=session_id,
                    trial_id=trial_id,
                )

        valid_trial = [sample for sample in trial if sample.packet_valid]
        if len(valid_trial) < min_packet_count:
            report.add(
                "warning",
                "too_few_packets",
                f"Trial has {len(valid_trial)} valid packets; expected at least {min_packet_count}.",
                session_id=session_id,
                trial_id=trial_id,
            )

        duration_ms = max(0, trial[-1].receive_timestamp_ms - trial[0].receive_timestamp_ms)
        observed_rate_hz = None
        if len(trial) >= 2 and duration_ms > 0:
            observed_rate_hz = (len(trial) - 1) * 1000.0 / duration_ms
            if observed_rate_hz < target_rate_hz * 0.8:
                report.add(
                    "warning",
                    "packet_rate_low",
                    f"Observed {observed_rate_hz:.2f} Hz; target is {target_rate_hz:.2f} Hz.",
                    session_id=session_id,
                    trial_id=trial_id,
                )
            elif observed_rate_hz > target_rate_hz * 1.25:
                report.add(
                    "warning",
                    "packet_rate_high",
                    f"Observed {observed_rate_hz:.2f} Hz; target is {target_rate_hz:.2f} Hz.",
                    session_id=session_id,
                    trial_id=trial_id,
                )

        sensor_ranges = {
            name: (
                min(float(getattr(sample, name)) for sample in trial),
                max(float(getattr(sample, name)) for sample in trial),
            )
            for name in FEATURE_COLUMNS
        }
        report.trials.append(
            TrialSummary(
                session_id=session_id,
                trial_id=trial_id,
                word=first.word,
                signer_id=first.signer_id,
                orientation_condition=first.orientation_condition,
                packet_count=raw_trial_counts.get((session_id, trial_id), len(trial)),
                valid_packet_count=len(valid_trial),
                duration_ms=duration_ms,
                observed_rate_hz=observed_rate_hz,
                sensor_ranges=sensor_ranges,
            )
        )


def load_recording(
    csv_path: str | Path,
    *,
    manifest_path: str | Path | None = None,
    expected_labels: Iterable[str] | None = None,
    allowed_orientations: Iterable[str] = ALLOWED_ORIENTATIONS,
    min_packet_count: int = DEFAULT_MIN_PACKET_COUNT,
    target_rate_hz: float = DEFAULT_TARGET_RATE_HZ,
) -> LoadedRecording:
    """Load and validate one exported session without silently repairing it."""

    path = Path(csv_path)
    report = ValidationReport(source=str(path))
    if min_packet_count < 1:
        raise ValueError("min_packet_count must be positive")
    if not math.isfinite(target_rate_hz) or target_rate_hz <= 0:
        raise ValueError("target_rate_hz must be a finite positive number")

    resolved_manifest = (
        Path(manifest_path)
        if manifest_path is not None
        else path.with_name("manifest.json")
    )
    manifest = _load_manifest(resolved_manifest, report)

    expected = (
        frozenset(label.strip() for label in expected_labels if label.strip())
        if expected_labels is not None
        else None
    )
    if expected is None and manifest is not None:
        manifest_vocabulary = manifest.get("vocabulary")
        if isinstance(manifest_vocabulary, list) and all(
            isinstance(label, str) for label in manifest_vocabulary
        ):
            expected = frozenset(manifest_vocabulary)

    samples: list[WordSample] = []
    raw_trial_counts: dict[tuple[str, str], int] = defaultdict(int)
    try:
        handle = path.open("r", encoding="utf-8-sig", newline="")
    except OSError as exc:
        report.add("error", "csv_unreadable", f"Cannot open CSV: {exc}")
        return LoadedRecording(path, manifest, (), report)

    with handle:
        reader = csv.DictReader(handle)
        headers = tuple(reader.fieldnames or ())
        missing = [name for name in REQUIRED_COLUMNS if name not in headers]
        if missing:
            report.add(
                "error",
                "missing_columns",
                f"CSV is missing required columns: {', '.join(missing)}.",
            )
        if not headers:
            report.add("error", "empty_csv", "CSV has no header row.")
            return LoadedRecording(path, manifest, (), report)

        allowed = frozenset(allowed_orientations)
        for row_number, row in enumerate(reader, start=2):
            report.row_count += 1
            session_id = (row.get("session_id") or "").strip()
            trial_id = (row.get("trial_id") or "").strip()
            if session_id and trial_id:
                raw_trial_counts[(session_id, trial_id)] += 1
            _validate_text_fields(row, report, row_number, expected, allowed)
            schema = (row.get("schema_version") or "").strip()
            if schema != SCHEMA_VERSION:
                report.add(
                    "error",
                    "schema_version_mismatch",
                    f"schema_version must be {SCHEMA_VERSION!r}; got {schema!r}.",
                    row_number=row_number,
                    session_id=row.get("session_id") or None,
                    trial_id=row.get("trial_id") or None,
                )
            sample = _sample_from_row(row, report, row_number)
            if sample is not None:
                samples.append(sample)

    report.parsed_row_count = len(samples)
    if report.row_count == 0:
        report.add("error", "empty_csv", "CSV contains no packet rows.")
    _check_manifest(manifest, samples, report)
    _summarize_trials(
        samples,
        report,
        min_packet_count,
        target_rate_hz,
        raw_trial_counts,
    )
    return LoadedRecording(path, manifest, tuple(samples), report)


def load_recordings(
    csv_paths: Iterable[str | Path],
    *,
    expected_labels: Iterable[str] | None = None,
    allowed_orientations: Iterable[str] = ALLOWED_ORIENTATIONS,
    min_packet_count: int = DEFAULT_MIN_PACKET_COUNT,
    target_rate_hz: float = DEFAULT_TARGET_RATE_HZ,
) -> tuple[LoadedRecording, ...]:
    """Load several session exports with the same validation configuration."""

    labels = tuple(expected_labels) if expected_labels is not None else None
    orientations = tuple(allowed_orientations)
    return tuple(
        load_recording(
            path,
            expected_labels=labels,
            allowed_orientations=orientations,
            min_packet_count=min_packet_count,
            target_rate_hz=target_rate_hz,
        )
        for path in csv_paths
    )


def resample_trial(
    samples: Sequence[WordSample], *, target_rate_hz: float = DEFAULT_TARGET_RATE_HZ
) -> ResampledSequence:
    """Linearly interpolate one valid trial on its monotonic device clock."""

    if not math.isfinite(target_rate_hz) or target_rate_hz <= 0:
        raise ValueError("target_rate_hz must be a finite positive number")
    valid = [sample for sample in samples if sample.packet_valid]
    if len(valid) < 2:
        raise ValueError("at least two valid packets are required for resampling")
    first = valid[0]
    identity = {
        (sample.session_id, sample.trial_id, sample.word, sample.signer_id)
        for sample in valid
    }
    if len(identity) != 1:
        raise ValueError("samples must all belong to the same labeled trial")

    source_times = [sample.device_timestamp_ms for sample in valid]
    if any(current <= previous for previous, current in zip(source_times, source_times[1:])):
        raise ValueError("device timestamps must increase strictly before resampling")
    relative_source = [float(value - source_times[0]) for value in source_times]
    step_ms = 1000.0 / target_rate_hz
    output_count = int(math.floor(relative_source[-1] / step_ms)) + 1
    output_times = tuple(index * step_ms for index in range(output_count))

    output_values: list[tuple[float, ...]] = []
    right = 1
    for timestamp in output_times:
        while right < len(valid) - 1 and relative_source[right] < timestamp:
            right += 1
        left = right - 1
        left_time = relative_source[left]
        right_time = relative_source[right]
        ratio = (timestamp - left_time) / (right_time - left_time)
        left_values = valid[left].features
        right_values = valid[right].features
        output_values.append(
            tuple(
                left_value + ratio * (right_value - left_value)
                for left_value, right_value in zip(left_values, right_values)
            )
        )

    return ResampledSequence(
        session_id=first.session_id,
        trial_id=first.trial_id,
        word=first.word,
        schema_version=first.schema_version,
        vocabulary_version=first.vocabulary_version,
        signer_id=first.signer_id,
        orientation_condition=first.orientation_condition,
        target_rate_hz=target_rate_hz,
        relative_timestamps_ms=output_times,
        values=tuple(output_values),
    )


def fixed_window(
    sequence: ResampledSequence, *, window_size: int
) -> FixedWindowSequence:
    """Center-trim or edge-pad a resampled complete trial to ``window_size``."""

    if window_size < 1:
        raise ValueError("window_size must be positive")
    values = list(sequence.values)
    if not values:
        raise ValueError("cannot window an empty sequence")

    trimmed = max(0, len(values) - window_size)
    padded = max(0, window_size - len(values))
    if trimmed:
        left_trim = trimmed // 2
        values = values[left_trim : left_trim + window_size]
    elif padded:
        left_pad = padded // 2
        right_pad = padded - left_pad
        values = [values[0]] * left_pad + values + [values[-1]] * right_pad

    return FixedWindowSequence(
        sequence=sequence,
        values=tuple(values),
        window_size=window_size,
        trimmed_samples=trimmed,
        padded_samples=padded,
    )
