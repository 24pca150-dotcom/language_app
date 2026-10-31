import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primary = Color(0xFF6366F1); // Indigo / Purple
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold
  static const Color danger = Color(0xFFEF4444); // Red (Logout, Error)
  
  // Backgrounds & Surfaces (Midnight Dark Blue Palette)
  static const Color bgLight = Color(0xFF0A0F1D); // Deep Midnight Navy background
  static const Color surfaceWhite = Color(0xFF161F38); // Elevated dark navy surface
  static const Color boxColor = Color(0xFF1E293B); // Dark slate box
  static const Color boxBorder = Color(0xFF283548); // Subtle dark border
  static const Color cardBorder = Color(0xFF283548); // Subtle dark card border
  
  // App bars and navigation
  static const Color navBarGreen = Color(0xFF0A0F1D); // Dark navy top/bottom bars
  static const Color navBarGreenBorder = Color(0xFF1E293B);
  static const Color navBarGreenDark = Color(0xFF818CF8); // Neon indigo highlight
  static const Color navBarGreenMuted = Color(0xFF94A3B8); // Muted slate
  
  // Text Colors (High Contrast on Dark Blue)
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp White/Slate
  static const Color textSecondary = Color(0xFF94A3B8); // Soft Light Slate
  static const Color textMuted = Color(0xFF64748B); // Muted Slate

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
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0F1D),
        indicatorColor: primary.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF818CF8));
          }
          return const IconThemeData(color: Color(0xFF94A3B8));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF818CF8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.normal,
            fontSize: 12,
          );
        }),
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
