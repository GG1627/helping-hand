"""Validate a development profile and prepare proposed firmware endpoints.

Does not edit firmware, change a model, or apply magnetic calibration.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

FINGERS = ("thumb", "index", "middle", "ring", "pinky")


def firmware_endpoints(profile: dict) -> dict:
    """Return measured endpoints only when compatible with the current mapper."""
    if profile.get("schema_version") != "glove-calibration-v1":
        raise ValueError("Unsupported calibration profile schema")
    if not profile.get("profile_id") or profile.get("applied_to_inference") is not False:
        raise ValueError("Expected an identified development-only profile")
    if profile.get("blockers") != [] or profile.get("gyro_axis_check") != "operator_confirmed":
        raise ValueError("Profile has failed or incomplete checks")
    flex = profile.get("flex")
    if (not isinstance(flex, list) or not all(isinstance(item, dict) for item in flex)
            or [item.get("finger") for item in flex] != list(FINGERS)):
        raise ValueError("Expected five flex channels in thumb-to-pinky order")
    straight, bent = [], []
    for item in flex:
        values = [item.get("straight_raw"), item.get("bent_raw")]
        if not all(isinstance(v, (int, float)) and not isinstance(v, bool)
                   and math.isfinite(v) and 0 <= v <= 4095 for v in values):
            raise ValueError("Invalid 12-bit flex endpoints")
        if values[0] <= values[1] or values[0] - values[1] < 30:
            raise ValueError("Current firmware requires straight > bent with a usable span; adapt its mapper for reversed sensors")
        straight.append(values[0])
        bent.append(values[1])
    return {
        "calibration_profile_id": profile["profile_id"],
        "kFlexMeasuredStraight": straight,
        "kFlexMeasuredBent": bent,
        "deployment_status": "proposal_only_retrain_and_rebuild_before_use",
        "gyro_bias_applied": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profile", type=Path)
    args = parser.parse_args()
    proposal = firmware_endpoints(json.loads(args.profile.read_text(encoding="utf-8")))
    print(json.dumps(proposal, indent=2, allow_nan=False))


if __name__ == "__main__":
    main()
