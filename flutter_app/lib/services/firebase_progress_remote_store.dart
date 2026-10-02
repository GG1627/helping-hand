import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'progress_repository.dart';

class FirebaseProgressRemoteStore implements ProgressRemoteStore {
  FirebaseProgressRemoteStore({
    required this.uid,
    this.operationTimeout = const Duration(seconds: 8),
  });

  final String uid;
  final Duration operationTimeout;

  @override
  Future<ProgressData?> read() {
    return _guard(() async {
      _requireCurrentUser();
      final snapshot = await _document().get(
        const GetOptions(source: Source.server),
      );
      final data = snapshot.data();
      if (data == null) return null;

      final updatedAt = data['updated_at'];
      if (updatedAt != null && updatedAt is! Timestamp) {
        throw const ProgressRemoteSyncException();
      }
      try {
        return ProgressData.fromJson({
          ...data,
          'updated_at': (updatedAt as Timestamp?)
              ?.toDate()
              .toUtc()
              .toIso8601String(),
        });
      } on FormatException {
        throw const ProgressRemoteSyncException();
      }
    });
  }

  @override
  Future<void> write(ProgressData progress) {
    return _guard(() async {
      _requireCurrentUser();
      final letters = progress.learnedLetters.toList()..sort();
      final numbers = progress.learnedNumbers.toList()..sort();
      final exercises = progress.completedExercises.toList()..sort();
      await _document().set({
        'schema_version': progressSchemaVersion,
        'learned_letters': letters,
        'learned_numbers': numbers,
        'completed_exercises': exercises,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _document() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('current');
  }

  void _requireCurrentUser() {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw const ProgressRemoteSyncException();
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(operationTimeout);
    } on ProgressRemoteUnavailableException {
      rethrow;
    } on ProgressRemoteSyncException {
      rethrow;
    } on TimeoutException {
      throw const ProgressRemoteUnavailableException();
    } on FirebaseException catch (error) {
      if (const {
        'deadline-exceeded',
        'network-request-failed',
        'unavailable',
      }.contains(error.code)) {
        throw const ProgressRemoteUnavailableException();
      }
      throw const ProgressRemoteSyncException();
    } on Object {
      throw const ProgressRemoteSyncException();
    }
  }
}
