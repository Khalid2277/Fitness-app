import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';
import 'package:alfanutrition/features/progress/widgets/weight_chart.dart';
import 'package:alfanutrition/features/progress/widgets/stats_overview.dart';
import 'package:alfanutrition/features/progress/widgets/body_metric_card.dart';

/// Progress tracking screen — premium data dashboard with three tabs.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Overview', 'Records', 'Stats'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // -- Header --
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GradientIconButton(
                      icon: Icons.camera_alt_rounded,
                      onTap: () => context.push('/progress-photos'),
                      tooltip: 'Progress Photos',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // -- Segmented control --
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _SegmentedControl(
                  tabs: _tabs,
                  selectedIndex: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // -- Tab content --
            _buildTabContent(),
          ],
        ),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusPill,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/add-body-metric'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildRecordsTab();
      case 2:
        return _buildStatsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 1: Overview
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weightAsync = ref.watch(weightHistoryProvider);
    final metricsAsync = ref.watch(bodyMetricsProvider);
    final latestAsync = ref.watch(latestMetricProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // ── Weight Trend Card ──
          _buildWeightHeroCard(theme, isDark, latestAsync, weightAsync),
          const SizedBox(height: AppSpacing.lg),

          // ── Weight Chart ──
          weightAsync.when(
            data: (data) => WeightChart(dataPoints: data),
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Body Metrics Grid ──
          _buildBodyMetricsSection(theme, isDark, latestAsync, metricsAsync),
          const SizedBox(height: AppSpacing.xl),

          // ── Log Measurement CTA ──
          _buildLogMeasurementCta(theme, isDark),
          const SizedBox(height: AppSpacing.lg),

          // ── Progress Photos CTA ──
          _buildProgressPhotosCta(theme, isDark),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildWeightHeroCard(
    ThemeData theme,
    bool isDark,
    AsyncValue<dynamic> latestAsync,
    AsyncValue<List<WeightDataPoint>> weightAsync,
  ) {
    return latestAsync.when(
      data: (metric) {
        // Fall back to profile weight if no body metrics logged yet
        final profileWeight = ref.watch(userProfileProvider).valueOrNull?.weight;
        final weight = metric?.weight ?? profileWeight;
        final weightData = weightAsync.valueOrNull ?? [];
        String changeText = '';
        Color changeColor = isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight;
        IconData changeIcon = Icons.remove_rounded;

        if (weightData.length >= 2) {
          final recent = weightData.last.weight;
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          final oldPoint = weightData.lastWhere(
            (p) => p.date.isBefore(weekAgo),
            orElse: () => weightData.first,
          );
          final diff = recent - oldPoint.weight;
          if (diff.abs() > 0.05) {
            final sign = diff > 0 ? '+' : '';
            changeText = '$sign${diff.toStringAsFixed(1)} kg this week';
            changeColor = diff > 0 ? AppColors.error : AppColors.success;
            changeIcon = diff > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkCardGradient
                : AppColors.lightCardGradient,
            borderRadius: AppSpacing.borderRadiusXl,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
            boxShadow: isDark
                ? AppColors.cardShadowDark
                : AppColors.cardShadowLight,
          ),
          child: Row(
            children: [
              // Left: weight value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT WEIGHT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weight != null
                              ? weight.toStringAsFixed(1)
                              : '--.-',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'kg',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (changeText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: changeColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(changeIcon, size: 14, color: changeColor),
                            const SizedBox(width: 4),
                            Text(
                              changeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: changeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Right: mini sparkline bars
              _buildMiniSparkline(weightAsync, isDark),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniSparkline(
    AsyncValue<List<WeightDataPoint>> weightAsync,
    bool isDark,
  ) {
    return weightAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox(width: 80);
        final recent =
            data.length > 7 ? data.sublist(data.length - 7) : data;
        final maxW =
            recent.map((d) => d.weight).reduce((a, b) => a > b ? a : b);
        final minW =
            recent.map((d) => d.weight).reduce((a, b) => a < b ? a : b);
        final range = maxW - minW;

        return SizedBox(
          width: 80,
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recent.asMap().entries.map((entry) {
              final isLast = entry.key == recent.length - 1;
              final normalized = range > 0
                  ? ((entry.value.weight - minW) / range).clamp(0.2, 1.0)
                  : 0.6;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 56 * normalized,
                    decoration: BoxDecoration(
                      gradient: isLast
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryBlue,
                                AppColors.primaryBlueLight,
                              ],
                            )
                          : null,
                      color: isLast
                          ? null
                          : AppColors.primaryBlue
                              .withValues(alpha: isDark ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox(width: 80),
      error: (_, _) => const SizedBox(width: 80),
    );
  }

  Widget _buildBodyMetricsSection(
    ThemeData theme,
    bool isDark,
    AsyncValue<dynamic> latestAsync,
    AsyncValue<List<dynamic>> metricsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'BODY COMPOSITION',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/add-body-metric'),
              child: Text(
                'Update',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 2x2 grid of metric summary cards
        latestAsync.when(
          data: (metric) {
            if (metric == null) {
              return _buildEmptyMetricsState(theme, isDark);
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricSummaryCard(
                        label: 'Weight',
                        value: metric.weight != null
                            ? metric.weight!.toStringAsFixed(1)
                            : '--',
                        unit: 'kg',
                        icon: Icons.monitor_weight_rounded,
                        iconColor: AppColors.primaryBlue,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricSummaryCard(
                        label: 'Body Fat',
                        value: metric.bodyFatPercentage != null
                            ? metric.bodyFatPercentage!.toStringAsFixed(1)
                            : '--',
                        unit: '%',
                        icon: Icons.water_drop_rounded,
                        iconColor: AppColors.accent,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _MetricSummaryCard(
                        label: 'Waist',
                        value: metric.waist != null
                            ? metric.waist!.toStringAsFixed(1)
                            : '--',
                        unit: 'cm',
                        icon: Icons.straighten_rounded,
                        iconColor: AppColors.warning,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricSummaryCard(
                        label: 'Chest',
                        value: metric.chest != null
                            ? metric.chest!.toStringAsFixed(1)
                            : '--',
                        unit: 'cm',
                        icon: Icons.accessibility_new_rounded,
                        iconColor: AppColors.muscleChest,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.05),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SizedBox.shrink(),
        ),

        // Full metric history below the grid
        const SizedBox(height: AppSpacing.xl),
        metricsAsync.when(
          data: (metrics) {
            if (metrics.isEmpty) return const SizedBox.shrink();
            // Show latest 3 entries as detailed cards
            final showMetrics = metrics.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT ENTRIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (int i = 0; i < showMetrics.length; i++) ...[
                  BodyMetricCard(
                    metric: showMetrics[i],
                    previousMetric:
                        i + 1 < metrics.length ? metrics[i + 1] : null,
                  )
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: (80 * i + 300).ms,
                        curve: Curves.easeOut,
                      ),
                  if (i < showMetrics.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEmptyMetricsState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: const Icon(
                Icons.straighten_rounded,
                size: 28,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No measurements yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Log your first body metric to start tracking',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogMeasurementCta(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/add-body-metric'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
              AppColors.primaryBlueLight
                  .withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.add_chart_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Measurement',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Record weight, body fat & measurements',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildProgressPhotosCta(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/progress-photos'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.06),
              AppColors.accentLight.withValues(alpha: isDark ? 0.06 : 0.03),
            ],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Photos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track visible body changes over time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.05);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 2: Records
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRecordsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prAsync = ref.watch(personalRecordsProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // PR count header
          prAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusXl,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 32,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No records yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Complete workouts to set personal records',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary row
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          AppColors.warning
                              .withValues(alpha: isDark ? 0.04 : 0.02),
                        ],
                      ),
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color:
                            AppColors.warning.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.15),
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.warning,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${records.length} Personal Records',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Heaviest lift: ${records.first.weight.toStringAsFixed(1)} kg',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
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
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'ALL RECORDS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Individual PR cards
                  ...records.asMap().entries.map((entry) {
                    final i = entry.key;
                    final pr = entry.value;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PRCard(
                        record: pr,
                        rank: i + 1,
                        isDark: isDark,
                        theme: theme,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: (60 * i + 100).ms,
                          curve: Curves.easeOut,
                        )
                        .slideX(begin: 0.03);
                  }),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 3: Stats
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(trainingStatsProvider);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          statsAsync.when(
            data: (stats) {
              if (stats.totalWorkouts == 0) {
                return _buildEmptyStatsState(theme, isDark);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Stats Row ──
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStatCard(
                          value: '${stats.totalWorkouts}',
                          label: 'Total\nWorkouts',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.primaryBlue,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _HeroStatCard(
                          value: '${stats.trainingStreak}',
                          label: 'Day\nStreak',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.warning,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _HeroStatCard(
                          value: '${stats.averageDurationMinutes}',
                          label: 'Avg Min\nPer Session',
                          icon: Icons.timer_rounded,
                          color: AppColors.accent,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Training Volume ──
                  _buildVolumeCard(stats, theme, isDark),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Full Stats Grid ──
                  StatsOverview(stats: stats),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildVolumeCard(
      TrainingStats stats, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkCardGradient
            : AppColors.lightCardGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'TOTAL VOLUME',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatVolume(stats.totalVolume),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kg lifted',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Most trained: ${stats.mostTrainedMuscle}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05);
  }

  Widget _buildEmptyStatsState(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusXl,
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 32,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No stats yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete your first workout to see training stats',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Gradient Icon Button (header action)
// ───────────────────────────────────────────────────────────────────────────

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _GradientIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceLight2,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.dividerLight,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Segmented Control
// ───────────────────────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceLight2,
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.surfaceDark3
                          : AppColors.surfaceLight)
                      : Colors.transparent,
                  borderRadius: AppSpacing.borderRadiusPill,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Metric Summary Card (2x2 grid item)
// ───────────────────────────────────────────────────────────────────────────

class _MetricSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final ThemeData theme;

  const _MetricSummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// PR Card (Records tab)
// ───────────────────────────────────────────────────────────────────────────

class _PRCard extends StatelessWidget {
  final PersonalRecord record;
  final int rank;
  final bool isDark;
  final ThemeData theme;

  const _PRCard({
    required this.record,
    required this.rank,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isTop3
              ? AppColors.warning.withValues(alpha: 0.2)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTop3
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.surfaceLight2,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            alignment: Alignment.center,
            child: isTop3
                ? const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 18,
                  )
                : Text(
                    '#$rank',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(record.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Weight & reps
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.weight.toStringAsFixed(1)} kg',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                '${record.reps} rep${record.reps != 1 ? 's' : ''}',
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
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Hero Stat Card (Stats tab top row)
// ───────────────────────────────────────────────────────────────────────────

class _HeroStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _HeroStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontWeight: FontWeight.w500,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
