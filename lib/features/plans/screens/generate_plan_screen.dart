import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart' as enums;
import 'package:alfanutrition/data/services/plan_generator_service.dart' hide ExperienceLevel, SplitType;
import 'package:alfanutrition/features/plans/providers/plan_providers.dart';
import 'package:alfanutrition/features/plans/widgets/goal_card.dart';
import 'package:alfanutrition/features/plans/widgets/split_card.dart';
import 'package:alfanutrition/features/plans/widgets/equipment_chip.dart';

class GeneratePlanScreen extends ConsumerStatefulWidget {
  const GeneratePlanScreen({super.key});

  @override
  ConsumerState<GeneratePlanScreen> createState() =>
      _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends ConsumerState<GeneratePlanScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    final state = ref.read(planGeneratorProvider);
    if (!state.isValid) return;

    ref.read(planGeneratorProvider.notifier).setGenerating(true);

    try {
      // Simulate a short delay for premium feel
      await Future.delayed(const Duration(milliseconds: 1200));

      final service = ref.read(planGeneratorServiceProvider);
      final config = PlanConfig(
        goal: toServiceGoal(state.goal!),
        experience: toServiceExperience(state.experienceLevel!),
        daysPerWeek: state.daysPerWeek,
        splitType: toServiceSplit(state.splitType!),
        availableEquipment: state.equipment.toList(),
      );

      final plan = service.generatePlan(config);

      // Store the generated plan
      ref.read(generatedPlanProvider.notifier).state = plan;

      ref.read(planGeneratorProvider.notifier).setGenerating(false);

      if (mounted) {
        final planId = plan['id'] as String;
        context.pushReplacement('/plan/$planId');
      }
    } catch (e) {
      ref.read(planGeneratorProvider.notifier).setGenerating(false);
      ref.read(planGeneratorProvider.notifier).setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formState = ref.watch(planGeneratorProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                ref.read(planGeneratorProvider.notifier).reset();
                                context.pop();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Step indicator
                            _buildStepIndicator(theme, isDark, formState),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'PLAN GENERATOR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Build Your Plan',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Customize your perfect workout routine',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.05),
                ),

                // ── 1. Goal Selection ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '1',
                    title: 'What\'s your goal?',
                    subtitle: 'Select your primary training objective',
                    icon: Icons.flag_rounded,
                    color: AppColors.primaryBlue,
                    child: Column(
                      children: _goalOptions
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: GoalCard(
                                  icon: entry.value.icon,
                                  name: entry.value.displayName,
                                  description: _goalDescriptions[entry.key],
                                  isSelected:
                                      formState.goal == entry.value,
                                  onTap: () => ref
                                      .read(planGeneratorProvider.notifier)
                                      .setGoal(entry.value),
                                  delay: Duration(
                                      milliseconds: 60 * entry.key),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // ── 2. Experience Level ───────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '2',
                    title: 'Experience level',
                    subtitle: 'This adjusts exercise complexity and volume',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.accent,
                    child: Row(
                      children: enums.ExperienceLevel.values.map((level) {
                        final isSelected =
                            formState.experienceLevel == level;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: level != enums.ExperienceLevel.advanced
                                  ? AppSpacing.sm
                                  : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(planGeneratorProvider.notifier)
                                  .setExperienceLevel(level),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryBlue
                                              .withValues(alpha: 0.15)
                                          : AppColors.primaryBlueSurface)
                                      : (isDark
                                          ? AppColors.surfaceDark1
                                          : AppColors.surfaceLight),
                                  borderRadius: AppSpacing.borderRadiusLg,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : (isDark
                                            ? AppColors.dividerDark
                                            : AppColors.dividerLight),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryBlue
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.06)
                                                : Colors.black
                                                    .withValues(alpha: 0.04)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        level.icon,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme
                                                .onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      level.displayName,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primaryBlue
                                            : theme
                                                .colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  ),
                ),

                // ── 3. Training Days ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '3',
                    title: 'Training days per week',
                    subtitle: '${formState.daysPerWeek} days selected',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.warning,
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            final days = index + 2;
                            final isSelected =
                                formState.daysPerWeek == days;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: index < 4 ? AppSpacing.sm : 0),
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(planGeneratorProvider.notifier)
                                      .setDaysPerWeek(days),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    height: AppSpacing.xxxxl + AppSpacing.lg,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? AppColors.primaryGradient
                                          : null,
                                      color: isSelected
                                          ? null
                                          : (isDark
                                              ? AppColors.surfaceDark1
                                              : AppColors.surfaceLight),
                                      borderRadius:
                                          AppSpacing.borderRadiusMd,
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: isDark
                                                  ? AppColors.dividerDark
                                                  : AppColors
                                                      .dividerLight,
                                            ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primaryBlue
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 12,
                                                offset:
                                                    const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$days',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : theme.colorScheme
                                                  .onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Minimal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                            Text(
                              'Maximum',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  ),
                ),

                // ── 4. Split Type ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '4',
                    title: 'Training split',
                    subtitle:
                        'How to distribute muscle groups across your training days',
                    icon: Icons.view_week_rounded,
                    color: AppColors.success,
                    child: Column(
                      children: _splitOptions
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: SplitCard(
                                  splitType: entry.value,
                                  isSelected:
                                      formState.splitType == entry.value,
                                  onTap: () => ref
                                      .read(planGeneratorProvider.notifier)
                                      .setSplitType(entry.value),
                                  delay: Duration(
                                      milliseconds: 60 * entry.key),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // ── 5. Equipment ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '5',
                    title: 'Available equipment',
                    subtitle: 'Select all equipment you have access to',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.copper,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _equipmentOptions
                          .asMap()
                          .entries
                          .map((entry) => EquipmentChip(
                                equipment: entry.value,
                                isSelected: formState.equipment
                                    .contains(entry.value),
                                onTap: () => ref
                                    .read(planGeneratorProvider.notifier)
                                    .toggleEquipment(entry.value),
                                delay:
                                    Duration(milliseconds: 40 * entry.key),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // ── 6. Training Location ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    number: '6',
                    title: 'Training location',
                    subtitle:
                        'This helps us optimize equipment selection',
                    icon: Icons.location_on_rounded,
                    color: AppColors.info,
                    child: Row(
                      children: [
                        Expanded(
                          child: _LocationToggle(
                            icon: Icons.fitness_center_rounded,
                            label: 'Gym',
                            isSelected: formState.isGym,
                            onTap: () => ref
                                .read(planGeneratorProvider.notifier)
                                .setIsGym(true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _LocationToggle(
                            icon: Icons.home_rounded,
                            label: 'Home',
                            isSelected: !formState.isGym,
                            onTap: () => ref
                                .read(planGeneratorProvider.notifier)
                                .setIsGym(false),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  ),
                ),

                // ── Error message ─────────────────────────────────────────
                if (formState.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                formState.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Spacer for bottom button
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxxl * 3),
                ),
              ],
            ),
          ),

          // ── Generate Button ───────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.95)
                    : AppColors.backgroundLight.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    width: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: formState.isValid && !formState.isGenerating
                        ? AppColors.primaryGradient
                        : null,
                    color: formState.isValid && !formState.isGenerating
                        ? null
                        : (isDark
                            ? AppColors.surfaceDark2
                            : AppColors.surfaceLight3),
                    borderRadius: AppSpacing.borderRadiusLg,
                    boxShadow: formState.isValid && !formState.isGenerating
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: formState.isValid && !formState.isGenerating
                        ? _generatePlan
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: isDark
                          ? AppColors.textDisabledDark
                          : AppColors.textDisabledLight,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                    ),
                    child: formState.isGenerating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Generating your plan...',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                                color: formState.isValid
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textDisabledDark
                                        : AppColors.textDisabledLight),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Generate Plan',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: formState.isValid
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textDisabledDark
                                          : AppColors.textDisabledLight),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────
          if (formState.isGenerating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppSpacing.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 800.ms,
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              begin: const Offset(1.1, 1.1),
                              end: const Offset(1, 1),
                              duration: 800.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Building Your Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Optimizing exercises for your goals...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
      ThemeData theme, bool isDark, PlanGeneratorState formState) {
    int completedSteps = 0;
    if (formState.goal != null) completedSteps++;
    if (formState.experienceLevel != null) completedSteps++;
    if (formState.splitType != null) completedSteps++;
    if (formState.equipment.isNotEmpty) completedSteps++;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: completedSteps >= 4
            ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: AppSpacing.borderRadiusPill,
        border: completedSteps >= 4
            ? Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completedSteps >= 4)
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppColors.accent,
            ),
          if (completedSteps >= 4) const SizedBox(width: AppSpacing.xs),
          Text(
            '$completedSteps/6',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: completedSteps >= 4
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: AppSpacing.borderRadiusSm,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    number,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }

  // ── Data ────────────────────────────────────────────────────────────────

  static final _goalOptions = [
    enums.WorkoutGoal.fatLoss,
    enums.WorkoutGoal.hypertrophy,
    enums.WorkoutGoal.strength,
    enums.WorkoutGoal.generalFitness,
    enums.WorkoutGoal.endurance,
  ];

  static const _goalDescriptions = [
    'Burn fat efficiently with high-intensity circuits and supersets',
    'Maximize muscle growth with optimal volume and rep ranges',
    'Build raw power with heavy compound lifts and low reps',
    'Improve overall health, mobility, and functional fitness',
    'Boost stamina and cardiovascular capacity with higher reps',
  ];

  static final _splitOptions = [
    enums.SplitType.pushPullLegs,
    enums.SplitType.upperLower,
    enums.SplitType.broSplit,
    enums.SplitType.fullBody,
    enums.SplitType.arnoldSplit,
  ];

  static final _equipmentOptions = [
    enums.EquipmentType.barbell,
    enums.EquipmentType.dumbbell,
    enums.EquipmentType.cable,
    enums.EquipmentType.machine,
    enums.EquipmentType.bodyweight,
    enums.EquipmentType.kettlebell,
    enums.EquipmentType.resistanceBand,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _LocationToggle extends StatelessWidget {
  const _LocationToggle({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.15)
                  : AppColors.primaryBlueSurface)
              : (isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04)),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryBlue
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
