import 'package:flutter/material.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/meal.dart';

/// A grouped section for a single meal type (Breakfast, Lunch, etc.)
/// following the premium dark-first design.
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.meals,
    required this.onAddTapped,
    this.onMealTapped,
    this.onMealDismissed,
  });

  final MealType mealType;
  final List<Meal> meals;
  final VoidCallback onAddTapped;
  final void Function(Meal meal)? onMealTapped;
  final Future<bool> Function(Meal meal)? onMealDismissed;

  double get _totalCalories =>
      meals.fold(0.0, (sum, m) => sum + m.calories);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(
                    mealType.icon,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealType.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meals.isNotEmpty)
                        Text(
                          '${meals.length} item${meals.length != 1 ? 's' : ''} \u2022 ${_totalCalories.toInt()} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          'No items logged',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAddTapped,
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: AppColors.primaryBlue,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Meal items
          if (meals.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: meals.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.dividerLight,
              ),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Dismissible(
                  key: ValueKey(meal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                  ),
                  // Use confirmDismiss to handle async deletion BEFORE the
                  // widget is removed from the tree. This prevents the
                  // "dismissed Dismissible still part of tree" crash.
                  confirmDismiss: (_) async {
                    if (onMealDismissed != null) {
                      return onMealDismissed!(meal);
                    }
                    return false;
                  },
                  child: InkWell(
                    onTap: () => onMealTapped?.call(meal),
                    borderRadius: AppSpacing.borderRadiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (meal.servingSize > 0 &&
                                    meal.servingUnit != null)
                                  Text(
                                    '${meal.servingSize.toStringAsFixed(meal.servingSize == meal.servingSize.roundToDouble() ? 0 : 1)} ${meal.servingUnit ?? ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Macro summary
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'P${meal.protein.toInt()} C${meal.carbs.toInt()} F${meal.fats.toInt()}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${meal.calories.toInt()}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' kcal',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
