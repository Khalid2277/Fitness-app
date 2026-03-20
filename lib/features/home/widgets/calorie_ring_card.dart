import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';
import 'package:alfanutrition/features/home/widgets/macro_bar.dart';

/// Daily Nutrition card with large calorie ring and macro progress bars.
class CalorieRingCard extends StatelessWidget {
  final DailyNutrition nutrition;

  const CalorieRingCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final consumed = nutrition.caloriesConsumed.toInt();
    final target = nutrition.caloriesTarget.toInt();
    final remaining = nutrition.caloriesRemaining.toInt();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              )
            : null,
        boxShadow: isDark ? null : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Nutrition',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$consumed / $target kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ring — centered
          Center(
            child: CircularPercentIndicator(
              radius: 80,
              lineWidth: 10,
              percent: nutrition.caloriesPercent,
              animation: true,
              animationDuration: 1200,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surfaceLight2,
              progressColor: theme.colorScheme.primary,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${remaining.abs()}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining >= 0 ? 'LEFT' : 'OVER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Macro bars
          MacroBar(
            label: 'PROTEIN',
            current: nutrition.proteinConsumed,
            target: nutrition.proteinTarget,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          MacroBar(
            label: 'CARBS',
            current: nutrition.carbsConsumed,
            target: nutrition.carbsTarget,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          MacroBar(
            label: 'FATS',
            current: nutrition.fatsConsumed,
            target: nutrition.fatsTarget,
            color: AppColors.warning,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
}
