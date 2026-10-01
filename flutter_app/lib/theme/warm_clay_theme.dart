import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WarmClayColors {
  static const background = Color(0xFFF7F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E8E3);
  static const accentPrimary = Color(0xFF285847);
  static const accentLight = Color(0xFFE8F0EB);
  static const textPrimary = Color(0xFF222A25);
  static const textSecondary = Color(0xFF68736C);
  static const success = Color(0xFF2F7854);
  static const info = Color(0xFF4B6F9B);
  static const error = Color(0xFFB64C49);
  static const streak = Color(0xFFB64C49);
}

class WarmClayTheme {
  static const screenPadding = EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 22,
  );
  static const cardRadius = 14.0;
  static const pillRadius = 99.0;
  static const cardGap = 12.0;

  static ThemeData build() {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: WarmClayColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: WarmClayColors.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
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
        fontWeight: FontWeight.w500,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WarmClayColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WarmClayColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WarmClayColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: WarmClayColors.accentPrimary,
            width: 1.5,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: WarmClayColors.background,
        foregroundColor: WarmClayColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: WarmClayColors.textSecondary),
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 19,
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
