import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/data/models/enums.dart' show MealType;
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/models/daily_nutrition.dart';
import 'package:alfanutrition/data/repositories/nutrition_repository.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

export 'package:alfanutrition/data/models/enums.dart' show MealType;

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Selected date
// ─────────────────────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition targets
// ─────────────────────────────────────────────────────────────────────────────

class NutritionTargets {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;

  const NutritionTargets({
    this.calories = AppConstants.defaultCalorieTarget,
    this.protein = AppConstants.defaultProteinTarget,
    this.carbs = AppConstants.defaultCarbsTarget,
    this.fats = AppConstants.defaultFatsTarget,
    this.fiber = 30,
  });
}

final nutritionTargetsProvider = Provider<NutritionTargets>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) => NutritionTargets(
      calories: profile.dailyCalorieTarget,
      protein: profile.proteinTarget,
      carbs: profile.carbsTarget,
      fats: profile.fatsTarget,
    ),
    loading: () => const NutritionTargets(),
    error: (_, _) => const NutritionTargets(),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Daily nutrition (loads meals for selected date from Hive)
// ─────────────────────────────────────────────────────────────────────────────

final dailyNutritionProvider = FutureProvider<DailyNutrition>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final targets = ref.watch(nutritionTargetsProvider);
  final source = ref.watch(dataSourceProvider);

  List<Meal> meals;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbNutritionRepositoryProvider);
    meals = await sbRepo.getMealsForDate(date);
  } else {
    final repo = ref.read(nutritionRepositoryProvider);
    final rawMeals = await repo.getMealsForDate(date);
    meals = rawMeals.map((m) => _mealFromRepoMap(m)).toList();
  }

  return DailyNutrition(
    date: date,
    meals: meals,
    targetCalories: targets.calories,
    targetProtein: targets.protein,
    targetCarbs: targets.carbs,
    targetFats: targets.fats,
  );
});

/// Bridge between the repository's raw map format and the [Meal] model.
Meal _mealFromRepoMap(Map<String, dynamic> m) {
  // The repository stores 'date' while Meal.fromJson expects 'dateTime',
  // and stores 'mealType' as an int index while Meal.fromJson expects a name.
  // Handle both formats gracefully.
  final mealTypeRaw = m['mealType'];
  final dateRaw = m['dateTime'] ?? m['date'];

  return Meal(
    id: m['id'] as String,
    name: m['name'] as String,
    mealType: mealTypeRaw is int
        ? MealType.values[mealTypeRaw]
        : MealType.values.byName(mealTypeRaw as String),
    calories: (m['calories'] as num).toDouble(),
    protein: (m['protein'] as num? ?? 0).toDouble(),
    carbs: (m['carbs'] as num? ?? 0).toDouble(),
    fats: (m['fats'] as num? ?? m['fat'] as num? ?? 0).toDouble(),
    fiber: (m['fiber'] as num? ?? 0).toDouble(),
    dateTime: DateTime.parse(dateRaw as String),
    servingSize: (m['servingSize'] as num? ?? 1).toDouble(),
    servingUnit: m['servingUnit'] as String?,
    notes: m['notes'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick food presets
// ─────────────────────────────────────────────────────────────────────────────

class QuickFood {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;
  final String emoji;

  const QuickFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.fiber = 0,
    this.emoji = '',
  });
}

final quickFoodsProvider = Provider<List<QuickFood>>((ref) {
  return const [
    QuickFood(
      name: 'Chicken Breast',
      calories: 165,
      protein: 31,
      carbs: 0,
      fats: 3.6,
      emoji: '\u{1F357}',
    ),
    QuickFood(
      name: 'White Rice',
      calories: 206,
      protein: 4.3,
      carbs: 45,
      fats: 0.4,
      fiber: 0.6,
      emoji: '\u{1F35A}',
    ),
    QuickFood(
      name: 'Eggs (2)',
      calories: 143,
      protein: 12.6,
      carbs: 0.7,
      fats: 9.5,
      emoji: '\u{1F95A}',
    ),
    QuickFood(
      name: 'Oats',
      calories: 154,
      protein: 5.3,
      carbs: 27,
      fats: 2.6,
      fiber: 4,
      emoji: '\u{1F35E}',
    ),
    QuickFood(
      name: 'Protein Shake',
      calories: 120,
      protein: 24,
      carbs: 3,
      fats: 1.5,
      emoji: '\u{1F964}',
    ),
    QuickFood(
      name: 'Banana',
      calories: 105,
      protein: 1.3,
      carbs: 27,
      fats: 0.4,
      fiber: 3.1,
      emoji: '\u{1F34C}',
    ),
    QuickFood(
      name: 'Greek Yogurt',
      calories: 100,
      protein: 17,
      carbs: 6,
      fats: 0.7,
      emoji: '\u{1F95B}',
    ),
    QuickFood(
      name: 'Salmon',
      calories: 208,
      protein: 20,
      carbs: 0,
      fats: 13,
      emoji: '\u{1F41F}',
    ),
    QuickFood(
      name: 'Avocado',
      calories: 160,
      protein: 2,
      carbs: 8.5,
      fats: 14.7,
      fiber: 6.7,
      emoji: '\u{1F951}',
    ),
    QuickFood(
      name: 'Almonds (28g)',
      calories: 164,
      protein: 6,
      carbs: 6,
      fats: 14,
      fiber: 3.5,
      emoji: '\u{1F330}',
    ),
  ];
});
