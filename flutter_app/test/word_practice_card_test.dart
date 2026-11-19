import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/learning_screen.dart';
import 'package:flutter_app/screens/tabs/words_tab.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/piezo_demo_protocol.dart';
import 'package:flutter_app/services/word_haptic_demo.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_app/theme/helping_hand_theme.dart';
import 'package:flutter_app/widgets/haptic_hand_visualizer_widget.dart';
import 'package:flutter_app/widgets/word_practice_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _Glove extends ChangeNotifier implements BleConnectionService {
  final controller = StreamController<BlePacket>.broadcast(sync: true);
  final outputs = StreamController<PiezoDemoEvent>.broadcast(sync: true);
  final requests = <(PiezoDemoAction, int, PiezoOutput?)>[];
  int _id = 0;
  bool connected = true;
  bool fresh = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<BlePacket> get packets => controller.stream;
  @override
  Stream<PiezoDemoEvent> get piezoDemoEvents => outputs.stream;
  @override
  bool get piezoDemoTransportReady => connected;
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

  void receive(String message) =>
      outputs.add(PiezoDemoEvent.tryParse(message)!);
  @override
  bool hasFreshValidPacket({
    Duration maximumAge = const Duration(seconds: 2),
  }) => fresh;
  void disconnectGlove() {
    connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.close();
    outputs.close();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Classifier implements WordClassifier {
  int calls = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<WordPrediction> predict(List<WordFrame> frames) async {
    calls++;
    return WordPrediction.fromProbabilities([0.98, 0.01, 0.01], trainedWords);
  }

  @override
  void dispose() {}
}

void main() {
  Future<void> screenshot(
    WidgetTester tester,
    GlobalKey key,
    String name,
  ) async {
    if (Platform.environment['HH_WORD_PREVIEW'] != '1') return;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/word-preview');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'Hello repeats after a confirmed stop, then practice ends guidance',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      if (Platform.environment['HH_WORD_PREVIEW'] == '1') {
        await tester.runAsync(() async {
          final loader = FontLoader('MaterialIcons');
          loader.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await loader.load();
        });
      }
      await tester.binding.setSurfaceSize(const Size(375, 812));
      final glove = _Glove();
      final classifier = _Classifier();
      var now = DateTime.utc(2026);
      final saved = <String>[];
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: HelpingHandTheme.build(),
          home: RepaintBoundary(
            key: key,
            child: LearningScreen(
              title: 'Hello',
              practice: WordPracticeCard(
                target: 'hello',
                bleService: glove,
                classifier: classifier,
                clock: () => now,
                showHapticDemo: true,
                onCompleted: (word) async => saved.add(word),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Start attempt'), findsOneWidget);
      await screenshot(tester, key, 'ready-375');
      final demoHand = find.byType(PiezoOutputHand);
      expect(find.text('Haptic guidance'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2499));
      expect(glove.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(glove.requests.single, (PiezoDemoAction.enable, 1, null));
      expect(tester.widget<PiezoOutputHand>(demoHand).activeOutput, isNull);
      for (final firstId in [1, 6]) {
        expect(glove.requests.last, (PiezoDemoAction.enable, firstId, null));
        glove.receive('HP1,R,$firstId');
        await tester.pump();
        for (final output in WordHapticDemo.patterns['hello']!) {
          final (action, id, requested) = glove.requests.last;
          expect(action, PiezoDemoAction.pulse);
          expect(requested, output);
          glove.receive('HP1,A,$id,${output.index}');
          await tester.pump();
          expect(tester.widget<PiezoOutputHand>(demoHand).activeOutput, output);
          if (firstId == 1 && output == PiezoOutput.handCenter) {
            await screenshot(tester, key, 'guidance-375');
          }
          glove.receive('HP1,E,$id');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 75));
        }
        final stopId = firstId + 4;
        expect(glove.requests.last, (PiezoDemoAction.stop, stopId, null));
        await tester.pump(const Duration(milliseconds: 500));
        expect(glove.requests, hasLength(stopId));
        glove.receive('HP1,E,$stopId');
        await tester.pump();
        expect(tester.widget<PiezoOutputHand>(demoHand).activeOutput, isNull);
        if (firstId == 1) {
          await tester.pump(const Duration(milliseconds: 1999));
          expect(glove.requests, hasLength(stopId));
          await tester.pump(const Duration(milliseconds: 1));
        }
      }
      await tester.ensureVisible(find.text('Start attempt'));
      await tester.tap(find.text('Start attempt'));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        now = now.add(const Duration(milliseconds: 25));
        glove.controller.add(
          BlePacket.parse(
            'seq=$i,t_ms=${i * 25},who=0x70,ax=0.1,ay=0.2,az=0.9,gx=1,gy=2,gz=3,flex0_raw=500,flex1_raw=501,flex2_raw=502,flex3_raw=503,flex4_raw=504',
            receivedAt: now,
          ),
        );
      }
      await tester.pump();
      await screenshot(tester, key, 'recording-375');
      await tester.ensureVisible(find.text('Finish sign'));
      await tester.tap(find.text('Finish sign'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(saved, ['hello']);
      expect(classifier.calls, 1);
      expect(find.text('Matched'), findsOneWidget);
      expect(glove.requests, hasLength(10));
      await screenshot(tester, key, 'matched-375');
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      glove.disconnectGlove();
      await tester.pump();
      expect(
        find.textContaining('glove disconnected. Reconnect'),
        findsOneWidget,
      );
      expect(saved, ['hello']);
      expect(classifier.calls, 1);
      await tester.pumpWidget(const SizedBox());
      glove.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'trained word controls stay reachable at large text in portrait and landscape',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      for (final size in [const Size(375, 812), const Size(812, 375)]) {
        await tester.binding.setSurfaceSize(size);
        final glove = _Glove();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: LearningScreen(
                title: 'Hello',
                practice: WordPracticeCard(
                  target: 'hello',
                  bleService: glove,
                  classifier: _Classifier(),
                  onCompleted: (_) async {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.ensureVisible(find.text('Start attempt'));
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Start attempt'),
              )
              .onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        glove.dispose();
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  for (final cueAlreadyPlaying in [false, true]) {
    testWidgets(
      cueAlreadyPlaying
          ? 'recording waits for the active guidance to stop'
          : 'starting early skips the scheduled guidance',
      (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        final glove = _Glove();
        await tester.pumpWidget(
          MaterialApp(
            home: LearningScreen(
              title: 'Hello',
              practice: WordPracticeCard(
                target: 'hello',
                bleService: glove,
                classifier: _Classifier(),
                onCompleted: (_) async {},
                clock: () => DateTime.utc(2026),
                showHapticDemo: true,
              ),
            ),
          ),
        );
        await tester.pump();
        if (cueAlreadyPlaying) {
          await tester.pump(const Duration(seconds: 3));
          glove.receive('HP1,R,1');
          await tester.pump();
          glove.receive('HP1,A,2,5');
          await tester.pump();
        }
        await tester.ensureVisible(find.text('Start attempt'));
        await tester.tap(find.text('Start attempt'));
        await tester.pump();
        if (cueAlreadyPlaying) {
          expect(glove.requests.last, (PiezoDemoAction.stop, 3, null));
          expect(find.text('Stopping guidance…'), findsOneWidget);
          glove.receive('HP1,E,2');
          await tester.pump();
          expect(find.text('Finish sign'), findsNothing);
          glove.receive('HP1,E,3');
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 4));
        expect(find.text('Finish sign'), findsOneWidget);
        expect(glove.requests, hasLength(cueAlreadyPlaying ? 3 : 0));
        if (cueAlreadyPlaying) {
          await tester.ensureVisible(find.text('Cancel attempt'));
          await tester.tap(find.text('Cancel attempt'));
          await tester.pump(const Duration(milliseconds: 1999));
          expect(glove.requests, hasLength(3));
          await tester.pump(const Duration(milliseconds: 1));
          expect(glove.requests.last, (PiezoDemoAction.enable, 4, null));
        }
        await tester.pumpWidget(const SizedBox());
        glove.dispose();
      },
    );
  }

  testWidgets(
    'untrained word has no capture control at large text in landscape',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(812, 375));
      final glove = _Glove();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(812, 375),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: LearningScreen(
              title: 'Thank You',
              practice: WordPracticeCard(
                target: 'thank_you',
                bleService: glove,
                classifier: _Classifier(),
                onCompleted: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('Recognition is not available for this word yet.'),
        findsNothing,
      );
      expect(find.text('Start attempt'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      glove.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('Please plays three left-top-right-bottom laps', (tester) async {
    final glove = _Glove();
    final demo = WordHapticDemo(glove, WordHapticDemo.patterns['please']!);
    final playing = demo.play();
    expect(glove.requests.single, (PiezoDemoAction.enable, 1, null));
    glove.receive('HP1,R,1');
    await tester.pump();
    for (var lap = 0; lap < 3; lap++) {
      for (final output in [
        PiezoOutput.handLeft,
        PiezoOutput.handUp,
        PiezoOutput.handRight,
        PiezoOutput.handDown,
      ]) {
        final (action, id, requested) = glove.requests.last;
        expect(action, PiezoDemoAction.pulse);
        expect(requested, output);
        glove.receive('HP1,A,$id,${output.index}');
        expect(demo.activeOutput, output);
        glove.receive('HP1,E,$id');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
      }
    }
    expect(glove.requests, hasLength(14));
    expect(glove.requests.last, (PiezoDemoAction.stop, 14, null));
    glove.receive('HP1,E,14');
    await playing;
    expect(demo.activeOutput, isNull);
    demo.dispose();
    glove.dispose();
  });

  testWidgets('stopping a word cue ignores a late pulse response', (
    tester,
  ) async {
    final glove = _Glove();
    final demo = WordHapticDemo(glove, WordHapticDemo.patterns['please']!);
    final playing = demo.play();
    glove.receive('HP1,R,1');
    await tester.pump();
    glove.receive('HP1,A,2,5');
    expect(demo.activeOutput, PiezoOutput.handLeft);
    final stopped = demo.stop();
    glove.receive('HP1,E,2');
    glove.receive('HP1,E,3');
    expect(await stopped, isTrue);
    await tester.pump(const Duration(seconds: 1));
    await playing;
    expect(glove.requests, [
      (PiezoDemoAction.enable, 1, null),
      (PiezoDemoAction.pulse, 2, PiezoOutput.handLeft),
      (PiezoDemoAction.stop, 3, null),
    ]);
    expect(demo.activeOutput, isNull);
    demo.dispose();
    glove.dispose();
  });

  testWidgets(
    'Words highlights persisted learned rows and keeps all lessons tappable',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final selected = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: WordsTab(
            learnedWords: const {'hello'},
            onWordSelected: selected.add,
          ),
        ),
      );
      final hello = find.byKey(const ValueKey('word-row-hello'));
      final thanks = find.byKey(const ValueKey('word-row-thank_you'));
      expect(tester.widget<Material>(hello).color, HelpingHandColors.secondary);
      expect(tester.widget<Material>(thanks).color, HelpingHandColors.surface);
      expect(find.text('Learned'), findsOneWidget);
      expect(find.text('1 of 8 learned'), findsOneWidget);
      expect(find.textContaining('Recognition coming later'), findsNothing);
      await tester.tap(find.text('Thank You'));
      expect(selected, ['thank_you']);
    },
  );
}
