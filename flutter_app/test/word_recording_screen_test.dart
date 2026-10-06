import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/tabs/record_signs_tab.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/recording_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _Glove extends ChangeNotifier implements BleConnectionService {
  bool complete = true;
  @override
  bool get isConnected => true;
  @override
  String get connectedDeviceName => 'Test glove';
  @override
  double get observedSampleRateHz => 40;
  @override
  bool hasFreshValidPacket({
    Duration maximumAge = const Duration(seconds: 2),
  }) => complete;
  @override
  bool hasFreshStaticFlexPacket({
    Duration maximumAge = const Duration(seconds: 2),
  }) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'word trial requires IMU data and stays in review until explicitly saved',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      // Optional local visual review with readable text; CI uses Flutter's test font.
      final previewFont = Platform.environment['HH_RECORDING_PREVIEW_FONT'];
      if (previewFont != null) {
        await tester.runAsync(() async {
          final loader = FontLoader('RecordingPreview');
          loader.addFont(
            File(
              previewFont,
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
          await loader.load();
        });
      }
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('word_screen_'),
      ))!;
      final recorder = RecordingService(
        storageDirectoryProvider: () async => directory,
      );
      final glove = _Glove();
      final previewKey = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: previewFont == null ? null : 'RecordingPreview',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007A70),
            ),
          ),
          home: RepaintBoundary(
            key: previewKey,
            child: RecordSignsTab(
              bleService: glove,
              recordingService: recorder,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Words'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Word label'),
        'thank_you',
      );
      tester.testTextInput.hide();
      await tester.binding.setSurfaceSize(const Size(360, 900));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      final boundary =
          previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final preview = await boundary.toImage();
        final png = await preview.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/word-recording-review.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        preview.dispose();
      });
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      await tester.pump();
      glove.complete = false;
      glove.notifyListeners();
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start 3-second countdown'),
            )
            .onPressed,
        isNull,
      );
      glove.complete = true;
      glove.notifyListeners();
      await tester.pump();
      await tester.ensureVisible(find.text('Start 3-second countdown'));
      await tester.tap(find.text('Start 3-second countdown'));
      await tester.pump(const Duration(seconds: 3));
      expect(recorder.state, TrialRecordingState.recording);
      expect(recorder.currentMetadata!.word, 'thank_you');
      expect(recorder.currentMetadata!.vocabularyVersion, 'words-draft');
      for (var i = 0; i < 20; i++) {
        recorder.handlePacket(
          BlePacket.parse(
            'seq=$i,t_ms=${i * 25},who=0x70,ax=0,ay=0,az=1,gx=0,gy=0,gz=0,'
            'flex0_raw=100,flex1_raw=200,flex2_raw=300,flex3_raw=400,flex4_raw=500',
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              1800000000000 + i * 25,
            ),
          ),
        );
      }
      await tester.pump();
      await tester.ensureVisible(find.text('Stop'));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(recorder.state, TrialRecordingState.review);
      expect(recorder.savedTrialCount, 0);
      await tester.ensureVisible(find.text('Save trial'));
      await tester.runAsync(() async {
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save trial'),
            )
            .onPressed!();
        // Wait for the save operation's real file I/O rather than fake timers.
        for (
          var attempt = 0;
          attempt < 100 && recorder.lastSavedFiles == null;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();
      expect(recorder.savedTrialCount, 1);
      await tester.runAsync(() async {
        expect(
          await recorder.lastSavedFiles!.csv.readAsString(),
          contains('thank_you,words-draft,signer_01,neutral'),
        );
        final oldCsv = recorder.lastSavedFiles!.csv;
        expect(await recorder.beginNewSession(), isNull);
        expect(recorder.sessionVocabularyVersion, isNull);
        expect(recorder.savedTrialCount, 0);
        expect(await oldCsv.exists(), isTrue);
      });
      await tester.pumpWidget(const SizedBox());
      recorder.dispose();
      glove.dispose();
      await tester.binding.setSurfaceSize(null);
      await tester.runAsync(() => directory.delete(recursive: true));
    },
  );
}
