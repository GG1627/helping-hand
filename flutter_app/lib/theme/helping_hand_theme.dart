import 'package:flutter/material.dart';

import 'warm_clay_theme.dart';

/// The Hands in motion design system, adopted by the Home pilot first.
class HelpingHandColors {
  static const primary = Color(0xFF007A70);
  static const primaryPressed = Color(0xFF00645C);
  static const secondary = Color(0xFFC8F0DD);
  static const accent = Color(0xFFFFD166);
  static const background = Color(0xFFFFFCF5);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF183B36);
  static const textSecondary = Color(0xFF526560);
  static const divider = Color(0xFFD9E2DC);
  static const outline = Color(0xFF81958C);
  static const success = Color(0xFF23754D);
  static const error = Color(0xFFB33B36);
  static const errorSurface = Color(0xFFFCEDEA);
}

class HelpingHandTheme {
  static ThemeData build() {
    final base = WarmClayTheme.build();
    final text = base.textTheme.apply(
      bodyColor: HelpingHandColors.textPrimary,
      displayColor: HelpingHandColors.textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: HelpingHandColors.background,
      colorScheme: const ColorScheme.light(
        primary: HelpingHandColors.primary,
        onPrimary: Colors.white,
        secondary: HelpingHandColors.secondary,
        onSecondary: HelpingHandColors.textPrimary,
        surface: HelpingHandColors.surface,
        onSurface: HelpingHandColors.textPrimary,
        error: HelpingHandColors.error,
        outline: HelpingHandColors.outline,
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 32,
          height: 38 / 32,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 28,
          height: 34 / 28,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          height: 26 / 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 18,
          height: 24 / 18,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
        bodySmall: text.bodySmall?.copyWith(
          fontSize: 14,
          height: 20 / 14,
          color: HelpingHandColors.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HelpingHandColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: HelpingHandColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
              textStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? const Color(0xFFE7ECE8)
                    : states.contains(WidgetState.pressed)
                    ? HelpingHandColors.primaryPressed
                    : HelpingHandColors.primary,
              ),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? Colors.white.withValues(alpha: 0.24)
                    : null,
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: HelpingHandColors.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: HelpingHandColors.primary,
          side: const BorderSide(color: HelpingHandColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HelpingHandColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
