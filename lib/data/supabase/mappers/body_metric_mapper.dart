import 'package:alfanutrition/data/models/body_metric.dart';

/// Maps between a Supabase `body_metrics` row and the app-side [BodyMetric].
abstract final class BodyMetricMapper {
  /// Converts a Supabase row `Map` into a [BodyMetric].
  static BodyMetric fromRow(Map<String, dynamic> row) {
    return BodyMetric(
      id: row['id'] as String,
      date: DateTime.parse(row['date'] as String),
      weight: (row['weight_kg'] as num?)?.toDouble(),
      bodyFatPercentage: (row['body_fat_percentage'] as num?)?.toDouble(),
      chest: (row['chest_cm'] as num?)?.toDouble(),
      waist: (row['waist_cm'] as num?)?.toDouble(),
      hips: (row['hips_cm'] as num?)?.toDouble(),
      bicepLeft: (row['bicep_left_cm'] as num?)?.toDouble(),
      bicepRight: (row['bicep_right_cm'] as num?)?.toDouble(),
      thighLeft: (row['thigh_left_cm'] as num?)?.toDouble(),
      thighRight: (row['thigh_right_cm'] as num?)?.toDouble(),
      neck: (row['neck_cm'] as num?)?.toDouble(),
      notes: row['notes'] as String?,
    );
  }

  /// Converts a [BodyMetric] into a Supabase-ready row `Map`.
  static Map<String, dynamic> toRow(
    BodyMetric metric, {
    required String userId,
  }) {
    // Store date as ISO date-only string (YYYY-MM-DD).
    final dateOnly =
        '${metric.date.year.toString().padLeft(4, '0')}-'
        '${metric.date.month.toString().padLeft(2, '0')}-'
        '${metric.date.day.toString().padLeft(2, '0')}';

    return {
      'id': metric.id,
      'user_id': userId,
      'date': dateOnly,
      'weight_kg': metric.weight,
      'body_fat_percentage': metric.bodyFatPercentage,
      'chest_cm': metric.chest,
      'waist_cm': metric.waist,
      'hips_cm': metric.hips,
      'bicep_left_cm': metric.bicepLeft,
      'bicep_right_cm': metric.bicepRight,
      'thigh_left_cm': metric.thighLeft,
      'thigh_right_cm': metric.thighRight,
      'neck_cm': metric.neck,
      'notes': metric.notes,
    };
  }
}
