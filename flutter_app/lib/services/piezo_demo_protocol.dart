enum PiezoOutput {
  thumb('Thumb', 0),
  indexFinger('Index', 1),
  middle('Middle', 2),
  ring('Ring', 3),
  pinky('Pinky', 4),
  handLeft('Back of hand left', 8),
  handRight('Back of hand right', 9),
  handCenter('Back of hand center', 5),
  handUp('Back of hand top', 6),
  handDown('Back of hand bottom', 7);

  const PiezoOutput(this.label, this.marker);

  final String label;
  // Painter order differs from firmware slot order after the five fingers.
  final int marker;
}

enum PiezoDemoAction {
  enable('Q'),
  pulse('P'),
  stop('S');

  const PiezoDemoAction(this.code);
  final String code;
}

enum PiezoDemoEventType { ready, unavailable, started, ended, rejected }

class PiezoDemoEvent {
  const PiezoDemoEvent(this.type, this.requestId, this.output);

  static const prefix = 'HP1,';
  final PiezoDemoEventType type;
  final int requestId;
  final PiezoOutput? output;

  static PiezoDemoEvent? tryParse(String payload) {
    if (!payload.startsWith(prefix) || payload.length > 16) return null;
    final fields = payload.split(',');
    if (fields.length < 3 || fields.length > 4) return null;
    final id = int.tryParse(fields[2]);
    if (id == null || id < 1 || id > 65535 || fields[2] != '$id') return null;
    final type = switch (fields[1]) {
      'R' => PiezoDemoEventType.ready,
      'U' => PiezoDemoEventType.unavailable,
      'A' => PiezoDemoEventType.started,
      'E' => PiezoDemoEventType.ended,
      'X' => PiezoDemoEventType.rejected,
      _ => null,
    };
    if (type == null) return null;
    if (type == PiezoDemoEventType.started) {
      if (fields.length != 4) return null;
      final slot = int.tryParse(fields[3]);
      if (slot == null ||
          slot < 0 ||
          slot >= PiezoOutput.values.length ||
          fields[3] != '$slot') {
        return null;
      }
      return PiezoDemoEvent(type, id, PiezoOutput.values[slot]);
    }
    return fields.length == 3 ? PiezoDemoEvent(type, id, null) : null;
  }
}
