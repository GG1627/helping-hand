"""Print synthetic cue/correction traces. Never connects to any equipment."""

import argparse
from dataclasses import asdict
import json

from .control import Command, DryRunScheduler, Opcode
from .correction import Observation, StaticEvaluator
from .fixtures import fixture_patterns, fixture_policy, fixture_reference


def emit(value):
    print(json.dumps(value, sort_keys=True))


def scheduler_demo():
    engine = DryRunScheduler(fixture_patterns())
    engine.connect(0)
    engine.begin_practice("abstract_fixture_not_an_ASL_demonstration", 0)
    engine.set_enabled(True, 0)
    command = Command(Opcode.PLAY, engine.session, 1, 21, 3500, 3500)
    emit({"ack": asdict(engine.receive(command.encode(), 0))})
    for now in range(25, 3001, 25):
        engine.tick(now)
    for event in engine.events:
        emit({"trace": asdict(event)})
    # Show that target changes invalidate a still-in-flight command.
    engine.begin_practice("another_fixture", 3000)
    engine.set_enabled(True, 3000)
    emit({"delayed_old_command": asdict(engine.receive(command.encode(), 3000))})


def correction_demo():
    reference = fixture_reference()
    evaluator = StaticEvaluator(reference, fixture_policy(), allow_synthetic=True)
    for sequence, now in enumerate(range(0, 701, 25)):
        # Index initially too straight, then inside the invented reference band.
        raw = (500, 700 if now < 200 else 500, 500, 500, 500)
        sample = Observation(reference.identity, sequence, now, now, raw, (True,) * 5)
        result = evaluator.evaluate(sample, now)
        if result.emit or now in (0, 200, 700):
            emit({"time_ms": now, "decision": asdict(result)})
    stale = Observation(reference.identity, 29, 725, 725, (500,) * 5, (True,) * 5)
    emit({"stale_check": asdict(evaluator.evaluate(stale, 1000))})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenario", choices=("all", "scheduler", "correction"), default="all")
    args = parser.parse_args()
    emit({"mode": "synthetic_dry_run", "hardware_access": False,
          "recognition_or_perception_evidence": False})
    if args.scenario in ("all", "scheduler"):
        scheduler_demo()
    if args.scenario in ("all", "correction"):
        correction_demo()


if __name__ == "__main__":
    main()
