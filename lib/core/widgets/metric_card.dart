import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// The direction a trend indicator should point.
enum TrendDirection { up, down, neutral }

/// A compact card that displays a single numeric metric with an optional
/// icon, unit label, subtitle, and trend indicator.
///
/// ```dart
/// MetricCard(
///   value: '2,450',
///   unit: 'kcal',
///   subtitle: 'Daily Goal',
///   icon: Icons.local_fire_department_rounded,
///   iconColor: AppColors.warning,
///   trend: TrendDirection.up,
///   trendLabel: '+12%',
/// )
/// ```
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.value,
    this.unit,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trend,
    this.trendLabel,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.compact = false,
  });

  /// The primary metric value (e.g. "2,450").
  final String value;

  /// Optional unit label (e.g. "kcal", "kg").
  final String? unit;

  /// Descriptive subtitle below the metric.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  /// Color of the icon glyph.
  final Color? iconColor;

  /// Background tint of the icon circle.
  final Color? iconBackgroundColor;

  /// Direction of the trend indicator arrow.
  final TrendDirection? trend;

  /// Trend label text (e.g. "+12%").
  final String? trendLabel;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Optional gradient for the card background.
  final Gradient? gradient;

  /// Explicit background color.
  final Color? backgroundColor;

  /// Uses smaller font sizes when true.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      gradient: gradient,
      backgroundColor: backgroundColor,
      padding: compact ? AppSpacing.cardPaddingCompact : AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Icon row ----
          if (icon != null) ...[
            _IconBadge(
              icon: icon!,
              color: iconColor ?? AppColors.primaryBlue,
              backgroundColor: iconBackgroundColor ??
                  (isDark
                      ? (iconColor ?? AppColors.primaryBlue)
                          .withValues(alpha: 0.15)
                      : (iconColor ?? AppColors.primaryBlue)
                          .withValues(alpha: 0.1)),
              compact: compact,
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          ],

          // ---- Value + unit ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: compact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.displaySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  unit!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          // ---- Subtitle + trend ----
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (trend != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _TrendBadge(
                    direction: trend!,
                    label: trendLabel,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Private helpers ───────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 32 : 40;
    final double iconSize = compact ? 18 : 22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.direction, this.label});

  final TrendDirection direction;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = switch (direction) {
      TrendDirection.up => AppColors.success,
      TrendDirection.down => AppColors.error,
      TrendDirection.neutral => (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    };

    final IconData arrow = switch (direction) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      TrendDirection.neutral => Icons.trending_flat_rounded,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(arrow, size: 16, color: color),
        if (label != null) ...[
          const SizedBox(width: 2),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
