import 'package:flutter/material.dart';

abstract final class BrandColors {
  static const forest = Color(0xFF123D32);
  static const forestDeep = Color(0xFF0B2B24);
  static const forestSoft = Color(0xFF245847);
  static const leaf = Color(0xFFBCEB73);
  static const paper = Color(0xFFF7F7F1);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17241F);
  static const muted = Color(0xFF66766E);
  static const line = Color(0xFFE5E9E1);
  static const paleGreen = Color(0xFFEAF1E8);
  static const amber = Color(0xFFE3A548);
}

abstract final class TopHeightsTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.forest,
      brightness: Brightness.light,
      primary: BrandColors.forest,
      secondary: BrandColors.leaf,
      surface: BrandColors.card,
      error: const Color(0xFFB33B36),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColors.paper,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          height: 1.03,
          fontWeight: FontWeight.w700,
          letterSpacing: -2.2,
          color: BrandColors.ink,
        ),
        displayMedium: TextStyle(
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: BrandColors.ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: BrandColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: BrandColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: BrandColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: BrandColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.55,
          color: BrandColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: BrandColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrandColors.paper,
        foregroundColor: BrandColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: BrandColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: BrandColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.forest, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.leaf,
          foregroundColor: BrandColors.forestDeep,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.forest,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: BrandColors.line),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BrandColors.card,
        indicatorColor: BrandColors.paleGreen,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? BrandColors.forest
                : BrandColors.muted,
          ),
        ),
      ),
      dividerColor: BrandColors.line,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
