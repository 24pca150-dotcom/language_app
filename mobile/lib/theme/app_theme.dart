import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primary = Color(0xFF6366F1); // Indigo / Purple
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold
  static const Color danger = Color(0xFFEF4444); // Red (Logout, Error)
  
  // Backgrounds & Surfaces
  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color boxColor = Color(0xFFF1F2FF);
  static const Color boxBorder = Color(0xFFE0E2F5);
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  // App bars and navigation
  static const Color navBarGreen = surfaceWhite;
  static const Color navBarGreenBorder = cardBorder;
  static const Color navBarGreenDark = primaryDark;
  static const Color navBarGreenMuted = Color(0xFF64748B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
