import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/body_metric.dart';

/// Body metric card — premium dark-first design with trend indicators.
class BodyMetricCard extends StatelessWidget {
  final BodyMetric metric;
  final BodyMetric? previousMetric;

  const BodyMetricCard({
    super.key,
    required this.metric,
    this.previousMetric,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(metric.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  letterSpacing: 0.5,
                ),
              ),
              if (metric.notes != null && metric.notes!.isNotEmpty)
                Icon(
                  Icons.note_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weight row
          Row(
            children: [
              if (metric.weight != null) ...[
                Text(
                  metric.weight!.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildWeightTrend(context),
              ],
              const Spacer(),
              if (metric.bodyFatPercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusPill,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${metric.bodyFatPercentage!.toStringAsFixed(1)}% BF',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          // Measurements row (if any)
          if (metric.hasMeasurements) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                if (metric.chest != null)
                  _MeasurementChip(
                    label: 'CHEST',
                    value: metric.chest!,
                    previousValue: previousMetric?.chest,
                  ),
                if (metric.waist != null)
                  _MeasurementChip(
                    label: 'WAIST',
                    value: metric.waist!,
                    previousValue: previousMetric?.waist,
                  ),
                if (metric.hips != null)
                  _MeasurementChip(
                    label: 'HIPS',
                    value: metric.hips!,
                    previousValue: previousMetric?.hips,
                  ),
                if (metric.bicepLeft != null)
                  _MeasurementChip(
                    label: 'BICEP L',
                    value: metric.bicepLeft!,
                    previousValue: previousMetric?.bicepLeft,
                  ),
                if (metric.bicepRight != null)
                  _MeasurementChip(
                    label: 'BICEP R',
                    value: metric.bicepRight!,
                    previousValue: previousMetric?.bicepRight,
                  ),
                if (metric.neck != null)
                  _MeasurementChip(
                    label: 'NECK',
                    value: metric.neck!,
                    previousValue: previousMetric?.neck,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightTrend(BuildContext context) {
    if (previousMetric == null ||
        metric.weight == null ||
        previousMetric!.weight == null) {
      return const SizedBox.shrink();
    }

    final diff = metric.weight! - previousMetric!.weight!;
    if (diff.abs() < 0.05) return const SizedBox.shrink();

    final isUp = diff > 0;
    final color = isUp ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            diff.abs().toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final double value;
  final double? previousValue;

  const _MeasurementChip({
    required this.label,
    required this.value,
    this.previousValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate percentage change
    String changeText = '\u2014 0%';
    Color changeColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    if (previousValue != null && previousValue! > 0) {
      final pctChange =
          ((value - previousValue!) / previousValue! * 100);
      if (pctChange.abs() >= 0.1) {
        final arrow = pctChange > 0 ? '\u2191' : '\u2193';
        changeText = '$arrow ${pctChange.abs().toStringAsFixed(1)}%';
        changeColor =
            pctChange > 0 ? AppColors.success : AppColors.error;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            letterSpacing: 0.8,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${value.toStringAsFixed(1)} cm',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              changeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: changeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
