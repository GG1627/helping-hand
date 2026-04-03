import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WarmClayColors {
  static const background = Color(0xFFFDF6EF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFF0DDD1);
  static const accentPrimary = Color(0xFFC96A3C);
  static const accentLight = Color(0xFFF5E5D8);
  static const textPrimary = Color(0xFF2E1A10);
  static const textSecondary = Color(0xFF9A6B52);
  static const streak = Color(0xFFC96A3C);
}

class WarmClayTheme {
  static const screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 24,
  );
  static const cardRadius = 16.0;
  static const pillRadius = 99.0;
  static const cardGap = 12.0;

  static ThemeData build() {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: WarmClayColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: WarmClayColors.textPrimary,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: WarmClayColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: WarmClayColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: WarmClayColors.textPrimary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: WarmClayColors.textSecondary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: WarmClayColors.background,
      colorScheme: const ColorScheme.light(
        primary: WarmClayColors.accentPrimary,
        secondary: WarmClayColors.accentLight,
        surface: WarmClayColors.surface,
        onSurface: WarmClayColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: WarmClayColors.background,
        foregroundColor: WarmClayColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: WarmClayColors.accentPrimary),
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: WarmClayColors.textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WarmClayColors.accentPrimary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WarmClayTheme.pillRadius),
          ),
        ),
      ),
    );
  }
}
