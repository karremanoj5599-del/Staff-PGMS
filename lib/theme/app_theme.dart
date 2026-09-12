import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<String> supportedFonts = [
    'Inter',
    'Roboto',
    'Poppins',
    'Open Sans',
    'Montserrat',
    'Lato',
    'Nunito',
    'Playfair Display',
  ];

  static const List<Color> primaryColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
  ];

  static TextTheme _buildTextTheme(String fontFamily, TextTheme base, double uiScale) {
    TextTheme themedText;
    try {
      themedText = GoogleFonts.getTextTheme(fontFamily, base);
    } catch (_) {
      themedText = GoogleFonts.interTextTheme(base);
    }

    if (uiScale == 1.0) {
      return themedText;
    }

    return themedText.copyWith(
      displayLarge: themedText.displayLarge?.copyWith(fontSize: (themedText.displayLarge?.fontSize ?? 57) * uiScale),
      displayMedium: themedText.displayMedium?.copyWith(fontSize: (themedText.displayMedium?.fontSize ?? 45) * uiScale),
      displaySmall: themedText.displaySmall?.copyWith(fontSize: (themedText.displaySmall?.fontSize ?? 36) * uiScale),
      headlineLarge: themedText.headlineLarge?.copyWith(fontSize: (themedText.headlineLarge?.fontSize ?? 32) * uiScale),
      headlineMedium: themedText.headlineMedium?.copyWith(fontSize: (themedText.headlineMedium?.fontSize ?? 28) * uiScale),
      headlineSmall: themedText.headlineSmall?.copyWith(fontSize: (themedText.headlineSmall?.fontSize ?? 24) * uiScale),
      titleLarge: themedText.titleLarge?.copyWith(fontSize: (themedText.titleLarge?.fontSize ?? 22) * uiScale),
      titleMedium: themedText.titleMedium?.copyWith(fontSize: (themedText.titleMedium?.fontSize ?? 16) * uiScale),
      titleSmall: themedText.titleSmall?.copyWith(fontSize: (themedText.titleSmall?.fontSize ?? 14) * uiScale),
      bodyLarge: themedText.bodyLarge?.copyWith(fontSize: (themedText.bodyLarge?.fontSize ?? 16) * uiScale),
      bodyMedium: themedText.bodyMedium?.copyWith(fontSize: (themedText.bodyMedium?.fontSize ?? 14) * uiScale),
      bodySmall: themedText.bodySmall?.copyWith(fontSize: (themedText.bodySmall?.fontSize ?? 12) * uiScale),
      labelLarge: themedText.labelLarge?.copyWith(fontSize: (themedText.labelLarge?.fontSize ?? 14) * uiScale),
      labelMedium: themedText.labelMedium?.copyWith(fontSize: (themedText.labelMedium?.fontSize ?? 12) * uiScale),
      labelSmall: themedText.labelSmall?.copyWith(fontSize: (themedText.labelSmall?.fontSize ?? 11) * uiScale),
    );
  }

  static ThemeData light({
    Color primaryColor = AppColors.accent,
    String fontFamily = 'Inter',
    double uiScale = 1.0,
  }) {
    final resolved = ResolvedColors.light(accentOverride: primaryColor);
    final base = ThemeData.light();
    final textTheme = _buildTextTheme(fontFamily, base.textTheme, uiScale).apply(
      bodyColor: resolved.text,
      displayColor: resolved.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: resolved.background,
      cardColor: resolved.card,
      dividerColor: resolved.separator,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: resolved.card,
        error: resolved.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: resolved.text,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: resolved.background,
        foregroundColor: resolved.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: resolved.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: resolved.card,
        selectedItemColor: primaryColor,
        unselectedItemColor: resolved.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: resolved.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: resolved.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: resolved.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: resolved.textSecondary),
        hintStyle: TextStyle(color: resolved.textMuted),
      ),
    );
  }

  static ThemeData dark({
    Color primaryColor = AppColors.accent,
    String fontFamily = 'Inter',
    double uiScale = 1.0,
  }) {
    final resolved = ResolvedColors.dark(accentOverride: primaryColor);
    final base = ThemeData.dark();
    final textTheme = _buildTextTheme(fontFamily, base.textTheme, uiScale).apply(
      bodyColor: resolved.text,
      displayColor: resolved.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: resolved.background,
      cardColor: resolved.card,
      dividerColor: resolved.separator,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: resolved.card,
        error: resolved.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: resolved.text,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: resolved.background,
        foregroundColor: resolved.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: resolved.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: resolved.card,
        selectedItemColor: primaryColor,
        unselectedItemColor: resolved.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: resolved.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: resolved.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: resolved.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: resolved.textSecondary),
        hintStyle: TextStyle(color: resolved.textMuted),
      ),
    );
  }
}
