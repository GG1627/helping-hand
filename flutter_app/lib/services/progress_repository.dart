import 'dart:async';
import 'dart:convert';

const int progressSchemaVersion = 1;

enum ProgressSyncStatus {
  loading,
  savedLocally,
  syncing,
  synced,
  offlineLocalOnly,
  syncFailure,
  localSaveFailure,
}

class ProgressData {
  ProgressData({
    Set<String> learnedLetters = const <String>{},
    Set<int> learnedNumbers = const <int>{},
    Set<String> completedExercises = const <String>{},
    this.updatedAt,
  }) : learnedLetters = Set.unmodifiable(learnedLetters),
       learnedNumbers = Set.unmodifiable(learnedNumbers),
       completedExercises = Set.unmodifiable(completedExercises);

  factory ProgressData.empty() => ProgressData();

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != progressSchemaVersion) {
      throw const FormatException('Unsupported progress schema version.');
    }

    final letters = _readStringSet(json, 'learned_letters');
    if (letters.any((letter) => !RegExp(r'^[A-Z]$').hasMatch(letter))) {
      throw const FormatException(
        'Stored progress contains an invalid letter.',
      );
    }

    final numbersValue = json['learned_numbers'];
    if (numbersValue is! List<dynamic> ||
        numbersValue.any((value) => value is! int || value < 0 || value > 9)) {
      throw const FormatException(
        'Stored progress contains an invalid number.',
      );
    }

    final exercises = _readStringSet(json, 'completed_exercises');
    if (exercises.any(
      (exercise) => !RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(exercise),
    )) {
      throw const FormatException(
        'Stored progress contains an invalid exercise identifier.',
      );
    }

    final updatedAtValue = json['updated_at'];
    DateTime? updatedAt;
    if (updatedAtValue != null) {
      if (updatedAtValue is! String) {
        throw const FormatException(
          'Stored progress has an invalid timestamp.',
        );
      }
      updatedAt = DateTime.tryParse(updatedAtValue)?.toUtc();
      if (updatedAt == null) {
        throw const FormatException(
          'Stored progress has an invalid timestamp.',
        );
      }
    }

    return ProgressData(
      learnedLetters: letters,
      learnedNumbers: numbersValue.cast<int>().toSet(),
      completedExercises: exercises,
      updatedAt: updatedAt,
    );
  }

  final Set<String> learnedLetters;
  final Set<int> learnedNumbers;
  final Set<String> completedExercises;
  final DateTime? updatedAt;

  bool get isEmpty =>
      learnedLetters.isEmpty &&
      learnedNumbers.isEmpty &&
      completedExercises.isEmpty;

  ProgressData completeStaticTarget(String target, DateTime completedAt) {
    final normalized = target.trim().toUpperCase();
    final letters = learnedLetters.toSet();
    final numbers = learnedNumbers.toSet();

    if (RegExp(r'^[A-Z]$').hasMatch(normalized)) {
      letters.add(normalized);
    } else if (RegExp(r'^[0-9]$').hasMatch(normalized)) {
      numbers.add(int.parse(normalized));
    } else {
      throw ArgumentError.value(target, 'target', 'Must be A-Z or 0-9.');
    }

    return ProgressData(
      learnedLetters: letters,
      learnedNumbers: numbers,
      completedExercises: {
        ...completedExercises,
        'static_prediction_${normalized.toLowerCase()}',
      },
      updatedAt: completedAt.toUtc(),
    );
  }

  ProgressData reset(DateTime resetAt) {
    return ProgressData(updatedAt: resetAt.toUtc());
  }

  Map<String, dynamic> toJson() {
    final letters = learnedLetters.toList()..sort();
    final numbers = learnedNumbers.toList()..sort();
    final exercises = completedExercises.toList()..sort();
    return {
      'schema_version': progressSchemaVersion,
      'learned_letters': letters,
      'learned_numbers': numbers,
      'completed_exercises': exercises,
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static Set<String> _readStringSet(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! List<dynamic> || value.any((item) => item is! String)) {
      throw FormatException('Stored progress has an invalid $field field.');
    }
    return value.cast<String>().toSet();
  }
}

class ProgressRepositoryState {
  const ProgressRepositoryState({
    required this.progress,
    required this.status,
    required this.message,
  });

  final ProgressData progress;
  final ProgressSyncStatus status;
  final String message;
}

abstract interface class ProgressLocalStore {
  Future<String?> read();

  Future<void> write(String value);
}

abstract interface class ProgressRemoteStore {
  Future<ProgressData?> read();

  Future<void> write(ProgressData progress);
}

class ProgressRemoteUnavailableException implements Exception {
  const ProgressRemoteUnavailableException();
}

class ProgressRemoteSyncException implements Exception {
  const ProgressRemoteSyncException();
}

class ProgressRepository {
  ProgressRepository({
    required ProgressLocalStore localStore,
    ProgressRemoteStore? remoteStore,
    DateTime Function()? clock,
  }) : _localStore = localStore,
       _remoteStore = remoteStore,
       _clock = clock ?? DateTime.now;

  final ProgressLocalStore _localStore;
  final ProgressRemoteStore? _remoteStore;
  final DateTime Function() _clock;
  final StreamController<ProgressRepositoryState> _stateController =
      StreamController<ProgressRepositoryState>.broadcast(sync: true);

  Future<void> _pendingOperation = Future<void>.value();
  bool _disposed = false;
  bool _hasUnsyncedLocalChanges = false;
  ProgressRepositoryState _state = ProgressRepositoryState(
    progress: ProgressData.empty(),
    status: ProgressSyncStatus.loading,
    message: 'Loading progress...',
  );

  ProgressRepositoryState get state => _state;
  Stream<ProgressRepositoryState> get states => _stateController.stream;

  Future<void> initialize() => _enqueue(() async {
    _emit(
      progress: _state.progress,
      status: ProgressSyncStatus.loading,
      message: 'Loading progress...',
    );

    var progress = ProgressData.empty();
    String? localWarning;
    try {
      final storedValue = await _localStore.read();
      if (storedValue != null && storedValue.trim().isNotEmpty) {
        final decoded = jsonDecode(storedValue);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Stored progress is not an object.');
        }
        progress = ProgressData.fromJson(decoded);
      }
    } on Object {
      localWarning = 'Saved progress was invalid; started with a safe copy.';
      try {
        await _localStore.write(jsonEncode(progress.toJson()));
      } on Object {
        localWarning =
            'Saved progress was invalid and could not be repaired locally.';
      }
    }

    _emit(
      progress: progress,
      status: _remoteStore == null
          ? ProgressSyncStatus.offlineLocalOnly
          : ProgressSyncStatus.savedLocally,
      message:
          localWarning ??
          (_remoteStore == null
              ? 'Progress is available on this device.'
              : 'Progress loaded from this device.'),
    );
    await _sync(localWarning: localWarning);
  });

  Future<void> completeStaticTarget(String target) => _enqueue(() async {
    final next = _state.progress.completeStaticTarget(target, _clock());
    await _saveLocallyThenSync(next);
  });

  Future<void> reset() => _enqueue(() async {
    await _saveLocallyThenSync(_state.progress.reset(_clock()));
  });

  Future<void> retrySync() => _enqueue(_sync);

  Future<void> _saveLocallyThenSync(ProgressData progress) async {
    _emit(
      progress: progress,
      status: ProgressSyncStatus.loading,
      message: 'Saving progress...',
    );
    try {
      await _localStore.write(jsonEncode(progress.toJson()));
    } on Object {
      _emit(
        progress: progress,
        status: ProgressSyncStatus.localSaveFailure,
        message: 'Progress could not be saved on this device.',
      );
      return;
    }
    _hasUnsyncedLocalChanges = true;

    _emit(
      progress: progress,
      status: ProgressSyncStatus.savedLocally,
      message: 'Saved locally.',
    );
    await _sync();
  }

  Future<void> _sync({String? localWarning}) async {
    final remoteStore = _remoteStore;
    if (remoteStore == null) {
      _emit(
        progress: _state.progress,
        status: ProgressSyncStatus.offlineLocalOnly,
        message: localWarning ?? 'Offline/local-only. Progress is saved here.',
      );
      return;
    }

    _emit(
      progress: _state.progress,
      status: ProgressSyncStatus.syncing,
      message: 'Syncing progress...',
    );

    try {
      final localProgress = _state.progress;
      if (_hasUnsyncedLocalChanges && localProgress.updatedAt != null) {
        await remoteStore.write(localProgress);
        _hasUnsyncedLocalChanges = false;
        _emit(
          progress: localProgress,
          status: ProgressSyncStatus.synced,
          message: 'Synced.',
        );
        return;
      }

      final remoteProgress = await remoteStore.read();
      final localUpdatedAt = localProgress.updatedAt;
      final remoteUpdatedAt = remoteProgress?.updatedAt;

      if (remoteProgress != null &&
          (localUpdatedAt == null ||
              (remoteUpdatedAt != null &&
                  remoteUpdatedAt.isAfter(localUpdatedAt)))) {
        try {
          await _localStore.write(jsonEncode(remoteProgress.toJson()));
        } on Object {
          _emit(
            progress: remoteProgress,
            status: ProgressSyncStatus.localSaveFailure,
            message: 'Cloud progress loaded, but could not be saved locally.',
          );
          return;
        }
        _emit(
          progress: remoteProgress,
          status: ProgressSyncStatus.synced,
          message: localWarning == null
              ? 'Synced.'
              : 'Recovered progress from the cloud and synced.',
        );
        return;
      }

      if (localUpdatedAt != null &&
          (remoteProgress == null ||
              remoteUpdatedAt == null ||
              !localUpdatedAt.isBefore(remoteUpdatedAt))) {
        await remoteStore.write(localProgress);
        _hasUnsyncedLocalChanges = false;
      }

      _emit(
        progress: localProgress,
        status: ProgressSyncStatus.synced,
        message: localWarning ?? 'Synced.',
      );
    } on ProgressRemoteUnavailableException {
      _emit(
        progress: _state.progress,
        status: ProgressSyncStatus.offlineLocalOnly,
        message: 'Offline/local-only. Progress is saved on this device.',
      );
    } on Object {
      _emit(
        progress: _state.progress,
        status: ProgressSyncStatus.syncFailure,
        message: 'Sync failed. Progress remains saved locally.',
      );
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pendingOperation.then((_) => operation());
    _pendingOperation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  void _emit({
    required ProgressData progress,
    required ProgressSyncStatus status,
    required String message,
  }) {
    if (_disposed) return;
    _state = ProgressRepositoryState(
      progress: progress,
      status: status,
      message: message,
    );
    _stateController.add(_state);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_stateController.close());
  }
}
