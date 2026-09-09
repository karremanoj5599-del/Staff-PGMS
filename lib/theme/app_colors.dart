import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Accent ───────────────────────────────────────────
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0x1A3B82F6);

  // ─── Status ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0x1A10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0x1AEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0x1AF59E0B);

  // ─── Dark Theme ───────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkSeparator = Color(0xFF334155);
  static const Color darkBackgroundTertiary = Color(0xFF1E293B);

  // ─── Light Theme ──────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightSeparator = Color(0xFFE2E8F0);
  static const Color lightBackgroundTertiary = Color(0xFFF1F5F9);
}

/// Resolved color set for the active theme brightness
class ResolvedColors {
  final Color background;
  final Color card;
  final Color cardBorder;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color separator;
  final Color backgroundTertiary;
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color successLight;
  final Color danger;
  final Color dangerLight;
  final Color warning;
  final Color warningLight;

  const ResolvedColors({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.separator,
    required this.backgroundTertiary,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.successLight,
    required this.danger,
    required this.dangerLight,
    required this.warning,
    required this.warningLight,
  });

  static ResolvedColors dark({Color? accentOverride}) {
    final a = accentOverride ?? AppColors.accent;
    return ResolvedColors(
      background: AppColors.darkBackground,
      card: AppColors.darkCard,
      cardBorder: AppColors.darkCardBorder,
      text: AppColors.darkText,
      textSecondary: AppColors.darkTextSecondary,
      textMuted: AppColors.darkTextMuted,
      separator: AppColors.darkSeparator,
      backgroundTertiary: AppColors.darkBackgroundTertiary,
      accent: a,
      accentLight: a.withAlpha(26),
      success: AppColors.success,
      successLight: AppColors.successLight,
      danger: AppColors.danger,
      dangerLight: AppColors.dangerLight,
      warning: AppColors.warning,
      warningLight: AppColors.warningLight,
    );
  }

  static ResolvedColors light({Color? accentOverride}) {
    final a = accentOverride ?? AppColors.accent;
    return ResolvedColors(
      background: AppColors.lightBackground,
      card: AppColors.lightCard,
      cardBorder: AppColors.lightCardBorder,
      text: AppColors.lightText,
      textSecondary: AppColors.lightTextSecondary,
      textMuted: AppColors.lightTextMuted,
      separator: AppColors.lightSeparator,
      backgroundTertiary: AppColors.lightBackgroundTertiary,
      accent: a,
      accentLight: a.withAlpha(26),
      success: AppColors.success,
      successLight: AppColors.successLight,
      danger: AppColors.danger,
      dangerLight: AppColors.dangerLight,
      warning: AppColors.warning,
      warningLight: AppColors.warningLight,
    );
  }
}
