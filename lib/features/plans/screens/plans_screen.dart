import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/plans/providers/plan_providers.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plansAsync = ref.watch(savedPlansProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark2
                                  : AppColors.surfaceLight2,
                              borderRadius: AppSpacing.borderRadiusMd,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : AppColors.dividerLight,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Plans',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your personalized training programs',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // "+" generate new plan CTA
                        GestureDetector(
                          onTap: () => context.push('/generate-plan'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: AppSpacing.borderRadiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.05, duration: 400.ms),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Generate CTA ──────────────────────────────────────
                    _GeneratePlanCTA(
                      onTap: () => context.push('/generate-plan'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Section header ──
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Saved Plans',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        plansAsync.maybeWhen(
                          data: (plans) => plans.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm + 2,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark2
                                        : AppColors.surfaceLight2,
                                    borderRadius: AppSpacing.borderRadiusPill,
                                  ),
                                  child: Text(
                                    '${plans.length} plan${plans.length == 1 ? '' : 's'}',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Plan List ───────────────────────────────────────────────
            plansAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Text('Error loading plans: $err'),
                ),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(),
                  );
                }

                return SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final plan = plans[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.itemSpacing),
                          child: _PlanListCard(
                            plan: plan,
                            onTap: () {
                              final planId = plan['id'] as String;
                              context.push('/plan/$planId');
                            },
                            delay: Duration(milliseconds: 80 * index),
                          ),
                        );
                      },
                      childCount: plans.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxxl),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generate CTA
// ─────────────────────────────────────────────────────────────────────────────

class _GeneratePlanCTA extends StatelessWidget {
  const _GeneratePlanCTA({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
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
                        'Generate New Plan',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'AI-powered workout plans tailored to your goals and experience',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxxxl),
      child: Column(
        children: [
          // Premium illustration placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                  AppColors.accent.withValues(alpha: isDarkMode ? 0.1 : 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 44,
                  color:
                      AppColors.primaryBlue.withValues(alpha: isDarkMode ? 0.7 : 0.5),
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'No Plans Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create your first personalized workout plan\nand start training smarter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Gradient "Generate Your First Plan" button
          GestureDetector(
            onTap: () => context.push('/generate-plan'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.md + 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppSpacing.borderRadiusPill,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 20, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Generate Your First Plan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanListCard extends StatelessWidget {
  const _PlanListCard({
    required this.plan,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  final Duration delay;

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _displaySplitType(String? splitType) {
    if (splitType == null) return '';
    switch (splitType) {
      case 'pushPullLegs':
        return 'Push/Pull/Legs';
      case 'upperLower':
        return 'Upper/Lower';
      case 'broSplit':
        return 'Bro Split';
      case 'fullBody':
        return 'Full Body';
      case 'arnoldSplit':
        return 'Arnold Split';
      default:
        return splitType;
    }
  }

  String _displayGoal(String? goal) {
    if (goal == null) return '';
    switch (goal) {
      case 'strength':
        return 'Strength';
      case 'hypertrophy':
        return 'Hypertrophy';
      case 'endurance':
        return 'Endurance';
      case 'fatLoss':
        return 'Fat Loss';
      default:
        return goal;
    }
  }

  Color _colorForSplitType(String? splitType) {
    switch (splitType) {
      case 'pushPullLegs':
        return AppColors.primaryBlue;
      case 'upperLower':
        return AppColors.accent;
      case 'broSplit':
        return AppColors.warning;
      case 'fullBody':
        return AppColors.success;
      case 'arnoldSplit':
        return AppColors.muscleArms;
      default:
        return AppColors.primaryBlue;
    }
  }

  Color _colorForGoal(String? goal) {
    switch (goal) {
      case 'strength':
        return AppColors.error;
      case 'hypertrophy':
        return AppColors.primaryBlue;
      case 'endurance':
        return AppColors.accent;
      case 'fatLoss':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final days = plan['days'] as List?;
    final daysPerWeek = plan['daysPerWeek'] as int? ?? days?.length ?? 0;
    final isActive = plan['isActive'] == true;
    final splitType = plan['splitType'] as String?;
    final goal = plan['goal'] as String?;
    final splitColor = _colorForSplitType(splitType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.5)
                : isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.dividerLight,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Accent top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    splitColor,
                    splitColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + active badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          plan['name'] as String? ?? 'Workout Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: AppSpacing.borderRadiusPill,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.accent.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Duration info row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs + 1),
                      Text(
                        '$daysPerWeek days/week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (days != null && days.isNotEmpty) ...[
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${days.length} total days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Chips row
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ColoredChip(
                        label: _displaySplitType(splitType),
                        color: splitColor,
                        isDark: isDark,
                      ),
                      _ColoredChip(
                        label: _displayGoal(goal),
                        color: _colorForGoal(goal),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bottom row: date + view button
                  Row(
                    children: [
                      Text(
                        _formatDate(plan['createdAt'] as String?),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm - 2,
                        ),
                        decoration: BoxDecoration(
                          color: splitColor.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: AppSpacing.borderRadiusPill,
                          border: Border.all(
                            color: splitColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isActive ? 'View' : 'Start',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: splitColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: splitColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _ColoredChip extends StatelessWidget {
  const _ColoredChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
