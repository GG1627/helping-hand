import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete recording packet', () {
    const raw =
        'seq=42,t_ms=1234,who=0x70,'
        'ax=0.100,ay=-0.200,az=1.000,gx=1.100,gy=2.200,gz=3.300,'
        'expected=-,pred=A,pred_conf=91.5,'
        'flex0_raw=500,flex0_norm=0.122,'
        'flex1_raw=450,flex1_norm=0.110,'
        'flex2_raw=400,flex2_norm=0.098,'
        'flex3_raw=350,flex3_norm=0.085,'
        'flex4_raw=300,flex4_norm=0.073';
    final receivedAt = DateTime.utc(2026, 9, 9, 12);

    final packet = BlePacket.parse(raw, receivedAt: receivedAt);

    expect(packet.isValid, isTrue);
    expect(packet.raw, raw);
    expect(packet.receivedAt, receivedAt);
    expect(packet.deviceSequence, 42);
    expect(packet.deviceTimestampMs, 1234);
    expect(packet.who, '0x70');
    expect(packet.ax, 0.1);
    expect(packet.gz, 3.3);
    expect(packet.flexRaw, [500, 450, 400, 350, 300]);
    expect(packet.predictedLabel, 'A');
    expect(packet.predictedConfidence, 91.5);
  });

  test('retains malformed raw packets and reports missing fields', () {
    const raw = 'who=0x70,ax=bad,imu=offline,broken-field';

    final packet = BlePacket.parse(raw);

    expect(packet.isValid, isFalse);
    expect(packet.raw, raw);
    expect(packet.issues, contains('Missing or invalid seq'));
    expect(packet.issues, contains('Missing or invalid ax'));
    expect(packet.issues, contains('Malformed field: broken-field'));
  });
}
