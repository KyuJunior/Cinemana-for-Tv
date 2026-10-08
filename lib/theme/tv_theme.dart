import 'package:flutter/material.dart';

class TVColors {
  static const Color background = Color(0xFF070A11);
  static const Color surface = Color(0xFF0F172A);
  static const Color card = Color(0xFF161F33);
  static const Color cardFocused = Color(0xFF1E293B);
  
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentSecondary = Color(0xFF38BDF8);
  static const Color gold = Color(0xFFFFB800);
  static const Color crimson = Color(0xFFE50914);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  
  static const Color focusBorder = Color(0xFF00D2FF);
  static const Color focusGlow = Color(0x6600D2FF);
  static const Color focusGlowGold = Color(0x55FFB800);
}

class TVTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TVColors.background,
      primaryColor: TVColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: TVColors.accent,
        secondary: TVColors.accentSecondary,
        surface: TVColors.surface,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: TVColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: TVColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: TVColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: TVColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: TVColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: TVColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: TextStyle(
          color: TVColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
