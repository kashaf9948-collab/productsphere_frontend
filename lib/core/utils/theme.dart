import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color primary = Color(0xFF00796B); // Teal brand color
  static const Color primaryDark = Color(0xFF004D40); // Darker teal
  static const Color primaryLight = Color(0xFFE0F2F1); // Teal tint bg

  static const Color dark = Color(0xFF212121);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);

  // ── Status Colors ─────────────────────────────────────────
  static const Color active = Color(0xFF2E7D32); // Green
  static const Color activeLight = Color(0xFFE8F5E9);
  static const Color expired = Color(0xFFC62828); // Red
  static const Color expiredLight = Color(0xFFFFEBEE);
  static const Color pending = Color(0xFFEF6C00); // Orange
  static const Color pendingLight = Color(0xFFFFF3E0);

  // ── Text Colors ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF263238); // Blue-grey dark
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A252C);

  // ── Border & Shadow ───────────────────────────────────────
  static const Color border = Color(0xFFCFD8DC);
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );

  // ── Radius ────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // ── ThemeData ─────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: textOnPrimary,
      surface: surface,
      background: background,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Lexend',

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: textOnPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textOnPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFECEFF1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color.fromARGB(255, 158, 177, 187), fontSize: 14),
    ),
  );
}
