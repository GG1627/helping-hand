import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/screens/piezo_outputs_screen.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/piezo_demo_protocol.dart';
import 'package:flutter_app/widgets/haptic_hand_visualizer_widget.dart';
import 'package:flutter_test/flutter_test.dart';

class _Glove extends ChangeNotifier implements BleConnectionService {
  final events = StreamController<PiezoDemoEvent>.broadcast(sync: true);
  final requests = <(PiezoDemoAction, int, PiezoOutput?)>[];
  bool ready = true;
  int _id = 0;

  @override
  Stream<PiezoDemoEvent> get piezoDemoEvents => events.stream;

  @override
  bool get piezoDemoTransportReady => ready;

  @override
  int nextPiezoDemoRequestId() => ++_id;

  @override
  Future<void> writePiezoDemo(
    PiezoDemoAction action,
    int id, {
    PiezoOutput? output,
  }) async {
    requests.add((action, id, output));
  }

  void receive(String message) => events.add(PiezoDemoEvent.tryParse(message)!);

  void disconnectGlove() {
    ready = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('firmware slots retain their locations on the plus diagram', () {
    expect(PiezoOutput.values.map((output) => output.marker), [
      0,
      1,
      2,
      3,
      4,
      8,
      9,
      5,
      6,
      7,
    ]);
    expect(
      PiezoDemoEvent.tryParse('HP1,A,10,7')?.output,
      PiezoOutput.handCenter,
    );
    for (final bad in ['HP1,A,0,1', 'HP1,A,1,10', 'HP1,E,1,2', 'HP1,A,1']) {
      expect(PiezoDemoEvent.tryParse(bad), isNull);
    }
  });

  testWidgets('only the matching glove response lights the hand dot', (
    tester,
  ) async {
    final glove = _Glove();
    await tester.binding.setSurfaceSize(const Size(375, 812));
    await tester.pumpWidget(
      MaterialApp(home: PiezoOutputsScreen(bleService: glove)),
    );
    await tester.tap(find.text('Enable outputs'));
    await tester.pump();
    expect(glove.requests, [(PiezoDemoAction.enable, 1, null)]);
    glove.receive('HP1,R,1');
    await tester.pump();
    await tester.tap(find.text('Pulse output'));
    await tester.pump();
    final hand = find.byType(PiezoOutputHand);
    expect(glove.requests.last, (
      PiezoDemoAction.pulse,
      2,
      PiezoOutput.indexFinger,
    ));
    expect(tester.widget<PiezoOutputHand>(hand).activeOutput, isNull);
    glove.receive('HP1,A,1,1');
    glove.receive('HP1,A,2,2');
    await tester.pump();
    expect(tester.widget<PiezoOutputHand>(hand).activeOutput, isNull);
    glove.receive('HP1,A,2,1');
    await tester.pump();
    expect(find.text('Index output active'), findsOneWidget);
    expect(
      tester.widget<PiezoOutputHand>(hand).activeOutput,
      PiezoOutput.indexFinger,
    );
    glove.receive('HP1,E,2');
    await tester.pump();
    expect(tester.widget<PiezoOutputHand>(hand).activeOutput, isNull);
    expect(find.text('Last output · Index'), findsOneWidget);

    await tester.tap(find.text('Pulse output'));
    await tester.pump();
    glove.receive('HP1,A,3,1');
    await tester.pump();
    await tester.tap(find.text('Stop outputs'));
    await tester.pump();
    expect(glove.requests.last, (PiezoDemoAction.stop, 4, null));
    glove.receive('HP1,E,4');
    await tester.pump();
    expect(tester.widget<PiezoOutputHand>(hand).activeOutput, isNull);
    expect(find.text('Outputs stopped.'), findsOneWidget);

    await tester.tap(find.text('Enable outputs'));
    await tester.pump();
    glove.receive('HP1,R,5');
    await tester.pump();
    await tester.tap(find.text('Pulse output'));
    await tester.pump();
    glove.receive('HP1,A,6,1');
    await tester.pump();
    expect(find.text('Index output active'), findsOneWidget);
    glove.disconnectGlove();
    await tester.pump();
    expect(tester.widget<PiezoOutputHand>(hand).activeOutput, isNull);
    expect(find.text('Connect the glove in BLE Testing.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await glove.events.close();
    glove.dispose();
    await tester.binding.setSurfaceSize(null);
  });
}
