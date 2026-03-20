import 'package:flutter/material.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';

/// Small chip card for quick-adding a preset food — dark-first design.
class QuickFoodChip extends StatelessWidget {
  const QuickFoodChip({
    super.key,
    required this.food,
    required this.onTap,
  });

  final QuickFood food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark1
              : AppColors.surfaceLight1,
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color: isDark
                ? AppColors.dividerDark
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (food.emoji.isNotEmpty) ...[
              Text(food.emoji, style: theme.textTheme.bodyLarge),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              food.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusPill,
              ),
              child: Text(
                '${food.calories.toInt()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
