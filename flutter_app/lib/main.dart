import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'test_hand_page.dart';
import 'screens/account_screen.dart';
import 'screens/main_shell.dart';
import 'services/firebase_auth_service.dart';
import 'services/progress_repository.dart';
import 'theme/warm_clay_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const HelpingHandApp());
}

class HelpingHandApp extends StatelessWidget {
  const HelpingHandApp({super.key, this.progressRepository, this.authService});

  final ProgressRepository? progressRepository;
  final FirebaseAuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helping Hand',
      theme: WarmClayTheme.build(),
      home: HelpingHandRoot(
        progressRepository: progressRepository,
        authService: authService,
      ),
    );
  }
}

class HelpingHandRoot extends StatefulWidget {
  const HelpingHandRoot({super.key, this.progressRepository, this.authService});

  final ProgressRepository? progressRepository;
  final FirebaseAuthService? authService;

  @override
  State<HelpingHandRoot> createState() => _HelpingHandRootState();
}

class _HelpingHandRootState extends State<HelpingHandRoot> {
  late final FirebaseAuthService _authService =
      widget.authService ?? FirebaseAuthService();
  late Future<void> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization = _authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInitialization,
      builder: (context, initialization) {
        if (initialization.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not connect to the account service.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      _firebaseInitialization = _authService.initialize();
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        if (initialization.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          initialData: _authService.currentUser,
          builder: (context, authState) {
            final user = authState.data;
            if (user != null && !user.isAnonymous) {
              return MainShell(
                key: ValueKey(user.uid),
                userId: user.uid,
                email: user.email ?? '',
                onSignOut: _authService.signOut,
                progressRepository: widget.progressRepository,
              );
            }
            return AccountScreen(authService: _authService);
          },
        );
      },
    );
  }
}
