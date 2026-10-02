import 'package:flutter/material.dart';
import '../theme/helping_hand_theme.dart';

/// Dedicated live-practice page, separate from the lesson picker.
class LearningScreen extends StatelessWidget {
  const LearningScreen({
    super.key,
    required this.title,
    required this.practice,
  });
  final String title;
  final Widget practice;

  static void open(
    BuildContext context, {
    required String category,
    required String target,
    required String title,
    required Widget practice,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/learn/$category/${Uri.encodeComponent(target)}',
        ),
        builder: (_) => LearningScreen(title: title, practice: practice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HelpingHandTheme.build(),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: HelpingHandColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: HelpingHandColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gutter = constraints.maxWidth < 360
                        ? 16.0
                        : constraints.maxWidth >= 600
                        ? 32.0
                        : 24.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: practice,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
