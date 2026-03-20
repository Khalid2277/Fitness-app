import 'package:hive/hive.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';

/// Repository for reminder CRUD operations using Hive.
class ReminderRepository {
  Future<Box> get _box async =>
      await Hive.openBox(AppConstants.remindersBox);

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

  /// Retrieve all stored reminders, sorted by creation date descending.
  Future<List<Map<String, dynamic>>> getAll() async {
    final box = await _box;
    final reminders = box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
    reminders.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt'] as String);
      final dateB = DateTime.parse(b['createdAt'] as String);
      return dateB.compareTo(dateA);
    });
    return reminders;
  }

  /// Save or update a reminder.
  Future<void> save(Map<String, dynamic> reminder) async {
    final box = await _box;
    await box.put(reminder['id'], reminder);
  }

  /// Delete a reminder by its id.
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Toggle the enabled state of a reminder. Returns updated data.
  Future<Map<String, dynamic>?> toggleEnabled(String id) async {
    final box = await _box;
    final data = box.get(id);
    if (data == null) return null;
    final map = _deepConvert(data) as Map<String, dynamic>;
    map['isEnabled'] = !(map['isEnabled'] as bool? ?? true);
    await box.put(id, map);
    return map;
  }

  /// Retrieve a single reminder by id.
  Future<Map<String, dynamic>?> getById(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }
}
