import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AlfaNutrition typography presets.
///
/// Every style comes in **light** and **dark** flavours.  Widgets that need to
/// adapt automatically should pull from the current [TextTheme] instead, but
/// these constants are handy for one-off overrides.
abstract final class AppTextStyles {
  // ──────────────────────── Base font family ─────────────────────────────

  static const String _fontFamily = '.SF Pro Display';
  static const String _fontFamilyFallback = 'Roboto';

  static List<String> get _fallback => [_fontFamilyFallback];

  // ──────────────────────── Screen-level titles ──────────────────────────

  /// Large screen titles – e.g. "Dashboard", "Workout".
  static TextStyle screenTitle({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  /// Section headings inside a screen.
  static TextStyle sectionTitle({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  /// Card titles / sub-section headings.
  static TextStyle cardTitle({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  // ────────────────────────── Body / Content ─────────────────────────────

  /// Default body text.
  static TextStyle body({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  /// Secondary body text (muted).
  static TextStyle bodySecondary({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color:
            dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  /// Caption / small supporting text.
  static TextStyle caption({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.1,
        color:
            dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      );

  /// Small uppercase labels (e.g. chips, badges).
  static TextStyle label({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.5,
        color:
            dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  // ────────────────────────── Metric / Numbers ───────────────────────────

  /// Large metric value – e.g. "2,450" for calories.
  static TextStyle metric({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  /// Compact metric for smaller cards.
  static TextStyle metricSmall({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
        color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  /// Unit label next to a metric value – e.g. "kcal", "kg".
  static TextStyle metricUnit({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color:
            dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  // ──────────────────────────── Navigation ───────────────────────────────

  /// Tab / bottom-nav labels.
  static TextStyle tabLabel({bool dark = false}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color:
            dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      );

  // ───────────────────────────── Buttons ─────────────────────────────────

  /// Primary button label.
  static TextStyle button() => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      );
}
