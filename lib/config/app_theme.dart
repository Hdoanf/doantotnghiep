import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── HealthPulse VN Color Palette (Blue Theme) ───
  static const primaryColor = Color(0xFF00408B);
  static const primaryDarkColor = Color(0xFF001A41);
  static const primaryLightColor = Color(0xFF0057B8);

  // Semantic: Health status colors
  static const normalColor = Color(0xFF0057B8); // Normal (Blue)
  static const warningColor = Color(0xFF752B00);
  static const criticalColor = Color(0xFFBA1A1A); // Critical (Error Red)
  static const infoColor = Color(0xFF0057B8); // Blue 500 — informational

  // Neutral palette
  static const backgroundColor = Color(0xFFF9F9FF); // background
  static const surfaceColor = Color(0xFFFFFFFF); // surface-container-lowest
  static const surface2Color = Color(0xFFEDEDF6); // surface-container
  static const cardColor = Color(0xFFFFFFFF);

  // Border & Divider
  static const borderColor = Color(0xFFE1E2EB); // surface-variant
  static const dividerColor = Color(0xFFEDEDF6); // surface-container

  // Text hierarchy
  static const textColor = Color(0xFF191C22); // on-background
  static const secondaryTextColor = Color(0xFF424752); // on-surface-variant
  static const mutedTextColor = Color(0xFF727784); // outline

  // Light accent fills for cards/badges
  static const accentColor = Color(0xFF14B8A6); // Teal 500
  static const accentLightColor = Color(0xFFDBE3F1); // secondary-container
  static const infoLightColor = Color(0xFFADC7FF); // primary-fixed-dim
  static const warningLightColor = Color(0xFFFFDBCC); // tertiary-fixed
  static const criticalLightColor = Color(0xFFFFDAD6); // error-container
  static const normalLightColor = Color(0xFFD8E2FF); // primary-fixed

  // Gradients for premium feel
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00408B), Color(0xFF0057B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF22D3EE)], // Teal → Cyan lighter
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo → Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Light Theme ───
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: const Color(0xFF06B6D4), // Cyan 500
      tertiary: const Color(0xFF8B5CF6), // Violet 500
      surface: surfaceColor,
      error: criticalColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: textColor, size: 22),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: mutedTextColor,
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 22),
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: criticalColor),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        color: mutedTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        color: secondaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: mutedTextColor,
      suffixIconColor: mutedTextColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2Color,
      selectedColor: accentLightColor,
      disabledColor: dividerColor,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: textColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedTextColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
      ),
    ),
  );

  // ─── Dark Theme ───
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: const Color(0xFF0C1222),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryLightColor,
      secondary: const Color(0xFF22D3EE),
      surface: const Color(0xFF1E293B),
      error: const Color(0xFFF87171),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      filled: true,
      fillColor: const Color(0xFF1E293B),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F172A),
      selectedItemColor: Color(0xFF14B8A6),
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
