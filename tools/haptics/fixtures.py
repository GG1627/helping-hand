"""Invented software fixtures, NOT electrical settings or correct ASL poses."""

from .control import Pattern, Step
from .correction import Band, Channel, Policy, Reference


def fixture_patterns():
    patterns = {slot + 1: Pattern((Step(slot, 100),)) for slot in range(10)}
    patterns[20] = Pattern((Step(1, 100), Step(None, 50), Step(5, 100),
                            Step(None, 50), Step(7, 100), Step(None, 50), Step(6, 100)))
    patterns[21] = Pattern(tuple(step for slot in (5, 7, 6, 7, 5)
                                 for step in (Step(slot, 500), Step(None, 100))))
    return patterns


def fixture_reference(*, reversed_polarity=False):
    endpoints = (300, 700) if reversed_polarity else (700, 300)
    return Reference(
        target="fixture_pose", glove_id="fixture_glove", mount_id="fixture_mount",
        calibration_id="fixture_calibration", provenance="synthetic_fixture",
        capture_ids=("invented_software_fixture_not_a_recording",),
        channels=tuple(Channel(*endpoints, Band(100, 900)) for _ in range(5)),
        variants=((Band(0.4, 0.6),) * 5,),
    )


def fixture_policy():
    # Deliberately explicit: these are test numbers, not measured tolerances.
    return Policy(enter_margin=0.1, exit_margin=0.03, persistence_ms=100,
                  cooldown_ms=500, maximum_age_ms=100, maximum_gap_ms=100,
                  minimum_span_raw=30, error_scales=(0.1,) * 5)
