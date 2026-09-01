import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1B5E20);
  static const secondaryColor = Color(0xFFF57F17);
  static const accentColor = Color(0xFFFFF8E1);
  static const errorColor = Color(0xFFB71C1C);
  static const warningColor = Color(0xFFE65100);
  static const successColor = Color(0xFF00695C);
  static const backgroundColor = Color(0xFFFCF9F8);
  static const surfaceColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: primaryColor,
        onSurface: const Color(0xFF1C1B1B),
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.hindSiliguriTextTheme().copyWith(
        headlineLarge: GoogleFonts.hindSiliguri(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1B1B),
        ),
        headlineMedium: GoogleFonts.hindSiliguri(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1B1B),
        ),
        bodyLarge: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1C1B1B),
        ),
        bodyMedium: GoogleFonts.hindSiliguri(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF41493E),
        ),
        labelLarge: GoogleFonts.hindSiliguri(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: const Color(0xFF1C1B1B),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF717A6D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF717A6D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.hindSiliguri(color: const Color(0xFF41493E)),
      ),
    );
  }
}
