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
