import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFAFAFA);
  static const Color secondary = Color(0xFF6366F1);
  static const Color accent = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color supporting = Color(0xFFE0E7FF);

  static ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: secondary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardTheme(
      color: supporting,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondary,
      primary: primary,
      secondary: secondary,
      error: accent,
    ),
  );
}