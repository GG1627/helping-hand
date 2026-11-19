import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/calibration_screen.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/calibration_service.dart';
import 'package:flutter_app/services/recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'calibration_service_test.dart'
    show calibrationPacket, completeCalibration;

class TestGlove extends ChangeNotifier implements BleConnectionService {
  final controller = StreamController<BlePacket>.broadcast(sync: true);
  bool connected = false;
  @override
  bool get isConnected => connected;
  @override
  Stream<BlePacket> get packets => controller.stream;
  @override
  bool hasFreshValidPacket({
    Duration maximumAge = const Duration(seconds: 2),
  }) => connected;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('guided capture, review and mobile large-text layout', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final loader = FontLoader('CalibrationPreview');
      loader.addFont(
        File(
          'assets/fonts/DMSans-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    });
    var now = DateTime.utc(2026, 11, 5);
    final calibration = CalibrationService(clock: () => now);
    // No saved profile for this isolated UI check; no real device or plugin calls.
    calibration.initialized = true;
    final recorder = RecordingService();
    final glove = TestGlove();
    final preview = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'CalibrationPreview',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A70)),
        ),
        home: RepaintBoundary(
          key: preview,
          child: CalibrationScreen(
            bleService: glove,
            calibration: calibration,
            recording: recorder,
          ),
        ),
      ),
    );
    expect(find.text('Glove disconnected'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Capture steady pose'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(
            find
                .ancestor(
                  of: find.text('Capture steady pose'),
                  matching: find.byWidgetPredicate((w) => w is FilledButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    glove.connected = true;
    glove.notifyListeners();
    await tester.pump();
    await tester.ensureVisible(find.text('Capture steady pose'));
    await tester.tap(find.text('Capture steady pose'));
    for (var i = 0; i <= 120; i++) {
      now = now.add(const Duration(milliseconds: 25));
      glove.controller.add(calibrationPacket(i + 1, now));
    }
    await tester.pump();
    expect(find.text('Open hand · 2 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    calibration.reset();
    completeCalibration(
      calibration,
      calibration.handlePacket,
      () => now = now.add(const Duration(milliseconds: 25)),
      clippedPoseId: 'index_bent_2',
    );
    await tester.pump();
    expect(find.text('Review measurements'), findsOneWidget);
    final save = find
        .ancestor(
          of: find.text('Save profile for recordings'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        )
        .first;
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    final export = find.ancestor(
      of: find.text('Export measurements'),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(export).onPressed, isNotNull);
    await tester.ensureVisible(find.text('Redo a pose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redo a pose'));
    await tester.pumpAndSettle();
    expect(find.text('Needs review'), findsOneWidget);
    await tester.tap(find.text('Bend index · 2 of 2'));
    await tester.pumpAndSettle();
    expect(find.text('Redo pose'), findsOneWidget);
    expect(find.text('Bend index · 2 of 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Capture steady pose'));
    await tester.tap(find.text('Capture steady pose'));
    for (var i = 0; i <= 120; i++) {
      now = now.add(const Duration(milliseconds: 25));
      glove.controller.add(calibrationPacket(i + 1, now, pose: 'index_bent_2'));
    }
    await tester.pumpAndSettle();
    expect(find.text('Review measurements'), findsOneWidget);
    expect(find.textContaining('ADC clipping'), findsNothing);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await tester.ensureVisible(find.text('Review measurements'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          preview.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/calibration-review.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.binding.setSurfaceSize(const Size(320, 720));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: CalibrationScreen(
          bleService: glove,
          calibration: calibration,
          recording: recorder,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Review measurements'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Redo a pose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redo a pose'));
    await tester.pumpAndSettle();
    expect(find.text('Open hand · 1 of 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Open hand · 1 of 2'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Keep previous capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep previous capture'));
    await tester.pumpAndSettle();
    expect(find.text('Review measurements'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    await glove.controller.close();
    glove.dispose();
    calibration.dispose();
    recorder.dispose();
  });

  testWidgets('IMU diagnostics offers export after a failed axis check', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 18);
    final calibration = CalibrationService(imuOnly: true, clock: () => now);
    final recorder = RecordingService();
    final glove = TestGlove()..connected = true;
    await tester.binding.setSurfaceSize(const Size(320, 720));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: CalibrationScreen(
          bleService: glove,
          calibration: calibration,
          recording: recorder,
        ),
      ),
    );
    expect(find.text('IMU diagnostics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('+X up'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    completeCalibration(calibration, (packet) {
      if (calibration.step.id == 'y_1') {
        glove.controller.add(
          calibrationPacket(
            packet.deviceSequence!,
            now,
            pose: 'z_1',
            indexRaw: 4095,
          ),
        );
      } else {
        glove.controller.add(packet);
      }
    }, () => now = now.add(const Duration(milliseconds: 25)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('+Y up · 0.000, 0.000, 1.000 · Check failed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save profile for recordings'), findsNothing);
    final export = find.ancestor(
      of: find.text('Export measurements'),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(export).onPressed, isNotNull);
    await tester.ensureVisible(export);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    await glove.controller.close();
    glove.dispose();
    calibration.dispose();
    recorder.dispose();
  });
}
