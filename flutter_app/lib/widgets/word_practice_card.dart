import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_connection_service.dart';
import '../services/ble_packet.dart';
import '../services/tflite_word_classifier.dart';
import '../services/word_haptic_demo.dart';
import '../services/word_practice_controller.dart';
import '../services/word_sequence.dart';
import '../theme/helping_hand_theme.dart';
import 'haptic_hand_visualizer_widget.dart';

class WordPracticeCard extends StatefulWidget {
  const WordPracticeCard({
    super.key,
    required this.target,
    required this.bleService,
    required this.onCompleted,
    this.classifier,
    this.clock,
    this.showHapticDemo = false,
    this.motionLetter = false,
  });
  final String target;
  final BleConnectionService bleService;
  final Future<void> Function(String word) onCompleted;
  final WordClassifier? classifier;
  final DateTime Function()? clock;
  final bool showHapticDemo;
  final bool motionLetter;

  @override
  State<WordPracticeCard> createState() => _WordPracticeCardState();
}

class _WordPracticeCardState extends State<WordPracticeCard>
    with WidgetsBindingObserver {
  static const _firstCueDelay = Duration(seconds: 3);
  static const _repeatCueDelay = Duration(seconds: 2);

  late final WordPracticeController _controller;
  StreamSubscription<BlePacket>? _packets;
  Timer? _timer;
  Timer? _guidanceTimer;
  WordHapticDemo? _haptics;
  String? _saveMessage;
  bool _saving = false;
  bool _startingAttempt = false;
  bool _foreground = true;
  bool _leaving = false;
  bool _guidanceSuspended = false;
  bool _cueTransportReady = false;
  int _foregroundRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final pattern = WordHapticDemo.patterns[widget.target];
    if (widget.showHapticDemo && pattern != null) {
      _haptics = WordHapticDemo(widget.bleService, pattern)
        ..addListener(_refresh);
      _cueTransportReady = widget.bleService.piezoDemoTransportReady;
      _scheduleGuidance(_firstCueDelay);
    }
    _controller = WordPracticeController(
      target: widget.target,
      classifier:
          widget.classifier ??
          (widget.motionLetter
              ? TfliteWordClassifier.motionLetters()
              : TfliteWordClassifier(target: widget.target)),
      motionLetter: widget.motionLetter,
      clock: widget.clock,
    );
    _controller.addListener(_practiceChanged);
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

  void _scheduleGuidance(Duration delay) {
    if (_haptics == null ||
        !_foreground ||
        _leaving ||
        _guidanceSuspended ||
        _guidanceTimer != null) {
      return;
    }
    _guidanceTimer = Timer(delay, () {
      _guidanceTimer = null;
      unawaited(_playGuidance());
    });
  }

  bool get _canPlayGuidance =>
      mounted &&
      _foreground &&
      !_leaving &&
      !_guidanceSuspended &&
      !_startingAttempt &&
      ModalRoute.of(context)?.isCurrent != false &&
      switch (_controller.phase) {
        WordPracticePhase.recording ||
        WordPracticePhase.evaluating ||
        WordPracticePhase.matched => false,
        _ => true,
      };

  Future<void> _playGuidance() async {
    if (_canPlayGuidance && await _haptics!.play() && _canPlayGuidance) {
      _scheduleGuidance(_repeatCueDelay);
    }
    _refresh();
  }

  void _cancelGuidanceTimer() {
    _guidanceTimer?.cancel();
    _guidanceTimer = null;
  }

  void _practiceChanged() {
    if (_controller.phase == WordPracticePhase.matched) {
      _guidanceSuspended = true;
      _cancelGuidanceTimer();
    } else if (_controller.phase == WordPracticePhase.retry) {
      _scheduleGuidance(_repeatCueDelay);
    }
    _refresh();
  }

  void _connectionChanged() {
    if (_haptics != null) {
      final ready = widget.bleService.piezoDemoTransportReady;
      if (_cueTransportReady && !ready) {
        _guidanceSuspended = true;
        _cancelGuidanceTimer();
      }
      _cueTransportReady = ready;
    }
    _controller.tick(connected: widget.bleService.isConnected);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground &&
        (_controller.phase == WordPracticePhase.recording ||
            _controller.phase == WordPracticePhase.evaluating)) {
      _controller.cancel('Attempt paused. Start again when you are ready.');
    }
    if (!_foreground) {
      _foregroundRevision++;
      _guidanceSuspended = true;
      _cancelGuidanceTimer();
      unawaited(_haptics?.stop());
    }
  }

  Future<void> _startAttempt() async {
    if (_startingAttempt) return;
    final foregroundRevision = _foregroundRevision;
    _cancelGuidanceTimer();
    final haptics = _haptics;
    if (haptics != null) {
      setState(() => _startingAttempt = true);
      final stopped = await haptics.stop();
      if (!mounted) return;
      setState(() => _startingAttempt = false);
      if (!stopped || foregroundRevision != _foregroundRevision) return;
    }
    if (!_foreground || _leaving) return;
    setState(() => _saveMessage = null);
    _controller.start(
      connected: widget.bleService.isConnected,
      freshSensors: widget.bleService.hasFreshValidPacket(
        maximumAge: const Duration(milliseconds: 250),
      ),
    );
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
    _cancelGuidanceTimer();
    _haptics?.removeListener(_refresh);
    _haptics?.dispose();
    unawaited(_packets?.cancel());
    widget.bleService.removeListener(_connectionChanged);
    _controller.removeListener(_practiceChanged);
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
    final haptics = _haptics;
    final guidanceStatus = _guidanceTimer?.isActive == true
        ? 'Guidance plays shortly.'
        : haptics?.status;
    final card = Container(
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
                widget.motionLetter
                    ? 'Letter motion practice'
                    : 'Word practice',
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
            widget.motionLetter
                ? 'Start the attempt, trace the full letter motion, then finish within 4 seconds.'
                : 'Perform the whole sign at your usual pace.',
            style: theme.textTheme.bodyMedium,
          ),
          if (haptics != null) ...[
            const SizedBox(height: 16),
            Text('Haptic guidance', style: theme.textTheme.titleSmall),
            if (guidanceStatus != null)
              Semantics(
                liveRegion: true,
                child: Text(guidanceStatus, style: theme.textTheme.bodySmall),
              ),
            PiezoOutputHand(
              activeOutput: haptics.activeOutput,
              height: 176,
              animatePulse: true,
            ),
          ],
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
                  prediction.label == 'other'
                      ? 'Other motion'
                      : displayWord(prediction.label),
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
          if (!unavailable ||
              widget.motionLetter ||
              wordPracticeTargets.contains(widget.target))
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
                      _startingAttempt ||
                      !connected ||
                      (!recording && !fresh)
                  ? null
                  : recording
                  ? _finish
                  : _startAttempt,
              icon: Icon(
                recording ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                _startingAttempt
                    ? 'Stopping guidance…'
                    : recording
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
    return haptics == null
        ? card
        : PopScope<void>(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) {
                _leaving = true;
                _cancelGuidanceTimer();
                unawaited(haptics.stop());
              }
            },
            child: card,
          );
  }
}
