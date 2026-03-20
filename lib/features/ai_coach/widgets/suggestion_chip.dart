import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// A small tappable chip used beneath AI chat messages to suggest follow-up
/// queries. Renders with a subtle border and primary-colored text.
class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primaryBlueSurface.withValues(alpha: 0.5)
              : AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.primaryBlueLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
