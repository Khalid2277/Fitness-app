import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';
import 'package:alfanutrition/features/nutrition/widgets/date_selector.dart';
import 'package:alfanutrition/features/nutrition/widgets/calorie_summary_ring.dart';
import 'package:alfanutrition/features/nutrition/widgets/macro_progress_bar.dart';
import 'package:alfanutrition/features/nutrition/widgets/meal_section.dart';

/// Main nutrition tracking tab — premium diary design inspired by
/// MyFitnessPal, Lose It!, and MacroFactor.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  static const _proteinColor = AppColors.primaryBlue;
  static const _carbsColor = AppColors.accent;
  static const _fatsColor = AppColors.warning;
  static const _fiberColor = AppColors.success;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final dailyNutritionAsync = ref.watch(dailyNutritionProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 1. Header: Avatar + Title + Today-reset ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nutrition',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d').format(selectedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.today_rounded,
                      isDark: isDark,
                      onTap: () {
                        final now = DateTime.now();
                        ref.read(selectedDateProvider.notifier).state =
                            DateTime(now.year, now.month, now.day);
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── 2. Horizontal Date Selector ──
            const SliverToBoxAdapter(child: DateSelector()),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── 3–6. Content (loading / error / data) ──
            dailyNutritionAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Could not load nutrition data',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$error',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (nutrition) {
                final burned = ref.watch(burnedCaloriesProvider);
                final remaining =
                    (nutrition.targetCalories + burned - nutrition.totalCalories)
                        .clamp(0.0, nutrition.targetCalories + burned);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── 3. Calorie Summary Hero ──
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xxl,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppSpacing.borderRadiusLg,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.dividerLight,
                          ),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.cardShadowLight,
                        ),
                        child: Column(
                          children: [
                            // Large calorie ring
                            CalorieSummaryRing(
                              consumed: nutrition.totalCalories,
                              target: nutrition.targetCalories,
                              size: 180,
                              strokeWidth: 14,
                            ),

                            const SizedBox(height: AppSpacing.xxl),

                            // Eaten / Burned / Remaining stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _CalorieStatColumn(
                                  label: 'Eaten',
                                  value: nutrition.totalCalories.toInt(),
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppColors.warning,
                                  isDark: isDark,
                                  theme: theme,
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.dividerLight,
                                ),
                                _CalorieStatColumn(
                                  label: 'Burned',
                                  value: burned,
                                  icon: Icons.directions_run_rounded,
                                  color: AppColors.error,
                                  isDark: isDark,
                                  theme: theme,
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.dividerLight,
                                ),
                                _CalorieStatColumn(
                                  label: 'Remaining',
                                  value: remaining.toInt(),
                                  icon: Icons.flag_rounded,
                                  color: AppColors.success,
                                  isDark: isDark,
                                  theme: theme,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: AppSpacing.xl),

                    // ── 4. Macro Progress Section ──
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppSpacing.borderRadiusLg,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.dividerLight,
                          ),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.cardShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Macronutrients',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Protein
                            _MacroRow(
                              label: 'Protein',
                              current: nutrition.totalProtein,
                              target: nutrition.targetProtein,
                              color: _proteinColor,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Carbs
                            _MacroRow(
                              label: 'Carbs',
                              current: nutrition.totalCarbs,
                              target: nutrition.targetCarbs,
                              color: _carbsColor,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Fats
                            _MacroRow(
                              label: 'Fats',
                              current: nutrition.totalFats,
                              target: nutrition.targetFats,
                              color: _fatsColor,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Fiber
                            _MacroRow(
                              label: 'Fiber',
                              current: nutrition.totalFiber,
                              target: 30,
                              color: _fiberColor,
                              isDark: isDark,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── 5. Meal Sections ──
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Text(
                        'FOOD DIARY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    ...MealType.values.map((type) {
                      final meals = nutrition.mealsForType(type);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: MealSection(
                          mealType: type,
                          meals: meals,
                          onAddTapped: () => context.push('/add-meal'),
                          onMealTapped: (meal) {
                            context.push('/add-meal', extra: meal);
                          },
                          onMealDismissed: (meal) async {
                            try {
                              final source = ref.read(dataSourceProvider);
                              if (source == DataSourceType.supabase) {
                                final sbRepo =
                                    ref.read(sbNutritionRepositoryProvider);
                                await sbRepo.deleteMeal(meal.id);
                              } else {
                                final repo =
                                    ref.read(nutritionRepositoryProvider);
                                await repo.deleteMeal(meal.id);
                              }
                              // Invalidate AFTER successful deletion so the
                              // rebuilt list no longer contains this meal.
                              ref.invalidate(dailyNutritionProvider);
                              ref.invalidate(todaysNutritionProvider);
                              return true; // allow dismiss
                            } catch (_) {
                              return false; // cancel dismiss on error
                            }
                          },
                        ),
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: (100 * type.index).ms,
                          ).slideY(begin: 0.03);
                    }),

                    // Bottom padding for tab bar
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),

      // ── 6. Gradient FAB ──
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/add-meal'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header icon button
// ---------------------------------------------------------------------------

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calorie stat column (Eaten / Burned / Remaining)
// ---------------------------------------------------------------------------

class _CalorieStatColumn extends StatelessWidget {
  const _CalorieStatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Macro row with colored dot, label, progress bar, and values
// ---------------------------------------------------------------------------

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.isDark,
    required this.theme,
  });
  final String label;
  final double current;
  final double target;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${current.toInt()}g',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              ' / ${target.toInt()}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        MacroProgressBar(
          label: label,
          current: current,
          target: target,
          color: color,
          showLabel: false,
          barHeight: 6,
        ),
      ],
    );
  }
}
