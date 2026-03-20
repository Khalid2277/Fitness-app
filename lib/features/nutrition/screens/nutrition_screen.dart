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
                    // Premium avatar with ring accent
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gradient-tinted title for premium feel
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.primaryGradient
                                    .createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'Nutrition',
                              style:
                                  theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d')
                                .format(selectedDate),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xxxxl,
                    ),
                    child: Column(
                      children: [
                        // Larger error icon with tinted background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.error.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Could not load nutrition data',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '$error',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        // Retry button
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: AppSpacing.borderRadiusPill,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.invalidate(dailyNutritionProvider);
                              },
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      AppSpacing.borderRadiusPill,
                                ),
                              ),
                            ),
                          ),
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
                          // Subtle gradient overlay on card background
                          gradient: isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.surfaceDark1,
                                    AppColors.surfaceDark2
                                        .withValues(alpha: 0.8),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.surfaceLight,
                                    AppColors.surfaceLight1,
                                  ],
                                ),
                          borderRadius: AppSpacing.borderRadiusXl,
                          border: Border.all(
                            color: isDark
                                ? AppColors.primaryBlue
                                    .withValues(alpha: 0.08)
                                : AppColors.dividerLight,
                          ),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.elevatedShadowLight,
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
                                // Premium divider with gradient fade
                                Container(
                                  width: 1,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: 0.0),
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: isDark ? 0.12 : 0.8),
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
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
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: 0.0),
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: isDark ? 0.12 : 0.8),
                                        (isDark
                                                ? Colors.white
                                                : AppColors.dividerLight)
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
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
                            // Premium section title with accent line
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius:
                                        AppSpacing.borderRadiusPill,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Macronutrients',
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

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

                    // ── 5. Food Diary Section Header ──
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: AppSpacing.borderRadiusPill,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'FOOD DIARY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.dividerLight)
                                        .withValues(alpha: 0.5),
                                    (isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.dividerLight)
                                        .withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Meal sections
                    ...MealType.values.map((type) {
                      final meals = nutrition.mealsForType(type);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
          )
          .fadeIn(duration: 300.ms, delay: 300.ms),
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
        // Larger icon container with subtle outer glow
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Larger value for visual hierarchy
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        // Smaller label
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 11,
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
            // Larger accent dot with subtle glow
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
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
          barHeight: 7,
        ),
      ],
    );
  }
}
