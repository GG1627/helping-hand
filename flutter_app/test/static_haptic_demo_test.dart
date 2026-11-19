import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/piezo_demo_protocol.dart';
import 'package:flutter_app/services/static_haptic_demo.dart';
import 'package:flutter_app/widgets/haptic_hand_visualizer_widget.dart';
import 'package:flutter_app/widgets/static_haptic_demo_card.dart';
import 'package:flutter_test/flutter_test.dart';

class _Glove extends ChangeNotifier implements BleConnectionService {
  final _events = StreamController<PiezoDemoEvent>.broadcast(sync: true);
  final _packets = StreamController<BlePacket>.broadcast(sync: true);
  final requests = <(PiezoDemoAction, int, PiezoOutput?)>[];
  int _requestId = 0;
  int _sequence = 0;

  @override
  bool get piezoDemoTransportReady => true;

  @override
  Stream<PiezoDemoEvent> get piezoDemoEvents => _events.stream;

  @override
  Stream<BlePacket> get packets => _packets.stream;

  @override
  int nextPiezoDemoRequestId() => ++_requestId;

  @override
  Future<void> writePiezoDemo(
    PiezoDemoAction action,
    int id, {
    PiezoOutput? output,
  }) async {
    requests.add((action, id, output));
  }

  void sample(int middle, int pinky, DateTime now) {
    final seq = ++_sequence;
    _packets.add(
      BlePacket.parse(
        'seq=$seq,t_ms=${seq * 25},who=0xEA,'
        'flex0_raw=4095,flex1_raw=4095,flex2_raw=$middle,flex3_raw=0,flex4_raw=$pinky',
        receivedAt: now,
      ),
    );
  }

  void receive(String message) =>
      _events.add(PiezoDemoEvent.tryParse(message)!);

  @override
  void dispose() {
    unawaited(_events.close());
    unawaited(_packets.close());
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'waits five seconds, repeats the worst cue after two seconds, and switches fingers',
    (tester) async {
      final glove = _Glove();
      var now = DateTime.utc(2026);
      final demo = StaticHapticDemo(glove, clock: () => now);

      void hold(int middle, int pinky, int count) {
        for (var i = 0; i < count; i++) {
          now = now.add(const Duration(milliseconds: 25));
          glove.sample(middle, pinky, now);
        }
      }

      Future<void> verifyPulse(PiezoOutput expected) async {
        final (action, id, output) = glove.requests.last;
        expect(action, PiezoDemoAction.pulse);
        expect(output, expected);
        expect(demo.activeOutput, isNull);
        glove.receive('HP1,A,${id - 1},${expected.index}');
        expect(demo.activeOutput, isNull);
        glove.receive('HP1,A,$id,${expected.index}');
        expect(demo.activeOutput, expected);
        glove.receive('HP1,E,$id');
        expect(demo.activeOutput, isNull);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
      }

      demo.setPractice(active: true, completed: false);
      await tester.pump(const Duration(milliseconds: 4999));
      expect(glove.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(glove.requests.single, (PiezoDemoAction.enable, 1, null));
      glove.receive('HP1,R,1');
      await tester.pump();
      hold(430, 415, 7);
      expect(glove.requests, hasLength(1));
      hold(430, 415, 1);
      expect(demo.status, 'Straighten middle finger.');
      const straighten = [
        PiezoOutput.middle,
        PiezoOutput.handDown,
        PiezoOutput.handCenter,
        PiezoOutput.handUp,
      ];
      for (final output in straighten) {
        await verifyPulse(output);
      }
      for (var i = 0; i < 76; i++) {
        hold(430, 415, 1);
        await tester.pump(const Duration(milliseconds: 25));
      }
      await tester.pump(const Duration(milliseconds: 24));
      expect(glove.requests, hasLength(5));
      await tester.pump(const Duration(milliseconds: 1));
      expect(glove.requests.last.$3, PiezoOutput.middle);
      for (final output in straighten) {
        await verifyPulse(output);
      }
      hold(530, 415, 8);
      expect(demo.status, 'Bend pinky finger.');
      for (final output in [
        PiezoOutput.pinky,
        PiezoOutput.handUp,
        PiezoOutput.handCenter,
        PiezoOutput.handDown,
      ]) {
        await verifyPulse(output);
      }
      hold(530, 335, 8);
      expect(demo.status, 'Hold 3 steady.');
      expect(glove.requests, hasLength(13));
      hold(0, 335, 1);
      expect(glove.requests.last.$1, PiezoDemoAction.stop);
      expect(demo.activeOutput, isNull);
      expect(demo.status, contains('finger reading is unavailable'));
      await tester.pump();
      demo.dispose();
      glove.dispose();
    },
  );

  testWidgets(
    'Demo card shows acknowledged dots and stops when the route pops',
    (tester) async {
      final glove = _Glove();
      final navigator = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const Scaffold()),
      );
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: ListView(
                children: [
                  StaticHapticDemoCard(bleService: glove, completed: false),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Demo'), findsOneWidget);
      expect(glove.requests, isEmpty);
      expect(find.text('Start demo'), findsNothing);
      expect(find.text('Stop demo'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      glove.receive('HP1,R,1');
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        glove.sample(430, 335, DateTime.now());
      }
      expect(glove.requests.last, (
        PiezoDemoAction.pulse,
        2,
        PiezoOutput.middle,
      ));
      glove.receive('HP1,A,2,2');
      await tester.pump();
      expect(
        tester
            .widget<PiezoOutputHand>(find.byType(PiezoOutputHand))
            .activeOutput,
        PiezoOutput.middle,
      );
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(glove.requests.last, (PiezoDemoAction.stop, 3, null));
      glove.receive('HP1,E,2');
      await tester.pump(const Duration(milliseconds: 100));
      expect(glove.requests, hasLength(3));

      await tester.pumpWidget(const SizedBox());
      glove.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('learning 3 cancels both pending and playing cues', (
    tester,
  ) async {
    final glove = _Glove();
    final completed = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: completed,
            builder: (context, value, _) =>
                StaticHapticDemoCard(bleService: glove, completed: value),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    completed.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(glove.requests, isEmpty);
    expect(find.text('3 learned.'), findsOneWidget);

    completed.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(glove.requests.single, (PiezoDemoAction.enable, 1, null));
    glove.receive('HP1,R,1');
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      glove.sample(430, 335, DateTime.now());
    }
    expect(glove.requests.last, (PiezoDemoAction.pulse, 2, PiezoOutput.middle));
    glove.receive('HP1,A,2,2');
    await tester.pump();
    completed.value = true;
    await tester.pump();
    expect(glove.requests.last, (PiezoDemoAction.stop, 3, null));
    expect(find.text('3 learned.'), findsOneWidget);
    expect(
      tester.widget<PiezoOutputHand>(find.byType(PiezoOutputHand)).activeOutput,
      isNull,
    );
    glove.receive('HP1,E,2');
    await tester.pump(const Duration(seconds: 8));
    expect(glove.requests, hasLength(3));

    await tester.pumpWidget(const SizedBox());
    glove.dispose();
    completed.dispose();
  });
}
