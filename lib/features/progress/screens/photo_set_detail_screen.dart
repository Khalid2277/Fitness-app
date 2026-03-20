import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/body_analysis.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/features/progress/providers/body_analysis_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_photo_providers.dart';

/// Detail view for a single progress photo set, displaying all 4 angles.
class PhotoSetDetailScreen extends ConsumerWidget {
  const PhotoSetDetailScreen({super.key, required this.photoSetId});

  final String photoSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allPhotosAsync = ref.watch(allProgressPhotosProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: allPhotosAsync.when(
          data: (all) {
            final photoSet = all.cast<ProgressPhotoSet?>().firstWhere(
                  (s) => s?.id == photoSetId,
                  orElse: () => null,
                );
            if (photoSet == null) {
              return const Center(child: Text('Photo set not found.'));
            }
            return _buildContent(context, ref, theme, isDark, photoSet);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Could not load photos.')),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    ProgressPhotoSet photoSet,
  ) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
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
                    // Delete action
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref, photoSet),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.08),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Date + completion
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(photoSet.date).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            DateFormat('MMMM d, yyyy').format(photoSet.date),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCompletionBadge(theme, isDark, photoSet),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Stats row ───────────────────────────────────────────────────
        if (photoSet.weight != null || photoSet.bodyFatPercentage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Row(
                children: [
                  if (photoSet.weight != null)
                    Expanded(
                      child: _StatTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                        value: '${photoSet.weight!.toStringAsFixed(1)} kg',
                        color: AppColors.primaryBlue,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                  if (photoSet.weight != null &&
                      photoSet.bodyFatPercentage != null)
                    const SizedBox(width: AppSpacing.md),
                  if (photoSet.bodyFatPercentage != null)
                    Expanded(
                      child: _StatTile(
                        icon: Icons.percent_rounded,
                        label: 'Body Fat',
                        value:
                            '${photoSet.bodyFatPercentage!.toStringAsFixed(1)}%',
                        color: AppColors.accent,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.05),
            ),
          ),

        if (photoSet.weight != null || photoSet.bodyFatPercentage != null)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Photo grid (2x2) ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
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
                      'PHOTOS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${photoSet.completedAngleCount} of 4 angles',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildPhotoGrid(theme, isDark, photoSet),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Notes ───────────────────────────────────────────────────────
        if (photoSet.notes != null && photoSet.notes!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Notes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      photoSet.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.05),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

        // ── Analyze Progress button (gradient CTA) ─────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: _AnalyzeButton(photoSet: photoSet),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.05),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Compare Side-by-Side button (outlined) ─────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/body-analysis/${photoSet.id}?compare=true'),
                icon: const Icon(Icons.compare_rounded, size: 20),
                label: const Text('Compare Side-by-Side'),
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
                .fadeIn(duration: 400.ms, delay: 500.ms)
                .slideY(begin: 0.05),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxxl)),
      ],
    );
  }

  // ─────────────────────────── Photo grid ───────────────────────────────────

  Widget _buildPhotoGrid(
      ThemeData theme, bool isDark, ProgressPhotoSet photoSet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PhotoTile(
                angle: PhotoAngle.front,
                path: photoSet.photoPathFor(PhotoAngle.front),
                theme: theme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PhotoTile(
                angle: PhotoAngle.leftSide,
                path: photoSet.photoPathFor(PhotoAngle.leftSide),
                theme: theme,
                isDark: isDark,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideY(begin: 0.05),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _PhotoTile(
                angle: PhotoAngle.rightSide,
                path: photoSet.photoPathFor(PhotoAngle.rightSide),
                theme: theme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PhotoTile(
                angle: PhotoAngle.back,
                path: photoSet.photoPathFor(PhotoAngle.back),
                theme: theme,
                isDark: isDark,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 250.ms)
            .slideY(begin: 0.05),
      ],
    );
  }

  // ─────────────────────────── Completion badge ─────────────────────────────

  Widget _buildCompletionBadge(
      ThemeData theme, bool isDark, ProgressPhotoSet photoSet) {
    final isComplete = photoSet.isComplete;
    final count = photoSet.completedAngleCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1)
            : (isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isComplete
              ? AppColors.accent.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isComplete)
            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accent),
          if (isComplete) const SizedBox(width: AppSpacing.sm),
          Text(
            isComplete ? 'Complete' : '$count of 4 angles',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isComplete
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

  // ─────────────────────────── Delete ───────────────────────────────────────

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProgressPhotoSet photoSet,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Delete photo set?'),
          ],
        ),
        content: const Text(
          'This will permanently remove these progress photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final repo = ref.read(progressPhotoRepositoryProvider);
                await repo.deletePhotoSet(photoSet.id);

                // Delete photo files from disk
                for (final path in photoSet.photos.values) {
                  final file = File(path);
                  if (file.existsSync()) {
                    try {
                      file.deleteSync();
                    } catch (_) {
                      // Best effort cleanup
                    }
                  }
                }

                ref.invalidate(allProgressPhotosProvider);
                ref.invalidate(latestProgressPhotoProvider);
                if (context.mounted) {
                  context.pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Tile (single angle in the 2x2 grid)
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.angle,
    required this.path,
    required this.theme,
    required this.isDark,
  });

  final PhotoAngle angle;
  final String? path;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: hasPhoto
              ? AppColors.accent.withValues(alpha: 0.2)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null) _buildImage(path!) else _buildEmpty(),
            // Angle label at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: path != null
                        ? [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ]
                        : [
                            (isDark
                                    ? AppColors.surfaceDark1
                                    : AppColors.surfaceLight1)
                                .withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                  ),
                ),
                child: Text(
                  angle.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: path != null
                        ? Colors.white
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                  ),
                ),
              ),
            ),
            // Check badge for captured
            if (hasPhoto)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _buildEmpty();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 22,
              color: isDark
                  ? AppColors.textDisabledDark
                  : AppColors.textDisabledLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not taken',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textDisabledDark
                  : AppColors.textDisabledLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Tile
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
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
          color: color.withValues(alpha: 0.15),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analyze Button (gradient CTA that checks for existing analysis)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyzeButton extends ConsumerStatefulWidget {
  const _AnalyzeButton({required this.photoSet});

  final ProgressPhotoSet photoSet;

  @override
  ConsumerState<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends ConsumerState<_AnalyzeButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final analysisAsync =
        ref.watch(photoSetAnalysisProvider(widget.photoSet.id));

    return analysisAsync.when(
      data: (existing) => _buildButton(context, existing),
      loading: () => _buildButton(context, null, forceLoading: true),
      error: (_, _) => _buildButton(context, null),
    );
  }

  Widget _buildButton(
    BuildContext context,
    BodyAnalysis? existing, {
    bool forceLoading = false,
  }) {
    final theme = Theme.of(context);
    final hasAnalysis = existing != null;
    final loading = _isLoading || forceLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: loading
              ? null
              : () async {
                  if (hasAnalysis) {
                    context.push('/body-analysis/${widget.photoSet.id}');
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    final allPhotos =
                        await ref.read(allProgressPhotosProvider.future);
                    final currentIndex = allPhotos.indexWhere(
                      (s) => s.id == widget.photoSet.id,
                    );

                    ProgressPhotoSet? previous;
                    if (currentIndex >= 0 &&
                        currentIndex < allPhotos.length - 1) {
                      previous = allPhotos[currentIndex + 1];
                    }

                    final service = ref.read(bodyAnalysisServiceProvider);
                    final result = await service.analyze(
                      current: widget.photoSet,
                      previous: previous,
                    );

                    final repo = ref.read(bodyAnalysisRepositoryProvider);
                    await repo.save(result);
                    ref.invalidate(
                        photoSetAnalysisProvider(widget.photoSet.id));

                    if (context.mounted) {
                      context.push('/body-analysis/${widget.photoSet.id}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Analysis failed: $e'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          icon: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                )
              : Icon(
                  hasAnalysis
                      ? Icons.analytics_rounded
                      : Icons.psychology_rounded,
                  size: 20,
                ),
          label: Text(
            hasAnalysis ? 'View Analysis' : 'Analyze Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusLg,
            ),
          ),
        ),
      ),
    );
  }
}
