import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late RecordingService service;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'helping_hand_recording_test_',
    );
    service = RecordingService(
      storageDirectoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    service.dispose();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('saves raw packets, numeric values, and manifest metadata', () async {
    final error = service.startTrial(
      const TrialMetadata(
        word: 'thank_you',
        vocabularyVersion: 'words-draft',
        signerId: 'signer_01',
        orientationCondition: 'neutral',
        trialId: 'trial_001',
      ),
      isConnected: true,
      hasFreshValidPacket: true,
    );
    expect(error, isNull);

    for (var index = 0; index < 20; index++) {
      service.handlePacket(_packet(index));
    }
    expect(service.stopTrial(), isNull);
    expect(service.currentPacketCount, 20);
    expect(service.currentWarnings, isEmpty);
    expect(await service.saveTrial(), isNull);

    final files = service.lastSavedFiles!;
    expect(await files.csv.exists(), isTrue);
    expect(await files.manifest.exists(), isTrue);
    final csv = await files.csv.readAsString();
    expect(csv, startsWith('${wordRecordingCsvColumns.join(',')}\n'));
    expect(csv, contains('thank_you'));
    expect(csv, contains('"seq=100,t_ms=1000,who=0x70'));

    final manifest =
        jsonDecode(await files.manifest.readAsString()) as Map<String, dynamic>;
    expect(manifest['schema_version'], wordRecordingSchemaVersion);
    expect(manifest['data_origin'], 'real');
    expect(manifest['target_sample_rate_hz'], 40);
    expect(manifest['vocabulary'], ['thank_you']);
    expect(manifest['packet_count'], 20);
    expect(manifest['magnetometer_data_present'], isFalse);
  });

  test(
    'rejects disconnected, invalid metadata, and duplicate saved trials',
    () async {
      const metadata = TrialMetadata(
        word: 'hello',
        vocabularyVersion: 'words-draft',
        signerId: 'signer_01',
        orientationCondition: 'neutral',
        trialId: 'trial_001',
      );
      expect(
        service.startTrial(
          metadata,
          isConnected: false,
          hasFreshValidPacket: false,
        ),
        contains('Connect'),
      );
      expect(
        service.startTrial(
          const TrialMetadata(
            word: 'Not Valid!',
            vocabularyVersion: 'words-draft',
            signerId: 'person name',
            orientationCondition: 'neutral',
            trialId: 'trial_001',
          ),
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        isNotNull,
      );

      expect(
        service.startTrial(
          metadata,
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        isNull,
      );
      service.handlePacket(_packet(0));
      service.stopTrial();
      await service.saveTrial();
      expect(
        service.startTrial(
          metadata,
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        contains('already saved'),
      );
    },
  );

  test('persists discard metadata without adding packet rows', () async {
    expect(
      service.startTrial(
        const TrialMetadata(
          word: 'hello',
          vocabularyVersion: 'words-draft',
          signerId: 'signer_02',
          orientationCondition: 'roll_left',
          trialId: 'trial_009',
        ),
        isConnected: true,
        hasFreshValidPacket: true,
      ),
      isNull,
    );
    service.handlePacket(_packet(0));

    expect(await service.discardTrial('bad_sign'), isNull);

    final files = service.lastSavedFiles!;
    final csvLines = await files.csv.readAsLines();
    expect(csvLines, hasLength(1));
    final manifest =
        jsonDecode(await files.manifest.readAsString()) as Map<String, dynamic>;
    final discarded = manifest['discarded_trials'] as List<dynamic>;
    expect(discarded, hasLength(1));
    expect(discarded.first['reason'], 'bad_sign');
    expect(discarded.first['signer_id'], 'signer_02');
    expect(discarded.first['orientation_condition'], 'roll_left');
  });
}

BlePacket _packet(int index) {
  final deviceTimestamp = 1000 + index * 25;
  final raw =
      'seq=${100 + index},t_ms=$deviceTimestamp,who=0x70,'
      'ax=0.1,ay=0.2,az=1.0,gx=1.1,gy=2.2,gz=3.3,'
      'flex0_raw=500,flex1_raw=450,flex2_raw=400,'
      'flex3_raw=350,flex4_raw=300';
  return BlePacket.parse(
    raw,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(
      1800000000000 + index * 25,
      isUtc: true,
    ),
  );
}
