import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // Theme mode (dark / light) — persisted in SharedPreferences
  // ---------------------------------------------------------------------------
  static const String _prefKey = 'app_dark_mode';

  /// true = dark theme, false = light theme. Listen to this to rebuild on change.
  static final ValueNotifier<bool> isDarkNotifier = ValueNotifier<bool>(true);

  static bool get isDark => isDarkNotifier.value;

  static Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkNotifier.value = prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setDarkMode(bool dark) async {
    isDarkNotifier.value = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, dark);
  }

  static Future<void> toggleTheme() => setDarkMode(!isDark);

  // ---------------------------------------------------------------------------
  // Brand Color Palette (same in both themes)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF6366F1); // Indigo / Purple
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold
  static const Color danger = Color(0xFFEF4444); // Red (Logout, Error)

  // ---------------------------------------------------------------------------
  // Backgrounds & Surfaces (switch with theme)
  // ---------------------------------------------------------------------------
  static Color get bgLight => isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);
  static Color get bgAlt => isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
  static Color get surfaceWhite => isDark ? const Color(0xFF161F38) : const Color(0xFFFFFFFF);
  static Color get boxColor => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get boxBorder => isDark ? const Color(0xFF283548) : const Color(0xFFE2E8F0);
  static Color get boxBorderStrong => isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
  static Color get cardBorder => boxBorder;

  // App bars and navigation
  static Color get navBarGreen => isDark ? const Color(0xFF0A0F1D) : const Color(0xFFFFFFFF);
  static Color get navBarGreenBorder => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get navBarGreenDark => isDark ? const Color(0xFF818CF8) : primary;
  static Color get navBarGreenMuted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Text Colors
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  /// Background gradient used behind the main tab screens.
  static LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0F1D), Color(0xFF0F172A), Color(0xFF080D1A)],
          stops: [0.0, 0.5, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          stops: [0.0, 0.5, 1.0],
        );

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

  /// ThemeData for the currently selected mode.
  static ThemeData get currentTheme => _buildTheme(isDark);

  /// Kept for backward compatibility.
  static ThemeData get lightTheme => currentTheme;

  static ThemeData _buildTheme(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: bgLight,
      dividerColor: boxBorder,
      dividerTheme: DividerThemeData(color: boxBorder),
      appBarTheme: AppBarTheme(
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
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surfaceWhite),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaceWhite),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarGreen,
        indicatorColor: primary.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: navBarGreenDark);
          }
          return IconThemeData(color: navBarGreenMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: navBarGreenDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: navBarGreenMuted,
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
