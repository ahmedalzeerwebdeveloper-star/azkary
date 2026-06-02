import 'package:flutter/material.dart';

class AppTheme {
  // Premium Colors
  static const Color background = Color(0xFF0D1B2A); // Very dark blue/black
  static const Color surface = Color(0xFF1B263B); // Darker surface
  static const Color primary = Color(0xFFE0A96D); // Elegant Gold
  static const Color textPrimary = Color(0xFFE0E1DD); // Off white
  static const Color textSecondary = Color(0xFF778DA9); // Muted blue-grey

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: primary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Cairo', color: textPrimary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'Cairo', color: textPrimary, fontSize: 18, height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Cairo', color: textPrimary, fontSize: 16),
        bodySmall: TextStyle(fontFamily: 'Cairo', color: textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
