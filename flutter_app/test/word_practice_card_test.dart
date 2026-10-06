import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/learning_screen.dart';
import 'package:flutter_app/services/ble_connection_service.dart';
import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/word_sequence.dart';
import 'package:flutter_app/theme/helping_hand_theme.dart';
import 'package:flutter_app/widgets/word_practice_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _Glove extends ChangeNotifier implements BleConnectionService {
  final controller = StreamController<BlePacket>.broadcast(sync: true);
  bool connected = true;
  bool fresh = true;
  @override
  bool get isConnected => connected;
  @override
  Stream<BlePacket> get packets => controller.stream;
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

  testWidgets('word attempt controls save once, retry and disconnect safely', (
    tester,
  ) async {
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
    await tester.tap(find.text('Finish sign'));
    await tester.pump();
    await tester.pump();
    expect(saved, ['hello']);
    expect(classifier.calls, 1);
    expect(find.text('Matched'), findsOneWidget);
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
  });

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
        findsOneWidget,
      );
      expect(find.text('Start attempt'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      glove.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
