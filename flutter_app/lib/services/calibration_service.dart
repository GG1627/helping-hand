import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'ble_packet.dart';

const calibrationSchema = 'glove-calibration-v1';
const calibrationFingers = ['thumb', 'index', 'middle', 'ring', 'pinky'];

class CalibrationStep {
  const CalibrationStep(this.id, this.title, this.instruction);
  final String id;
  final String title;
  final String instruction;
}

final calibrationSteps = <CalibrationStep>[
  for (var repeat = 1; repeat <= 2; repeat++)
    CalibrationStep(
      'open_$repeat',
      'Open hand · $repeat of 2',
      'Keep all fingers comfortably straight. Hold still before capturing.',
    ),
  for (final finger in calibrationFingers)
    for (var repeat = 1; repeat <= 2; repeat++)
      CalibrationStep(
        '${finger}_bent_$repeat',
        'Bend $finger · $repeat of 2',
        'Bend your $finger comfortably. Keep the pose steady; do not force it.',
      ),
  const CalibrationStep(
    'stationary',
    'Rest the glove',
    'Rest the glove on a stable surface. Do not touch it during capture.',
  ),
  for (final axis in ['x', 'y', 'z'])
    for (final sign in [1, -1])
      CalibrationStep(
        '${axis}_$sign',
        '${sign == 1 ? '+' : '−'}${axis.toUpperCase()} up',
        'Point the board’s ${sign == 1 ? '+' : '−'}${axis.toUpperCase()} axis upward. Support it and hold still.',
      ),
];

class CalibrationProfile {
  CalibrationProfile(Map<String, dynamic> json) : _encoded = jsonEncode(json) {
    if (json['schema_version'] != calibrationSchema ||
        json['profile_id'] is! String ||
        json['flex'] is! List ||
        (json['flex'] as List).length != 5) {
      throw const FormatException('Invalid calibration profile.');
    }
    final flex = json['flex'] as List;
    for (var i = 0; i < 5; i++) {
      final item = flex[i];
      if (item is! Map ||
          item['finger'] != calibrationFingers[i] ||
          !['straight_raw', 'bent_raw'].every(
            (key) =>
                item[key] is num &&
                (item[key] as num).isFinite &&
                item[key] >= 0 &&
                item[key] <= 4095,
          )) {
        throw const FormatException('Invalid flex measurements in profile.');
      }
    }
    if (json['gyro_bias_dps'] is! List ||
        (json['gyro_bias_dps'] as List).length != 3 ||
        !(json['gyro_bias_dps'] as List).every((v) => v is num && v.isFinite) ||
        json['applied_to_inference'] != false) {
      throw const FormatException('Invalid development profile metadata.');
    }
  }
  final String _encoded;
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  String get id => toJson()['profile_id'] as String;
}

/// Measures and exports calibration evidence; never changes live inference.
class CalibrationService extends ChangeNotifier {
  CalibrationService({
    Future<Directory> Function()? storageDirectoryProvider,
    DateTime Function()? clock,
  }) : _storage = storageDirectoryProvider ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;
  final Future<Directory> Function() _storage;
  final DateTime Function() _clock;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final Map<String, List<BlePacket>> _captures = {};
  final List<BlePacket> _current = [];
  int stepIndex = 0;
  bool capturing = false;
  bool saving = false;
  bool initialized = false;
  DateTime? _captureStartedAt;
  bool axisCheckConfirmed = false;
  String message = 'Connect the glove to start.';
  CalibrationProfile? activeProfile;
  Directory? _activeDirectory;
  String? _who;
  bool get complete => stepIndex == calibrationSteps.length;
  CalibrationStep get step => calibrationSteps[stepIndex];
  int get packetCount => _current.length;
  double get captureSeconds => _current.length < 2
      ? 0
      : (_current.last.deviceTimestampMs! - _current.first.deviceTimestampMs!) /
            1000;

  Future<void> initialize() async {
    try {
      final root = await _storage();
      final pointer = File('${root.path}/calibration/active.json');
      if (!await pointer.exists()) return;
      final profile = CalibrationProfile(
        jsonDecode(await pointer.readAsString()),
      );
      if (!RegExp(r'^cal_[0-9]+$').hasMatch(profile.id)) {
        throw const FormatException('Invalid profile ID.');
      }
      activeProfile = profile;
      _activeDirectory = Directory('${root.path}/calibration/${profile.id}');
      message = 'Saved profile loaded. New measurements are optional.';
    } catch (_) {
      message =
          'Could not load calibration. Run a new calibration before collecting data.';
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  void reset() {
    if (saving) return;
    capturing = false;
    _captures.clear();
    _current.clear();
    _who = null;
    stepIndex = 0;
    axisCheckConfirmed = false;
    message =
        'Prepare the first pose. The previous saved profile stays active.';
    notifyListeners();
  }

  void start({
    required bool connected,
    required bool fresh,
    required bool recordingBusy,
  }) {
    if (capturing || complete || saving) return;
    if (!connected || !fresh || recordingBusy) {
      message = recordingBusy
          ? 'Finish or discard the sign trial first.'
          : 'Connect the glove and wait for fresh complete sensor packets.';
    } else {
      _current.clear();
      _captureStartedAt = _clock().toUtc();
      capturing = true;
      message = 'Hold steady. Capturing three seconds…';
    }
    notifyListeners();
  }

  void cancel([
    String reason = 'Capture canceled. Prepare the pose and retry.',
  ]) {
    if (!capturing) return;
    capturing = false;
    _current.clear();
    message = reason;
    notifyListeners();
  }

  void checkCaptureHealth({required bool connected}) {
    if (!capturing) return;
    final last = _current.isEmpty
        ? _captureStartedAt
        : _current.last.receivedAt;
    if (!connected ||
        (last != null &&
            _clock().toUtc().difference(last) > const Duration(seconds: 2))) {
      cancel('Connection or sensor stream interrupted. Retry this pose.');
    }
  }

  void handlePacket(BlePacket packet) {
    if (!capturing) return;
    final age = _clock().toUtc().difference(packet.receivedAt);
    if (!packet.isValid ||
        age.isNegative ||
        age > const Duration(seconds: 2) ||
        packet.flexRaw.any((v) => v! < 0 || v > 4095) ||
        packet.deviceTimestampMs! < 0 ||
        packet.deviceSequence! < 0 ||
        (_who != null && _who != packet.who)) {
      cancel(
        'Invalid, stale, or changed sensor packet. Check the glove and retry.',
      );
      return;
    }
    if (_current.isNotEmpty) {
      final previous = _current.last;
      final gap = packet.deviceTimestampMs! - previous.deviceTimestampMs!;
      if (gap <= 0 ||
          gap > 250 ||
          packet.deviceSequence! != previous.deviceSequence! + 1) {
        cancel(
          'Capture interrupted by a packet gap or reset. Retry this pose.',
        );
        return;
      }
    }
    _who ??= packet.who;
    _current.add(packet);
    if (captureSeconds >= 3) {
      capturing = false;
      if (_current.length < 60) {
        message = 'Too few packets. Check the stream and retry.';
      } else {
        _captures[step.id] = List.of(_current);
        stepIndex++;
        message = complete
            ? 'Review the measurements before saving.'
            : 'Pose captured. Prepare the next pose.';
      }
    }
    notifyListeners();
  }

  void retryPrevious() {
    if (capturing || saving || stepIndex == 0) return;
    stepIndex--;
    _captures.remove(step.id);
    _current.clear();
    message = 'Prepare this pose again.';
    notifyListeners();
  }

  static double _median(Iterable<num> input) {
    final sorted = input.map((v) => v.toDouble()).toList()..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static Map<String, double> _stats(Iterable<num> input) {
    final values = input.map((v) => v.toDouble()).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    return {
      'median': _median(values),
      'mean': mean,
      'std': math.sqrt(
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length,
      ),
      'min': values.reduce(math.min),
      'max': values.reduce(math.max),
    };
  }

  Map<String, dynamic> measurements() {
    if (!complete) throw StateError('Complete every pose first.');
    final blockers = <String>[];
    final warnings = <String>[];
    final flex = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final finger = calibrationFingers[i];
      final open = [
        for (var r = 1; r <= 2; r++)
          _stats(_captures['open_$r']!.map((p) => p.flexRaw[i]!)),
      ];
      final bent = [
        for (var r = 1; r <= 2; r++)
          _stats(_captures['${finger}_bent_$r']!.map((p) => p.flexRaw[i]!)),
      ];
      final straight = (open[0]['median']! + open[1]['median']!) / 2;
      final bentValue = (bent[0]['median']! + bent[1]['median']!) / 2;
      final span = (straight - bentValue).abs();
      if (span < 30) {
        blockers.add('$finger: insufficient bend response (<30 ADC counts).');
      }
      for (final repeats in [open, bent]) {
        if ((repeats[0]['median']! - repeats[1]['median']!).abs() >
            math.max(30, span * .25)) {
          blockers.add('$finger: repeated poses disagree.');
        }
        if (repeats.any((s) => s['std']! > math.max(10, span * .1))) {
          warnings.add('$finger: noisy hold; check mounting and repeat.');
        }
        if (repeats.any((s) => s['min']! <= 0 || s['max']! >= 4095)) {
          blockers.add('$finger: ADC clipping at a rail.');
        }
      }
      if (straight < bentValue) {
        warnings.add(
          '$finger: reversed response; current firmware calibration needs adaptation.',
        );
      }
      flex.add({
        'finger': finger,
        'straight_raw': straight,
        'bent_raw': bentValue,
        'span_raw': span,
        'straight_repeats': open,
        'bent_repeats': bent,
      });
    }
    final still = _captures['stationary']!;
    final gyro = [
      _stats(still.map((p) => p.gx!)),
      _stats(still.map((p) => p.gy!)),
      _stats(still.map((p) => p.gz!)),
    ];
    final acceleration = [
      _stats(still.map((p) => p.ax!)),
      _stats(still.map((p) => p.ay!)),
      _stats(still.map((p) => p.az!)),
    ];
    if (gyro.any((s) => s['std']! > 3) ||
        acceleration.any((s) => s['std']! > .05)) {
      blockers.add('Stationary capture shows movement or excess noise.');
    }
    final gravity = math.sqrt(
      acceleration.map((s) => math.pow(s['mean']!, 2)).reduce((a, b) => a + b),
    );
    if ((gravity - 1).abs() > .25) {
      blockers.add(
        'Stationary acceleration is not near 1 g. Verify units and sensor health.',
      );
    }
    if (gyro.any((s) => s['mean']!.abs() > 5)) {
      warnings.add(
        'Large stationary gyro bias. Check warmup, units, and sensor health.',
      );
    }
    final axisChecks = <Map<String, dynamic>>[];
    for (var i = 0; i < 3; i++) {
      for (final sign in [1, -1]) {
        final id = '${['x', 'y', 'z'][i]}_$sign';
        final packets = _captures[id]!;
        final vector = [
          _median(packets.map((p) => p.ax!)),
          _median(packets.map((p) => p.ay!)),
          _median(packets.map((p) => p.az!)),
        ];
        final stable = [
          _stats(packets.map((p) => p.ax!)),
          _stats(packets.map((p) => p.ay!)),
          _stats(packets.map((p) => p.az!)),
        ].every((s) => s['std']! <= .05);
        final passed =
            stable &&
            List.generate(
              3,
              (axis) => (vector[axis] - (axis == i ? sign : 0)).abs() <= .25,
            ).every((v) => v);
        axisChecks.add({'pose': id, 'median_g': vector, 'passed': passed});
        if (!passed) {
          blockers.add('$id: pose/axis check failed; verify board directions.');
        }
      }
    }
    return {
      'flex': flex,
      'gyro_bias_dps': gyro.map((s) => s['mean']).toList(),
      'stationary_gyro': gyro,
      'stationary_acceleration': acceleration,
      'acceleration_axis_checks': axisChecks,
      'blockers': blockers.toSet().toList(),
      'warnings': warnings.toSet().toList(),
    };
  }

  Future<bool> save({
    required String gloveId,
    required String mountingId,
    required String firmwareRevision,
    required String settingsNotes,
  }) async {
    if (saving || !complete) return false;
    final identity = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$');
    if (![
          gloveId,
          mountingId,
          firmwareRevision,
        ].every((s) => identity.hasMatch(s.trim())) ||
        settingsNotes.trim().isEmpty) {
      message =
          'Enter glove, mounting, firmware IDs and sensor settings notes.';
      notifyListeners();
      return false;
    }
    final measured = measurements();
    if ((measured['blockers'] as List).isNotEmpty || !axisCheckConfirmed) {
      message =
          'Resolve failed checks and confirm gyro directions before saving.';
      notifyListeners();
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      final now = _clock().toUtc();
      final id = 'cal_${now.microsecondsSinceEpoch}';
      final profile = CalibrationProfile({
        'schema_version': calibrationSchema,
        'profile_id': id,
        'created_at': now.toIso8601String(),
        'glove_id': gloveId.trim(),
        'mounting_id': mountingId.trim(),
        'firmware_revision': firmwareRevision.trim(),
        'settings_notes': settingsNotes.trim(),
        'settings_source': 'operator_declared_not_read_from_firmware',
        'imu_who': _who,
        'units': {
          'flex': 'ADC_12bit',
          'acceleration': 'g',
          'gyro': 'degrees/s',
          'magnetic': 'uT',
        },
        'thresholds_status':
            'initial_engineering_checks_not_hardware_validated',
        'magnetic_calibration_status': 'not_performed',
        'gyro_axis_check': 'operator_confirmed',
        'applied_to_inference': false,
        ...measured,
      });
      final root = await _storage();
      final directory = Directory('${root.path}/calibration/$id');
      if (await directory.exists()) {
        throw StateError('Profile already exists; retry.');
      }
      await directory.create(recursive: true);
      await File('${directory.path}/captures.json').writeAsString(
        jsonEncode({
          'profile_id': id,
          'data_origin': 'real',
          'captures': {
            for (final entry in _captures.entries)
              entry.key: [
                for (final packet in entry.value)
                  {
                    'received_at': packet.receivedAt.toIso8601String(),
                    'raw_packet': packet.raw,
                  },
              ],
          },
        }),
        flush: true,
      );
      await File('${directory.path}/profile.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(profile.toJson()),
        flush: true,
      );
      final pending = File('${root.path}/calibration/active.pending');
      await pending.writeAsString(jsonEncode(profile.toJson()), flush: true);
      await pending.rename('${root.path}/calibration/active.json');
      activeProfile = profile;
      _activeDirectory = directory;
      message =
          'Profile saved for recording metadata. Live model inputs are unchanged.';
      return true;
    } catch (error) {
      message = 'Save failed; measurements are retained. $error';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> export({Rect? sharePositionOrigin}) async {
    final directory = _activeDirectory;
    if (directory == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Helping Hand calibration ${activeProfile!.id}',
          files: [
            XFile('${directory.path}/profile.json'),
            XFile('${directory.path}/captures.json'),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      message = 'Calibration export opened.';
    } catch (error) {
      message = 'Export failed: $error';
    }
    notifyListeners();
  }
}
