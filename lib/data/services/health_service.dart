import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

// Try to import the health package. If it's not installed, the mock
// implementation will be used instead. The service is designed so that
// a missing `health` package causes no compile-time errors — all HealthKit
// calls are isolated behind `_useHealthKit` and wrapped in try-catch.
//
// To enable real HealthKit integration:
//   1. Run `flutter pub add health`
//   2. Add HealthKit entitlement in ios/Runner/Runner.entitlements
//   3. Add NSHealthShareUsageDescription to Info.plist
//   4. Set `_healthKitSupported = true` below

// ─────────────────────────────────────────────────────────────────────────────
// MET values for workout calorie estimation
// ─────────────────────────────────────────────────────────────────────────────

/// Metabolic Equivalent of Task values by workout type.
abstract final class WorkoutMET {
  static const double weightTraining = 5.0;
  static const double hiit = 8.0;
  static const double cardio = 7.0;
  static const double general = 4.0;
  static const double yoga = 2.5;
  static const double stretching = 2.3;
  static const double calisthenics = 3.8;

  /// Returns the MET value for a given workout name / type string.
  ///
  /// Matches common keywords; falls back to [general].
  static double forWorkoutType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('hiit') || lower.contains('interval')) return hiit;
    if (lower.contains('cardio') || lower.contains('run') || lower.contains('cycling')) return cardio;
    if (lower.contains('weight') || lower.contains('strength') || lower.contains('resistance')) return weightTraining;
    if (lower.contains('yoga') || lower.contains('pilates')) return yoga;
    if (lower.contains('stretch') || lower.contains('mobility')) return stretching;
    if (lower.contains('bodyweight') || lower.contains('calisthenics')) return calisthenics;
    return general;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HealthService
// ─────────────────────────────────────────────────────────────────────────────

/// Provides access to health/activity data from Apple HealthKit (when
/// available) or falls back to time-based estimates so the app always has
/// reasonable values.
///
/// Usage:
/// ```dart
/// final service = ref.read(healthServiceProvider);
/// await service.initialize();
/// final steps = await service.getTodaySteps();
/// ```
class HealthService {
  // ── Singleton ──────────────────────────────────────────────────────────────

  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _initialized = false;
  bool _healthKitAvailable = false;

  /// Whether HealthKit was successfully initialized and authorized.
  bool get isAvailable => _healthKitAvailable;

  /// Whether [initialize] has been called (regardless of HealthKit status).
  bool get isInitialized => _initialized;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Requests HealthKit permissions and probes availability.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// If the `health` package is not installed or the platform doesn't support
  /// HealthKit, this silently falls back to the mock estimator.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Attempt to use HealthKit via the `health` package.
      // If the package isn't installed, this block will fail at compile time
      // and you should set _healthKitAvailable = false.
      //
      // When the `health` package IS available, uncomment the block below
      // and remove the line that sets _healthKitAvailable = false.

      // ── Uncomment when `health` package is added ──────────────────────
      // final health = HealthFactory();
      // final types = [
      //   HealthDataType.STEPS,
      //   HealthDataType.ACTIVE_ENERGY_BURNED,
      //   HealthDataType.DISTANCE_WALKING_RUNNING,
      // ];
      // final permissions = types.map((_) => HealthDataAccess.READ).toList();
      // _healthKitAvailable = await health.requestAuthorization(types, permissions: permissions);
      // ────────────────────────────────────────────────────────────────────

      _healthKitAvailable = false; // Remove when uncommenting above
    } catch (e) {
      _healthKitAvailable = false;
    }
  }

  // ── Steps ──────────────────────────────────────────────────────────────────

  /// Returns today's step count from HealthKit, or an estimate based on the
  /// current time of day.
  Future<int> getTodaySteps() async {
    if (_healthKitAvailable) {
      try {
        return await _fetchHealthKitSteps();
      } catch (_) {
        // Fall through to estimate
      }
    }
    return _estimateSteps();
  }

  /// Fetches steps from HealthKit. Override when the `health` package is
  /// installed.
  Future<int> _fetchHealthKitSteps() async {
    // ── Uncomment when `health` package is added ──────────────────────────
    // final health = HealthFactory();
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);
    // final steps = await health.getTotalStepsInInterval(midnight, now);
    // return steps ?? 0;
    // ──────────────────────────────────────────────────────────────────────
    return 0;
  }

  /// Estimates steps based on time of day.
  ///
  /// Assumes ~500 steps/hour between 7 AM and 10 PM, with a slight bump
  /// around typical active hours (8–9 AM, 12–1 PM, 5–7 PM).
  int _estimateSteps() {
    final now = DateTime.now();
    final hour = now.hour;
    final minuteFraction = now.minute / 60.0;

    if (hour < 7) return 0;

    int steps = 0;
    for (int h = 7; h < hour; h++) {
      steps += _stepsForHour(h);
    }
    // Partial hour
    steps += (_stepsForHour(hour) * minuteFraction).round();
    return steps;
  }

  /// Returns estimated steps for a given hour of the day.
  int _stepsForHour(int hour) {
    // Morning commute / exercise
    if (hour >= 7 && hour <= 9) return 700;
    // Midday activity
    if (hour >= 12 && hour <= 13) return 650;
    // Evening activity
    if (hour >= 17 && hour <= 19) return 800;
    // Late night
    if (hour >= 22) return 100;
    // Default active hours
    return 500;
  }

  // ── Active Calories ────────────────────────────────────────────────────────

  /// Returns today's active energy burned (kcal) from HealthKit, or an
  /// estimate derived from step count.
  Future<double> getTodayActiveCalories() async {
    if (_healthKitAvailable) {
      try {
        return await _fetchHealthKitActiveCalories();
      } catch (_) {
        // Fall through to estimate
      }
    }
    return _estimateActiveCalories();
  }

  Future<double> _fetchHealthKitActiveCalories() async {
    // ── Uncomment when `health` package is added ──────────────────────────
    // final health = HealthFactory();
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);
    // final data = await health.getHealthDataFromTypes(
    //   midnight, now, [HealthDataType.ACTIVE_ENERGY_BURNED]);
    // return data.fold<double>(
    //   0.0,
    //   (sum, d) => sum + (d.value as NumericHealthValue).numericValue,
    // );
    // ──────────────────────────────────────────────────────────────────────
    return 0.0;
  }

  /// Estimates active calories from step count.
  /// Average: ~0.04 kcal per step for a 70 kg person.
  Future<double> _estimateActiveCalories() async {
    final steps = _estimateSteps();
    return steps * 0.04;
  }

  // ── Distance ───────────────────────────────────────────────────────────────

  /// Returns today's walking + running distance in **kilometers**.
  Future<double> getTodayDistance() async {
    if (_healthKitAvailable) {
      try {
        return await _fetchHealthKitDistance();
      } catch (_) {
        // Fall through to estimate
      }
    }
    return _estimateDistance();
  }

  Future<double> _fetchHealthKitDistance() async {
    // ── Uncomment when `health` package is added ──────────────────────────
    // final health = HealthFactory();
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);
    // final data = await health.getHealthDataFromTypes(
    //   midnight, now, [HealthDataType.DISTANCE_WALKING_RUNNING]);
    // final meters = data.fold<double>(
    //   0.0,
    //   (sum, d) => sum + (d.value as NumericHealthValue).numericValue,
    // );
    // return meters / 1000.0;
    // ──────────────────────────────────────────────────────────────────────
    return 0.0;
  }

  /// Estimates distance from step count. Average stride ~0.75 m.
  Future<double> _estimateDistance() async {
    final steps = _estimateSteps();
    return (steps * 0.75) / 1000.0; // km
  }

  // ── Workout Calorie Estimation ─────────────────────────────────────────────

  /// Estimates calories burned during a workout.
  ///
  /// [durationMinutes] — length of the workout in minutes.
  /// [workoutType] — free-text workout name/type (matched to MET values).
  /// [bodyWeightKg] — user's body weight in kilograms.
  ///
  /// Formula: calories = MET x weight_kg x duration_hours
  static double estimateWorkoutCalories({
    required int durationMinutes,
    required String workoutType,
    required double bodyWeightKg,
  }) {
    final met = WorkoutMET.forWorkoutType(workoutType);
    final durationHours = durationMinutes / 60.0;
    return met * bodyWeightKg * durationHours;
  }

  // ── BMR Calculation ────────────────────────────────────────────────────────

  /// Calculates Basal Metabolic Rate using the Mifflin-St Jeor equation.
  ///
  /// Returns BMR in kcal/day.
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    // Mifflin-St Jeor equation
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78, // average of male and female
    };
  }

  /// Returns the activity multiplier for TDEE calculation.
  static double activityMultiplier(ActivityLevel? level) {
    return switch (level) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.extremelyActive => 1.9,
      null => 1.4, // Reasonable default
    };
  }

  // ── TDEE ───────────────────────────────────────────────────────────────────

  /// Calculates Total Daily Energy Expenditure.
  ///
  /// Combines BMR (scaled by activity level), estimated step-based calories,
  /// and explicit workout calories.
  ///
  /// [bmr] — Basal Metabolic Rate from [calculateBMR].
  /// [activityLevel] — user's self-reported activity level.
  /// [stepsCalories] — calories burned from steps today.
  /// [workoutCalories] — calories burned from logged workouts today.
  static double calculateTDEE({
    required double bmr,
    ActivityLevel? activityLevel,
    double stepsCalories = 0,
    double workoutCalories = 0,
  }) {
    // Base TDEE from BMR and activity multiplier already accounts for
    // general daily movement. We add explicit workout calories on top,
    // but only a fraction of step calories to avoid double-counting
    // (the activity multiplier already factors in some walking).
    final baseTDEE = bmr * activityMultiplier(activityLevel);
    final extraSteps = max(0.0, stepsCalories - _baselineStepCalories(activityLevel));
    return baseTDEE + workoutCalories + extraSteps;
  }

  /// Baseline step calories already accounted for by the activity multiplier,
  /// so we don't double-count.
  static double _baselineStepCalories(ActivityLevel? level) {
    return switch (level) {
      ActivityLevel.sedentary => 50,
      ActivityLevel.lightlyActive => 120,
      ActivityLevel.moderatelyActive => 200,
      ActivityLevel.veryActive => 300,
      ActivityLevel.extremelyActive => 400,
      null => 100,
    };
  }

  // ── Remaining Calories ─────────────────────────────────────────────────────

  /// Calculates how many calories the user can still eat today.
  ///
  /// [tdee] — Total Daily Energy Expenditure.
  /// [consumedCalories] — Calories consumed from logged meals.
  ///
  /// Returns remaining kcal (can be negative if over budget).
  static double remainingCalories({
    required double tdee,
    required double consumedCalories,
  }) {
    return tdee - consumedCalories;
  }

  // ── Summary ────────────────────────────────────────────────────────────────

  /// Fetches a complete daily health summary.
  Future<DailyHealthSummary> getTodaySummary({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    ActivityLevel? activityLevel,
    double workoutCalories = 0,
    double consumedCalories = 0,
  }) async {
    final steps = await getTodaySteps();
    final activeCalories = await getTodayActiveCalories();
    final distance = await getTodayDistance();

    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final tdee = calculateTDEE(
      bmr: bmr,
      activityLevel: activityLevel,
      stepsCalories: activeCalories,
      workoutCalories: workoutCalories,
    );

    final remaining = remainingCalories(
      tdee: tdee,
      consumedCalories: consumedCalories,
    );

    return DailyHealthSummary(
      steps: steps,
      activeCalories: activeCalories,
      distanceKm: distance,
      bmr: bmr,
      tdee: tdee,
      workoutCalories: workoutCalories,
      consumedCalories: consumedCalories,
      remainingCalories: remaining,
      isHealthKitConnected: _healthKitAvailable,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Health Summary Model
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of today's health/activity data.
class DailyHealthSummary {
  final int steps;
  final double activeCalories;
  final double distanceKm;
  final double bmr;
  final double tdee;
  final double workoutCalories;
  final double consumedCalories;
  final double remainingCalories;
  final bool isHealthKitConnected;

  const DailyHealthSummary({
    required this.steps,
    required this.activeCalories,
    required this.distanceKm,
    required this.bmr,
    required this.tdee,
    required this.workoutCalories,
    required this.consumedCalories,
    required this.remainingCalories,
    required this.isHealthKitConnected,
  });

  /// Percentage of daily calorie budget consumed (0.0 – 1.0+).
  double get consumedFraction => tdee > 0 ? consumedCalories / tdee : 0.0;

  /// Distance formatted as a string with one decimal place.
  String get distanceFormatted => '${distanceKm.toStringAsFixed(1)} km';

  /// Steps formatted with comma separators.
  String get stepsFormatted {
    final str = steps.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'DailyHealthSummary(steps: $steps, active: ${activeCalories.round()} kcal, '
      'distance: $distanceFormatted, TDEE: ${tdee.round()} kcal, '
      'remaining: ${remainingCalories.round()} kcal)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton [HealthService] instance.
final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

/// Today's step count (from HealthKit or estimated).
final todayStepsProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!service.isInitialized) await service.initialize();
  return service.getTodaySteps();
});

/// Today's active calories burned (from HealthKit or estimated from steps).
final todayActiveCaloriesProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!service.isInitialized) await service.initialize();
  return service.getTodayActiveCalories();
});

/// Today's walking/running distance in km.
final todayDistanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!service.isInitialized) await service.initialize();
  return service.getTodayDistance();
});

/// Today's total calorie burn: BMR portion (prorated to current time) +
/// step-based active calories + workout calories.
///
/// Requires the user profile to be loaded for BMR calculation.
final todayTotalBurnProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!service.isInitialized) await service.initialize();

  // Get user profile for BMR inputs
  final profile = await ref.watch(userProfileProvider.future);
  final weight = profile.weight ?? 70.0;
  final height = profile.height ?? 170.0;
  final age = profile.age ?? 25;
  final gender = profile.gender ?? Gender.male;
  // Calculate BMR
  final bmr = HealthService.calculateBMR(
    weightKg: weight,
    heightCm: height,
    age: age,
    gender: gender,
  );

  // Prorate BMR to current time of day
  final now = DateTime.now();
  final hoursPassed = now.hour + (now.minute / 60.0);
  final proratedBMR = bmr * (hoursPassed / 24.0);

  // Active calories from steps
  final activeCalories = await service.getTodayActiveCalories();

  // Combine: prorated BMR + active calories
  // Workout calories would be added separately when workout data is available
  final total = proratedBMR + activeCalories;

  return total;
});

/// Full daily health summary with all metrics.
///
/// Depends on user profile. Provides TDEE, remaining calories, steps, etc.
final dailyHealthSummaryProvider = FutureProvider<DailyHealthSummary>((ref) async {
  final service = ref.watch(healthServiceProvider);
  if (!service.isInitialized) await service.initialize();

  final profile = await ref.watch(userProfileProvider.future);

  return service.getTodaySummary(
    weightKg: profile.weight ?? 70.0,
    heightCm: profile.height ?? 170.0,
    age: profile.age ?? 25,
    gender: profile.gender ?? Gender.male,
    activityLevel: profile.activityLevel,
    // TODO: wire in actual consumed calories from dailyNutritionProvider
    // and workout calories from today's workout history
    workoutCalories: 0,
    consumedCalories: 0,
  );
});
