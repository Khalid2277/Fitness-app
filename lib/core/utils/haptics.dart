import 'package:flutter/services.dart';

/// Centralized haptic feedback utility.
///
/// Provides semantic haptic methods so every feature uses the same
/// feedback patterns consistently across the entire app.
abstract final class Haptics {
  /// Light tap — for toggling selections, tapping chips, minor interactions.
  static void light() => HapticFeedback.lightImpact();

  /// Medium tap — for completing a set, saving a meal, confirming an action.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy tap — for finishing a workout, hitting a PR, major milestones.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection click — for scrolling through pickers, switching tabs.
  static void selection() => HapticFeedback.selectionClick();

  /// Success vibration — double tap pattern for positive feedback.
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Error vibration — for validation failures, destructive confirmations.
  static void error() => HapticFeedback.heavyImpact();

  /// Warning vibration — for approaching limits, caution states.
  static void warning() => HapticFeedback.lightImpact();
}
