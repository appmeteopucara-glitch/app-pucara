import 'package:flutter/material.dart';
import 'package:pronosticosapp/core/theme/pucara_ui.dart';

class AppTheme {
  static final ThemeData lightTheme = _buildTheme();
  static final ThemeData darkTheme = _buildTheme();

  static ThemeData _buildTheme() {
    const colorScheme = ColorScheme.dark(
      primary: PucaraColors.accent,
      secondary: PucaraColors.accentBright,
      surface: PucaraColors.surfaceStrong,
      error: PucaraColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: PucaraColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: PucaraColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: PucaraColors.textPrimary),
        bodyMedium: TextStyle(color: PucaraColors.textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.white12,
      cardColor: PucaraColors.surface,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PucaraColors.surfaceStrong,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        hintStyle: const TextStyle(color: PucaraColors.textSecondary),
        labelStyle: const TextStyle(color: PucaraColors.textSecondary),
        prefixIconColor: Colors.white,
        suffixIconColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PucaraColors.accentBright),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PucaraColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: PucaraColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PucaraColors.accentBright,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: PucaraColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
