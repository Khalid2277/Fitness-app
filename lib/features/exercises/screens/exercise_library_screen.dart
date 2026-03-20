import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/features/exercises/providers/exercise_providers.dart';
import 'package:alfanutrition/features/exercises/widgets/exercise_card.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final exercises = ref.watch(exerciseListProvider);
    final filter = ref.watch(exerciseFilterProvider);
    final sortMode = ref.watch(exerciseSortProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: back button + title + count badge + sort
                    Row(
                      children: [
                        _BackButton(isDark: isDark),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Exercise Library',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Exercise count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppSpacing.borderRadiusPill,
                          ),
                          child: Text(
                            '${exercises.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Sort dropdown
                        _SortButton(
                          sortMode: sortMode,
                          isDark: isDark,
                          onSelected: (mode) {
                            ref.read(exerciseSortProvider.notifier).state =
                                mode;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Frosted Search Bar ──────────────────────────────
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusLg,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark2
                                    .withValues(alpha: 0.8)
                                : AppColors.surfaceLight1
                                    .withValues(alpha: 0.85),
                            borderRadius: AppSpacing.borderRadiusLg,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.dividerLight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              ref
                                  .read(exerciseSearchProvider.notifier)
                                  .state = value;
                              setState(() {});
                            },
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search exercises, muscles, equipment...',
                              hintStyle:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                    left: AppSpacing.lg,
                                    right: AppSpacing.sm),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: _searchController.text.isNotEmpty
                                      ? AppColors.primaryBlue
                                      : (isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(
                                            AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceDark3
                                              : AppColors.surfaceLight3,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(exerciseSearchProvider
                                                .notifier)
                                            .state = '';
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.lg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Filter Chips ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  // Difficulty filters
                  ..._buildDifficultyChips(filter, ref, theme, isDark),
                  _ChipDivider(isDark: isDark),
                  // Muscle group filters
                  ..._buildMuscleChips(filter, ref, theme, isDark),
                  _ChipDivider(isDark: isDark),
                  // Equipment filters
                  ..._buildEquipmentChips(filter, ref, theme, isDark),
                  const SizedBox(width: AppSpacing.xl),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.02),
          ),

          // ── Active filter indicator + clear ───────────────────────
          if (filter.hasActiveFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue
                            .withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 14,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${exercises.length} found',
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ref.read(exerciseFilterProvider.notifier).state =
                            const ExerciseFilter();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: AppSpacing.borderRadiusPill,
                          border: Border.all(
                            color:
                                AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Clear',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── AI Insights card ────────────────────────────────────────
          if (!filter.hasActiveFilters && _searchController.text.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
                child: _AIInsightsCard(isDark: isDark),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            ),

          // ── Section header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    filter.hasActiveFilters ? 'Results' : 'All Exercises',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark2
                          : AppColors.surfaceLight2,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),
          ),

          // ── Exercise list / empty state ─────────────────────────────
          exercises.isEmpty
              ? SliverFillRemaining(
                  child: _EmptySearchState(isDark: isDark),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxxl),
                  sliver: SliverList.separated(
                    itemCount: exercises.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == exercises.length) {
                        return _CantFindCTA(isDark: isDark);
                      }
                      final exercise = exercises[index];
                      return ExerciseCard(
                        exercise: exercise,
                        onTap: () {
                          context.push('/exercise/${exercise.id}');
                        },
                      ).animate().fadeIn(
                            delay: Duration(
                                milliseconds:
                                    30 * (index.clamp(0, 15))),
                          );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // ── Difficulty Chips ────────────────────────────────────────────────
  List<Widget> _buildDifficultyChips(
    ExerciseFilter filter,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final difficulties = ExerciseDifficulty.values;
    return difficulties.map((diff) {
      final isSelected = filter.difficulty == diff;
      final Color diffColor;
      switch (diff) {
        case ExerciseDifficulty.beginner:
          diffColor = AppColors.success;
        case ExerciseDifficulty.intermediate:
          diffColor = AppColors.warning;
        case ExerciseDifficulty.advanced:
          diffColor = AppColors.error;
      }
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(clearDifficulty: true);
            } else {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(difficulty: diff);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        diffColor.withValues(alpha: 0.2),
                        diffColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight2),
              borderRadius: AppSpacing.borderRadiusPill,
              border: Border.all(
                color: isSelected
                    ? diffColor.withValues(alpha: 0.5)
                    : Colors.white
                        .withValues(alpha: isDark ? 0.06 : 0.0),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: diffColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  diff.icon,
                  size: 14,
                  color: isSelected
                      ? diffColor
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  diff.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? diffColor
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Muscle Chips ────────────────────────────────────────────────────
  List<Widget> _buildMuscleChips(
    ExerciseFilter filter,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final muscles = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.quadriceps,
      MuscleGroup.hamstrings,
      MuscleGroup.glutes,
      MuscleGroup.core,
    ];

    return muscles.map((muscle) {
      final isSelected = filter.muscleGroup == muscle;
      final muscleColor = AppColors.colorForMuscle(muscle);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(clearMuscle: true);
            } else {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(muscleGroup: muscle);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        muscleColor.withValues(alpha: 0.2),
                        muscleColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight2),
              borderRadius: AppSpacing.borderRadiusPill,
              border: Border.all(
                color: isSelected
                    ? muscleColor.withValues(alpha: 0.5)
                    : Colors.white
                        .withValues(alpha: isDark ? 0.06 : 0.0),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: muscleColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? muscleColor
                        : muscleColor.withValues(alpha: 0.4),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  muscleColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  muscle.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? muscleColor
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── Equipment Chips ─────────────────────────────────────────────────
  List<Widget> _buildEquipmentChips(
    ExerciseFilter filter,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    final equipment = [
      EquipmentType.barbell,
      EquipmentType.dumbbell,
      EquipmentType.cable,
      EquipmentType.machine,
      EquipmentType.bodyweight,
    ];

    return equipment.map((eq) {
      final isSelected = filter.equipment == eq;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(clearEquipment: true);
            } else {
              ref.read(exerciseFilterProvider.notifier).state =
                  filter.copyWith(equipment: eq);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight2),
              borderRadius: AppSpacing.borderRadiusPill,
              border: isSelected
                  ? null
                  : Border.all(
                      color: Colors.white
                          .withValues(alpha: isDark ? 0.06 : 0.0),
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  eq.icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  eq.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortMode,
    required this.isDark,
    required this.onSelected,
  });

  final ExerciseSortMode sortMode;
  final bool isDark;
  final ValueChanged<ExerciseSortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<ExerciseSortMode>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      offset: const Offset(0, 44),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color:
                Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _sortLabel(sortMode),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildSortMenuItem(
            context, ExerciseSortMode.alphabetical, 'A - Z', sortMode),
        _buildSortMenuItem(
            context, ExerciseSortMode.muscleGroup, 'Muscle Group', sortMode),
        _buildSortMenuItem(
            context, ExerciseSortMode.difficulty, 'Difficulty', sortMode),
      ],
    );
  }

  String _sortLabel(ExerciseSortMode mode) {
    switch (mode) {
      case ExerciseSortMode.alphabetical:
        return 'A-Z';
      case ExerciseSortMode.muscleGroup:
        return 'Muscle';
      case ExerciseSortMode.difficulty:
        return 'Level';
    }
  }

  PopupMenuItem<ExerciseSortMode> _buildSortMenuItem(
    BuildContext context,
    ExerciseSortMode mode,
    String label,
    ExerciseSortMode current,
  ) {
    final isActive = current == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: isActive ? AppColors.primaryBlue : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primaryBlue : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      child: Container(
        width: 1,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark2
                    : AppColors.surfaceLight2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No exercises found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your search or filters\nto find what you\'re looking for',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AIInsightsCard extends StatelessWidget {
  const _AIInsightsCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryBlueSurface,
                  AppColors.surfaceDark1,
                ]
              : [
                  AppColors.primaryBlue.withValues(alpha: 0.08),
                  AppColors.surfaceLight,
                ],
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.primaryBlueLight,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI INSIGHTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryBlueLight,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Correcting Hamstring Imbalance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your recent workout data suggests a quad-dominant pattern. We recommend adding more hamstring-focused movements.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI tutorials coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryBlue.withValues(alpha: 0.2),
                foregroundColor: AppColors.primaryBlueLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Start Tutorial'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CantFindCTA extends StatelessWidget {
  const _CantFindCTA({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 32,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Can't find an exercise?",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Request a new exercise to be added to the library',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Exercise requests coming soon')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
              child: const Text('Request Exercise'),
            ),
          ),
        ],
      ),
    );
  }
}
