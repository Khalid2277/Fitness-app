import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/body_analysis.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/features/progress/providers/body_analysis_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_photo_providers.dart';

/// Displays the results of an AI-powered body progress analysis.
class BodyAnalysisScreen extends ConsumerStatefulWidget {
  const BodyAnalysisScreen({super.key, required this.photoSetId});

  final String photoSetId;

  @override
  ConsumerState<BodyAnalysisScreen> createState() =>
      _BodyAnalysisScreenState();
}

class _BodyAnalysisScreenState extends ConsumerState<BodyAnalysisScreen> {
  bool _isAnalyzing = false;
  BodyAnalysis? _analysis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrRunAnalysis();
  }

  Future<void> _loadOrRunAnalysis() async {
    try {
      final repo = ref.read(bodyAnalysisRepositoryProvider);
      final existing = await repo.getForPhotoSet(widget.photoSetId);
      if (existing != null) {
        setState(() => _analysis = existing);
        return;
      }
      await _runAnalysis();
    } catch (e) {
      setState(() => _error = 'Failed to load analysis: $e');
    }
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final allPhotos = await ref.read(allProgressPhotosProvider.future);
      final current = allPhotos.cast<ProgressPhotoSet?>().firstWhere(
            (s) => s?.id == widget.photoSetId,
            orElse: () => null,
          );

      if (current == null) {
        setState(() {
          _error = 'Photo set not found.';
          _isAnalyzing = false;
        });
        return;
      }

      // Find previous photo set for comparison
      ProgressPhotoSet? previous;
      final currentIndex = allPhotos.indexOf(current);
      if (currentIndex < allPhotos.length - 1) {
        previous = allPhotos[currentIndex + 1];
      }

      final service = ref.read(bodyAnalysisServiceProvider);
      final result = await service.analyze(
        current: current,
        previous: previous,
      );

      // Cache the result
      final repo = ref.read(bodyAnalysisRepositoryProvider);
      await repo.save(result);
      ref.invalidate(photoSetAnalysisProvider(widget.photoSetId));

      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: _isAnalyzing
            ? _buildLoadingState(theme, isDark)
            : _error != null
                ? _buildErrorState(theme, isDark)
                : _analysis != null
                    ? _buildResultsContent(theme, isDark, _analysis!)
                    : _buildLoadingState(theme, isDark),
      ),
    );
  }

  // ─────────────────────── Loading State ──────────────────────────────────────

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated brain icon with gradient ring
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 48,
                color: Colors.white,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.08, 1.08),
                  end: const Offset(1, 1),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: AppSpacing.xxxl),

            Text(
              'Analyzing your progress...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Examining photos and metrics to generate insights.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Shimmer loading bars
            ..._buildShimmerBars(theme, isDark),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShimmerBars(ThemeData theme, bool isDark) {
    return List.generate(3, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          height: 12,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 40.0 + (index * 20)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
            borderRadius: AppSpacing.borderRadiusPill,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1500.ms,
              delay: (index * 200).ms,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
            ),
      );
    });
  }

  // ─────────────────────── Error State ────────────────────────────────────────

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.1),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Analysis Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppSpacing.borderRadiusLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _runAnalysis,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Results Content ────────────────────────────────────

  Widget _buildResultsContent(
    ThemeData theme,
    bool isDark,
    BodyAnalysis analysis,
  ) {
    final allPhotosAsync = ref.watch(allProgressPhotosProvider);

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
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
                    _buildMethodBadge(theme, isDark, analysis.analysisMethod),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'ANALYSIS RESULTS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Body Analysis',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('MMMM d, yyyy \u2022 h:mm a')
                      .format(analysis.analyzedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Confidence Score ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: _ConfidenceCard(
              score: analysis.confidenceScore,
              theme: theme,
              isDark: isDark,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.05),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        // ── Summary Card ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: _SummaryCard(
              summary: analysis.summary,
              theme: theme,
              isDark: isDark,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.05),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Data Metrics ────────────────────────────────────────────────
        if (analysis.dataMetrics.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: _buildSectionLabel(theme, isDark, 'DATA METRICS'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: _DataMetricsRow(
                metrics: analysis.dataMetrics,
                theme: theme,
                isDark: isDark,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms)
                .slideY(begin: 0.05),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],

        // ── Insights Section ────────────────────────────────────────────
        if (analysis.insights.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: _buildSectionLabel(theme, isDark, 'INSIGHTS'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    index < analysis.insights.length - 1
                        ? AppSpacing.md
                        : 0,
                  ),
                  child: _InsightCard(
                    insight: analysis.insights[index],
                    index: index,
                    theme: theme,
                    isDark: isDark,
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: 400.ms,
                      delay: (300 + index * 80).ms,
                    )
                    .slideY(begin: 0.05);
              },
              childCount: analysis.insights.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],

        // ── Comparison Photos ───────────────────────────────────────────
        if (analysis.comparedToSetId != null)
          allPhotosAsync.when(
            data: (allSets) {
              final currentSet = allSets.cast<ProgressPhotoSet?>().firstWhere(
                    (s) => s?.id == analysis.photoSetId,
                    orElse: () => null,
                  );
              final previousSet = allSets.cast<ProgressPhotoSet?>().firstWhere(
                    (s) => s?.id == analysis.comparedToSetId,
                    orElse: () => null,
                  );
              if (currentSet == null || previousSet == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: _ComparisonSection(
                  currentSet: currentSet,
                  previousSet: previousSet,
                  theme: theme,
                  isDark: isDark,
                ),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

        // ── Recommendations ─────────────────────────────────────────────
        if (analysis.recommendations.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: _buildSectionLabel(theme, isDark, 'RECOMMENDATIONS'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: _RecommendationsCard(
                recommendations: analysis.recommendations,
                theme: theme,
                isDark: isDark,
              ),
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: (300 + analysis.insights.length * 80 + 100).ms,
                )
                .slideY(begin: 0.05),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],

        // ── Re-analyze button ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Delete old analysis and re-run
                  final repo = ref.read(bodyAnalysisRepositoryProvider);
                  await repo.delete(analysis.id);
                  ref.invalidate(photoSetAnalysisProvider(widget.photoSetId));
                  setState(() => _analysis = null);
                  await _runAnalysis();
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Re-analyze'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms)
                .slideY(begin: 0.05),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxxl)),
      ],
    );
  }

  // ─────────────────────── Helpers ────────────────────────────────────────────

  Widget _buildMethodBadge(ThemeData theme, bool isDark, String method) {
    final (label, color, icon) = switch (method) {
      'ai_vision' => ('AI Vision', AppColors.primaryBlue, Icons.visibility_rounded),
      'combined' => ('Combined', AppColors.primaryBlueLight, Icons.auto_awesome_rounded),
      _ => ('Data Analysis', AppColors.accent, Icons.analytics_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, bool isDark, String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusPill,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Confidence Card
// =============================================================================

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({
    required this.score,
    required this.theme,
    required this.isDark,
  });

  final double score;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = score >= 0.7
        ? AppColors.success
        : score >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? AppColors.cardShadowDark
            : AppColors.cardShadowLight,
      ),
      child: Row(
        children: [
          // Circular score indicator
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: score,
                    strokeWidth: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      '%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xl),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Confidence Score',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  score >= 0.7
                      ? 'High confidence. Multiple data points support these insights.'
                      : score >= 0.4
                          ? 'Moderate confidence. More data would improve accuracy.'
                          : 'Low confidence. Add more photos or metrics for better results.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
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

// =============================================================================
// Summary Card
// =============================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.theme,
    required this.isDark,
  });

  final String summary;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueSurface.withValues(alpha: 0.5),
                  AppColors.surfaceDark1,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                  AppColors.surfaceLight,
                ],
              ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Data Metrics Row
// =============================================================================

class _DataMetricsRow extends StatelessWidget {
  const _DataMetricsRow({
    required this.metrics,
    required this.theme,
    required this.isDark,
  });

  final Map<String, dynamic> metrics;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    if (metrics.containsKey('weightChange')) {
      final change = metrics['weightChange'] as double;
      tiles.add(Expanded(
        child: _MetricTile(
          icon: Icons.monitor_weight_outlined,
          label: 'Weight',
          value: '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
          valueColor: change < 0 ? AppColors.success : change > 0 ? AppColors.warning : null,
          theme: theme,
          isDark: isDark,
        ),
      ));
    }

    if (metrics.containsKey('bfChange')) {
      final change = metrics['bfChange'] as double;
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: AppSpacing.md));
      tiles.add(Expanded(
        child: _MetricTile(
          icon: Icons.percent_rounded,
          label: 'Body Fat',
          value: '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
          valueColor: change < 0 ? AppColors.success : change > 0 ? AppColors.error : null,
          theme: theme,
          isDark: isDark,
        ),
      ));
    }

    if (metrics.containsKey('daysBetween')) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: AppSpacing.md));
      tiles.add(Expanded(
        child: _MetricTile(
          icon: Icons.calendar_today_rounded,
          label: 'Period',
          value: '${metrics['daysBetween']}d',
          theme: theme,
          isDark: isDark,
        ),
      ));
    }

    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(children: tiles);
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.theme,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: valueColor != null
              ? valueColor!.withValues(alpha: 0.2)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (valueColor ?? AppColors.primaryBlue)
                  .withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: 14,
              color: valueColor ?? (isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Insight Card
// =============================================================================

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.index,
    required this.theme,
    required this.isDark,
  });

  final AnalysisInsight insight;
  final int index;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (sentimentColor, sentimentIcon) = switch (insight.sentiment) {
      'positive' => (AppColors.success, Icons.trending_up_rounded),
      'negative' => (AppColors.error, Icons.trending_down_rounded),
      _ => (AppColors.warning, Icons.trending_flat_rounded),
    };

    final categoryIcon = switch (insight.category) {
      'muscle' => Icons.fitness_center_rounded,
      'fat_loss' => Icons.local_fire_department_rounded,
      'posture' => Icons.accessibility_new_rounded,
      _ => Icons.analytics_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: sentimentColor.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: category icon + title + sentiment
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(categoryIcon, size: 20, color: sentimentColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      insight.category.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: sentimentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sentimentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
                child: Icon(sentimentIcon, size: 18, color: sentimentColor),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            insight.description,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),

          // Change score bar
          if (insight.changeScore != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ChangeScoreBar(
              score: insight.changeScore!,
              theme: theme,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Change Score Bar (-1 to +1)
// =============================================================================

class _ChangeScoreBar extends StatelessWidget {
  const _ChangeScoreBar({
    required this.score,
    required this.theme,
    required this.isDark,
  });

  final double score;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Normalize score from [-1,1] to [0,1] for display
    final normalized = (score + 1.0) / 2.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (score > 0
                          ? AppColors.success
                          : score < 0
                              ? AppColors.error
                              : AppColors.warning)
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  score > 0
                      ? '+${(score * 100).round()}%'
                      : '${(score * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: score > 0
                        ? AppColors.success
                        : score < 0
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 6,
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusPill,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    color: isDark
                        ? AppColors.surfaceDark2
                        : AppColors.surfaceLight2,
                  ),
                  // Center line
                  Positioned(
                    left: 0,
                    right: 0,
                    child: FractionallySizedBox(
                      widthFactor: 1.0,
                      child: Center(
                        child: Container(
                          width: 1,
                          height: 6,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  // Score indicator
                  LayoutBuilder(builder: (context, constraints) {
                    final center = constraints.maxWidth / 2;
                    final pos = normalized * constraints.maxWidth;
                    final left = math.min(center, pos);
                    final width = (pos - center).abs();

                    return Positioned(
                      left: left,
                      child: Container(
                        width: width,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: score > 0
                                ? [AppColors.success.withValues(alpha: 0.5), AppColors.success]
                                : score < 0
                                    ? [AppColors.error, AppColors.error.withValues(alpha: 0.5)]
                                    : [AppColors.warning, AppColors.warning],
                          ),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Recommendations Card
// =============================================================================

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({
    required this.recommendations,
    required this.theme,
    required this.isDark,
  });

  final List<String> recommendations;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < recommendations.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.accentLight,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      recommendations[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (i < recommendations.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(
                  height: 1,
                  indent: 44,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.dividerLight,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Comparison Section (before/after photos with slider)
// =============================================================================

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.currentSet,
    required this.previousSet,
    required this.theme,
    required this.isDark,
  });

  final ProgressPhotoSet currentSet;
  final ProgressPhotoSet previousSet;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Find angles that both sets have in common
    final commonAngles = PhotoAngle.values.where((angle) {
      return currentSet.photoPathFor(angle) != null &&
          previousSet.photoPathFor(angle) != null;
    }).toList();

    if (commonAngles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'BEFORE & AFTER',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: AppSpacing.borderRadiusPill,
            ),
            child: Text(
              '${DateFormat('MMM d').format(previousSet.date)} vs ${DateFormat('MMM d, yyyy').format(currentSet.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...commonAngles.map((angle) => Padding(
                padding: EdgeInsets.only(
                  bottom: angle != commonAngles.last ? AppSpacing.lg : 0,
                ),
                child: _BeforeAfterSlider(
                  angle: angle,
                  beforePath: previousSet.photoPathFor(angle)!,
                  afterPath: currentSet.photoPathFor(angle)!,
                  theme: theme,
                  isDark: isDark,
                ),
              )),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .slideY(begin: 0.05);
  }
}

// =============================================================================
// Before/After Slider for a single angle
// =============================================================================

class _BeforeAfterSlider extends StatefulWidget {
  const _BeforeAfterSlider({
    required this.angle,
    required this.beforePath,
    required this.afterPath,
    required this.theme,
    required this.isDark,
  });

  final PhotoAngle angle;
  final String beforePath;
  final String afterPath;
  final ThemeData theme;
  final bool isDark;

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Angle label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: widget.isDark ? 0.12 : 0.08),
            borderRadius: AppSpacing.borderRadiusPill,
          ),
          child: Text(
            widget.angle.displayName,
            style: widget.theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Slider comparison
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusMd,
          child: SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderValue = (details.localPosition.dx / width)
                          .clamp(0.0, 1.0);
                    });
                  },
                  onTapDown: (details) {
                    setState(() {
                      _sliderValue = (details.localPosition.dx / width)
                          .clamp(0.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      // After (current) image — full width background
                      Positioned.fill(
                        child: _buildPhoto(widget.afterPath),
                      ),
                      // Before (previous) image — clipped by slider
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _SliderClipper(_sliderValue),
                          child: _buildPhoto(widget.beforePath),
                        ),
                      ),
                      // Slider line
                      Positioned(
                        left: width * _sliderValue - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Slider handle
                      Positioned(
                        left: width * _sliderValue - 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 20,
                              color: AppColors.primaryBlue.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      // Before label
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: _buildPhotoLabel('Before'),
                      ),
                      // After label
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: _buildPhotoLabel('After'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoto(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: widget.isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          size: 40,
          color: widget.isDark
              ? AppColors.textDisabledDark
              : AppColors.textDisabledLight,
        ),
      ),
    );
  }

  Widget _buildPhotoLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        label,
        style: widget.theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Custom clipper that reveals only the left portion of the widget.
class _SliderClipper extends CustomClipper<Rect> {
  _SliderClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _SliderClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
