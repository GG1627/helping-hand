import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/services/json_progress_local_store.dart';
import 'package:flutter_app/services/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressRepository', () {
    late Directory temporaryDirectory;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'helping_hand_progress_test_',
      );
    });

    tearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('saves locally and restores after a new repository starts', () async {
      final store = JsonProgressLocalStore(
        directoryProvider: () async => temporaryDirectory,
      );
      final first = ProgressRepository(
        localStore: store,
        clock: () => DateTime.utc(2026, 9, 10, 12),
      );
      await first.initialize();
      await first.completeStaticTarget('A');
      first.dispose();

      final restored = ProgressRepository(localStore: store);
      await restored.initialize();

      expect(restored.state.progress.learnedLetters, {'A'});
      expect(restored.state.progress.completedExercises, {
        'static_prediction_a',
      });
      expect(restored.state.status, ProgressSyncStatus.offlineLocalOnly);
      restored.dispose();
    });

    test(
      'malformed stored state safely falls back to empty progress',
      () async {
        final store = _MemoryLocalStore(value: '{not-json');
        final repository = ProgressRepository(localStore: store);

        await repository.initialize();

        expect(repository.state.progress.isEmpty, isTrue);
        expect(repository.state.status, ProgressSyncStatus.offlineLocalOnly);
        expect(repository.state.message, contains('invalid'));
        expect(
          ProgressData.fromJson(
            jsonDecode(store.value!) as Map<String, dynamic>,
          ).isEmpty,
          isTrue,
        );
        repository.dispose();
      },
    );

    test('reset clears all progress and persists the empty state', () async {
      final store = _MemoryLocalStore();
      final repository = ProgressRepository(
        localStore: store,
        clock: () => DateTime.utc(2026, 9, 10, 13),
      );
      await repository.initialize();
      await repository.completeStaticTarget('7');

      await repository.reset();

      expect(repository.state.progress.isEmpty, isTrue);
      final stored = ProgressData.fromJson(
        jsonDecode(store.value!) as Map<String, dynamic>,
      );
      expect(stored.isEmpty, isTrue);
      expect(stored.updatedAt, DateTime.utc(2026, 9, 10, 13));
      repository.dispose();
    });

    test('Firebase unavailable keeps the saved local copy usable', () async {
      final store = _MemoryLocalStore();
      final remote = _FakeRemoteStore(
        readError: const ProgressRemoteUnavailableException(),
        writeError: const ProgressRemoteUnavailableException(),
      );
      final repository = ProgressRepository(
        localStore: store,
        remoteStore: remote,
        clock: () => DateTime.utc(2026, 9, 10, 14),
      );

      await repository.initialize();
      await repository.completeStaticTarget('B');

      expect(repository.state.progress.learnedLetters, {'B'});
      expect(repository.state.status, ProgressSyncStatus.offlineLocalOnly);
      expect(store.value, isNotNull);
      repository.dispose();
    });

    test('a reset is pushed even when the cloud timestamp is newer', () async {
      final remoteProgress = ProgressData().completeStaticTarget(
        'G',
        DateTime.utc(2030),
      );
      final store = _MemoryLocalStore(
        value: jsonEncode(remoteProgress.toJson()),
      );
      final remote = _FakeRemoteStore(value: remoteProgress);
      final repository = ProgressRepository(
        localStore: store,
        remoteStore: remote,
        clock: () => DateTime.utc(2026, 9, 10, 17),
      );
      await repository.initialize();

      await repository.reset();

      expect(remote.writeCount, 2);
      expect(remote.value?.isEmpty, isTrue);
      expect(repository.state.status, ProgressSyncStatus.synced);
      repository.dispose();
    });

    test('newer local progress is written to the cloud', () async {
      final localProgress = ProgressData().completeStaticTarget(
        'C',
        DateTime.utc(2026, 9, 10, 16),
      );
      final remoteProgress = ProgressData().completeStaticTarget(
        'D',
        DateTime.utc(2026, 9, 10, 15),
      );
      final store = _MemoryLocalStore(
        value: jsonEncode(localProgress.toJson()),
      );
      final remote = _FakeRemoteStore(value: remoteProgress);
      final repository = ProgressRepository(
        localStore: store,
        remoteStore: remote,
      );

      await repository.initialize();

      expect(remote.writeCount, 1);
      expect(remote.value?.learnedLetters, {'C'});
      expect(repository.state.status, ProgressSyncStatus.synced);
      repository.dispose();
    });

    test('newer cloud progress replaces and saves the local copy', () async {
      final localProgress = ProgressData().completeStaticTarget(
        'E',
        DateTime.utc(2026, 9, 10, 15),
      );
      final remoteProgress = ProgressData().completeStaticTarget(
        'F',
        DateTime.utc(2026, 9, 10, 16),
      );
      final store = _MemoryLocalStore(
        value: jsonEncode(localProgress.toJson()),
      );
      final remote = _FakeRemoteStore(value: remoteProgress);
      final repository = ProgressRepository(
        localStore: store,
        remoteStore: remote,
      );

      await repository.initialize();

      expect(repository.state.progress.learnedLetters, {'F'});
      expect(remote.writeCount, 0);
      final saved = ProgressData.fromJson(
        jsonDecode(store.value!) as Map<String, dynamic>,
      );
      expect(saved.learnedLetters, {'F'});
      repository.dispose();
    });
  });
}

class _MemoryLocalStore implements ProgressLocalStore {
  _MemoryLocalStore({this.value});

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

class _FakeRemoteStore implements ProgressRemoteStore {
  _FakeRemoteStore({this.value, this.readError, this.writeError});

  ProgressData? value;
  final Object? readError;
  final Object? writeError;
  int writeCount = 0;

  @override
  Future<ProgressData?> read() async {
    if (readError != null) throw readError!;
    return value;
  }

  @override
  Future<void> write(ProgressData progress) async {
    if (writeError != null) throw writeError!;
    writeCount += 1;
    value = progress;
  }
}
