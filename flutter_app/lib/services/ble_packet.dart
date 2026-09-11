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
  final List<int?> flexRaw;
  final List<double?> flexNorm;
  final String? predictedLabel;
  final double? predictedConfidence;
  final String? expectedLabel;

  bool get isValid => issues.isEmpty;
}
