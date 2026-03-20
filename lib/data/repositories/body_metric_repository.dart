import 'package:hive/hive.dart';

/// Repository for body-metric CRUD operations using Hive.
class BodyMetricRepository {
  static const String _boxName = 'body_metrics';

  Future<Box> get _box async => await Hive.openBox(_boxName);

  /// Save a body-metric entry.
  Future<void> saveMetric(Map<String, dynamic> metric) async {
    final box = await _box;
    await box.put(metric['id'], metric);
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

  /// Retrieve all stored body metrics, sorted by date descending.
  Future<List<Map<String, dynamic>>> getAllMetrics() async {
    final box = await _box;
    final metrics = box.values
        .map((e) => _deepConvert(e) as Map<String, dynamic>)
        .toList();
    metrics.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });
    return metrics;
  }

  /// Retrieve the most recently recorded metric.
  Future<Map<String, dynamic>?> getLatestMetric() async {
    final all = await getAllMetrics();
    return all.isNotEmpty ? all.first : null;
  }

  /// Retrieve metrics within [start] and [end] (inclusive).
  Future<List<Map<String, dynamic>>> getMetricsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllMetrics();
    return all.where((m) {
      final date = DateTime.parse(m['date'] as String);
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Delete a metric by its id.
  Future<void> deleteMetric(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Retrieve a single metric by id.
  Future<Map<String, dynamic>?> getMetric(String id) async {
    final box = await _box;
    final data = box.get(id);
    return data != null ? _deepConvert(data) as Map<String, dynamic> : null;
  }
}
