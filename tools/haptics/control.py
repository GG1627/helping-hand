"""Executable draft of bounded haptic commands and sequential scheduling.

This module can only produce trace events. It has no hardware output adapter.
All timing bounds are provisional software limits, not actuator ratings.
"""

from collections import deque
from dataclasses import dataclass
from enum import IntEnum
import secrets
import struct
from types import MappingProxyType


UINT32_MAX = 0xFFFFFFFF
HALF_CLOCK = 0x80000000
MAX_CUE_MS = 5000
MAX_STEPS = 16
MAX_PATTERNS = 32
WIRE = struct.Struct("<2sBBIIHHI")  # exactly 20 bytes; draft v1


def uint(value, maximum, name):
    if type(value) is not int or not 0 <= value <= maximum:
        raise ValueError(f"invalid {name}")
    return value


def elapsed(now, before):
    return (now - before) & UINT32_MAX


class Opcode(IntEnum):
    STOP = 0
    PLAY = 1


@dataclass(frozen=True)
class Command:
    opcode: Opcode
    session: int
    request: int
    pattern: int = 0
    lease_ms: int = 0
    deadline_ms: int = 0

    def encode(self):
        if not isinstance(self.opcode, Opcode):
            raise ValueError("invalid opcode")
        for value, maximum, name in (
            (int(self.opcode), 255, "opcode"),
            (self.session, UINT32_MAX, "session"),
            (self.request, UINT32_MAX, "request"),
            (self.pattern, 65535, "pattern"),
            (self.lease_ms, 65535, "lease"),
            (self.deadline_ms, UINT32_MAX, "deadline"),
        ):
            uint(value, maximum, name)
        wire = WIRE.pack(b"HH", 1, self.opcode, self.session, self.request,
                         self.pattern, self.lease_ms, self.deadline_ms)
        decode(wire)
        return wire


def decode(payload):
    if type(payload) is not bytes or len(payload) != WIRE.size:
        raise ValueError("bad_length_or_type")
    magic, version, op, session, request, pattern, lease, deadline = WIRE.unpack(payload)
    if magic != b"HH" or version != 1:
        raise ValueError("bad_magic_or_version")
    if op not in (Opcode.STOP, Opcode.PLAY):
        raise ValueError("unknown_opcode")
    if session == 0 or request == 0:
        raise ValueError("zero_session_or_request")
    if op == Opcode.STOP and (pattern or lease or deadline):
        raise ValueError("stop_has_parameters")
    if op == Opcode.PLAY and (pattern == 0 or not 1 <= lease <= MAX_CUE_MS):
        raise ValueError("invalid_play_parameters")
    return Command(Opcode(op), session, request, pattern, lease, deadline)


@dataclass(frozen=True)
class Step:
    slot: int | None  # None is a silent gap; 0..9 are electrical slot IDs
    duration_ms: int

    def __post_init__(self):
        if self.slot is not None:
            uint(self.slot, 9, "slot")
        uint(self.duration_ms, 1000, "step duration")
        if self.duration_ms == 0:
            raise ValueError("zero step duration")


@dataclass(frozen=True)
class Pattern:
    steps: tuple[Step, ...]

    def __post_init__(self):
        if type(self.steps) is not tuple or not 1 <= len(self.steps) <= MAX_STEPS:
            raise ValueError("invalid step count or mutable steps")
        if not all(isinstance(step, Step) for step in self.steps):
            raise ValueError("invalid step")
        if self.duration_ms > MAX_CUE_MS:
            raise ValueError("pattern too long")
        if all(step.slot is None for step in self.steps):
            raise ValueError("pattern has no output")

    @property
    def duration_ms(self):
        return sum(step.duration_ms for step in self.steps)


@dataclass(frozen=True)
class Ack:
    status: str
    request: int | None = None


@dataclass(frozen=True)
class Event:
    time_ms: int
    kind: str
    request: int
    slot: int | None = None
    reason: str = ""


class DryRunScheduler:
    """One active pattern, no pending playback queue, bounded diagnostic history.

    Call receive/tick/lifecycle methods serially in the output-owning task.
    A real BLE callback mailbox and real-time cutoff are NOT implemented here.
    """

    def __init__(self, patterns, *, maximum_lateness_ms=50, maximum_start_delay_ms=100):
        if not 1 <= len(patterns) <= MAX_PATTERNS:
            raise ValueError("invalid pattern count")
        for key, pattern in patterns.items():
            uint(key, 65535, "pattern ID")
            if key == 0 or not isinstance(pattern, Pattern):
                raise ValueError("invalid pattern registry")
        uint(maximum_lateness_ms, 1000, "maximum lateness")
        uint(maximum_start_delay_ms, 1000, "maximum start delay")
        self.patterns = MappingProxyType(dict(patterns))
        self.maximum_lateness_ms = maximum_lateness_ms
        self.maximum_start_delay_ms = maximum_start_delay_ms
        self.events = deque(maxlen=256)
        self.connected = False
        self.foreground = True
        self.target = None
        self.enabled = False
        self.session = secrets.randbelow(UINT32_MAX) + 1
        self._last_request = 0
        self._now = None
        self._active = None
        self._slot = None

    @property
    def output_slot(self):
        return self._slot

    @property
    def busy(self):
        return self._active is not None

    def _observe(self, now):
        uint(now, UINT32_MAX, "clock")
        if self._now is not None and elapsed(now, self._now) >= HALF_CLOCK:
            self._now = now
            self._invalidate("clock_reset")
            return False
        self._now = now
        return True

    def _off(self):
        if self._slot is not None:
            self.events.append(Event(self._now, "off", self._active[0].request, self._slot))
        self._slot = None

    def _finish(self, kind, reason=""):
        if self._active is not None:
            request = self._active[0].request
            self._off()
            self.events.append(Event(self._now, kind, request, reason=reason))
        self._active = None

    def _invalidate(self, reason):
        self._finish("cancelled", reason)
        self.enabled = False
        self.session = self.session % UINT32_MAX + 1
        self._last_request = 0

    def connect(self, now):
        self._observe(now)
        self._invalidate("connection_changed")
        self.connected = True
        self.target = None

    def begin_practice(self, target, now):
        if not isinstance(target, str) or not target.strip() or len(target) > 64:
            raise ValueError("invalid target")
        self._observe(now)
        self._invalidate("target_changed")
        self.target = target

    def lifecycle(self, reason, now):
        if reason not in ("disconnect", "practice_exit", "background", "resume"):
            raise ValueError("unknown lifecycle event")
        self._observe(now)
        self._invalidate(reason)
        if reason == "disconnect":
            self.connected = False
            self.target = None
        elif reason == "practice_exit":
            self.target = None
        else:
            self.foreground = reason == "resume"

    def set_enabled(self, enabled, now):
        if type(enabled) is not bool:
            raise ValueError("enable must be bool")
        clock_ok = self._observe(now)
        if not enabled:
            self._invalidate("disabled")
            return
        if not clock_ok or not self.connected or not self.foreground or self.target is None:
            raise ValueError("practice is not active")
        self.enabled = True

    def receive(self, payload, now):
        if not self._observe(now):
            return Ack("clock_reset")
        try:
            command = decode(payload)
        except ValueError as error:
            return Ack(str(error))
        if not self.connected or command.session != self.session:
            return Ack("wrong_session_or_disconnected", command.request)
        # STOP is handled before tick, busy, expiry, or enable checks. Rotating
        # the session also invalidates delayed PLAYs from before STOP.
        if command.opcode == Opcode.STOP:
            self._invalidate("stop")
            return Ack("stopped", command.request)
        self.tick(now)
        if command.request <= self._last_request:
            return Ack("duplicate_or_out_of_order", command.request)
        self._last_request = command.request
        if not self.enabled or not self.foreground or self.target is None:
            return Ack("disabled", command.request)
        if self.busy:
            return Ack("busy", command.request)
        pattern = self.patterns.get(command.pattern)
        if pattern is None:
            return Ack("unknown_pattern", command.request)
        remaining = elapsed(command.deadline_ms, now)
        if not 1 <= remaining <= MAX_CUE_MS:
            return Ack("expired_or_distant_deadline", command.request)
        if pattern.duration_ms > min(remaining, command.lease_ms):
            return Ack("insufficient_lifetime", command.request)
        # deadline - lease is the source-frame/issuance device time. A long
        # pattern lifetime must not allow an old correction to START late.
        if remaining > command.lease_ms:
            return Ack("future_issuance", command.request)
        if command.lease_ms - remaining > self.maximum_start_delay_ms:
            return Ack("stale_start", command.request)
        self._active = (command, pattern, now, 0)
        self.events.append(Event(now, "started", command.request))
        self._on(pattern.steps[0], command.request)
        return Ack("started_dry_run", command.request)

    def _on(self, step, request):
        self._slot = step.slot
        if step.slot is not None:
            self.events.append(Event(self._now, "on", request, step.slot))

    def tick(self, now):
        if not self._observe(now) or self._active is None:
            return
        command, pattern, started, index = self._active
        age = elapsed(now, started)
        boundary = sum(step.duration_ms for step in pattern.steps[:index + 1])
        if age < boundary:
            return
        if age - boundary > self.maximum_lateness_ms:
            self._finish("cancelled", "late_tick")
            return
        if index == len(pattern.steps) - 1 and age == pattern.duration_ms:
            self._finish("completed")
            return
        if age >= command.lease_ms or elapsed(now, command.deadline_ms) < HALF_CLOCK:
            self._finish("cancelled", "expired")
            return
        self._off()
        index += 1
        if index == len(pattern.steps):
            self._finish("completed")
        elif age >= boundary + pattern.steps[index].duration_ms:
            self._finish("cancelled", "late_tick")
        else:
            self._active = (command, pattern, started, index)
            self._on(pattern.steps[index], command.request)
