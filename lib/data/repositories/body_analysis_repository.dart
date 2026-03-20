import 'package:hive/hive.dart';

import 'package:alfanutrition/data/models/body_analysis.dart';

/// Repository for body analysis CRUD operations using Hive.
class BodyAnalysisRepository {
  static const String _boxName = 'body_analyses';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save or update a body analysis result.
  Future<void> save(BodyAnalysis analysis) async {
    final box = await _box;
    await box.put(analysis.id, analysis.toJson());
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

  /// Get the analysis for a specific photo set, or null if none exists.
  Future<BodyAnalysis?> getForPhotoSet(String photoSetId) async {
    final box = await _box;
    for (final raw in box.values) {
      final map = _deepConvert(raw) as Map<String, dynamic>;
      if (map['photoSetId'] == photoSetId) {
        return BodyAnalysis.fromJson(map);
      }
    }
    return null;
  }

  /// Retrieve a single analysis by id.
  Future<BodyAnalysis?> getById(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null
        ? BodyAnalysis.fromJson(_deepConvert(data) as Map<String, dynamic>)
        : null;
  }

  /// Retrieve all analyses, sorted by analyzedAt descending (newest first).
  Future<List<BodyAnalysis>> getAll() async {
    final box = await _box;
    final results = box.values
        .map((e) => BodyAnalysis.fromJson(_deepConvert(e) as Map<String, dynamic>))
        .toList();
    results.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return results;
  }

  /// Delete an analysis by id.
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}
