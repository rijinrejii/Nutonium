import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color forest = Color(0xFF173327);
  static const Color forestDeep = Color(0xFF10251C);
  static const Color brass = Color(0xFFC8A45E);
  static const Color parchment = Color(0xFFF3EBDD);
  static const Color canvas = Color(0xFFEEE5D4);
  static const Color card = Color(0xFFFFFBF4);
  static const Color ink = Color(0xFF1E1B16);
  static const Color muted = Color(0xFF6D675E);
  static const Color success = Color(0xFF2F7B57);
  static const Color warning = Color(0xFFBF7F22);
  static const Color danger = Color(0xFFB5483C);
}

class AppTheme {
  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.forest,
      onPrimary: Colors.white,
      secondary: AppPalette.brass,
      onSecondary: AppPalette.ink,
      error: AppPalette.danger,
      onError: Colors.white,
      surface: AppPalette.card,
      onSurface: AppPalette.ink,
    );

    final baseBody = GoogleFonts.manropeTextTheme();
    final display = GoogleFonts.cormorantGaramondTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.parchment,
      textTheme: baseBody.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: display.displaySmall?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseBody.titleLarge?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseBody.titleMedium?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseBody.bodyLarge?.copyWith(
          color: AppPalette.ink,
          height: 1.45,
        ),
        bodyMedium: baseBody.bodyMedium?.copyWith(
          color: AppPalette.ink,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPalette.ink,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppPalette.forest.withValues(alpha: 0.08)),
        ),
      ),
      dividerColor: AppPalette.forest.withValues(alpha: 0.12),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppPalette.forest,
        disabledColor: Colors.white,
        secondarySelectedColor: AppPalette.forest,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: AppPalette.forest.withValues(alpha: 0.14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: baseBody.labelLarge!.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: baseBody.labelLarge!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: baseBody.bodyMedium?.copyWith(color: AppPalette.muted),
        hintStyle: baseBody.bodyMedium?.copyWith(
          color: AppPalette.muted.withValues(alpha: 0.72),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppPalette.forest.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppPalette.forest, width: 1.2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppPalette.forest.withValues(alpha: 0.12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseBody.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.forest,
          side: BorderSide(color: AppPalette.forest.withValues(alpha: 0.24)),
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseBody.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.forestDeep,
        contentTextStyle: baseBody.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}