import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'json_progress_local_store.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth? _auth;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _auth ??= FirebaseAuth.instance;
  }

  Future<UserCredential> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final current = auth.currentUser;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final result = current?.isAnonymous == true
        ? await current!.linkWithCredential(credential)
        : await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

    final user = result.user;
    if (user == null) throw StateError('Firebase did not return the new user.');
    final name = displayName.trim();
    if (name.isNotEmpty) await user.updateDisplayName(name);
    await JsonProgressLocalStore.migrateLegacyProgress(user.uid);
    return result;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    if (auth.currentUser?.isAnonymous == true) await auth.signOut();
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => auth.signOut();
}
