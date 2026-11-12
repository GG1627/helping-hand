import 'dart:async';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/word_practice_controller.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClassifier implements WordClassifier {
  int calls = 0;
  int loads = 0;
  bool failLoad = false;
  Completer<WordPrediction>? pending;
  List<double> probabilities = [0.98, 0.01, 0.01];
  @override
  Future<void> initialize() async {
    loads++;
    if (failLoad) throw StateError('load failed');
  }

  @override
  Future<WordPrediction> predict(List<WordFrame> frames) async {
    calls++;
    return pending != null
        ? pending!.future
        : WordPrediction.fromProbabilities(probabilities, trainedWords);
  }

  @override
  void dispose() {}
}

BlePacket sensorPacket(
  DateTime now,
  int seq, {
  int? timestamp,
  bool offline = false,
}) => BlePacket.parse(
  'seq=$seq,t_ms=${timestamp ?? seq * 25},${offline ? 'imu=offline' : 'who=0x70,ax=0.1,ay=0.2,az=0.9,gx=1,gy=2,gz=3'},flex0_raw=500,flex1_raw=501,flex2_raw=502,flex3_raw=503,flex4_raw=504',
  receivedAt: now,
);

void main() {
  late DateTime now;
  late FakeClassifier classifier;
  late WordPracticeController controller;
  setUp(() async {
    now = DateTime.utc(2026);
    classifier = FakeClassifier();
    controller = WordPracticeController(
      target: 'hello',
      classifier: classifier,
      clock: () => now,
    );
    await controller.initialize();
  });
  tearDown(() => controller.dispose());
  void record({int count = 40}) {
    controller.start(connected: true, freshSensors: true);
    for (var i = 0; i < count; i++) {
      now = now.add(const Duration(milliseconds: 25));
      controller.add(sensorPacket(now, i));
    }
  }

  test(
    'completion requires an explicit finish and only fires once per attempt',
    () async {
      record();
      expect(classifier.calls, 0);
      expect(await controller.finish(connected: true), isTrue);
      expect(controller.phase, WordPracticePhase.matched);
      expect(controller.prediction!.label, 'hello');
      expect(await controller.finish(connected: true), isFalse);
      expect(classifier.calls, 1);
      record();
      expect(controller.prediction, isNull);
      expect(await controller.finish(connected: true), isTrue);
      expect(classifier.calls, 2);
    },
  );
  test(
    'another word is shown honestly and cannot complete the selected target',
    () async {
      classifier.probabilities = [0.01, 0.98, 0.01];
      record();
      expect(await controller.finish(connected: true), isFalse);
      expect(controller.prediction!.label, 'please');
      expect(controller.phase, WordPracticePhase.retry);
    },
  );
  test('matching but uncertain prediction does not complete', () async {
    classifier.probabilities = [0.45, 0.4, 0.15];
    record();
    expect(await controller.finish(connected: true), isFalse);
    expect(controller.prediction!.confidence, 45);
  });
  test(
    'offline IMU discards attempt rather than using static flex data',
    () async {
      record();
      controller.add(sensorPacket(now, 40, offline: true));
      expect(controller.packetCount, 0);
      expect(await controller.finish(connected: true), isFalse);
      expect(classifier.calls, 0);
    },
  );
  test('clock reset and duplicate sequence discard the buffer', () {
    record();
    controller.add(sensorPacket(now, 40, timestamp: 0));
    expect(controller.phase, WordPracticePhase.retry);
    record();
    controller.add(sensorPacket(now, 39, timestamp: 1000));
    expect(controller.phase, WordPracticePhase.retry);
  });
  test(
    'silent stream loss, stale packets and disconnected starts are blocked',
    () {
      controller.start(connected: false, freshSensors: true);
      expect(controller.phase, WordPracticePhase.ready);
      controller.start(connected: true, freshSensors: false);
      expect(controller.phase, WordPracticePhase.ready);
      record();
      now = now.add(const Duration(milliseconds: 251));
      controller.tick(connected: true);
      expect(controller.phase, WordPracticePhase.retry);
      controller.start(connected: true, freshSensors: true);
      controller.add(
        sensorPacket(now.subtract(const Duration(seconds: 1)), 100),
      );
      expect(controller.phase, WordPracticePhase.retry);
    },
  );
  test('too-short recordings never run the model', () async {
    record(count: 15);
    expect(await controller.finish(connected: true), isFalse);
    expect(classifier.calls, 0);
  });
  test('disconnect while inference runs prevents stale completion', () async {
    classifier.pending = Completer<WordPrediction>();
    record();
    final finish = controller.finish(connected: true);
    controller.tick(connected: false);
    classifier.pending!.complete(
      WordPrediction.fromProbabilities([0.98, 0.01, 0.01], trainedWords),
    );
    expect(await finish, isFalse);
    expect(controller.prediction, isNull);
    expect(controller.phase, WordPracticePhase.retry);
  });
  test('manual cancellation during inference prevents completion', () async {
    classifier.pending = Completer<WordPrediction>();
    record();
    final finish = controller.finish(connected: true);
    controller.cancel('Page paused');
    classifier.pending!.complete(
      WordPrediction.fromProbabilities([0.98, 0.01, 0.01], trainedWords),
    );
    expect(await finish, isFalse);
  });
  test('attempt timeout does not classify partial gestures', () {
    record(count: 322);
    expect(controller.phase, WordPracticePhase.retry);
    expect(classifier.calls, 0);
  });
  test('untrained word never loads the classifier', () async {
    final otherClassifier = FakeClassifier();
    final other = WordPracticeController(
      target: 'sorry',
      classifier: otherClassifier,
    );
    await other.initialize();
    expect(other.phase, WordPracticePhase.unavailable);
    expect(otherClassifier.loads, 0);
    other.dispose();
  });
  test('runtime load failure is visible and cannot start', () async {
    final failed = WordPracticeController(
      target: 'hello',
      classifier: FakeClassifier()..failLoad = true,
    );
    await failed.initialize();
    failed.start(connected: true, freshSensors: true);
    expect(failed.phase, WordPracticePhase.unavailable);
    failed.dispose();
  });
}
