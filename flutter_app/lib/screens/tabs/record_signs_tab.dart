import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/ble_connection_service.dart';
import '../../services/recording_service.dart';
import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

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
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _vocabularyController = TextEditingController(
    text: 'words-draft',
  );
  final TextEditingController _signerController = TextEditingController(
    text: 'signer_01',
  );
  final TextEditingController _trialController = TextEditingController(
    text: 'trial_001',
  );
  String _orientation = 'neutral';
  Timer? _elapsedTimer;
  late final Listenable _services;

  @override
  void initState() {
    super.initState();
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
    _elapsedTimer?.cancel();
    _wordController.dispose();
    _vocabularyController.dispose();
    _signerController.dispose();
    _trialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _services,
      builder: (context, _) {
        final ble = widget.bleService;
        final recording = widget.recordingService;
        final livePacketReady = ble.hasFreshValidPacket();
        final fieldsEnabled = recording.state == TrialRecordingState.idle;
        return TabScaffold(
          title: 'Record Signs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConnectionCard(context, livePacketReady),
              const SizedBox(height: WarmClayTheme.cardGap),
              _buildMetadataCard(context, fieldsEnabled),
              const SizedBox(height: WarmClayTheme.cardGap),
              _buildRecordingCard(context, livePacketReady),
              if (recording.currentWarnings.isNotEmpty) ...[
                const SizedBox(height: WarmClayTheme.cardGap),
                _buildWarningsCard(context),
              ],
              const SizedBox(height: WarmClayTheme.cardGap),
              _buildSessionCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionCard(BuildContext context, bool livePacketReady) {
    final ble = widget.bleService;
    final status = !ble.isConnected
        ? 'Not connected'
        : livePacketReady
        ? 'Connected; complete packets are arriving'
        : 'Connected; waiting for a complete recent packet';
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glove connection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(status, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(
            '${ble.connectedDeviceName} • ${ble.status}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Live rate: ${ble.observedSampleRateHz.toStringAsFixed(1)} Hz • '
            'Latest packet: ${ble.lastPacket?.isValid == true ? 'valid' : 'unavailable/invalid'}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (!ble.isConnected) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ble.isScanning
                  ? null
                  : () => unawaited(ble.startScan()),
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(ble.isScanning ? 'Scanning…' : 'Find glove'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, bool enabled) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trial metadata',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use pseudonymous signer IDs. The vocabulary is still a draft until checkpoint D1 is approved.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wordController,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Word label',
              hintText: 'for example: thank_you',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vocabularyController,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Vocabulary version',
              helperText:
                  'Keep words-draft until an immutable vocabulary is approved.',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signerController,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'Signer ID'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _orientation,
            decoration: const InputDecoration(
              labelText: 'Orientation condition',
            ),
            items: const [
              DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
              DropdownMenuItem(value: 'pitch_up', child: Text('Pitch up')),
              DropdownMenuItem(value: 'roll_left', child: Text('Roll left')),
              DropdownMenuItem(value: 'yaw_right', child: Text('Yaw right')),
            ],
            onChanged: enabled
                ? (value) => setState(() => _orientation = value ?? 'neutral')
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trialController,
            enabled: enabled,
            decoration: const InputDecoration(labelText: 'Trial ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(BuildContext context, bool livePacketReady) {
    final ble = widget.bleService;
    final recording = widget.recordingService;
    final stateLabel = switch (recording.state) {
      TrialRecordingState.idle => 'Ready',
      TrialRecordingState.recording => 'RECORDING',
      TrialRecordingState.review => 'Review required',
    };
    final rate = recording.state == TrialRecordingState.idle
        ? ble.observedSampleRateHz
        : recording.observedSampleRateHz;
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recording.state == TrialRecordingState.recording
                    ? Icons.fiber_manual_record
                    : Icons.radio_button_unchecked,
                color: recording.state == TrialRecordingState.recording
                    ? Theme.of(context).colorScheme.error
                    : WarmClayColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stateLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _StatusMetric(
                label: 'Elapsed',
                value: _formatDuration(recording.elapsed),
              ),
              _StatusMetric(
                label: 'Packets',
                value: '${recording.currentPacketCount}',
              ),
              _StatusMetric(
                label: 'Valid',
                value: '${recording.currentValidPacketCount}',
              ),
              _StatusMetric(
                label: 'Rate',
                value: '${rate.toStringAsFixed(1)} Hz',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recording.message,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (recording.state == TrialRecordingState.idle)
                FilledButton.icon(
                  onPressed: ble.isConnected && livePacketReady
                      ? _startTrial
                      : null,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Start recording'),
                ),
              if (recording.state == TrialRecordingState.recording)
                FilledButton.icon(
                  onPressed: _stopTrial,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              if (recording.state == TrialRecordingState.review)
                FilledButton.icon(
                  onPressed: _saveTrial,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save trial'),
                ),
              if (recording.state != TrialRecordingState.idle)
                OutlinedButton.icon(
                  onPressed: _discardTrial,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Discard'),
                ),
            ],
          ),
          if (!ble.isConnected || !livePacketReady) ...[
            const SizedBox(height: 10),
            Text(
              'Recording is disabled until the glove is connected and a complete packet arrives.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality warnings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final warning in widget.recordingService.currentWarnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context) {
    final recording = widget.recordingService;
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            recording.sessionId ?? 'Created when the first trial starts',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '${recording.savedTrialCount} saved • '
            '${recording.discardedTrialCount} discarded • '
            'schema $wordRecordingSchemaVersion',
            style: Theme.of(context).textTheme.labelSmall,
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
            label: const Text('Export session CSV + JSON'),
          ),
        ],
      ),
    );
  }

  void _startTrial() {
    final error = widget.recordingService.startTrial(
      TrialMetadata(
        word: _wordController.text,
        vocabularyVersion: _vocabularyController.text,
        signerId: _signerController.text,
        orientationCondition: _orientation,
        trialId: _trialController.text,
      ),
      isConnected: widget.bleService.isConnected,
      hasFreshValidPacket: widget.bleService.hasFreshValidPacket(),
    );
    _showError(error);
  }

  void _stopTrial() => _showError(widget.recordingService.stopTrial());

  Future<void> _saveTrial() async {
    final error = await widget.recordingService.saveTrial();
    if (!mounted) return;
    _showError(error);
    if (error == null) _advanceTrialId();
  }

  Future<void> _discardTrial() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Why discard this trial?'),
        children: [
          for (final reason in const [
            'bad_sign',
            'BLE_drop',
            'wrong_label',
            'interrupted',
            'other',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, reason),
              child: Text(reason),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    final error = await widget.recordingService.discardTrial(reason);
    if (mounted) _showError(error);
  }

  Future<void> _exportSession() async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final error = await widget.recordingService.exportSession(
      sharePositionOrigin: origin,
    );
    if (mounted) _showError(error);
  }

  void _advanceTrialId() {
    final match = RegExp(
      r'^(.*?)(\d+)$',
    ).firstMatch(_trialController.text.trim());
    if (match == null) return;
    final digits = match.group(2)!;
    final next = (int.parse(digits) + 1).toString().padLeft(digits.length, '0');
    _trialController.text = '${match.group(1)}$next';
  }

  void _showError(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  static String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((value.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
