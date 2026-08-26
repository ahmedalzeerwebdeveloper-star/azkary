import 'package:flutter/material.dart';

class AppTheme {
  // Premium Dark Colors
  static const Color background = Color(0xFF0D1B2A); // Very dark blue/black
  static const Color surface = Color(0xFF1B263B); // Darker surface
  static const Color primary = Color(0xFFE0A96D); // Elegant Gold
  static const Color textPrimary = Color(0xFFE0E1DD); // Off white
  static const Color textSecondary = Color(0xFF778DA9); // Muted blue-grey

  // Premium Light Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // Clean crisp slate-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white card
  static const Color lightPrimary = Color(0xFFB8782E); // Deep Warm Gold (High contrast on white)
  static const Color lightTextPrimary = Color(0xFF0F172A); // Midnight Slate (Maximum legibility)
  static const Color lightTextSecondary = Color(0xFF475569); // Medium Slate Grey

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
        headlineSmall: TextStyle(fontFamily: 'Cairo', color: textPrimary, fontSize: 20, height: 1.8, fontWeight: FontWeight.w600),
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

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        surface: lightSurface,
        onSurface: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: lightPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: lightPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', color: lightTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Cairo', color: lightTextPrimary, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Cairo', color: lightTextPrimary, fontSize: 20, height: 1.8, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Cairo', color: lightTextPrimary, fontSize: 18, height: 1.6),
        bodyMedium: TextStyle(fontFamily: 'Cairo', color: lightTextPrimary, fontSize: 16),
        bodySmall: TextStyle(fontFamily: 'Cairo', color: lightTextSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
