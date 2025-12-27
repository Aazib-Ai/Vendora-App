import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // -------------------------
  // COLORS FOR BASE GRAY THEME
  // -------------------------
  static const Color grayPrimary = Color(0xFF1A1A1A);
  static const Color graySecondary = Color(0xFF636363);
  static const Color grayBackground = Color(0xFFFFFFFF);
  static const Color graySurface = Color(0xFFF5F5F5);
  static const Color grayInput = Color(0xFFE0E0E0);

  // -------------------------
  // COLORS FOR PURPLE THEME
  // -------------------------
  static const Color purplePrimary = Color(0xFF3A2AD8);
  static const Color purplePrimaryDark = Color(0xFF2A1FB5);
  static const Color purpleBackground = Color(0xFFF1EEFF);
  static const Color purpleCard = Color(0xFF3A2AD8);

  // ============================================================
  // 🟦 DEFAULT GRAY THEME (Vendora Base)
  // ============================================================
  static ThemeData get grayTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: grayPrimary,
      brightness: Brightness.light,
      primary: grayPrimary,
      secondary: graySecondary,
      surface: graySurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: grayBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // --------------------
      // APP BAR
      // --------------------
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: grayBackground,
        foregroundColor: grayPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: grayPrimary,
        ),
      ),

      // --------------------
      // INPUT FIELDS
      // --------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grayInput,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: graySecondary),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grayPrimary, width: 1.4),
        ),
      ),

      // --------------------
      // BUTTONS
      // --------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: grayPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // --------------------
      // CARDS
      // --------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: graySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ============================================================
  // 🟣 PURPLE THEME (Vendora Prime)
  // ============================================================
  static ThemeData get purpleTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: purplePrimary,
      brightness: Brightness.light,
      primary: purplePrimary,
      secondary: purplePrimaryDark,
      surface: purpleCard,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: purpleBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // --------------------
      // APP BAR
      // --------------------
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: purpleBackground,
        foregroundColor: purplePrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: purplePrimary,
        ),
      ),

      // --------------------
      // INPUT FIELDS
      // --------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: purplePrimaryDark),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: purplePrimary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: purplePrimary, width: 2),
        ),
      ),

      // --------------------
      // BUTTONS
      // --------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purplePrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // --------------------
      // CARDS
      // --------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: purpleCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // --------------------
      // TEXT
      // --------------------
      textTheme: TextTheme(
        bodyMedium: GoogleFonts.poppins(color: purplePrimaryDark),
        bodyLarge: GoogleFonts.poppins(color: purplePrimaryDark),
      ),
    );
  }
}
