import 'package:hive/hive.dart';

/// Repository for workout-plan CRUD operations using Hive.
class PlanRepository {
  static const String _boxName = 'plans';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save a workout plan.
  Future<void> savePlan(Map<String, dynamic> plan) async {
    final box = await _box;
    await box.put(plan['id'], plan);
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

  /// Retrieve all stored plans.
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    final box = await _box;
    return box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
  }

  /// Retrieve the currently active plan (where `isActive` is true).
  /// Returns null if no plan is active.
  Future<Map<String, dynamic>?> getActivePlan() async {
    final all = await getAllPlans();
    try {
      return all.firstWhere((p) => p['isActive'] == true);
    } catch (_) {
      return null;
    }
  }

  /// Set a plan as active and deactivate all others.
  Future<void> setActivePlan(String id) async {
    final box = await _box;
    for (final key in box.keys) {
      final plan = _deepConvert(box.get(key)) as Map<String, dynamic>;
      final shouldBeActive = plan['id'] == id;
      if (plan['isActive'] != shouldBeActive) {
        plan['isActive'] = shouldBeActive;
        await box.put(key, plan);
      }
    }
  }

  /// Delete a plan by its id.
  Future<void> deletePlan(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Retrieve a single plan by id.
  Future<Map<String, dynamic>?> getPlan(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }
}
