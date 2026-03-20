import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';


class PlanDayCard extends StatefulWidget {
  const PlanDayCard({
    super.key,
    required this.dayNumber,
    required this.dayName,
    required this.exercises,
    this.onStartWorkout,
    this.delay = Duration.zero,
  });

  final int dayNumber;
  final String dayName;
  final List<Map<String, dynamic>> exercises;
  final VoidCallback? onStartWorkout;
  final Duration delay;

  @override
  State<PlanDayCard> createState() => _PlanDayCardState();
}

class _PlanDayCardState extends State<PlanDayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.dayNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
                          widget.dayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.exercises.length} exercises',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context, theme, isDark),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    )
        .animate(delay: widget.delay)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms);
  }

  Widget _buildExpandedContent(
      BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            children: [
              ...widget.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return _ExerciseRow(
                  index: index + 1,
                  name: exercise['exerciseName'] as String? ?? 'Exercise',
                  sets: exercise['sets'] as int? ?? 3,
                  repRange: exercise['repRange'] as String? ?? '8-12',
                  restSeconds: exercise['restSeconds'] as int? ?? 90,
                  isLast: index == widget.exercises.length - 1,
                );
              }),
              if (widget.onStartWorkout != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onStartWorkout,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start This Workout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.name,
    required this.sets,
    required this.repRange,
    required this.restSeconds,
    required this.isLast,
  });

  final int index;
  final String name;
  final int sets;
  final String repRange;
  final int restSeconds;
  final bool isLast;

  IconData _guessEquipmentIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('barbell') || lower.contains('bench press') || lower.contains('squat') || lower.contains('deadlift')) {
      return Icons.fitness_center;
    }
    if (lower.contains('dumbbell') || lower.contains('db ')) return Icons.fitness_center;
    if (lower.contains('cable')) return Icons.cable;
    if (lower.contains('machine') || lower.contains('press')) return Icons.precision_manufacturing;
    if (lower.contains('bodyweight') || lower.contains('push-up') || lower.contains('pull-up') || lower.contains('dip')) {
      return Icons.self_improvement;
    }
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: (isDark ? AppColors.dividerDark : AppColors.dividerLight)
                      .withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Center(
              child: Text(
                '$index',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            _guessEquipmentIcon(name),
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.12)
                  : AppColors.primaryBlueSurface,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Text(
              '$sets x $repRange',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${restSeconds}s',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
