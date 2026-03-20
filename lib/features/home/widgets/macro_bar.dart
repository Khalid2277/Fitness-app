import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// A thin horizontal progress bar for a macronutrient.
///
/// Label is displayed uppercase on the left, current/target on the right.
/// The bar track is 5px tall with a rounded colored fill.
class MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              '${current.toInt()}$unit / ${target.toInt()}$unit',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusPill,
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : color.withValues(alpha: 0.12),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                )
                    .animate()
                    .scaleX(
                      begin: 0,
                      end: 1,
                      alignment: Alignment.centerLeft,
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                      delay: 200.ms,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
