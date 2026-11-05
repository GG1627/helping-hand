import pytest

from backend.calibration_profile import FINGERS, firmware_endpoints


def profile():
    return {"schema_version": "glove-calibration-v1", "profile_id": "cal_1",
            "applied_to_inference": False, "blockers": [],
            "gyro_axis_check": "operator_confirmed",
            "flex": [{"finger": finger, "straight_raw": 700, "bent_raw": 300}
                     for finger in FINGERS]}


def test_export_proposes_endpoints_without_applying_bias_or_deploying():
    result = firmware_endpoints(profile())
    assert result["kFlexMeasuredStraight"] == [700] * 5
    assert result["kFlexMeasuredBent"] == [300] * 5
    assert result["gyro_bias_applied"] is False
    assert result["deployment_status"].startswith("proposal_only")


@pytest.mark.parametrize("bad", [float("nan"), float("inf"), -1, 5000, True, 300, 200])
def test_bad_or_incompatible_endpoints_are_rejected(bad):
    value = profile()
    value["flex"][0]["straight_raw"] = bad
    with pytest.raises(ValueError):
        firmware_endpoints(value)
