import 'package:flutter/material.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// Compact horizontal progress bar for a single macronutrient.
///
/// When [showLabel] is false, only the bar is rendered (for inline use
/// inside the new macro cards). When true, the full label row is shown.
class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.showLabel = true,
    this.barHeight = 5,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final bool showLabel;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${current.toInt()}/${target.toInt()}g  $percentage%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusPill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: barHeight,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
