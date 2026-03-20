import 'package:hive/hive.dart';

/// Repository for workout CRUD operations using Hive.
class WorkoutRepository {
  static const String _boxName = 'workouts';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save a workout entry.
  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    final box = await _box;
    await box.put(workout['id'], workout);
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

  /// Retrieve all stored workouts.
  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    final box = await _box;
    return box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
  }

  /// Retrieve workouts whose date falls within [start] and [end] (inclusive).
  Future<List<Map<String, dynamic>>> getWorkoutsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllWorkouts();
    return all.where((w) {
      final date = DateTime.parse(w['date'] as String);
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Retrieve workouts for a specific date.
  Future<List<Map<String, dynamic>>> getWorkoutsForDate(DateTime date) async {
    final all = await getAllWorkouts();
    final target = DateTime(date.year, date.month, date.day);
    return all.where((w) {
      final d = DateTime.parse(w['date'] as String);
      return DateTime(d.year, d.month, d.day) == target;
    }).toList();
  }

  /// Delete a workout by its id.
  Future<void> deleteWorkout(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Retrieve a single workout by id.
  Future<Map<String, dynamic>?> getWorkout(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }
}
