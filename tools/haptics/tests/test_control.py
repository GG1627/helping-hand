import random
import unittest

from tools.haptics.control import (
    Command, DryRunScheduler, Opcode, Pattern, Step, UINT32_MAX, WIRE, decode,
)
from tools.haptics.fixtures import fixture_patterns


class ProtocolTests(unittest.TestCase):
    def test_exact_twenty_byte_round_trip(self):
        command = Command(Opcode.PLAY, 12, 34, 20, 1000, 2000)
        self.assertEqual(len(command.encode()), 20)
        self.assertEqual(decode(command.encode()), command)

    def test_rejects_truncation_trailing_bytes_and_wrong_types(self):
        payload = Command(Opcode.STOP, 1, 1).encode()
        for malformed in [payload[:n] for n in range(20)] + [payload + b"x", "HH", None]:
            with self.subTest(malformed=malformed), self.assertRaises(ValueError):
                decode(malformed)

    def test_rejects_bad_headers_parameters_and_unsigned_overflow(self):
        valid = [b"HH", 1, 1, 1, 1, 20, 1000, 2000]
        for index, value in [(0, b"XX"), (1, 2), (2, 255), (3, 0), (4, 0),
                             (5, 0), (6, 0), (6, 5001), (6, 65535)]:
            fields = valid.copy()
            fields[index] = value
            with self.subTest(index=index, value=value), self.assertRaises(ValueError):
                decode(WIRE.pack(*fields))
        for command in (Command(Opcode.STOP, 1, 1, 2), Command(Opcode.STOP, 1, 1, 0, 1),
                        Command(Opcode.STOP, 1, 1, 0, 0, 1), Command(Opcode.PLAY, True, 1),
                        Command(Opcode.STOP, -1, 1), Command(Opcode.STOP, 1, 2**32),
                        Command(True, 1, 1)):
            with self.subTest(command=command), self.assertRaises(ValueError):
                command.encode()

    def test_patterns_reject_invalid_slots_sizes_and_mutability(self):
        for slot in (-1, 10, True, 1.5):
            with self.subTest(slot=slot), self.assertRaises(ValueError):
                Step(slot, 100)
        for duration in (0, -1, True, 1001):
            with self.subTest(duration=duration), self.assertRaises(ValueError):
                Step(0, duration)
        for steps in ((), [Step(0, 100)], (Step(None, 100),),
                      (Step(0, 100),) * 17, (Step(0, 1000),) * 6):
            with self.subTest(steps=steps), self.assertRaises(ValueError):
                Pattern(steps)


class SchedulerTests(unittest.TestCase):
    def setUp(self):
        self.engine = DryRunScheduler(fixture_patterns())
        self.engine.connect(0)
        self.engine.begin_practice("fixture", 0)

    def play(self, *, now=0, request=1, pattern=20, lease=1000, deadline=None, session=None):
        command = Command(Opcode.PLAY, self.engine.session if session is None else session,
                          request, pattern, lease,
                          (now + lease) & UINT32_MAX if deadline is None else deadline)
        return self.engine.receive(command.encode(), now).status

    def enable(self, now=0):
        self.engine.set_enabled(True, now)

    def test_disabled_at_start_and_never_emits_on_rejection(self):
        self.assertEqual(self.play(), "disabled")
        self.assertFalse(self.engine.busy)
        self.assertEqual(list(self.engine.events), [])

    def test_sequence_boundaries_gaps_and_completion(self):
        self.enable()
        self.assertEqual(self.play(), "started_dry_run")
        self.assertEqual(self.engine.output_slot, 1)
        for now, expected in [(99, 1), (100, None), (150, 5), (250, None),
                              (300, 7), (400, None), (450, 6), (550, None)]:
            self.engine.tick(now)
            self.assertEqual(self.engine.output_slot, expected)
        self.assertFalse(self.engine.busy)
        self.assertEqual(self.engine.events[-1].kind, "completed")
        self.assertEqual([e.slot for e in self.engine.events if e.kind == "on"], [1, 5, 7, 6])

    def test_busy_rejection_and_duplicates_never_queue_or_replay(self):
        self.enable()
        self.play(pattern=1)
        self.assertEqual(self.play(request=2, now=25), "busy")
        self.engine.tick(100)
        self.assertEqual(self.play(request=2, now=100), "duplicate_or_out_of_order")
        self.assertEqual(self.play(request=1, now=100), "duplicate_or_out_of_order")
        self.assertFalse(self.engine.busy)

    def test_stop_preempts_due_step_and_invalidates_delayed_play(self):
        self.enable()
        self.play()
        session = self.engine.session
        stop = Command(Opcode.STOP, session, 2).encode()
        self.assertEqual(self.engine.receive(stop, 100).status, "stopped")
        self.assertIsNone(self.engine.output_slot)
        self.engine.set_enabled(True, 100)
        self.assertEqual(self.play(request=3, now=100, session=session), "wrong_session_or_disconnected")
        self.assertEqual([e.slot for e in self.engine.events if e.kind == "on"], [1])

    def test_stop_valid_when_disabled_and_with_older_request_id(self):
        self.enable()
        self.play(request=10)
        stop = Command(Opcode.STOP, self.engine.session, 1).encode()
        self.assertEqual(self.engine.receive(stop, 1).status, "stopped")
        self.assertFalse(self.engine.enabled)
        stop = Command(Opcode.STOP, self.engine.session, 1).encode()
        self.assertEqual(self.engine.receive(stop, 2).status, "stopped")

    def test_wrong_session_stop_cannot_affect_current_session(self):
        self.enable()
        self.play()
        wrong = self.engine.session % UINT32_MAX + 1
        self.assertEqual(self.engine.receive(Command(Opcode.STOP, wrong, 2).encode(), 1).status,
                         "wrong_session_or_disconnected")
        self.assertEqual(self.engine.output_slot, 1)

    def test_bad_packet_cannot_start_or_extend_output(self):
        self.enable()
        self.play(pattern=1)
        for now in (25, 50, 75):
            self.assertEqual(self.engine.receive(b"garbage", now).status, "bad_length_or_type")
        self.engine.tick(100)
        self.assertFalse(self.engine.busy)

    def test_deadlines_and_leases_require_entire_pattern_to_fit(self):
        self.enable()
        for request, deadline, lease, status in [
            (1, 0, 1000, "expired_or_distant_deadline"),
            (2, UINT32_MAX, 1000, "expired_or_distant_deadline"),
            (3, 5001, 1000, "expired_or_distant_deadline"),
            (4, 549, 1000, "insufficient_lifetime"),
            (5, 2000, 549, "insufficient_lifetime"),
        ]:
            self.assertEqual(self.play(request=request, deadline=deadline, lease=lease), status)
        self.assertFalse(self.engine.busy)

    def test_unknown_pattern_is_rejected(self):
        self.enable()
        self.assertEqual(self.play(pattern=999), "unknown_pattern")

    def test_short_start_freshness_is_independent_of_long_playback_lifetime(self):
        self.enable()
        self.assertEqual(self.play(now=101, pattern=1, deadline=1000), "stale_start")
        self.assertFalse(self.engine.busy)
        self.assertEqual(self.play(now=101, request=2, pattern=1, deadline=1200), "future_issuance")
        self.assertEqual(self.play(now=101, request=3, pattern=1, deadline=1101), "started_dry_run")

    def test_expiration_cancels_a_late_final_step(self):
        self.enable()
        self.assertEqual(self.play(pattern=1, lease=100), "started_dry_run")
        self.engine.tick(101)
        self.assertFalse(self.engine.busy)
        self.assertEqual(self.engine.events[-1].reason, "expired")

    def test_late_tick_cancels_without_catchup_burst(self):
        self.enable()
        self.play()
        self.engine.tick(500)
        self.assertFalse(self.engine.busy)
        self.assertEqual(self.engine.events[-1].reason, "late_tick")
        self.assertEqual(len([e for e in self.engine.events if e.kind == "on"]), 1)

    def test_lateness_does_not_stretch_following_step(self):
        self.enable()
        self.play()
        self.engine.tick(110)
        self.engine.tick(150)
        self.assertEqual(self.engine.output_slot, 5)
        self.engine.tick(250)
        self.assertIsNone(self.engine.output_slot)

    def test_clock_rollover_preserves_timing(self):
        self.engine = DryRunScheduler(fixture_patterns())
        now = UINT32_MAX - 49
        self.engine.connect(now)
        self.engine.begin_practice("fixture", now)
        self.enable(now)
        self.assertEqual(self.play(now=now, pattern=1), "started_dry_run")
        self.engine.tick(49)
        self.assertEqual(self.engine.output_slot, 0)
        self.engine.tick(50)
        self.assertFalse(self.engine.busy)
        self.assertEqual(self.engine.events[-1].kind, "completed")

    def test_clock_regression_cancels_and_disables(self):
        self.enable(100)
        self.play(now=100)
        self.engine.tick(99)
        self.assertFalse(self.engine.busy)
        self.assertFalse(self.engine.enabled)
        self.assertEqual(self.engine.events[-1].reason, "clock_reset")

    def test_lifecycle_cancellation_invalidates_old_commands(self):
        for reason in ("disconnect", "practice_exit", "background", "resume", "target_changed", "disabled"):
            with self.subTest(reason=reason):
                self.setUp()
                self.enable()
                self.play()
                session = self.engine.session
                if reason == "target_changed":
                    self.engine.begin_practice("new_fixture", 25)
                elif reason == "disabled":
                    self.engine.set_enabled(False, 25)
                else:
                    self.engine.lifecycle(reason, 25)
                self.assertFalse(self.engine.busy)
                self.assertFalse(self.engine.enabled)
                self.assertIsNone(self.engine.output_slot)
                self.assertEqual(self.play(now=25, session=session), "wrong_session_or_disconnected")

    def test_resume_and_reconnect_never_automatically_enable(self):
        self.enable()
        self.engine.lifecycle("background", 10)
        with self.assertRaises(ValueError):
            self.enable(10)
        self.engine.lifecycle("resume", 20)
        self.assertEqual(self.play(now=20), "disabled")
        self.engine.connect(30)
        with self.assertRaises(ValueError):
            self.enable(30)

    def test_flood_is_bounded_and_does_not_extend_cue(self):
        self.enable()
        self.play(pattern=1)
        for request in range(2, 10002):
            self.assertEqual(self.play(request=request, now=1), "busy")
        self.engine.tick(100)
        self.assertFalse(self.engine.busy)
        self.assertLessEqual(len(self.engine.events), 256)
        self.assertEqual(len([e for e in self.engine.events if e.kind == "on"]), 1)

    def test_random_malformed_payloads_never_activate_output(self):
        self.enable()
        rng = random.Random(63)
        for _ in range(2000):
            self.engine.receive(rng.randbytes(rng.randrange(0, 40)), 0)
        self.assertFalse(self.engine.busy)
        self.assertIsNone(self.engine.output_slot)
        self.assertEqual(list(self.engine.events), [])


if __name__ == "__main__":
    unittest.main()
