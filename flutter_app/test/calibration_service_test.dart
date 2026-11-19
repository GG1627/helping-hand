import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/ble_packet.dart';
import 'package:flutter_app/services/calibration_service.dart';
import 'package:flutter_app/services/recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

BlePacket calibrationPacket(
  int sequence,
  DateTime now, {
  String pose = 'open_1',
  bool flat = false,
  int? indexRaw,
}) {
  final flex = List.filled(5, 700);
  for (var i = 0; i < 5; i++) {
    if (!flat && pose.startsWith('${calibrationFingers[i]}_bent')) {
      flex[i] = 300;
    }
  }
  if (indexRaw != null) flex[1] = indexRaw;
  final accel = <double>[0, 0, 1];
  if (RegExp(r'^[xyz]_-?1$').hasMatch(pose)) {
    accel.fillRange(0, 3, 0);
    accel[['x', 'y', 'z'].indexOf(pose[0])] = pose.endsWith('_-1') ? -1 : 1;
  }
  return BlePacket.parse(
    'seq=$sequence,t_ms=${sequence * 25},who=0xEA,'
    'ax=${accel[0]},ay=${accel[1]},az=${accel[2]},gx=0.2,gy=-0.1,gz=0.3,'
    '${List.generate(5, (i) => 'flex${i}_raw=${flex[i]}').join(',')},mag=unavailable',
    receivedAt: now,
  );
}

void completeCalibration(
  CalibrationService service,
  void Function(BlePacket) send,
  DateTime Function() nextTime, {
  bool flat = false,
  String? clippedPoseId,
}) {
  var sequence = 1;
  while (!service.complete) {
    final pose = service.step.id;
    service.start(connected: true, fresh: true, recordingBusy: false);
    for (var i = 0; i <= 120; i++) {
      send(
        calibrationPacket(
          sequence++,
          nextTime(),
          pose: pose,
          flat: flat,
          indexRaw: pose == clippedPoseId && i == 0 ? 4095 : null,
        ),
      );
    }
  }
}

void main() {
  late Directory directory;
  late CalibrationService service;
  late DateTime now;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hh_calibration_');
    now = DateTime.utc(2026, 11, 5);
    service = CalibrationService(
      storageDirectoryProvider: () async => directory,
      clock: () => now,
    );
    await service.initialize();
  });
  tearDown(() async {
    service.dispose();
    await directory.delete(recursive: true);
  });
  DateTime nextTime() => now = now.add(const Duration(milliseconds: 25));

  test(
    'captures measured endpoints, bias and axes; saves raw evidence and reloads profile',
    () async {
      completeCalibration(service, service.handlePacket, nextTime);
      final measured = service.measurements();
      expect(measured['blockers'], isEmpty);
      expect(measured['gyro_bias_dps'], [
        closeTo(.2, 1e-8),
        closeTo(-.1, 1e-8),
        closeTo(.3, 1e-8),
      ]);
      expect(measured['flex'][0]['straight_raw'], 700);
      expect(measured['flex'][0]['bent_raw'], 300);
      expect(
        await service.save(
          gloveId: 'glove_01',
          mountingId: 'mount_1',
          firmwareRevision: 'build1',
          settingsNotes: 'test',
        ),
        isFalse,
      );
      service.axisCheckConfirmed = true;
      expect(
        await service.save(
          gloveId: 'glove_01',
          mountingId: 'mount_1',
          firmwareRevision: 'ea38c33',
          settingsNotes: '2g, 250dps, DLPF3, 40Hz',
        ),
        isTrue,
      );
      final profile = service.activeProfile!;
      expect(profile.toJson()['applied_to_inference'], isFalse);
      expect(profile.toJson()['magnetic_calibration_status'], 'not_performed');
      final captures = jsonDecode(
        await File(
          '${directory.path}/calibration/${profile.id}/captures.json',
        ).readAsString(),
      );
      expect(captures['captures'].length, calibrationSteps.length);
      expect(
        captures['captures']['open_1'].first['raw_packet'],
        contains('flex0_raw=700'),
      );
      // Returned snapshots cannot mutate a saved profile.
      profile.toJson()['flex'][0]['straight_raw'] = -1;
      expect(profile.toJson()['flex'][0]['straight_raw'], 700);
      final loaded = CalibrationService(
        storageDirectoryProvider: () async => directory,
      );
      await loaded.initialize();
      expect(loaded.activeProfile!.id, profile.id);
      loaded.dispose();
      now = now.add(const Duration(seconds: 1));
      expect(
        await service.save(
          gloveId: 'glove_01',
          mountingId: 'mount_2',
          firmwareRevision: 'build1',
          settingsNotes: 'test',
        ),
        isTrue,
      );
      expect(service.activeProfile!.id, isNot(profile.id));
      expect(
        await File(
          '${directory.path}/calibration/${profile.id}/profile.json',
        ).exists(),
        isTrue,
      );
    },
  );

  test('blocks flat sensors and incomplete operator checks', () async {
    completeCalibration(service, service.handlePacket, nextTime, flat: true);
    expect(service.measurements()['blockers'], isNotEmpty);
    service.axisCheckConfirmed = true;
    expect(
      await service.save(
        gloveId: 'glove_01',
        mountingId: 'mount_1',
        firmwareRevision: 'build1',
        settingsNotes: 'test',
      ),
      isFalse,
    );
    expect(service.activeProfile, isNull);
  });

  test('redo replaces just the selected pose after a complete capture', () {
    completeCalibration(
      service,
      service.handlePacket,
      nextTime,
      clippedPoseId: 'index_bent_2',
    );
    final original = service.review();
    expect(original.failedPoseIds, {'index_bent_2'});
    expect(original.measurements['blockers'], [
      'index: ADC clipping at a rail.',
    ]);
    final diagnostics = service.diagnosticSnapshot(
      gloveId: '',
      mountingId: '',
      firmwareRevision: '',
      settingsNotes: '',
    );
    expect(
      diagnostics['full_review']['blockers'],
      original.measurements['blockers'],
    );
    expect(
      diagnostics['captures']['index_bent_2'].first['raw_packet'],
      contains('flex1_raw=4095'),
    );
    final pose = calibrationSteps.firstWhere((s) => s.id == 'index_bent_2');
    service.axisCheckConfirmed = true;
    service.retakePose(pose);
    expect(service.step.id, pose.id);
    expect(service.complete, isFalse);
    expect(service.capturedPoseCount, calibrationSteps.length);
    service.start(connected: true, fresh: true, recordingBusy: false);
    service.handlePacket(calibrationPacket(1, nextTime(), pose: pose.id));
    service.handlePacket(calibrationPacket(3, nextTime(), pose: pose.id));
    expect(service.capturing, isFalse);
    service.keepPreviousCapture();
    expect(service.review(), isNotNull);
    expect(service.measurements(), original.measurements);

    service.retakePose(pose);
    service.start(connected: true, fresh: true, recordingBusy: false);
    for (var i = 0; i <= 120; i++) {
      service.handlePacket(calibrationPacket(i + 1, nextTime(), pose: pose.id));
    }
    expect(service.complete, isTrue);
    expect(service.axisCheckConfirmed, isTrue);
    final renewed = service.review();
    expect(renewed.failedPoseIds, isEmpty);
    expect(renewed.measurements['blockers'], isEmpty);
    expect(
      renewed.measurements['acceleration_axis_checks'],
      original.measurements['acceleration_axis_checks'],
    );
    for (var i = 0; i < calibrationFingers.length; i++) {
      if (calibrationFingers[i] != 'index') {
        expect(
          renewed.measurements['flex'][i],
          original.measurements['flex'][i],
        );
      }
    }
  });

  test(
    'IMU diagnostics capture six faces with clipping and a failed axis',
    () async {
      final imu = CalibrationService(imuOnly: true, clock: () => now);
      addTearDown(imu.dispose);
      expect(imu.initialized, isTrue);
      expect(imu.steps.map((pose) => pose.id), [
        'x_1',
        'x_-1',
        'y_1',
        'y_-1',
        'z_1',
        'z_-1',
      ]);
      Map<String, dynamic> snapshot() => imu.diagnosticSnapshot(
        gloveId: '',
        mountingId: '',
        firmwareRevision: '',
        settingsNotes: '',
      );
      for (final pose in imu.steps) {
        expect(imu.step.id, pose.id);
        imu.start(connected: true, fresh: true, recordingBusy: false);
        for (var i = 0; i <= 120; i++) {
          imu.handlePacket(
            calibrationPacket(
              i + 1,
              nextTime(),
              pose: pose.id == 'y_1' ? 'z_1' : pose.id,
              indexRaw: 4095,
            ),
          );
        }
        if (pose.id == 'x_1') {
          expect(imu.complete, isFalse);
          expect(snapshot()['captures'].keys, ['x_1']);
        }
      }
      expect(imu.complete, isTrue);
      final diagnostic = snapshot();
      expect(diagnostic['capture_mode'], 'imu_only');
      expect(diagnostic.containsKey('profile_id'), isFalse);
      expect(diagnostic['captures'].length, 6);
      expect(diagnostic['acceleration_axis_checks'][2], {
        'pose': 'y_1',
        'median_g': [0, 0, 1],
        'passed': false,
      });
      expect(
        diagnostic['captures']['y_1'].first['raw_packet'],
        contains('flex1_raw=4095'),
      );
      expect(
        await imu.save(
          gloveId: 'glove_01',
          mountingId: 'mount_1',
          firmwareRevision: 'build1',
          settingsNotes: 'test',
        ),
        isFalse,
      );
      expect(imu.activeProfile, isNull);
    },
  );

  test(
    'cancels stale, dropped and disconnected captures without advancing',
    () {
      service.start(connected: true, fresh: true, recordingBusy: false);
      service.handlePacket(calibrationPacket(1, nextTime()));
      service.handlePacket(calibrationPacket(3, nextTime()));
      expect(service.capturing, isFalse);
      expect(service.stepIndex, 0);
      service.start(connected: true, fresh: true, recordingBusy: false);
      now = now.add(const Duration(seconds: 3));
      service.checkCaptureHealth(connected: true);
      expect(service.capturing, isFalse);
      service.start(connected: true, fresh: true, recordingBusy: false);
      service.checkCaptureHealth(connected: false);
      expect(service.capturing, isFalse);
      service.start(connected: true, fresh: true, recordingBusy: true);
      expect(service.capturing, isFalse);
    },
  );

  test(
    'corrupt profiles fail visibly and save errors retain measurements',
    () async {
      final root = Directory('${directory.path}/calibration');
      await root.create();
      await File('${root.path}/active.json').writeAsString('{broken');
      await service.initialize();
      expect(service.activeProfile, isNull);
      expect(service.message, contains('Could not load'));
      final failing = CalibrationService(
        storageDirectoryProvider: () async =>
            throw const FileSystemException('storage unavailable'),
        clock: () => now,
      );
      completeCalibration(failing, failing.handlePacket, nextTime);
      failing.axisCheckConfirmed = true;
      expect(
        await failing.save(
          gloveId: 'glove_01',
          mountingId: 'mount_1',
          firmwareRevision: 'build1',
          settingsNotes: 'test',
        ),
        isFalse,
      );
      expect(failing.complete, isTrue);
      expect(failing.measurements()['blockers'], isEmpty);
      expect(failing.message, contains('Save failed'));
      failing.dispose();
    },
  );

  test(
    'recording freezes profile snapshot and requires a new session after a change',
    () async {
      completeCalibration(service, service.handlePacket, nextTime);
      service.axisCheckConfirmed = true;
      await service.save(
        gloveId: 'glove_01',
        mountingId: 'mount_1',
        firmwareRevision: 'build1',
        settingsNotes: 'test',
      );
      CalibrationProfile? active = service.activeProfile;
      final recorder = RecordingService(
        storageDirectoryProvider: () async => directory,
        calibrationProfileProvider: () => active,
      );
      const metadata = TrialMetadata(
        word: 'hello',
        vocabularyVersion: 'words-draft',
        signerId: 'signer_01',
        orientationCondition: 'neutral',
        trialId: 'trial_1',
      );
      expect(
        recorder.startTrial(
          metadata,
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        isNull,
      );
      recorder.handlePacket(calibrationPacket(1, nextTime()));
      recorder.stopTrial();
      expect(await recorder.saveTrial(), isNull);
      final manifest = jsonDecode(
        await recorder.lastSavedFiles!.manifest.readAsString(),
      );
      expect(manifest['calibration_profile_id'], active!.id);
      expect(manifest['calibration_profile']['flex'][0]['straight_raw'], 700);
      expect(manifest['calibration_applied_to_recorded_values'], isFalse);
      expect(
        await recorder.lastSavedFiles!.csv.readAsString(),
        contains(active.id),
      );
      active = null;
      expect(
        recorder.startTrial(
          metadata,
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        contains('Calibration changed'),
      );
      await recorder.beginNewSession();
      expect(
        recorder.startTrial(
          metadata,
          isConnected: true,
          hasFreshValidPacket: true,
        ),
        isNull,
      );
      recorder.dispose();
    },
  );
}
