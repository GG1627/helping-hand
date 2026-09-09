import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ble_packet.dart';

const String wordRecordingSchemaVersion = 'word-sequence-v1';
const int wordRecordingTargetRateHz = 40;
const int wordRecordingMinimumPackets = 20;

const List<String> wordRecordingCsvColumns = [
  'schema_version',
  'session_id',
  'trial_id',
  'sample_index',
  'device_sequence',
  'device_timestamp_ms',
  'receive_timestamp_ms',
  'word',
  'vocabulary_version',
  'signer_id',
  'orientation_condition',
  'who',
  'ax',
  'ay',
  'az',
  'gx',
  'gy',
  'gz',
  'flex_thumb_raw',
  'flex_index_raw',
  'flex_middle_raw',
  'flex_ring_raw',
  'flex_pinky_raw',
  'raw_packet',
  'packet_valid',
];

enum TrialRecordingState { idle, recording, review }

typedef StorageDirectoryProvider = Future<Directory> Function();

class TrialMetadata {
  const TrialMetadata({
    required this.word,
    required this.vocabularyVersion,
    required this.signerId,
    required this.orientationCondition,
    required this.trialId,
  });

  final String word;
  final String vocabularyVersion;
  final String signerId;
  final String orientationCondition;
  final String trialId;

  TrialMetadata normalized() => TrialMetadata(
    word: word.trim().toLowerCase().replaceAll(' ', '_'),
    vocabularyVersion: vocabularyVersion.trim(),
    signerId: signerId.trim(),
    orientationCondition: orientationCondition.trim(),
    trialId: trialId.trim(),
  );
}

class RecordedPacketRow {
  const RecordedPacketRow({
    required this.sessionId,
    required this.metadata,
    required this.sampleIndex,
    required this.packet,
  });

  final String sessionId;
  final TrialMetadata metadata;
  final int sampleIndex;
  final BlePacket packet;

  List<Object?> toCsvValues() => [
    wordRecordingSchemaVersion,
    sessionId,
    metadata.trialId,
    sampleIndex,
    packet.deviceSequence,
    packet.deviceTimestampMs,
    packet.receivedAt.millisecondsSinceEpoch,
    metadata.word,
    metadata.vocabularyVersion,
    metadata.signerId,
    metadata.orientationCondition,
    packet.who,
    packet.ax,
    packet.ay,
    packet.az,
    packet.gx,
    packet.gy,
    packet.gz,
    packet.flexRaw[0],
    packet.flexRaw[1],
    packet.flexRaw[2],
    packet.flexRaw[3],
    packet.flexRaw[4],
    packet.raw,
    packet.isValid,
  ];
}

class SavedSessionFiles {
  const SavedSessionFiles({
    required this.directory,
    required this.csv,
    required this.manifest,
  });

  final Directory directory;
  final File csv;
  final File manifest;
}

class RecordingService extends ChangeNotifier {
  RecordingService({StorageDirectoryProvider? storageDirectoryProvider})
    : _storageDirectoryProvider =
          storageDirectoryProvider ?? getApplicationDocumentsDirectory;

  final StorageDirectoryProvider _storageDirectoryProvider;
  final List<RecordedPacketRow> _acceptedRows = [];
  final List<Map<String, Object?>> _savedTrials = [];
  final List<Map<String, Object?>> _discardedTrials = [];
  final List<RecordedPacketRow> _currentRows = [];

  TrialRecordingState _state = TrialRecordingState.idle;
  TrialMetadata? _currentMetadata;
  String? _sessionId;
  String? _sessionVocabularyVersion;
  DateTime? _sessionCreatedAt;
  DateTime? _recordingStartedAt;
  DateTime? _recordingEndedAt;
  SavedSessionFiles? _lastSavedFiles;
  String _message = 'Ready for a connected glove.';

  TrialRecordingState get state => _state;
  TrialMetadata? get currentMetadata => _currentMetadata;
  String? get sessionId => _sessionId;
  String get message => _message;
  int get currentPacketCount => _currentRows.length;
  int get currentValidPacketCount =>
      _currentRows.where((row) => row.packet.isValid).length;
  int get savedTrialCount => _savedTrials.length;
  int get discardedTrialCount => _discardedTrials.length;
  bool get hasSavedTrials => _savedTrials.isNotEmpty;
  SavedSessionFiles? get lastSavedFiles => _lastSavedFiles;

  Duration get elapsed {
    final start = _recordingStartedAt;
    if (start == null) return Duration.zero;
    final end = _state == TrialRecordingState.recording
        ? DateTime.now().toUtc()
        : (_recordingEndedAt ?? start);
    return end.difference(start);
  }

  double get observedSampleRateHz {
    if (_currentRows.length < 2) return 0;
    final elapsedUs = _currentRows.last.packet.receivedAt
        .difference(_currentRows.first.packet.receivedAt)
        .inMicroseconds;
    if (elapsedUs <= 0) return 0;
    return (_currentRows.length - 1) * 1000000 / elapsedUs;
  }

  List<String> get currentWarnings {
    final warnings = <String>[];
    if (_state == TrialRecordingState.idle) return warnings;
    if (_currentRows.length < wordRecordingMinimumPackets) {
      warnings.add(
        'Too short: ${_currentRows.length}/$wordRecordingMinimumPackets packets.',
      );
    }
    final invalid = _currentRows.length - currentValidPacketCount;
    if (invalid > 0) {
      warnings.add('$invalid malformed or incomplete packet(s).');
    }
    final rate = observedSampleRateHz;
    if (_currentRows.length >= 2 && rate < 25) {
      warnings.add(
        'Observed rate is below 25 Hz (${rate.toStringAsFixed(1)} Hz).',
      );
    }
    var missingPackets = 0;
    int? previous;
    for (final row in _currentRows.where(
      (row) => row.packet.deviceSequence != null,
    )) {
      final current = row.packet.deviceSequence!;
      if (previous != null && current > previous + 1) {
        missingPackets += current - previous - 1;
      }
      previous = current;
    }
    if (missingPackets > 0) {
      warnings.add('$missingPackets device packet(s) missing by sequence ID.');
    }
    return warnings;
  }

  String? startTrial(
    TrialMetadata metadata, {
    required bool isConnected,
    required bool hasFreshValidPacket,
  }) {
    if (_state != TrialRecordingState.idle) {
      return 'Finish or discard the current trial first.';
    }
    if (!isConnected) return 'Connect the glove before recording.';
    if (!hasFreshValidPacket) {
      return 'Wait for a complete, recent sensor packet before recording.';
    }

    final normalized = metadata.normalized();
    final validationError = _validateMetadata(normalized);
    if (validationError != null) return validationError;
    if (_savedTrials.any((trial) => trial['trial_id'] == normalized.trialId)) {
      return 'Trial ID ${normalized.trialId} is already saved in this session.';
    }
    if (_sessionVocabularyVersion != null &&
        _sessionVocabularyVersion != normalized.vocabularyVersion) {
      return 'Use one vocabulary version per session.';
    }

    final now = DateTime.now().toUtc();
    _sessionId ??= _buildSessionId(now);
    _sessionCreatedAt ??= now;
    _sessionVocabularyVersion ??= normalized.vocabularyVersion;
    _currentRows.clear();
    _currentMetadata = normalized;
    _recordingStartedAt = now;
    _recordingEndedAt = null;
    _state = TrialRecordingState.recording;
    _message = 'Recording ${normalized.word} / ${normalized.trialId}';
    notifyListeners();
    return null;
  }

  void handlePacket(BlePacket packet) {
    if (_state != TrialRecordingState.recording || _currentMetadata == null) {
      return;
    }
    _currentRows.add(
      RecordedPacketRow(
        sessionId: _sessionId!,
        metadata: _currentMetadata!,
        sampleIndex: _currentRows.length,
        packet: packet,
      ),
    );
    notifyListeners();
  }

  String? stopTrial() {
    if (_state != TrialRecordingState.recording) {
      return 'No trial is recording.';
    }
    _recordingEndedAt = DateTime.now().toUtc();
    _state = TrialRecordingState.review;
    _message = 'Review the trial, then save or discard it.';
    notifyListeners();
    return null;
  }

  Future<String?> saveTrial() async {
    if (_state != TrialRecordingState.review || _currentMetadata == null) {
      return 'Stop a recording before saving it.';
    }
    if (_currentRows.isEmpty) return 'Cannot save a trial with no packets.';

    final metadata = _currentMetadata!;
    final warnings = currentWarnings;
    _acceptedRows.addAll(_currentRows);
    _savedTrials.add({
      'trial_id': metadata.trialId,
      'word': metadata.word,
      'vocabulary_version': metadata.vocabularyVersion,
      'signer_id': metadata.signerId,
      'orientation_condition': metadata.orientationCondition,
      'started_at': _recordingStartedAt?.toIso8601String(),
      'ended_at': _recordingEndedAt?.toIso8601String(),
      'packet_count': _currentRows.length,
      'valid_packet_count': currentValidPacketCount,
      'observed_sample_rate_hz': observedSampleRateHz,
      'quality_warnings': warnings,
    });
    _resetCurrent();
    try {
      _lastSavedFiles = await _persistSession();
      _message = 'Trial saved locally. Session files are up to date.';
      notifyListeners();
      return null;
    } catch (error) {
      _message = 'Trial retained in memory, but local save failed: $error';
      notifyListeners();
      return _message;
    }
  }

  Future<String?> discardTrial(String reason) async {
    if (_state == TrialRecordingState.idle || _currentMetadata == null) {
      return 'There is no current trial to discard.';
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) return 'Enter a discard reason.';
    if (_state == TrialRecordingState.recording) {
      _recordingEndedAt = DateTime.now().toUtc();
    }
    _discardedTrials.add({
      'trial_id': _currentMetadata!.trialId,
      'word': _currentMetadata!.word,
      'vocabulary_version': _currentMetadata!.vocabularyVersion,
      'signer_id': _currentMetadata!.signerId,
      'orientation_condition': _currentMetadata!.orientationCondition,
      'reason': trimmedReason,
      'started_at': _recordingStartedAt?.toIso8601String(),
      'ended_at': _recordingEndedAt?.toIso8601String(),
      'packet_count': _currentRows.length,
    });
    _resetCurrent();
    try {
      _lastSavedFiles = await _persistSession();
      _message = 'Trial discarded and reason saved: $trimmedReason';
      notifyListeners();
      return null;
    } catch (error) {
      _message = 'Discard retained in memory, but local save failed: $error';
      notifyListeners();
      return _message;
    }
  }

  Future<String?> exportSession({Rect? sharePositionOrigin}) async {
    if (!hasSavedTrials) return 'Save at least one trial before exporting.';
    try {
      final files = await _persistSession();
      _lastSavedFiles = files;
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Helping Hand word recording ${_sessionId!}',
          text: 'Raw word-sequence CSV and manifest JSON.',
          files: [
            XFile(files.csv.path, mimeType: 'text/csv'),
            XFile(files.manifest.path, mimeType: 'application/json'),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      _message = 'Export opened for ${_sessionId!}.';
      notifyListeners();
      return null;
    } catch (error) {
      _message = 'Export failed: $error';
      notifyListeners();
      return _message;
    }
  }

  String? _validateMetadata(TrialMetadata metadata) {
    if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$').hasMatch(metadata.word)) {
      return 'Word must use lowercase letters, numbers, and underscores.';
    }
    if (!RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9_.-]*$',
    ).hasMatch(metadata.vocabularyVersion)) {
      return 'Enter a vocabulary version such as words-v1.';
    }
    if (!RegExp(
      r'^signer_[A-Za-z0-9][A-Za-z0-9_-]*$',
    ).hasMatch(metadata.signerId)) {
      return 'Signer ID must be pseudonymous and begin with signer_.';
    }
    if (!const {
      'neutral',
      'pitch_up',
      'roll_left',
      'yaw_right',
    }.contains(metadata.orientationCondition)) {
      return 'Choose a supported orientation condition.';
    }
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$').hasMatch(metadata.trialId)) {
      return 'Trial ID contains unsupported characters.';
    }
    return null;
  }

  void _resetCurrent() {
    _state = TrialRecordingState.idle;
    _currentMetadata = null;
    _currentRows.clear();
    _recordingStartedAt = null;
    _recordingEndedAt = null;
  }

  Future<SavedSessionFiles> _persistSession() async {
    final root = await _storageDirectoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}recordings${Platform.pathSeparator}'
      'raw${Platform.pathSeparator}${_sessionId!}',
    );
    await directory.create(recursive: true);
    final csv = File('${directory.path}${Platform.pathSeparator}trials.csv');
    final manifest = File(
      '${directory.path}${Platform.pathSeparator}manifest.json',
    );

    final csvBuffer = StringBuffer()
      ..writeln(wordRecordingCsvColumns.map(_csvCell).join(','));
    for (final row in _acceptedRows) {
      csvBuffer.writeln(row.toCsvValues().map(_csvCell).join(','));
    }
    await csv.writeAsString(csvBuffer.toString(), flush: true);

    final whoValues =
        _acceptedRows
            .map((row) => row.packet.who)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final vocabulary = <String>{
      ..._savedTrials.map((trial) => trial['word'] as String),
      ..._discardedTrials.map((trial) => trial['word'] as String),
    }.toList()..sort();
    final manifestValue = {
      'schema_version': wordRecordingSchemaVersion,
      'session_id': _sessionId,
      'data_origin': 'real',
      'created_at': _sessionCreatedAt?.toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'app_version': '1.0.0+1',
      'target_sample_rate_hz': wordRecordingTargetRateHz,
      'firmware_who_values': whoValues,
      'vocabulary_version': _sessionVocabularyVersion,
      'vocabulary': vocabulary,
      'trials': _savedTrials,
      'discarded_trials': _discardedTrials,
      'packet_count': _acceptedRows.length,
      'valid_packet_count': _acceptedRows
          .where((row) => row.packet.isValid)
          .length,
      'raw_packets_preserved': true,
      'magnetometer_data_present': false,
    };
    await manifest.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifestValue)}\n',
      flush: true,
    );
    return SavedSessionFiles(
      directory: directory,
      csv: csv,
      manifest: manifest,
    );
  }

  static String _buildSessionId(DateTime value) {
    final timestamp = value
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .replaceAll('.', '_');
    return 'session_$timestamp';
  }

  static String _csvCell(Object? value) {
    if (value == null) return '';
    final text = value is double
        ? value.toStringAsPrecision(12)
        : value.toString();
    if (!text.contains(RegExp('[,"\\r\\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
