import 'package:flutter/material.dart';

/// AlfaNutrition spacing & radius tokens.
///
/// Use these instead of hard-coded numeric values so the entire app stays
/// visually consistent and is trivial to adjust globally.
abstract final class AppSpacing {
  // ──────────────────────────── Spacing scale ────────────────────────────

  /// 4 px
  static const double xs = 4;

  /// 8 px
  static const double sm = 8;

  /// 12 px
  static const double md = 12;

  /// 16 px
  static const double lg = 16;

  /// 20 px
  static const double xl = 20;

  /// 24 px
  static const double xxl = 24;

  /// 32 px
  static const double xxxl = 32;

  /// 40 px – useful for large gaps between major sections.
  static const double xxxxl = 40;

  // ──────────────────────────── Semantic spacing ─────────────────────────

  /// Standard horizontal padding for full-width screens.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 20);

  /// Padding inside cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Compact card padding for smaller cards / list tiles.
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12);

  /// Vertical space between major screen sections.
  static const double sectionSpacing = 24;

  /// Vertical space between items within a section.
  static const double itemSpacing = 12;

  // ──────────────────────────── Border radii ─────────────────────────────

  /// 8 px
  static const double radiusSm = 8;

  /// 12 px
  static const double radiusMd = 12;

  /// 16 px
  static const double radiusLg = 16;

  /// 20 px
  static const double radiusXl = 20;

  /// 24 px
  static const double radiusXxl = 24;

  /// 100 px – fully rounded / pill shape.
  static const double radiusPill = 100;

  // Convenience [BorderRadius] objects
  static final BorderRadius borderRadiusSm =
      BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd =
      BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg =
      BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl =
      BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl =
      BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusPill =
      BorderRadius.circular(radiusPill);
}
