import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  // ============================================================
  // 🟦 MAIN THEME (Vendora Standard)
  // ============================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // --------------------
      // APP BAR
      // --------------------
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.headingSmall,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // --------------------
      // INPUT FIELDS
      // --------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // --------------------
      // BUTTONS
      // --------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // --------------------
      // CARDS
      // --------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      
      // --------------------
      // TEXT
      // --------------------
      textTheme: TextTheme(
        displayLarge: AppTypography.headingLarge,
        displayMedium: AppTypography.headingMedium,
        displaySmall: AppTypography.headingSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.caption,
      ),
    );
  }

  // ============================================================
  // 🟪 VENDORA GRAY THEME (Alternative Theme)
  // ============================================================
  static ThemeData get grayBuyerTheme {
    final base = lightTheme;
    const grayPrimary = Color(0xFF5A5A5A);
    const grayBackground = Color(0xFFF5F5F5);
    const grayDark = Color(0xFF3A3A3A);
    const grayLight = Color(0xFFE0E0E0);
    
    return base.copyWith(
      scaffoldBackgroundColor: grayBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.black,
        secondary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      
      // --------------------
      // APP BAR
      // --------------------
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: grayBackground,
        foregroundColor: grayDark,
        titleTextStyle: AppTypography.headingSmall.copyWith(color: grayDark),
        iconTheme: const IconThemeData(color: grayDark),
      ),
      
      // --------------------
      // INPUT FIELDS - Gray themed
      // --------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade500),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grayLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grayLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grayPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      
      // --------------------
      // BUTTONS - Gray themed
      // --------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // --------------------
      // CARDS - Gray themed
      // --------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: grayLight, width: 1),
        ),
      ),
      
      // --------------------
      // SWITCH & CHECKBOX - Gray themed
      // --------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return grayDark;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return grayPrimary;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  // ============================================================
  // 🟣 VENDORA PURPLE THEME (Alternative Theme)
  // ============================================================
  static ThemeData get purpleBuyerTheme {
    final base = lightTheme;
    const purple = Color(0xFF3A2AD8);
    const purpleLight = Color(0xFF6B5AED);
    const purpleDark = Color(0xFF2A1FA8);
    const purpleBackground = Color(0xFFF8F7FF);
    
    return base.copyWith(
      scaffoldBackgroundColor: purpleBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: purple,
        secondary: purple,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      
      // --------------------
      // APP BAR
      // --------------------
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: purpleBackground,
        foregroundColor: purple,
        titleTextStyle: AppTypography.headingSmall.copyWith(color: purple),
        iconTheme: const IconThemeData(color: purple),
      ),
      
      // --------------------
      // INPUT FIELDS - Purple themed
      // --------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade500),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: purple.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: purple.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      
      // --------------------
      // BUTTONS - Purple themed
      // --------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(color: purple),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      
      // --------------------
      // CARDS - Purple themed
      // --------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: purple.withOpacity(0.2), width: 1),
        ),
      ),
      
      // --------------------
      // SWITCH & CHECKBOX - Purple themed
      // --------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purple;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purpleLight;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }
}
