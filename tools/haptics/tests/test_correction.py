from dataclasses import replace
import math
import unittest

from tools.haptics.correction import (
    Band, Channel, Observation, Policy, Reference, StaticEvaluator,
)
from tools.haptics.fixtures import fixture_policy, fixture_reference


class CorrectionTests(unittest.TestCase):
    def setUp(self):
        self.reference = fixture_reference()
        self.policy = fixture_policy()
        self.evaluator = StaticEvaluator(self.reference, self.policy, allow_synthetic=True)

    def observation(self, sequence, bends=(0.5, 0, 0.5, 0.5, 0.5), *, now=None):
        now = sequence * 25 if now is None else now
        raw = tuple(round(c.straight_raw + v * (c.bent_raw - c.straight_raw))
                    for c, v in zip(self.reference.channels, bends))
        return Observation(self.reference.identity, sequence, sequence * 25, now, raw, (True,) * 5)

    def evaluate(self, sequence, bends=(0.5, 0, 0.5, 0.5, 0.5)):
        return self.evaluator.evaluate(self.observation(sequence, bends), sequence * 25)

    def test_no_default_references_and_synthetic_requires_opt_in(self):
        with self.assertRaises(ValueError):
            StaticEvaluator(self.reference, self.policy)
        with self.assertRaises(ValueError):
            StaticEvaluator(None, self.policy)

    def test_bend_request_requires_persistence_and_repeats_only_after_cooldown(self):
        emissions = []
        for sequence in range(25):
            decision = self.evaluate(sequence)
            if decision.emit:
                emissions.append((sequence * 25, decision.finger, decision.direction))
        self.assertEqual(emissions, [(100, 1, "bend"), (600, 1, "bend")])

    def test_straighten_request_is_opposite_of_bend(self):
        for sequence in range(5):
            result = self.evaluate(sequence, (0.5, 1, 0.5, 0.5, 0.5))
        self.assertTrue(result.emit)
        self.assertEqual((result.finger, result.direction), (1, "straighten"))

    def test_reversed_raw_polarity_has_identical_semantic_directions(self):
        for reverse in (False, True):
            for bend, direction in [(0, "bend"), (1, "straighten")]:
                with self.subTest(reverse=reverse, bend=bend):
                    self.reference = fixture_reference(reversed_polarity=reverse)
                    self.evaluator = StaticEvaluator(self.reference, self.policy, allow_synthetic=True)
                    for sequence in range(5):
                        result = self.evaluate(sequence, (0.5, bend, 0.5, 0.5, 0.5))
                    self.assertTrue(result.emit)
                    self.assertEqual(result.direction, direction)

    def test_noise_inside_deadband_never_emits(self):
        for sequence in range(100):
            bend = (0.32, 0.36, 0.41, 0.5, 0.65, 0.68)[sequence % 6]
            self.assertFalse(self.evaluate(sequence, (0.5, bend, 0.5, 0.5, 0.5)).emit)

    def test_hysteresis_retains_correction_below_entry_margin_until_release(self):
        for sequence in range(4):
            self.evaluate(sequence)
        result = self.evaluate(4, (0.5, 0.35, 0.5, 0.5, 0.5))
        self.assertTrue(result.emit)  # 0.05 error: between 0.03 exit and 0.1 entry
        self.assertEqual(result.direction, "bend")
        result = self.evaluate(5, (0.5, 0.39, 0.5, 0.5, 0.5))
        self.assertEqual(result.reason, "within_reference")
        self.assertIsNone(result.finger)

    def test_direction_flip_restarts_persistence_and_obeys_global_cooldown(self):
        for sequence in range(5):
            self.evaluate(sequence)
        for sequence in range(5, 24):
            result = self.evaluate(sequence, (0.5, 1, 0.5, 0.5, 0.5))
            self.assertFalse(result.emit)
        result = self.evaluate(24, (0.5, 1, 0.5, 0.5, 0.5))
        self.assertTrue(result.emit)
        self.assertEqual(result.direction, "straighten")

    def test_alternating_direction_never_accumulates_persistence(self):
        for sequence in range(100):
            result = self.evaluate(sequence, (0.5, sequence % 2, 0.5, 0.5, 0.5))
            self.assertFalse(result.emit)

    def test_prioritizes_one_finger_and_keeps_it_until_corrected(self):
        for sequence in range(5):
            result = self.evaluate(sequence, (0.2, 0, 0.5, 0.5, 0.5))
        self.assertEqual(result.finger, 1)
        # Thumb becomes worse, but index is still outside the release band.
        result = self.evaluate(5, (0, 0.1, 0.5, 0.5, 0.5))
        self.assertEqual(result.finger, 1)
        result = self.evaluate(6, (0, 0.5, 0.5, 0.5, 0.5))
        self.assertEqual(result.finger, 0)
        self.assertFalse(result.emit)

    def test_accepts_either_complete_variant_but_not_a_mix_of_variants(self):
        self.reference = replace(self.reference, variants=((Band(0, 0.1),) * 5,
                                                            (Band(0.9, 1),) * 5))
        self.evaluator = StaticEvaluator(self.reference, self.policy, allow_synthetic=True)
        self.assertEqual(self.evaluate(0, (0.05,) * 5).reason, "within_reference")
        self.assertEqual(self.evaluate(1, (0.95,) * 5).reason, "within_reference")
        for sequence in range(2, 7):
            result = self.evaluate(sequence, (0.05, 0.95, 0.05, 0.95, 0.05))
        self.assertTrue(result.emit)

    def test_variant_is_stable_while_a_correction_is_pending(self):
        self.reference = replace(self.reference, variants=((Band(0, 0.1),) * 5,
                                                            (Band(0.9, 1),) * 5))
        self.evaluator = StaticEvaluator(self.reference, self.policy, allow_synthetic=True)
        first = self.evaluate(0, (0.4,) * 5)
        second = self.evaluate(1, (0.6,) * 5)
        self.assertEqual(first.variant, second.variant)
        self.assertEqual(first.direction, second.direction)

    def test_invalid_channels_suppress_all_corrections(self):
        sample = self.observation(0)
        cases = [(None, "missing_or_saturated_channel"), (0, "missing_or_saturated_channel"),
                 (4095, "missing_or_saturated_channel"), (True, "missing_or_saturated_channel"),
                 (math.nan, "missing_or_saturated_channel"), (4096, "missing_or_saturated_channel"),
                 (99, "outside_measured_health_band"), (901, "outside_measured_health_band")]
        for value, reason in cases:
            with self.subTest(value=value):
                result = self.evaluator.evaluate(replace(sample, raw=(value,) + sample.raw[1:]), 0)
                self.assertFalse(result.emit)
                self.assertEqual(result.reason, reason)
        for usable in ((True, True, False, True, True), (1,) * 5, (), None):
            with self.subTest(usable=usable):
                result = self.evaluator.evaluate(replace(sample, channel_usable=usable), 0)
                self.assertFalse(result.emit)
        self.assertFalse(self.evaluator.evaluate(replace(sample, raw=None), 0).emit)
        self.assertFalse(self.evaluator.evaluate(None, 0).emit)

    def test_bad_channel_clears_existing_persistence(self):
        for sequence in range(4):
            self.evaluate(sequence)
        bad = replace(self.observation(4), raw=(500, 700, 500, None, 500))
        self.assertFalse(self.evaluator.evaluate(bad, 100).emit)
        # First healthy frame after the missing packet reports a stream gap.
        self.assertEqual(self.evaluate(5).reason, "stream_gap")
        for sequence in range(6, 10):
            self.assertFalse(self.evaluate(sequence).emit)
        self.assertTrue(self.evaluate(10).emit)

    def test_stale_and_future_samples_cannot_trigger_or_preserve_pending_cue(self):
        for sequence in range(4):
            self.evaluate(sequence)
        sample = self.observation(4)
        self.assertEqual(self.evaluator.evaluate(sample, 201).reason, "stale_or_future_sample")
        self.assertEqual(self.evaluator.evaluate(replace(sample, received_ms=300), 201).reason,
                         "stale_or_future_sample")
        self.assertFalse(self.evaluator.evaluate(self.observation(4, now=201), 201).emit)

    def test_duplicate_reordered_and_reset_device_clocks_are_rejected(self):
        self.evaluate(0)
        self.evaluate(1)
        for sample in (self.observation(1), self.observation(0),
                       replace(self.observation(2), device_ms=0),
                       replace(self.observation(2), received_ms=24)):
            with self.subTest(sample=sample):
                result = self.evaluator.evaluate(sample, 50)
                self.assertEqual(result.reason, "duplicate_or_reordered_sample")
                self.assertFalse(result.emit)

    def test_sequence_device_time_and_receive_time_gaps_reset_persistence(self):
        for kind in ("sequence", "device", "receive"):
            with self.subTest(kind=kind):
                self.setUp()
                for sequence in range(4):
                    self.evaluate(sequence)
                sample = self.observation(4)
                sample = {"sequence": replace(sample, sequence=5),
                          "device": replace(sample, device_ms=200),
                          "receive": replace(sample, received_ms=200)}[kind]
                self.assertEqual(self.evaluator.evaluate(sample, 200).reason, "stream_gap")

    def test_context_mismatch_never_gives_a_correction(self):
        for sequence in range(4):
            self.evaluate(sequence)
        for index in range(4):
            identity = list(self.reference.identity)
            identity[index] = "different"
            sample = replace(self.observation(4), identity=tuple(identity))
            self.assertEqual(self.evaluator.evaluate(sample, 100).reason, "reference_context_mismatch")
        self.assertFalse(self.evaluate(4).emit)

    def test_explicit_reset_clears_pending_cues_and_accepts_new_device_stream(self):
        for sequence in range(4):
            self.evaluate(sequence)
        self.evaluator.reset()
        for sequence in range(4):
            self.assertFalse(self.evaluate(sequence).emit)
        self.assertTrue(self.evaluate(4).emit)

    def test_host_clock_regression_requires_explicit_reset(self):
        self.evaluate(0)
        self.evaluate(1)
        sample = self.observation(2)
        self.assertEqual(self.evaluator.evaluate(sample, 24).reason, "clock_reset_requires_reset")
        self.assertEqual(self.evaluator.evaluate(sample, 50).reason, "clock_reset_requires_reset")
        self.evaluator.reset()
        self.assertEqual(self.evaluator.evaluate(sample, 50).reason, "persisting")


class ReferenceValidationTests(unittest.TestCase):
    def test_reference_and_policy_validation(self):
        reference = fixture_reference()
        for changes in ({"capture_ids": ()}, {"provenance": "guessed"}, {"calibration_id": ""},
                        {"channels": reference.channels[:4]}, {"variants": ()},
                        {"variants": ((Band(-1, 1),) * 5,)},
                        {"variants": ((Band(0, 1),) * 4,)}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                replace(reference, **changes)
        policy = fixture_policy()
        for changes in ({"exit_margin": policy.enter_margin}, {"enter_margin": math.nan},
                        {"minimum_span_raw": 0}, {"error_scales": (0,) * 5},
                        {"persistence_ms": True}, {"maximum_age_ms": 0}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                replace(policy, **changes)

    def test_calibration_span_and_raw_health_bounds_are_required(self):
        for channel_args in [(700, 700, Band(100, 900)), (0, 700, Band(0, 900)),
                             (700, 300, Band(400, 900)), (700, 300, Band(100, 4095))]:
            with self.subTest(args=channel_args), self.assertRaises(ValueError):
                Channel(*channel_args)
        reference = replace(fixture_reference(), channels=(Channel(700, 699, Band(100, 900)),) * 5)
        with self.assertRaises(ValueError):
            StaticEvaluator(reference, fixture_policy(), allow_synthetic=True)


if __name__ == "__main__":
    unittest.main()
