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
    TextStyle applyFont(TextStyle? style, {double? defaultSize, FontWeight? weight}) {
      final size = ((style?.fontSize ?? defaultSize ?? 14.0) * uiScale);
      final fw = weight ?? style?.fontWeight;

      switch (fontFamily) {
        case 'Roboto':
          return GoogleFonts.roboto(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Poppins':
          return GoogleFonts.poppins(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Open Sans':
          return GoogleFonts.openSans(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Montserrat':
          return GoogleFonts.montserrat(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Lato':
          return GoogleFonts.lato(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Nunito':
          return GoogleFonts.nunito(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Playfair Display':
        case 'Playfair':
          return GoogleFonts.playfairDisplay(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
        case 'Inter':
        default:
          return GoogleFonts.inter(fontSize: size, fontWeight: fw, letterSpacing: style?.letterSpacing);
      }
    }

    return TextTheme(
      displayLarge: applyFont(base.displayLarge, defaultSize: 32, weight: FontWeight.bold),
      displayMedium: applyFont(base.displayMedium, defaultSize: 28, weight: FontWeight.bold),
      displaySmall: applyFont(base.displaySmall, defaultSize: 24, weight: FontWeight.bold),
      headlineLarge: applyFont(base.headlineLarge, defaultSize: 22, weight: FontWeight.w700),
      headlineMedium: applyFont(base.headlineMedium, defaultSize: 20, weight: FontWeight.w600),
      headlineSmall: applyFont(base.headlineSmall, defaultSize: 18, weight: FontWeight.w600),
      titleLarge: applyFont(base.titleLarge, defaultSize: 18, weight: FontWeight.w600),
      titleMedium: applyFont(base.titleMedium, defaultSize: 16, weight: FontWeight.w600),
      titleSmall: applyFont(base.titleSmall, defaultSize: 14, weight: FontWeight.w500),
      bodyLarge: applyFont(base.bodyLarge, defaultSize: 16, weight: FontWeight.normal),
      bodyMedium: applyFont(base.bodyMedium, defaultSize: 14, weight: FontWeight.normal),
      bodySmall: applyFont(base.bodySmall, defaultSize: 12, weight: FontWeight.normal),
      labelLarge: applyFont(base.labelLarge, defaultSize: 14, weight: FontWeight.w600),
      labelMedium: applyFont(base.labelMedium, defaultSize: 12, weight: FontWeight.w500),
      labelSmall: applyFont(base.labelSmall, defaultSize: 11, weight: FontWeight.w500),
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
