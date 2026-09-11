import 'test_hand_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_shell.dart';
import 'screens/start_screen.dart';
import 'services/progress_repository.dart';
import 'theme/warm_clay_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const HelpingHandApp());
}

class HelpingHandApp extends StatelessWidget {
  const HelpingHandApp({super.key, this.progressRepository});

  final ProgressRepository? progressRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helping Hand',
      theme: WarmClayTheme.build(),
      home: HelpingHandRoot(progressRepository: progressRepository),
    );
  }
}

class HelpingHandRoot extends StatefulWidget {
  const HelpingHandRoot({super.key, this.progressRepository});

  final ProgressRepository? progressRepository;

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
    return MainShell(progressRepository: widget.progressRepository);
  }
}
