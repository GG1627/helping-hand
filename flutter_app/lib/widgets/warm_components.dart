import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/warm_clay_theme.dart';

class TabScaffold extends StatelessWidget {
  const TabScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: WarmClayTheme.screenPadding,
          child: child,
        ),
      ),
    );
  }
}

class WarmCard extends StatelessWidget {
  const WarmCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        borderRadius: BorderRadius.circular(WarmClayTheme.cardRadius),
        border: Border.all(color: WarmClayColors.border),
      ),
      child: child,
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: WarmClayColors.border,
        borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: WarmClayColors.accentPrimary,
              borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
            ),
          ),
        ),
      ),
    );
  }
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: WarmClayColors.streak,
        borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarmClayColors.border),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: WarmClayColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: WarmClayColors.textSecondary,
            ),
          ),
        ],
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
      2,
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

    Color toneFor(int level) {
      switch (level) {
        case 1:
          return WarmClayColors.accentLight;
        case 2:
          return const Color(0xFFE9BCA4);
        case 3:
          return WarmClayColors.accentPrimary;
        default:
          return WarmClayColors.surface;
      }
    }

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Calendar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your daily ASL practice.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(cells.length, (index) {
              final tone = toneFor(cells[index]);
              final dark = cells[index] >= 2;
              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WarmClayColors.border),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: dark ? Colors.white : WarmClayColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
