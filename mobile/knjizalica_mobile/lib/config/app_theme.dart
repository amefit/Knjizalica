import 'package:flutter/material.dart';

/// Visual design aligned with Prijava.doc mobile mockups.
class AppTheme {
  static const Color primary = Color(0xFF111111);
  static const Color primaryLight = Color(0xFF4A6FA5);
  static const Color accent = Color(0xFF9CA3AF);
  static const Color navActiveBg = Color(0xFFE8EEF5);
  static const Color navActive = Color(0xFF4A6FA5);
  static const Color available = Color(0xFF4CAF50);
  static const Color availableBg = Color(0xFFE8F5E9);
  static const Color borrowed = Color(0xFF757575);
  static const Color borrowedBg = Color(0xFFEEEEEE);
  static const Color recommendedBg = Color(0xFF616161);
  static const Color active = Color(0xFF52B1E1);
  static const Color activeBg = Color(0xFFE3F4FC);
  static const Color returned = Color(0xFF76C893);
  static const Color returnedBg = Color(0xFFE8F5E9);
  static const Color overdue = Color(0xFFE57373);
  static const Color overdueBg = Color(0xFFFFEBEE);
  static const Color calendarFree = Color(0xFF4CAF50);
  static const Color calendarBusy = Color(0xFFE53935);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: navActive,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primary,
          elevation: 0,
          side: const BorderSide(color: primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }
}
