import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/seed/exercise_database.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/exercises/providers/exercise_providers.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  bool _tipsExpanded = true;
  bool _mistakesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final exercise = ref.watch(exerciseByIdProvider(widget.exerciseId));

    if (exercise == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Exercise not found')),
      );
    }

    // Find related exercises (same primary muscle, different exercise)
    final related = exercisesForMuscle(exercise.primaryMuscle)
        .where((e) => e.id != exercise.id)
        .take(6)
        .toList();

    final muscleColor = AppColors.colorForMuscle(exercise.primaryMuscle);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header with gradient ─────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: muscleColor,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      muscleColor,
                      muscleColor.withValues(alpha: 0.85),
                      muscleColor.withValues(alpha: 0.6),
                      isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative pattern overlay
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Icon(
                        exercise.equipment.icon,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, 60, AppSpacing.xl, AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category + difficulty label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.15),
                                borderRadius: AppSpacing.borderRadiusPill,
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '${exercise.category.displayName} \u2022 ${exercise.difficulty.displayName}'
                                    .toUpperCase(),
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white
                                      .withValues(alpha: 0.9),
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Exercise name
                            Text(
                              exercise.name,
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Muscle tags row
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _HeroChip(
                                  label: exercise
                                      .primaryMuscle.displayName,
                                  isPrimary: true,
                                ),
                                ...exercise.secondaryMuscles
                                    .map((m) => _HeroChip(
                                          label: m.displayName,
                                          isPrimary: false,
                                        )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Info Row ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickInfoChip(
                          icon: exercise.primaryMuscle.icon,
                          label: exercise.primaryMuscle.displayName,
                          color: muscleColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickInfoChip(
                          icon: exercise.equipment.icon,
                          label: exercise.equipment.displayName,
                          color: AppColors.primaryBlue,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickInfoChip(
                          icon: exercise.difficulty.icon,
                          label: exercise.difficulty.displayName,
                          color: _difficultyColor(exercise.difficulty),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Suggested rep range card ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          muscleColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          AppColors.primaryBlue
                              .withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                      ),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: muscleColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: muscleColor.withValues(alpha: 0.15),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: muscleColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suggested Rep Range',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exercise.suggestedRepRange} reps',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (exercise.bestForGoals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  muscleColor.withValues(alpha: 0.15),
                              borderRadius: AppSpacing.borderRadiusPill,
                            ),
                            child: Text(
                              exercise.bestForGoals.first,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                color: muscleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Description ────────────────────────────────────
                  Text(
                    exercise.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Video button ───────────────────────────────────
                  if (exercise.videoUrl != null) ...[
                    _VideoCard(
                      videoUrl: exercise.videoUrl!,
                      muscleColor: muscleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── Instructions Section ───────────────────────────
                  _SectionCard(
                    icon: Icons.format_list_numbered_rounded,
                    iconColor: AppColors.primaryBlue,
                    title: 'How to Perform',
                    isDark: isDark,
                    delay: 300,
                    child: _NumberedInstructions(
                      text: exercise.instructions,
                      accentColor: muscleColor,
                      isDark: isDark,
                    ),
                  ),

                  // ── Setup instructions ─────────────────────────────
                  if (exercise.setupInstructions != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      icon: Icons.build_circle_outlined,
                      iconColor: AppColors.accent,
                      title: 'Setup',
                      isDark: isDark,
                      delay: 350,
                      child: Text(
                        exercise.setupInstructions!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.7,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],

                  // ── Tips Section (Collapsible) ─────────────────────
                  if (exercise.tips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _CollapsibleSection(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: AppColors.accent,
                      title: 'Pro Tips',
                      isExpanded: _tipsExpanded,
                      onToggle: () =>
                          setState(() => _tipsExpanded = !_tipsExpanded),
                      isDark: isDark,
                      delay: 400,
                      child: Column(
                        children: exercise.tips
                            .map((tip) => _IconBulletPoint(
                                  text: tip,
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.accent,
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  // ── Common Mistakes (Collapsible) ──────────────────
                  if (exercise.commonMistakes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _CollapsibleSection(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.error,
                      title: 'Common Mistakes',
                      isExpanded: _mistakesExpanded,
                      onToggle: () => setState(
                          () => _mistakesExpanded = !_mistakesExpanded),
                      isDark: isDark,
                      delay: 450,
                      child: Column(
                        children: exercise.commonMistakes
                            .map((mistake) => _IconBulletPoint(
                                  text: mistake,
                                  icon: Icons.cancel_rounded,
                                  color: AppColors.error,
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  // ── Safety Tips ────────────────────────────────────
                  if (exercise.safetyTips != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SafetyCard(
                      text: exercise.safetyTips!,
                      isDark: isDark,
                    ),
                  ],

                  // ── Best For goals ─────────────────────────────────
                  if (exercise.bestForGoals.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionCard(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.warning,
                      title: 'Best For',
                      isDark: isDark,
                      delay: 500,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: exercise.bestForGoals
                            .map((goal) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.warning
                                            .withValues(alpha: 0.1),
                                        AppColors.warning
                                            .withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius:
                                        AppSpacing.borderRadiusPill,
                                    border: Border.all(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 14,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(
                                          width: AppSpacing.xs),
                                      Text(
                                        goal,
                                        style: theme
                                            .textTheme.labelMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  // ── Related Exercises ──────────────────────────────
                  if (related.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    Row(
                      children: [
                        Text(
                          'Related Exercises',
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
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
                            color: muscleColor.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusPill,
                          ),
                          child: Text(
                            '${related.length}',
                            style:
                                theme.textTheme.labelSmall?.copyWith(
                              color: muscleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ),

          // ── Related exercises horizontal scroll ───────────────────
          if (related.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  itemCount: related.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ex = related[index];
                    final exColor =
                        AppColors.colorForMuscle(ex.primaryMuscle);
                    return GestureDetector(
                      onTap: () {
                        context.push('/exercise/${ex.id}');
                      },
                      child: Container(
                        width: 200,
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppSpacing.borderRadiusLg,
                          border: Border.all(
                            color: Colors.white.withValues(
                                alpha: isDark ? 0.07 : 0.0),
                          ),
                          boxShadow: isDark
                              ? AppColors.cardShadowDark
                              : AppColors.cardShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: exColor
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        AppSpacing.borderRadiusSm,
                                  ),
                                  child: Icon(
                                    ex.equipment.icon,
                                    size: 18,
                                    color: exColor,
                                  ),
                                ),
                                const Spacer(),
                                // Colored accent strip
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: exColor,
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              ex.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: exColor
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        AppSpacing.borderRadiusPill,
                                  ),
                                  child: Text(
                                    ex.primaryMuscle.displayName,
                                    style: theme
                                        .textTheme.labelSmall
                                        ?.copyWith(
                                      color: exColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: AppSpacing.xs),
                                Text(
                                  ex.equipment.displayName,
                                  style: theme
                                      .textTheme.labelSmall
                                      ?.copyWith(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors
                                            .textTertiaryLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(
                          delay: Duration(
                              milliseconds: 650 + index * 50),
                        );
                  },
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxxl),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(dynamic difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return AppColors.success;
      case ExerciseDifficulty.intermediate:
        return AppColors.warning;
      case ExerciseDifficulty.advanced:
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.isPrimary});
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPrimary ? 0.22 : 0.1),
        borderRadius: AppSpacing.borderRadiusPill,
        border: isPrimary
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QuickInfoChip extends StatelessWidget {
  const _QuickInfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.delay,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.0),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.02);
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.isDark,
    required this.delay,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isDark;
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.0),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          // Header (tappable)
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 24,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.02);
  }
}

class _NumberedInstructions extends StatelessWidget {
  const _NumberedInstructions({
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  final String text;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Split by sentences ending with period or by newlines
    final steps = text
        .split(RegExp(r'(?<=\.)\s+|\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (steps.length <= 1) {
      // Single block of text - just show it
      return Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.7,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      );
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value.trim();
        return Padding(
          padding: EdgeInsets.only(
              bottom: idx < steps.length - 1 ? AppSpacing.md : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  step,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IconBulletPoint extends StatelessWidget {
  const _IconBulletPoint({
    required this.text,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppColors.warningLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 20,
              color: isDark ? AppColors.warning : AppColors.warningDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Notice',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? AppColors.warning
                        : AppColors.warningDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.warning.withValues(alpha: 0.8)
                        : AppColors.warningDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.02);
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.videoUrl,
    required this.muscleColor,
    required this.isDark,
  });

  final String videoUrl;
  final Color muscleColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(videoUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              muscleColor.withValues(alpha: isDark ? 0.15 : 0.1),
              AppColors.primaryBlue.withValues(alpha: isDark ? 0.1 : 0.06),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: muscleColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    muscleColor,
                    muscleColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusMd,
                boxShadow: [
                  BoxShadow(
                    color: muscleColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watch Tutorial',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Video demonstration & form guide',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: muscleColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: muscleColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.02);
  }
}
