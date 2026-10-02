import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ble_connection_service.dart';
import '../../services/recording_service.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

/// A deliberately small collection flow for the existing static ASL baseline.
/// The `word` column stores the selected character in lowercase (or a digit).
class RecordSignsTab extends StatefulWidget {
  const RecordSignsTab({
    super.key,
    required this.bleService,
    required this.recordingService,
  });

  final BleConnectionService bleService;
  final RecordingService recordingService;

  @override
  State<RecordSignsTab> createState() => _RecordSignsTabState();
}

class _RecordSignsTabState extends State<RecordSignsTab> {
  static final _targets = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('');
  final _signerController = TextEditingController(text: 'signer_01');
  late final Listenable _services;
  Timer? _countdownTimer;
  Timer? _elapsedTimer;
  String? _selectedTarget;
  int? _countdownSeconds;
  int _nextTrialNumber = 1;

  @override
  void initState() {
    super.initState();
    _services = Listenable.merge([widget.bleService, widget.recordingService]);
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && widget.recordingService.state == TrialRecordingState.recording) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    _signerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _services,
      builder: (context, _) {
        final recording = widget.recordingService;
        final live = widget.bleService.hasFreshStaticFlexPacket();
        final isBusy = _countdownSeconds != null ||
            recording.state != TrialRecordingState.idle;
        return TabScaffold(
          title: 'Record Signs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _connectionCard(context, live),
              const SizedBox(height: WarmClayTheme.cardGap),
              _targetCard(context, disabled: isBusy),
              const SizedBox(height: WarmClayTheme.cardGap),
              _captureCard(context, live),
              if (recording.currentWarnings.isNotEmpty) ...[
                const SizedBox(height: WarmClayTheme.cardGap),
                _warningsCard(context),
              ],
              const SizedBox(height: WarmClayTheme.cardGap),
              _sessionCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _connectionCard(BuildContext context, bool live) => WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Glove connection', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              !widget.bleService.isConnected
                  ? 'Connect the glove from BLE Testing first.'
                  : live
                      ? 'Connected — live sensor packets are ready.'
                      : 'Connected — waiting for a complete sensor packet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.bleService.connectedDeviceName} • '
              '${widget.bleService.observedSampleRateHz.toStringAsFixed(1)} Hz',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );

  Widget _targetCard(BuildContext context, {required bool disabled}) => WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Choose the sign', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Pick a letter or number. You will get three seconds to form it.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signerController,
              enabled: !disabled,
              decoration: const InputDecoration(
                labelText: 'Signer ID',
                helperText: 'Use a pseudonym such as signer_01.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final target in _targets)
                  ChoiceChip(
                    label: Text(target),
                    selected: _selectedTarget == target,
                    onSelected: disabled
                        ? null
                        : (_) => setState(() => _selectedTarget = target),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _captureCard(BuildContext context, bool live) {
    final recording = widget.recordingService;
    final seconds = _countdownSeconds;
    final isRecording = recording.state == TrialRecordingState.recording;
    final label = _selectedTarget ?? 'a sign';
    final detail = seconds != null
        ? 'Get ready: $seconds'
        : isRecording
            ? 'Recording $label — hold the sign, then tap Stop & save.'
            : 'Select a sign, then start a three-second countdown.';
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2. Capture', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 10),
          if (isRecording)
            Text(
              '${_formatDuration(recording.elapsed)} • '
              '${recording.currentPacketCount} packets • '
              '${recording.observedSampleRateHz.toStringAsFixed(1)} Hz',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (seconds == null && recording.state == TrialRecordingState.idle)
                FilledButton.icon(
                  onPressed: live && _selectedTarget != null ? _beginCountdown : null,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Start 3-second countdown'),
                ),
              if (isRecording)
                FilledButton.icon(
                  onPressed: _stopAndSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Stop & save'),
                ),
              if (seconds != null || recording.state != TrialRecordingState.idle)
                OutlinedButton.icon(
                  onPressed: _cancelCapture,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ring sensor note: its actual raw value is saved as received. Do not fill it from the label or another finger during collection; that would leak the answer into training data.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _warningsCard(BuildContext context) => WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capture warnings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final warning in widget.recordingService.currentWarnings)
              Text('• $warning', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );

  Widget _sessionCard(BuildContext context) {
    final recording = widget.recordingService;
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${recording.savedTrialCount} sign sample(s) saved locally.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (recording.lastSavedFiles != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              recording.lastSavedFiles!.directory.path,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: recording.hasSavedTrials ? _exportSession : null,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export CSV + manifest'),
          ),
        ],
      ),
    );
  }

  void _beginCountdown() {
    if (_selectedTarget == null ||
        !widget.bleService.hasFreshStaticFlexPacket()) {
      return;
    }
    setState(() => _countdownSeconds = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _countdownSeconds;
      if (!mounted || remaining == null) {
        timer.cancel();
        return;
      }
      if (remaining > 1) {
        setState(() => _countdownSeconds = remaining - 1);
        return;
      }
      timer.cancel();
      setState(() => _countdownSeconds = null);
      _startCapture();
    });
  }

  void _startCapture() {
    final target = _selectedTarget;
    if (target == null) return;
    final error = widget.recordingService.startTrial(
      TrialMetadata(
        word: target,
        vocabularyVersion: 'static-asl-v1',
        signerId: _signerController.text,
        orientationCondition: 'neutral',
        trialId: 'static_${target.toLowerCase()}_${_nextTrialNumber.toString().padLeft(4, '0')}',
      ),
      isConnected: widget.bleService.isConnected,
      hasFreshValidPacket: widget.bleService.hasFreshStaticFlexPacket(),
    );
    _showError(error);
  }

  Future<void> _stopAndSave() async {
    final stopError = widget.recordingService.stopTrial();
    if (stopError != null) {
      _showError(stopError);
      return;
    }
    final saveError = await widget.recordingService.saveTrial();
    if (!mounted) return;
    if (saveError == null) {
      setState(() => _nextTrialNumber += 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedTarget ?? 'Sign'} saved. Pick the next sign.')),
      );
    } else {
      _showError(saveError);
    }
  }

  Future<void> _cancelCapture() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdownSeconds != null) setState(() => _countdownSeconds = null);
    if (widget.recordingService.state != TrialRecordingState.idle) {
      await widget.recordingService.discardTrial('cancelled');
    }
  }

  Future<void> _exportSession() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    _showError(await widget.recordingService.exportSession(sharePositionOrigin: origin));
  }

  void _showError(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  static String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
