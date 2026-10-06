import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ble_connection_service.dart';
import '../../services/recording_service.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

/// Captures static characters or complete labeled word sequences.
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
  final _wordController = TextEditingController();
  final _vocabularyController = TextEditingController(text: 'words-draft');
  bool _wordMode = false;
  bool _saving = false;
  String _orientation = 'neutral';
  late final Listenable _services;
  Timer? _countdownTimer;
  Timer? _elapsedTimer;
  String? _selectedTarget;
  int? _countdownSeconds;
  int _nextTrialNumber = 1;

  @override
  void initState() {
    super.initState();
    _nextTrialNumber =
        widget.recordingService.savedTrialCount +
        widget.recordingService.discardedTrialCount +
        1;
    final version = widget.recordingService.sessionVocabularyVersion;
    if (version != null && version != 'static-asl-v1') {
      _wordMode = true;
      _vocabularyController.text = version;
    }
    final metadata = widget.recordingService.currentMetadata;
    if (metadata != null) {
      _signerController.text = metadata.signerId;
      _orientation = metadata.orientationCondition;
      if (_wordMode) {
        _wordController.text = metadata.word;
      } else {
        _selectedTarget = metadata.word.toUpperCase();
      }
    }
    _services = Listenable.merge([widget.bleService, widget.recordingService]);
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted &&
          widget.recordingService.state == TrialRecordingState.recording) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    _signerController.dispose();
    _wordController.dispose();
    _vocabularyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _services,
      builder: (context, _) {
        final recording = widget.recordingService;
        final live = _hasFreshPacket;
        final isBusy =
            _countdownSeconds != null ||
            recording.state != TrialRecordingState.idle ||
            _saving;
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
        Text(
          'Glove connection',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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

  Widget _targetCard(
    BuildContext context, {
    required bool disabled,
  }) => WarmCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Choose the sign',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _wordMode
              ? 'Record one complete word gesture per trial.'
              : 'Pick a letter or number. You will get three seconds to form it.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Letters / numbers')),
            ButtonSegment(value: true, label: Text('Words')),
          ],
          selected: {_wordMode},
          onSelectionChanged:
              disabled || widget.recordingService.sessionId != null
              ? null
              : (values) => setState(() => _wordMode = values.single),
        ),
        if (widget.recordingService.sessionId != null) ...[
          const SizedBox(height: 8),
          Text(
            'Start a new session to change recording mode or vocabulary.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
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
        if (_wordMode) ...[
          TextField(
            controller: _wordController,
            enabled: !disabled,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Word label',
              helperText: 'Use the agreed label, for example thank_you.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vocabularyController,
            enabled: !disabled && widget.recordingService.sessionId == null,
            decoration: const InputDecoration(
                  labelText: 'Vocabulary version',
                  helperMaxLines: 2,
              helperText:
                  'Use words-draft for pilots; words-v1 after team approval.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _orientation,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Wrist orientation'),
            items: const [
              DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
              DropdownMenuItem(value: 'pitch_up', child: Text('Pitch up')),
              DropdownMenuItem(value: 'roll_left', child: Text('Roll left')),
              DropdownMenuItem(value: 'yaw_right', child: Text('Yaw right')),
            ],
            onChanged: disabled
                ? null
                : (value) => setState(() => _orientation = value!),
          ),
        ] else
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
    final label = _wordMode
        ? _wordController.text.trim()
        : (_selectedTarget ?? 'a sign');
    final detail = seconds != null
        ? 'Get ready: $seconds'
        : isRecording
        ? (_wordMode
              ? 'Recording $label — pause briefly, perform the whole sign, pause, then tap Stop.'
              : 'Recording $label — hold the sign, then tap Stop & save.')
        : recording.state == TrialRecordingState.review
        ? 'Review $label: ${recording.currentPacketCount} packets, ${recording.currentValidPacketCount} valid.'
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
              if (seconds == null &&
                  recording.state == TrialRecordingState.idle)
                FilledButton.icon(
                  onPressed:
                      !_saving &&
                          live &&
                          (_wordMode
                              ? _wordController.text.trim().isNotEmpty
                              : _selectedTarget != null)
                      ? _beginCountdown
                      : null,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Start 3-second countdown'),
                ),
              if (isRecording)
                FilledButton.icon(
                  onPressed: _wordMode ? _stopForReview : _stopAndSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_wordMode ? 'Stop' : 'Stop & save'),
                ),
              if (recording.state == TrialRecordingState.review)
                FilledButton.icon(
                  onPressed: _saving ? null : _saveTrial,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save trial'),
                ),
              if (seconds != null ||
                  recording.state != TrialRecordingState.idle)
                OutlinedButton.icon(
                  onPressed: _saving ? null : _cancelCapture,
                  icon: const Icon(Icons.close),
                  label: Text(
                    recording.state == TrialRecordingState.review
                        ? 'Discard trial'
                        : 'Cancel',
                  ),
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
        Text(
          'Capture warnings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
            onPressed:
                !_saving &&
                    recording.state == TrialRecordingState.idle &&
                    _countdownSeconds == null &&
                    recording.hasSavedTrials
                ? _exportSession
                : null,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Export CSV + manifest'),
          ),
          if (recording.sessionId != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed:
                  !_saving &&
                      recording.state == TrialRecordingState.idle &&
                      _countdownSeconds == null
                  ? _newSession
                  : null,
              child: const Text('New session'),
            ),
          ],
        ],
      ),
    );
  }

  void _beginCountdown() {
    if ((_wordMode
            ? _wordController.text.trim().isEmpty
            : _selectedTarget == null) ||
        !_hasFreshPacket) {
      return;
    }
    if (_wordMode) {
      final label = _wordController.text.trim().toLowerCase().replaceAll(
        ' ',
        '_',
      );
      if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$').hasMatch(label)) {
        _showError('Use a word label such as thank_you.');
        return;
      }
      if (_vocabularyController.text.trim() == 'static-asl-v1') {
        _showError('Use a word vocabulary version such as words-draft.');
        return;
      }
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
    final target = _wordMode ? _wordController.text.trim() : _selectedTarget;
    if (target == null) return;
    final error = widget.recordingService.startTrial(
      TrialMetadata(
        word: target,
        vocabularyVersion: _wordMode
            ? _vocabularyController.text
            : 'static-asl-v1',
        signerId: _signerController.text,
        orientationCondition: _wordMode ? _orientation : 'neutral',
        trialId:
            '${_wordMode ? 'word' : 'static'}_${target.trim().toLowerCase().replaceAll(' ', '_')}_${_nextTrialNumber.toString().padLeft(4, '0')}',
      ),
      isConnected: widget.bleService.isConnected,
      hasFreshValidPacket: _hasFreshPacket,
    );
    _showError(error);
  }

  Future<void> _stopAndSave() async {
    final stopError = widget.recordingService.stopTrial();
    if (stopError != null) {
      _showError(stopError);
      return;
    }
    await _saveTrial();
  }

  bool get _hasFreshPacket => _wordMode
      ? widget.bleService.hasFreshValidPacket()
      : widget.bleService.hasFreshStaticFlexPacket();

  void _stopForReview() => _showError(widget.recordingService.stopTrial());

  Future<void> _saveTrial() async {
    setState(() => _saving = true);
    final saveError = await widget.recordingService.saveTrial();
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.recordingService.state == TrialRecordingState.idle) {
      setState(() => _nextTrialNumber += 1);
    }
    if (saveError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_wordMode ? _wordController.text.trim() : (_selectedTarget ?? 'Sign')} saved.',
          ),
        ),
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
      String? reason = 'cancelled';
      if (_wordMode) {
        reason = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Why discard this trial?'),
            children: [
              for (final entry in const {
                'bad_sign': 'Incorrect sign',
                'BLE_drop': 'Connection or packet loss',
                'wrong_label': 'Wrong label',
                'interrupted': 'Interrupted',
                'other': 'Other',
              }.entries)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, entry.key),
                  child: Text(entry.value),
                ),
            ],
          ),
        );
      }
      if (reason == null || !mounted) return;
      setState(() => _saving = true);
      final error = await widget.recordingService.discardTrial(reason);
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(error);
    }
  }

  Future<void> _newSession() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new session?'),
        content: const Text(
          'Export this session first if you need to share it. Its files will remain saved locally, but the export button will switch to the new session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New session'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    setState(() => _saving = true);
    final error = await widget.recordingService.beginNewSession();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _nextTrialNumber = 1;
    });
    _showError(error);
  }

  Future<void> _exportSession() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    _showError(
      await widget.recordingService.exportSession(sharePositionOrigin: origin),
    );
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
