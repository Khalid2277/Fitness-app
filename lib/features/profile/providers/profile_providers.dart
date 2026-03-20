import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/repositories/user_repository.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository (local Hive)
// ─────────────────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// User Profile — auto-selects Supabase or Hive based on data source
// ─────────────────────────────────────────────────────────────────────────────

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbProfileRepositoryProvider);
    final profile = await sbRepo.getProfile();
    if (profile != null) return profile;
  }

  // Fallback to local Hive
  final repo = ref.watch(userRepositoryProvider);
  final raw = await repo.getProfile();
  if (raw != null) {
    return UserProfile.fromJson(raw);
  }
  return UserProfile();
});

// ─────────────────────────────────────────────────────────────────────────────
// Profile Update Helper
// ─────────────────────────────────────────────────────────────────────────────

/// Saves an updated [UserProfile] to the active data source (Supabase or Hive)
/// and invalidates all dependent providers so the entire app refreshes.
Future<void> saveProfileAndRefresh(WidgetRef ref, UserProfile profile) async {
  final source = ref.read(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbProfileRepositoryProvider);
    await sbRepo.updateProfile(profile);
  } else {
    final repo = ref.read(userRepositoryProvider);
    await repo.saveProfile(profile.toJson());
  }

  // Invalidate the profile provider so all watchers re-fetch.
  ref.invalidate(userProfileProvider);
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Mode
// ─────────────────────────────────────────────────────────────────────────────

/// Theme mode state notifier for dark/light mode toggle.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDark => state == ThemeMode.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Measurement Unit System
// ─────────────────────────────────────────────────────────────────────────────

enum MeasurementSystem { metric, imperial }

final measurementSystemProvider =
    StateNotifierProvider<MeasurementSystemNotifier, MeasurementSystem>((ref) {
  return MeasurementSystemNotifier();
});

class MeasurementSystemNotifier extends StateNotifier<MeasurementSystem> {
  MeasurementSystemNotifier() : super(MeasurementSystem.metric);

  void setSystem(MeasurementSystem system) => state = system;

  void toggle() {
    state = state == MeasurementSystem.metric
        ? MeasurementSystem.imperial
        : MeasurementSystem.metric;
  }

  bool get isMetric => state == MeasurementSystem.metric;
}

/// Utility helpers for unit conversions.
/// Internally all data is stored in metric (kg, cm).
class UnitConvert {
  const UnitConvert._();

  // ── Weight ──
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;

  // ── Height ──
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;
  static (int feet, double inches) cmToFeetInches(double cm) {
    final totalInches = cmToInches(cm);
    final feet = totalInches ~/ 12;
    final remainingInches = totalInches - (feet * 12);
    return (feet, remainingInches);
  }
  static double feetInchesToCm(int feet, double inches) {
    return inchesToCm((feet * 12) + inches);
  }

  // ── Display helpers ──
  static String weightStr(double kg, MeasurementSystem system, {int decimals = 1}) {
    if (system == MeasurementSystem.imperial) {
      return '${kgToLbs(kg).toStringAsFixed(decimals)} lbs';
    }
    return '${kg.toStringAsFixed(decimals)} kg';
  }

  static String heightStr(double cm, MeasurementSystem system) {
    if (system == MeasurementSystem.imperial) {
      final (feet, inches) = cmToFeetInches(cm);
      return '$feet\'${inches.round()}"';
    }
    return '${cm.round()} cm';
  }

  static String weightUnit(MeasurementSystem system) =>
      system == MeasurementSystem.imperial ? 'lbs' : 'kg';

  static String heightUnit(MeasurementSystem system) =>
      system == MeasurementSystem.imperial ? 'ft/in' : 'cm';
}

// ─────────────────────────────────────────────────────────────────────────────
// Language
// ─────────────────────────────────────────────────────────────────────────────

enum AppLanguage {
  english,
  arabic;

  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.arabic:
        return 'العربية';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.arabic:
        return 'ar';
    }
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.english);

  void setLanguage(AppLanguage language) => state = language;
}
