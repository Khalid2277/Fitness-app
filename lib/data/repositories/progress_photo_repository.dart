import 'package:hive/hive.dart';

/// Repository for progress-photo-set CRUD operations using Hive.
class ProgressPhotoRepository {
  static const String _boxName = 'progress_photos';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save or update a progress photo set.
  Future<void> savePhotoSet(Map<String, dynamic> photoSet) async {
    final box = await _box;
    await box.put(photoSet['id'], photoSet);
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

  /// Retrieve a single photo set by id.
  Future<Map<String, dynamic>?> getPhotoSet(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }

  /// Retrieve all photo sets, sorted by date descending (newest first).
  Future<List<Map<String, dynamic>>> getAllPhotoSets() async {
    final box = await _box;
    final sets = box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
    sets.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });
    return sets;
  }

  /// Retrieve photo sets within a date range (inclusive).
  Future<List<Map<String, dynamic>>> getPhotoSetsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllPhotoSets();
    return all.where((m) {
      final date = DateTime.parse(m['date'] as String);
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Delete a photo set by id.
  Future<void> deletePhotoSet(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
