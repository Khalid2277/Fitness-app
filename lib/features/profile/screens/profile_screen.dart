import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(trainingStatsProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          final name = (profile.name != null && profile.name!.isNotEmpty)
              ? profile.name!
              : 'User';
          final initials = profile.initials;
          final goal = profile.goal.displayName;
          final weight = profile.weight;
          final unitSystem = ref.watch(measurementSystemProvider);
          final proteinTarget = profile.proteinTarget.toInt();
          final carbsTarget = profile.carbsTarget.toInt();
          final fatsTarget = profile.fatsTarget.toInt();
          final calorieTarget = profile.dailyCalorieTarget.toInt();

          return CustomScrollView(
            slivers: [
              // ── Back button ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
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
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Profile',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // balance
                      ],
                    ),
                  ),
                ),
              ),

              // ── 1. Profile Header Card ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                    child: _buildPremiumCard(
                      theme,
                      isDark,
                      child: Column(
                        children: [
                          // Gradient avatar with outer ring
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF818CF8),
                                  Color(0xFF00BFA6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.surface,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // User name with gradient
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF818CF8),
                                Color(0xFF00BFA6),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              name,
                              style:
                                  theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Goal badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
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
                                  Icons.local_fire_department_rounded,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  goal,
                                  style:
                                      theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Edit Profile button with gradient accent
                          GestureDetector(
                            onTap: () => context.push('/edit-profile'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue
                                        .withValues(alpha: 0.12),
                                    AppColors.accent
                                        .withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: AppSpacing.borderRadiusPill,
                                border: Border.all(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Edit Profile',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primaryBlue,
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
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              ),

              // ── 2. Stats Summary Row ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: _buildPremiumCard(
                    theme,
                    isDark,
                    child: Row(
                      children: [
                        _StatColumn(
                          value: weight != null
                              ? UnitConvert.weightStr(weight, unitSystem,
                                  decimals: 1)
                              : '--',
                          label: 'CURRENT',
                        ),
                        _verticalDivider(isDark),
                        _StatColumn(
                          value: profile.computedTargetWeight != null
                              ? UnitConvert.weightStr(
                                  profile.computedTargetWeight!, unitSystem,
                                  decimals: 1)
                              : '--',
                          label: 'TARGET',
                        ),
                        _verticalDivider(isDark),
                        _StatColumn(
                          value: '$calorieTarget',
                          label: 'KCAL/DAY',
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
              ),

              // ── Training Stats Row ──────────────────────────────────────
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                    child: _buildPremiumCard(
                      theme,
                      isDark,
                      child: Row(
                        children: [
                          _StatColumn(
                            value: '${stats.totalWorkouts}',
                            label: 'WORKOUTS',
                          ),
                          _verticalDivider(isDark),
                          _StatColumn(
                            value: '${stats.trainingStreak}',
                            label: 'STREAK',
                          ),
                          _verticalDivider(isDark),
                          _StatColumn(
                            value: '${stats.daysSinceStarted}',
                            label: 'DAYS',
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              // ── 3. Daily Targets Card ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: _buildPremiumCard(
                    theme,
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Targets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _MacroRow(
                          color: AppColors.primaryBlue,
                          label: 'Protein',
                          value: '${proteinTarget}g',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MacroRow(
                          color: AppColors.accent,
                          label: 'Carbs',
                          value: '${carbsTarget}g',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MacroRow(
                          color: AppColors.warning,
                          label: 'Fats',
                          value: '${fatsTarget}g',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.dividerLight,
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.dividerLight,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.8, 1.0],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue
                                        .withValues(alpha: 0.1),
                                    AppColors.accent
                                        .withValues(alpha: 0.06),
                                  ],
                                ),
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue,
                                    AppColors.accent,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  '$calorieTarget kcal',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
              ),

              // ── 4. Settings Section ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0),
                  child: _buildSettingsGroup(
                    theme,
                    isDark,
                    title: 'Settings',
                    items: [
                      _SettingItem(
                        icon: ref.watch(themeModeProvider) == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: AppColors.muscleArms,
                        title: 'Theme',
                        trailing: _SettingBadge(
                          label: isDark ? 'Dark' : 'Light',
                          isDark: isDark,
                        ),
                        onTap: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .toggleDarkMode();
                        },
                      ),
                      _SettingItem(
                        icon: Icons.straighten_rounded,
                        iconColor: AppColors.info,
                        title: 'Measurement System',
                        trailing: _SettingBadge(
                          label: unitSystem == MeasurementSystem.metric
                              ? 'Metric'
                              : 'Imperial',
                          isDark: isDark,
                        ),
                        onTap: () {
                          ref
                              .read(measurementSystemProvider.notifier)
                              .toggle();
                        },
                      ),
                      _SettingItem(
                        icon: Icons.language_rounded,
                        iconColor: AppColors.accent,
                        title: 'Language',
                        trailing: _SettingBadge(
                          label: ref.watch(appLanguageProvider).displayName,
                          isDark: isDark,
                        ),
                        onTap: () =>
                            _showLanguagePicker(context, ref, isDark),
                      ),
                      _SettingItem(
                        icon: Icons.notifications_outlined,
                        iconColor: AppColors.warning,
                        title: 'Notifications',
                        onTap: () => context.push('/reminders'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
              ),

              // ── 5. App Info ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '${AppConstants.appName} v${AppConstants.appVersion}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        GestureDetector(
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: AppConstants.appName,
                              applicationVersion: AppConstants.appVersion,
                            );
                          },
                          child: Text(
                            'About',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms),
              ),

              // ── 6. Sign Out Button ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ─────────────────────────── Premium card wrapper ───────────────────────
  Widget _buildPremiumCard(
    ThemeData theme,
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.0),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: child,
    );
  }

  // ─────────────────────────── Settings group ────────────────────────────
  Widget _buildSettingsGroup(
    ThemeData theme,
    bool isDark, {
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.08)
                  : AppColors.dividerLight,
            ),
            boxShadow: [
              ...(isDark
                  ? AppColors.cardShadowDark
                  : AppColors.cardShadowLight),
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.03),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildSettingTile(theme, isDark, items[i]),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.dividerLight,
                            Colors.transparent,
                          ],
                        ),
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

  Widget _buildSettingTile(
    ThemeData theme,
    bool isDark,
    _SettingItem item,
  ) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.iconColor.withValues(alpha: 0.15),
                    item.iconColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: item.iconColor.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.trailing != null) ...[
              item.trailing!,
              const SizedBox(width: AppSpacing.xs),
            ],
            if (item.onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: AppSpacing.xxxl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.dividerLight,
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (SupabaseConfig.isConfigured) {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          context.go('/auth');
        }
      } else {
        if (context.mounted) {
          context.go('/onboarding');
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final Color color;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.onSurface,
                theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ],
            ).createShader(bounds),
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingBadge extends StatelessWidget {
  const _SettingBadge({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onTap,
    this.trailing,
  });
}

// ─────────────────────────── Language Picker ──────────────────────────────

void _showLanguagePicker(BuildContext context, WidgetRef ref, bool isDark) {
  final theme = Theme.of(context);
  final current = ref.read(appLanguageProvider);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Select Language',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...AppLanguage.values.map((lang) {
              final isSelected = lang == current;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(appLanguageProvider.notifier).setLanguage(lang);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color:
                              isSelected ? AppColors.primaryBlue : null,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(
              height:
                  MediaQuery.of(ctx).padding.bottom + AppSpacing.sm,
            ),
          ],
        ),
      );
    },
  );
}
