import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const primary = Color(0xFF1A1A2E);      // Deep Navy
  static const primaryLight = Color(0xFF16213E); // Navy Blue
  static const accent = Color(0xFFE94560);       // Coral Red (CTAs)
  static const accentLight = Color(0xFFF5A623);  // Golden Yellow (Highlights)
  
  // Neutral Colors
  static const background = Color(0xFFF8F9FA);   // Light Gray Background
  static const surface = Color(0xFFFFFFFF);      // White Cards
  static const textPrimary = Color(0xFF1A1A2E);  // Dark Text
  static const textSecondary = Color(0xFF6C757D);// Gray Text
  static const border = Color(0xFFE9ECEF);       // Light Border
  
  // Status Colors
  static const success = Color(0xFF28A745);      // Green
  static const warning = Color(0xFFFFC107);      // Yellow
  static const error = Color(0xFFDC3545);        // Red
  static const info = Color(0xFF17A2B8);         // Blue
  
  // Gradient
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );
}
