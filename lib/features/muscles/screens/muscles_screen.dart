import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/muscles/widgets/body_map.dart';
import 'package:alfanutrition/features/muscles/widgets/muscle_detail_sheet.dart';
import 'package:alfanutrition/features/muscles/providers/muscle_providers.dart';

class MusclesScreen extends ConsumerWidget {
  const MusclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final volume = ref.watch(muscleVolumeProvider);

    // Listen for muscle selection to show detail sheet
    ref.listen<MuscleGroup?>(selectedMuscleProvider, (prev, next) {
      if (next != null && prev != next) {
        showMuscleDetailSheet(context);
      }
    });

    // Calculate global fatigue
    final totalSets = volume.values.fold<int>(0, (a, b) => a + b);
    final maxPossibleSets = MuscleGroup.values.length * 16;
    final globalFatigue =
        ((totalSets / maxPossibleSets) * 100).clamp(0, 100).round();
    final fatigueLabel = globalFatigue > 75
        ? 'High'
        : globalFatigue > 40
            ? 'Moderate'
            : 'Low';
    final fatigueColor = globalFatigue > 75
        ? AppColors.error
        : globalFatigue > 40
            ? AppColors.warning
            : AppColors.success;

    final selectedMuscle = ref.watch(selectedMuscleProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MUSCLE MAP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Body Analysis',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Global fatigue badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: fatigueColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: fatigueColor.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: fatigueColor.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: fatigueColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: fatigueColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$globalFatigue%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fatigueColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          fatigueLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: fatigueColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: AppSpacing.sm),

            // ── Selected Muscle Info Card ────────────────────────────────
            if (selectedMuscle != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: _SelectedMuscleCard(
                  muscle: selectedMuscle,
                  sets: volume[selectedMuscle] ?? 0,
                  isDark: isDark,
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),

            // Body map — takes most of the screen
            const Expanded(
              child: BodyMap(),
            ),

            // Heatmap legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppColors.surfaceLight1,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.dividerLight,
                  ),
                ),
                child: _HeatmapLegend(isDark: isDark),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.md),

            // Muscle group volume chips — horizontal scroll
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: MuscleGroup.values.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final muscle = MuscleGroup.values[index];
                  final sets = volume[muscle] ?? 0;
                  final selected =
                      ref.watch(selectedMuscleProvider) == muscle;

                  return _MuscleChip(
                    muscle: muscle,
                    sets: sets,
                    isSelected: selected,
                    isDark: isDark,
                    onTap: () {
                      ref.read(selectedMuscleProvider.notifier).state =
                          muscle;
                    },
                  );
                },
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected Muscle Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedMuscleCard extends StatelessWidget {
  const _SelectedMuscleCard({
    required this.muscle,
    required this.sets,
    required this.isDark,
  });

  final MuscleGroup muscle;
  final int sets;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscleColor = AppColors.colorForMuscle(muscle);
    final volumeLabel = sets == 0
        ? 'Not trained'
        : sets >= 12
            ? 'Well trained'
            : sets >= 6
                ? 'Moderate volume'
                : 'Light volume';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: muscleColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: muscleColor.withValues(alpha: isDark ? 0.1 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Muscle color indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: muscleColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: muscleColor.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                muscle.displayName.substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: muscleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  volumeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Sets count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: muscleColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sets',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: muscleColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'sets',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muscleColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heatmap Legend
// ─────────────────────────────────────────────────────────────────────────────

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.isDark});
  final bool isDark;

  // Heatmap intensity colors — light and dark variants
  static const Color _restLight = Color(0xFFD0D3DA);
  static const Color _restDark = Color(0xFF2A2D35);
  static const Color _lightLight = Color(0xFF86EFAC);
  static const Color _lightDark = Color(0xFF1A4D3A);
  static const Color _activeLight = Color(0xFF93C5FD);
  static const Color _activeDark = Color(0xFF1E3A5F);
  static const Color _highLight = Color(0xFFFCD34D);
  static const Color _highDark = Color(0xFF5C4813);
  static const Color _overLight = Color(0xFFFCA5A5);
  static const Color _overDark = Color(0xFF6B2020);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
          color: isDark ? _restDark : _restLight,
          label: 'Rest',
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: isDark ? _lightDark : _lightLight,
          label: 'Light',
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: isDark ? _activeDark : _activeLight,
          label: 'Active',
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: isDark ? _highDark : _highLight,
          label: 'High',
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendDot(
          color: isDark ? _overDark : _overLight,
          label: 'Over',
          theme: theme,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.theme,
  });

  final Color color;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muscle Chip
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({
    required this.muscle,
    required this.sets,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final MuscleGroup muscle;
  final int sets;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscleColor = AppColors.colorForMuscle(muscle);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? muscleColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.surfaceLight2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected
                ? muscleColor.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.dividerLight),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: muscleColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              muscle.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? muscleColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs / 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? muscleColor.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.surfaceLight3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '$sets',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? muscleColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
