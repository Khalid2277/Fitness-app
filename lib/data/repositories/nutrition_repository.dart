import 'package:hive/hive.dart';

/// Repository for meal / nutrition CRUD operations using Hive.
class NutritionRepository {
  static const String _boxName = 'meals';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save a meal entry.
  Future<void> saveMeal(Map<String, dynamic> meal) async {
    final box = await _box;
    await box.put(meal['id'], meal);
  }

  /// Deep-converts Hive internal map/list types to standard Dart types.
  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
      );
    } else if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  /// Retrieve all stored meals.
  Future<List<Map<String, dynamic>>> getAllMeals() async {
    final box = await _box;
    return box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
  }

  /// Retrieve meals for a specific date.
  Future<List<Map<String, dynamic>>> getMealsForDate(DateTime date) async {
    final all = await getAllMeals();
    final target = DateTime(date.year, date.month, date.day);
    return all.where((m) {
      final d = DateTime.parse(m['date'] as String);
      return DateTime(d.year, d.month, d.day) == target;
    }).toList();
  }

  /// Retrieve meals whose date falls within [start] and [end] (inclusive).
  Future<List<Map<String, dynamic>>> getMealsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllMeals();
    return all.where((m) {
      final date = DateTime.parse(m['date'] as String);
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Delete a meal by its id.
  Future<void> deleteMeal(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Retrieve a single meal by id.
  Future<Map<String, dynamic>?> getMeal(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }

  /// Compute daily nutrition totals for the given date.
  /// Returns a map with keys: calories, protein, carbs, fats.
  Future<Map<String, double>> getDailyTotals(DateTime date) async {
    final meals = await getMealsForDate(date);
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    for (final meal in meals) {
      calories += (meal['calories'] as num?)?.toDouble() ?? 0;
      protein += (meal['protein'] as num?)?.toDouble() ?? 0;
      carbs += (meal['carbs'] as num?)?.toDouble() ?? 0;
      fats += (meal['fats'] as num? ?? meal['fat'] as num? ?? 0).toDouble();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}
