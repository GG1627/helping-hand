import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_connection_service.dart';
import '../services/ble_packet.dart';
import '../services/tflite_word_classifier.dart';
import '../services/word_practice_controller.dart';
import '../services/word_sequence.dart';
import '../theme/helping_hand_theme.dart';

class WordPracticeCard extends StatefulWidget {
  const WordPracticeCard({
    super.key,
    required this.target,
    required this.bleService,
    required this.onCompleted,
    this.classifier,
    this.clock,
  });
  final String target;
  final BleConnectionService bleService;
  final Future<void> Function(String word) onCompleted;
  final WordClassifier? classifier;
  final DateTime Function()? clock;

  @override
  State<WordPracticeCard> createState() => _WordPracticeCardState();
}

class _WordPracticeCardState extends State<WordPracticeCard>
    with WidgetsBindingObserver {
  late final WordPracticeController _controller;
  StreamSubscription<BlePacket>? _packets;
  Timer? _timer;
  String? _saveMessage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WordPracticeController(
      target: widget.target,
      classifier: widget.classifier ?? TfliteWordClassifier(),
      clock: widget.clock,
    );
    _controller.addListener(_refresh);
    widget.bleService.addListener(_connectionChanged);
    _packets = widget.bleService.packets.listen(_controller.add);
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _connectionChanged(),
    );
    unawaited(_controller.initialize());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _connectionChanged() {
    _controller.tick(connected: widget.bleService.isConnected);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        (_controller.phase == WordPracticePhase.recording ||
            _controller.phase == WordPracticePhase.evaluating)) {
      _controller.cancel('Attempt paused. Start again when you are ready.');
    }
  }

  Future<void> _finish() async {
    final matched = await _controller.finish(
      connected: widget.bleService.isConnected,
    );
    if (!mounted || !matched) return;
    setState(() {
      _saving = true;
      _saveMessage = 'Saving completion...';
    });
    try {
      await widget.onCompleted(widget.target);
      if (mounted) {
        setState(() => _saveMessage = 'Completion saved on this device.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveMessage =
              'Matched, but progress could not be saved. Try again.',
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_packets?.cancel());
    widget.bleService.removeListener(_connectionChanged);
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = _controller.phase;
    final recording = phase == WordPracticePhase.recording;
    final evaluating = phase == WordPracticePhase.evaluating;
    final loading = phase == WordPracticePhase.loading;
    final unavailable = phase == WordPracticePhase.unavailable;
    final matched = phase == WordPracticePhase.matched;
    final connected = widget.bleService.isConnected;
    final fresh = widget.bleService.hasFreshValidPacket(
      maximumAge: const Duration(milliseconds: 250),
    );
    final prediction = _controller.prediction;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HelpingHandColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Word practice',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HelpingHandColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                connected ? 'Glove connected' : 'Glove disconnected',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            displayWord(widget.target),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: HelpingHandColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Perform the whole sign at your usual pace.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (loading || evaluating) ...[
            LinearProgressIndicator(
              semanticsLabel: loading ? 'Loading recognition' : 'Checking sign',
            ),
            const SizedBox(height: 16),
          ],
          if (recording) ...[
            Text(
              'Recording ${_controller.elapsedSeconds.toStringAsFixed(1)} s',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
          if (prediction != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              matched ? 'Matched' : 'Recognized',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  displayWord(prediction.label),
                  style: theme.textTheme.titleLarge,
                ),
                if (matched)
                  const Icon(
                    Icons.check_circle_outline,
                    color: HelpingHandColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
            liveRegion: true,
            child: Text(
              _controller.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: matched
                    ? HelpingHandColors.success
                    : HelpingHandColors.textSecondary,
              ),
            ),
          ),
          if (_saveMessage != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(_saveMessage!, style: theme.textTheme.bodySmall),
            ),
          ],
          if (!unavailable) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed:
                  loading ||
                      evaluating ||
                      _saving ||
                      !connected ||
                      (!recording && !fresh)
                  ? null
                  : recording
                  ? _finish
                  : () {
                      setState(() => _saveMessage = null);
                      _controller.start(
                        connected: connected,
                        freshSensors: fresh,
                      );
                    },
              icon: Icon(
                recording ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                recording
                    ? 'Finish sign'
                    : matched || phase == WordPracticePhase.retry
                    ? 'Try again'
                    : 'Start attempt',
              ),
            ),
            if (recording)
              TextButton(
                onPressed: () => _controller.cancel(
                  'Attempt cancelled. Start again when ready.',
                ),
                child: const Text('Cancel attempt'),
              ),
            if (!connected) ...[
              const SizedBox(height: 12),
              const Text('Connect the glove from BLE Testing to start.'),
            ] else if (!fresh && !recording && !evaluating && !loading) ...[
              const SizedBox(height: 12),
              const Text('Waiting for finger and motion readings.'),
            ],
          ],
        ],
      ),
    );
  }
}
