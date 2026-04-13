import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_shell.dart';
import 'screens/start_screen.dart';
import 'theme/warm_clay_theme.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /* try {
  await FirebaseFirestore.instance
      .collection('connection_test')
      .add({'timestamp': DateTime.now().toIso8601String()});
  print('Firebase connection verified!');
} catch (e) {
  print('Firebase connection failed: $e');
} */

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  runApp(const HelpingHandApp());
}

class HelpingHandApp extends StatelessWidget {
  const HelpingHandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helping Hand',
      theme: WarmClayTheme.build(),
      home: const HelpingHandRoot(),
    );
  }
}

class HelpingHandRoot extends StatefulWidget {
  const HelpingHandRoot({super.key});

  @override
  State<HelpingHandRoot> createState() => _HelpingHandRootState();
}

class _HelpingHandRootState extends State<HelpingHandRoot> {
  bool started = false;

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return StartScreen(
        onGetStarted: () {
          setState(() {
            started = true;
          });
        },
      );
    }
    return const MainShell();
  }
}
