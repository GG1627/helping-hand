import 'package:flutter/material.dart';

void main() {
  runApp(const HelpingHandApp());
}

class AppColors {
  static const background = Color(0xFFF3F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE9EEF3);
  static const primary = Color(0xFF153E63);
  static const secondary = Color(0xFF2A756B);
  static const text = Color(0xFF17212B);
  static const mutedText = Color(0xFF5E6975);
  static const border = Color(0xFFD6DDE5);
  static const success = Color(0xFFBEE3D2);
  static const warning = Color(0xFFFFE2B8);
}

class HelpingHandApp extends StatelessWidget {
  const HelpingHandApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helping Hand',
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
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
  bool _hasStarted = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return StartScreen(
        onGetStarted: () {
          setState(() {
            _hasStarted = true;
          });
        },
      );
    }

    return const MainShell();
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _SurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.pan_tool_alt_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Helping Hand',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Learn ASL with focused lessons for the alphabet and numbers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onGetStarted,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardTab(),
    AlphabetTab(),
    NumbersTab(),
    BleTestingTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceMuted,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sort_by_alpha_outlined),
            selectedIcon: Icon(Icons.sort_by_alpha_rounded),
            label: 'Alphabet',
          ),
          NavigationDestination(
            icon: Icon(Icons.pin_outlined),
            selectedIcon: Icon(Icons.pin_rounded),
            label: 'Numbers',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory_rounded),
            label: 'BLE Testing',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your current ASL progress across the alphabet and numbers.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ProgressSummaryCard(
                      title: 'Overall progress',
                      value: '54%',
                      subtitle: '19 of 35 learning targets complete',
                      accentColor: AppColors.primary,
                    ),
                    ProgressSummaryCard(
                      title: 'Alphabet progress',
                      value: '62%',
                      subtitle: '16 of 26 letters reviewed',
                      accentColor: AppColors.secondary,
                    ),
                    ProgressSummaryCard(
                      title: 'Numbers progress',
                      value: '30%',
                      subtitle: '3 of 10 numbers reviewed',
                      accentColor: Color(0xFFC77C2E),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 820;

                    if (compact) {
                      return const Column(
                        children: [
                          ProgressCalendarCard(),
                          SizedBox(height: 16),
                          CurrentFocusCard(),
                        ],
                      );
                    }

                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: ProgressCalendarCard()),
                        SizedBox(width: 16),
                        Expanded(flex: 2, child: CurrentFocusCard()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      child: _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.show_chart_rounded, color: accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressCalendarCard extends StatelessWidget {
  const ProgressCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    const cells = [
      0,
      1,
      2,
      0,
      1,
      3,
      2,
      1,
      0,
      2,
      3,
      1,
      0,
      1,
      2,
      2,
      0,
      1,
      3,
      2,
      0,
      1,
      3,
      2,
      1,
      0,
      2,
      3,
    ];

    Color colorForLevel(int level) {
      switch (level) {
        case 1:
          return AppColors.success.withValues(alpha: 0.55);
        case 2:
          return const Color(0xFF75BEA3);
        case 3:
          return AppColors.secondary;
        default:
          return AppColors.surfaceMuted;
      }
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice calendar',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'A quick view of your recent learning consistency.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(cells.length, (index) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorForLevel(cells[index]),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cells[index] == 0
                        ? AppColors.mutedText
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current focus',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          const FocusTile(
            title: 'Alphabet',
            subtitle: 'Next up: G, H, I, J',
            progress: 0.62,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          const FocusTile(
            title: 'Numbers',
            subtitle: 'Next up: 3, 4, 5',
            progress: 0.30,
            accentColor: Color(0xFFC77C2E),
          ),
        ],
      ),
    );
  }
}

class FocusTile extends StatelessWidget {
  const FocusTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AlphabetTab extends StatelessWidget {
  const AlphabetTab({super.key});

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    return _TabScaffold(
      title: 'Alphabet',
      subtitle: 'Learn and review the ASL alphabet one letter at a time.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionBanner(
            title: 'Alphabet roadmap',
            subtitle:
                'Start with the first five letters and build toward full finger-spelling confidence.',
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 18),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Letters',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: letters.split('').map((letter) {
                    final learned = 'ABCDEF'.contains(letter);
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: learned
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: learned ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: learned ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NumbersTab extends StatelessWidget {
  const NumbersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Numbers',
      subtitle: 'Focus on ASL numbers 0 through 9.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionBanner(
            title: 'Numbers 0-9',
            subtitle: 'A simple set of number lessons for early practice.',
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 18),
          _SurfaceCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(10, (index) {
                final learned = index < 3;
                return Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: learned ? AppColors.secondary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: learned ? AppColors.secondary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: learned ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class BleTestingTab extends StatelessWidget {
  const BleTestingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'BLE Testing',
      subtitle: 'Reserved for future Bluetooth Low Energy development.',
      child: const _SurfaceCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BLE testing area',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This tab is intentionally blank for now and will hold BLE scanning, connection, and diagnostics later.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
