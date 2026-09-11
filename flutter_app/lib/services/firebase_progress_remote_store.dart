import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'progress_repository.dart';

class FirebaseProgressRemoteStore implements ProgressRemoteStore {
  FirebaseProgressRemoteStore({
    this.operationTimeout = const Duration(seconds: 8),
  });

  final Duration operationTimeout;

  @override
  Future<ProgressData?> read() {
    return _guard(() async {
      final user = await _anonymousUser();
      final snapshot = await _document(
        user.uid,
      ).get(const GetOptions(source: Source.server));
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
      final user = await _anonymousUser();
      final letters = progress.learnedLetters.toList()..sort();
      final numbers = progress.learnedNumbers.toList()..sort();
      final exercises = progress.completedExercises.toList()..sort();
      await _document(user.uid).set({
        'schema_version': progressSchemaVersion,
        'learned_letters': letters,
        'learned_numbers': numbers,
        'completed_exercises': exercises,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('current');
  }

  Future<User> _anonymousUser() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) return currentUser;
    final credential = await auth.signInAnonymously();
    final user = credential.user;
    if (user == null) throw const ProgressRemoteSyncException();
    return user;
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
