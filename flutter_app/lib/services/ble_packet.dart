class BlePacket {
  BlePacket._({
    required this.raw,
    required this.receivedAt,
    required this.fields,
    required this.issues,
    required this.deviceSequence,
    required this.deviceTimestampMs,
    required this.who,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.magneticStatus,
    required this.magneticIssues,
    required this.mx,
    required this.my,
    required this.mz,
    required this.flexRaw,
    required this.flexNorm,
    required this.predictedLabel,
    required this.predictedConfidence,
    required this.expectedLabel,
  });

  factory BlePacket.parse(String raw, {DateTime? receivedAt}) {
    final fields = <String, String>{};
    final issues = <String>[];
    for (final segment in raw.trim().split(',')) {
      final separator = segment.indexOf('=');
      if (separator <= 0 || separator == segment.length - 1) {
        issues.add('Malformed field: $segment');
        continue;
      }
      final key = segment.substring(0, separator).trim();
      final value = segment.substring(separator + 1).trim();
      if (fields.containsKey(key)) {
        issues.add('Duplicate field: $key');
      }
      fields[key] = value;
    }

    int? parseInt(String key) {
      final value = int.tryParse(fields[key] ?? '');
      if (value == null) issues.add('Missing or invalid $key');
      return value;
    }

    double? parseDouble(String key) {
      final value = double.tryParse(fields[key] ?? '');
      if (value == null || !value.isFinite) {
        issues.add('Missing or invalid $key');
        return null;
      }
      return value;
    }

    final sequence = parseInt('seq');
    final timestamp = parseInt('t_ms');
    final who = fields['who'];
    if (who == null || !RegExp(r'^0x[0-9A-Fa-f]{2}$').hasMatch(who)) {
      issues.add('Missing or invalid who');
    }
    final ax = parseDouble('ax');
    final ay = parseDouble('ay');
    final az = parseDouble('az');
    final gx = parseDouble('gx');
    final gy = parseDouble('gy');
    final gz = parseDouble('gz');
    // Magnetic quality is independent of the existing 11-feature model.
    final magneticIssues = <String>[];
    var magneticStatus = fields['mag'] ?? 'not_reported';
    final hasMagneticAxes = ['mx', 'my', 'mz'].any(fields.containsKey);
    double? mx;
    double? my;
    double? mz;
    if (magneticStatus == 'ok') {
      final values = [
        'mx',
        'my',
        'mz',
      ].map((key) => double.tryParse(fields[key] ?? '')).toList();
      if (values.every((value) => value != null && value.isFinite)) {
        mx = values[0];
        my = values[1];
        mz = values[2];
      } else {
        magneticIssues.add('Invalid or incomplete magnetic vector');
      }
    } else if ((magneticStatus != 'unavailable' &&
            magneticStatus != 'not_reported') ||
        hasMagneticAxes ||
        (fields.containsKey('mag') && magneticStatus == 'not_reported')) {
      magneticIssues.add('Invalid magnetic status or unexpected axes');
    }
    if (issues.any(
      (issue) => [
        'mag',
        'mx',
        'my',
        'mz',
      ].any((key) => issue == 'Duplicate field: $key'),
    )) {
      magneticIssues.add('Duplicate magnetic field');
    }
    if (magneticIssues.isNotEmpty) {
      magneticStatus = 'invalid';
      mx = my = mz = null;
    }
    final flexRaw = List<int?>.generate(5, (index) {
      return parseInt('flex${index}_raw');
    });
    final flexNorm = List<double?>.generate(5, (index) {
      final value = fields['flex${index}_norm'];
      if (value == null) return null;
      final parsed = double.tryParse(value);
      return parsed != null && parsed.isFinite ? parsed : null;
    });

    return BlePacket._(
      raw: raw,
      receivedAt: (receivedAt ?? DateTime.now()).toUtc(),
      fields: Map.unmodifiable(fields),
      issues: List.unmodifiable(issues),
      deviceSequence: sequence,
      deviceTimestampMs: timestamp,
      who: who,
      ax: ax,
      ay: ay,
      az: az,
      gx: gx,
      gy: gy,
      gz: gz,
      magneticStatus: magneticStatus,
      magneticIssues: List.unmodifiable(magneticIssues),
      mx: mx,
      my: my,
      mz: mz,
      flexRaw: List.unmodifiable(flexRaw),
      flexNorm: List.unmodifiable(flexNorm),
      predictedLabel: fields['pred'],
      predictedConfidence: double.tryParse(fields['pred_conf'] ?? ''),
      expectedLabel: fields['expected'],
    );
  }

  final String raw;
  final DateTime receivedAt;
  final Map<String, String> fields;
  final List<String> issues;
  final int? deviceSequence;
  final int? deviceTimestampMs;
  final String? who;
  final double? ax;
  final double? ay;
  final double? az;
  final double? gx;
  final double? gy;
  final double? gz;

  /// Per-packet availability, not proof of calibrated orientation.
  final String magneticStatus;
  final List<String> magneticIssues;
  final double? mx;
  final double? my;
  final double? mz;
  bool get hasMagneticData => magneticStatus == 'ok';
  final List<int?> flexRaw;
  final List<double?> flexNorm;
  final String? predictedLabel;
  final double? predictedConfidence;
  final String? expectedLabel;

  /// Select the best class in the lesson category, retaining its original
  /// full-model confidence. Older firmware can supply a same-category global
  /// prediction; an opposite-category prediction is never shown in practice.
  (String?, double?) predictionForStaticTarget(String target) {
    final normalized = target.trim().toUpperCase();
    final isLetter = RegExp(r'^[A-Z]$').hasMatch(normalized);
    if (!isLetter && !RegExp(r'^[0-9]$').hasMatch(normalized)) {
      return (null, null);
    }
    final category = isLetter ? 'letter' : 'number';
    final hasCategory =
        fields.containsKey('pred_$category') ||
        fields.containsKey('pred_${category}_conf');
    final label = (hasCategory ? fields['pred_$category'] : predictedLabel)
        ?.trim()
        .toUpperCase();
    final confidence = hasCategory
        ? double.tryParse(fields['pred_${category}_conf'] ?? '')
        : predictedConfidence;
    final pattern = isLetter ? r'^[A-Z]$' : r'^[0-9]$';
    if (label == null ||
        !RegExp(pattern).hasMatch(label) ||
        confidence == null ||
        !confidence.isFinite ||
        confidence < 0 ||
        confidence > 100) {
      return (null, null);
    }
    return (label, confidence);
  }

  bool get isValid => issues.isEmpty;

  /// Static letter/number collection needs a timestamped flex frame, but not
  /// motion data. Dynamic word collection must continue to use [isValid].
  bool get isStaticFlexValid =>
      deviceSequence != null &&
      deviceTimestampMs != null &&
      flexRaw.every((value) => value != null);
}
