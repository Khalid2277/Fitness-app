import 'package:flutter/material.dart';
import 'package:alfanutrition/data/models/enums.dart';

/// AlfaNutrition color system.
///
/// All palette constants are defined here so that [AppTheme] and widgets
/// reference a single source of truth.  Every semantic color has both a
/// light-mode and a dark-mode variant where the two differ.
abstract final class AppColors {
  // ─────────────────────────── Brand / Primary ───────────────────────────

  /// Deep navy-black used as the dark-mode background / brand anchor.
  static const Color primaryDark = Color(0xFF0A0E14);

  /// Slightly lighter variant for dark surfaces that sit above the base.
  static const Color primaryDarkElevated = Color(0xFF141820);

  /// Soft lavender accent for primary interactive elements.
  static const Color primaryBlue = Color(0xFF6366F1);

  /// Lighter tint of primary lavender for highlights / chips.
  static const Color primaryBlueLight = Color(0xFF818CF8);

  /// Dark indigo surface used for tinted containers in dark mode.
  static const Color primaryBlueSurface = Color(0xFF1E1B4B);

  // ──────────────────────────── Accent / Teal ────────────────────────────

  /// Vibrant teal used for success / active / CTA accents.
  static const Color accent = Color(0xFF00BFA6);

  /// Lighter tint for backgrounds that need a hint of accent.
  static const Color accentLight = Color(0xFF69F0AE);

  /// Darker shade for text rendered on top of accent surfaces.
  static const Color accentDark = Color(0xFF00897B);

  /// Very light accent used as tinted surface in light mode.
  static const Color accentSurface = Color(0xFFE0F7F1);

  // ──────────────────────────── Copper / Warm ────────────────────────────

  /// Warm copper used for tertiary highlights and accents.
  static const Color copper = Color(0xFFC4956A);

  /// Lighter copper tint.
  static const Color copperLight = Color(0xFFD4A574);

  // ───────────────────────── Surface / Background ────────────────────────

  // Light mode
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLight1 = Color(0xFFF8F9FC);
  static const Color surfaceLight2 = Color(0xFFF0F1F5);
  static const Color surfaceLight3 = Color(0xFFE8E9ED);

  // Dark mode — obsidian palette
  static const Color backgroundDark = Color(0xFF0A0E14);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color surfaceDark1 = Color(0xFF161B22);
  static const Color surfaceDark2 = Color(0xFF1C2129);
  static const Color surfaceDark3 = Color(0xFF21262D);

  // ───────────────────────────── Text colors ─────────────────────────────

  // Light mode text
  static const Color textPrimaryLight = Color(0xFF1A1D2E);
  static const Color textSecondaryLight = Color(0xFF5F6380);
  static const Color textTertiaryLight = Color(0xFF9396A8);
  static const Color textDisabledLight = Color(0xFFBFC2D0);

  // Dark mode text
  static const Color textPrimaryDark = Color(0xFFE6EDF3);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textTertiaryDark = Color(0xFF6E7681);
  static const Color textDisabledDark = Color(0xFF464A66);

  // ─────────────────────────── Semantic colors ───────────────────────────

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF047857);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

  // ────────────────────── Muscle group colors ────────────────────────────

  static const Color muscleChest = Color(0xFFEF4444);
  static const Color muscleBack = Color(0xFF3B82F6);
  static const Color muscleShoulders = Color(0xFFF97316);
  static const Color muscleArms = Color(0xFF8B5CF6);
  static const Color muscleLegs = Color(0xFF10B981);
  static const Color muscleCore = Color(0xFFEAB308);
  static const Color muscleGlutes = Color(0xFFEC4899);
  static const Color muscleTraps = Color(0xFF06B6D4);
  static const Color muscleForearms = Color(0xFF6366F1);
  static const Color muscleCalves = Color(0xFF14B8A6);

  /// Returns a color representing the given [MuscleGroup].
  static Color colorForMuscle(MuscleGroup muscle) {
    return switch (muscle) {
      MuscleGroup.chest => muscleChest,
      MuscleGroup.back || MuscleGroup.lats => muscleBack,
      MuscleGroup.shoulders => muscleShoulders,
      MuscleGroup.biceps || MuscleGroup.triceps => muscleArms,
      MuscleGroup.quadriceps || MuscleGroup.hamstrings => muscleLegs,
      MuscleGroup.core || MuscleGroup.obliques => muscleCore,
      MuscleGroup.glutes || MuscleGroup.hipFlexors || MuscleGroup.adductors || MuscleGroup.abductors => muscleGlutes,
      MuscleGroup.traps => muscleTraps,
      MuscleGroup.forearms => muscleForearms,
      MuscleGroup.calves => muscleCalves,
    };
  }

  /// Convenience list for iterating over muscle-group colors (e.g. charts).
  static const List<Color> muscleGroupColors = [
    muscleChest,
    muscleBack,
    muscleShoulders,
    muscleArms,
    muscleLegs,
    muscleCore,
    muscleGlutes,
    muscleTraps,
    muscleForearms,
    muscleCalves,
  ];

  // ──────────────────────────── Divider / Border ─────────────────────────

  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF21262D);

  // ──────────────────────────── Gradients ────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceDark1, surfaceDark2],
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceLight, surfaceLight1],
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [primaryBlue, accent],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  // ──────────────────────────── Shadows ──────────────────────────────────

  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
          color: const Color(0xFF1A1D2E).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A1D2E).withValues(alpha: 0.02),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadowLight => [
        BoxShadow(
          color: const Color(0xFF1A1D2E).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF1A1D2E).withValues(alpha: 0.04),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];
}
