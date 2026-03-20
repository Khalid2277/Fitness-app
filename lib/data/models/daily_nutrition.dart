import 'package:hive/hive.dart';

import 'enums.dart';
import 'meal.dart';

@HiveType(typeId: 13)
class DailyNutrition extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<Meal> meals;

  @HiveField(2)
  final double targetCalories;

  @HiveField(3)
  final double targetProtein;

  @HiveField(4)
  final double targetCarbs;

  @HiveField(5)
  final double targetFats;

  DailyNutrition({
    required this.date,
    required this.meals,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
  });

  // ──────────────────────── Computed totals ────────────────────────

  double get totalCalories =>
      meals.fold(0.0, (sum, m) => sum + m.calories);

  double get totalProtein =>
      meals.fold(0.0, (sum, m) => sum + m.protein);

  double get totalCarbs =>
      meals.fold(0.0, (sum, m) => sum + m.carbs);

  double get totalFats =>
      meals.fold(0.0, (sum, m) => sum + m.fats);

  double get totalFiber =>
      meals.fold(0.0, (sum, m) => sum + m.fiber);

  // ──────────────────────── Remaining ────────────────────────

  double get remainingCalories => targetCalories - totalCalories;

  double get remainingProtein => targetProtein - totalProtein;

  double get remainingCarbs => targetCarbs - totalCarbs;

  double get remainingFats => targetFats - totalFats;

  // ──────────────────────── Progress (0.0 – 1.0+) ────────────────────────

  double get calorieProgress =>
      targetCalories > 0 ? (totalCalories / targetCalories).clamp(0.0, 1.5) : 0;

  double get proteinProgress =>
      targetProtein > 0 ? (totalProtein / targetProtein).clamp(0.0, 1.5) : 0;

  double get carbsProgress =>
      targetCarbs > 0 ? (totalCarbs / targetCarbs).clamp(0.0, 1.5) : 0;

  double get fatsProgress =>
      targetFats > 0 ? (totalFats / targetFats).clamp(0.0, 1.5) : 0;

  // ──────────────────────── Per meal-type helpers ────────────────────────

  List<Meal> mealsForType(MealType type) =>
      meals.where((m) => m.mealType == type).toList();

  double caloriesForType(MealType type) =>
      mealsForType(type).fold(0.0, (sum, m) => sum + m.calories);

  DailyNutrition copyWith({
    DateTime? date,
    List<Meal>? meals,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFats,
  }) {
    return DailyNutrition(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFats: targetFats ?? this.targetFats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFats': targetFats,
    };
  }

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      date: DateTime.parse(json['date'] as String),
      meals: (json['meals'] as List)
          .map((m) => Meal.fromJson(m as Map<String, dynamic>))
          .toList(),
      targetCalories: (json['targetCalories'] as num).toDouble(),
      targetProtein: (json['targetProtein'] as num).toDouble(),
      targetCarbs: (json['targetCarbs'] as num).toDouble(),
      targetFats: (json['targetFats'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'DailyNutrition(date: $date, meals: ${meals.length}, '
      'cals: $totalCalories/$targetCalories)';
}

class DailyNutritionAdapter extends TypeAdapter<DailyNutrition> {
  @override
  final int typeId = 13;

  @override
  DailyNutrition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return DailyNutrition(
      date: fields[0] as DateTime,
      meals: (fields[1] as List).cast<Meal>(),
      targetCalories: fields[2] as double,
      targetProtein: fields[3] as double,
      targetCarbs: fields[4] as double,
      targetFats: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DailyNutrition obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.meals)
      ..writeByte(2)
      ..write(obj.targetCalories)
      ..writeByte(3)
      ..write(obj.targetProtein)
      ..writeByte(4)
      ..write(obj.targetCarbs)
      ..writeByte(5)
      ..write(obj.targetFats);
  }
}
