import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/body_metric.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/body_metric_mapper.dart';

class SbBodyMetricRepository {
  final SupabaseClient _client;

  SbBodyMetricRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns all body metrics ordered by date descending.
  Future<List<BodyMetric>> getAllMetrics() async {
    final rows = await _client
        .from(SupabaseConfig.bodyMetricsTable)
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false);
    return rows.map((r) => BodyMetricMapper.fromRow(r)).toList();
  }

  /// Returns the most recent body metric entry.
  Future<BodyMetric?> getLatestMetric() async {
    final row = await _client
        .from(SupabaseConfig.bodyMetricsTable)
        .select()
        .eq('user_id', _uid)
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return BodyMetricMapper.fromRow(row);
  }

  /// Adds or updates a body metric entry.
  Future<void> addMetric(BodyMetric metric) async {
    final data = BodyMetricMapper.toRow(metric, userId: _uid);
    await _client.from(SupabaseConfig.bodyMetricsTable).upsert(data);
  }

  /// Deletes a body metric entry.
  Future<void> deleteMetric(String id) async {
    await _client
        .from(SupabaseConfig.bodyMetricsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  /// Returns body metrics within a date range.
  Future<List<BodyMetric>> getMetricsForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final fromStr =
        '${from.year.toString().padLeft(4, '0')}-'
        '${from.month.toString().padLeft(2, '0')}-'
        '${from.day.toString().padLeft(2, '0')}';
    final toStr =
        '${to.year.toString().padLeft(4, '0')}-'
        '${to.month.toString().padLeft(2, '0')}-'
        '${to.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from(SupabaseConfig.bodyMetricsTable)
        .select()
        .eq('user_id', _uid)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date', ascending: false);
    return rows.map((r) => BodyMetricMapper.fromRow(r)).toList();
  }
}
