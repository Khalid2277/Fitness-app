import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/core/widgets/empty_state.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/features/progress/providers/progress_photo_providers.dart';

/// Displays the user's progress photo timeline.
class ProgressPhotosScreen extends ConsumerWidget {
  const ProgressPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photosAsync = ref.watch(allProgressPhotosProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: photosAsync.when(
          data: (photoSets) => _buildContent(
            context,
            theme,
            isDark,
            photoSets,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Something went wrong loading your photos.'),
          ),
        ),
      ),
      floatingActionButton: photosAsync.valueOrNull?.isNotEmpty == true
          ? DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/capture-progress-photo'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.camera_alt_rounded, size: 20),
          label: Text(
            'New Session',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<ProgressPhotoSet> photoSets,
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
                    if (photoSets.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          '${photoSets.length} ${photoSets.length == 1 ? 'session' : 'sessions'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'PROGRESS PHOTOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Body Transformation',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Track visible changes over time with consistent photos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

        // ── Content ─────────────────────────────────────────────────────
        if (photoSets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.photo_library_rounded,
              title: 'No Progress Photos Yet',
              subtitle:
                  'Take your first set of progress photos to start tracking visible changes.',
              ctaLabel: 'Take Photos',
              onCtaPressed: () => context.push('/capture-progress-photo'),
            ),
          )
        else
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final set = photoSets[index];
                  return _PhotoSetGridCard(
                    photoSet: set,
                    onTap: () => context.push('/photo-set/${set.id}'),
                  )
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: (60 * index).ms,
                        curve: Curves.easeOut,
                      )
                      .slideY(begin: 0.05)
                      .scale(begin: const Offset(0.97, 0.97));
                },
                childCount: photoSets.length,
              ),
            ),
          ),

        // Bottom padding for FAB clearance
        if (photoSets.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxxl * 2)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Set Grid Card
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSetGridCard extends StatelessWidget {
  const _PhotoSetGridCard({
    required this.photoSet,
    required this.onTap,
  });

  final ProgressPhotoSet photoSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completedCount = photoSet.completedAngleCount;
    final isComplete = photoSet.isComplete;

    // Find the first available photo for the hero thumbnail
    String? heroPath;
    for (final angle in PhotoAngle.values) {
      final path = photoSet.photoPathFor(angle);
      if (path != null) {
        heroPath = path;
        break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Hero thumbnail area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail image or placeholder
                    if (heroPath != null)
                      _buildThumbnail(heroPath, isDark)
                    else
                      Container(
                        color: isDark
                            ? AppColors.surfaceDark2
                            : AppColors.surfaceLight2,
                        child: Center(
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 32,
                            color: isDark
                                ? AppColors.textDisabledDark
                                : AppColors.textDisabledLight,
                          ),
                        ),
                      ),

                    // Completion badge overlay
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isComplete
                              ? AppColors.accent.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isComplete)
                              const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            if (isComplete) const SizedBox(width: 2),
                            Text(
                              '$completedCount/4',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: heroPath != null ? 0.4 : 0),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Mini angle indicator row
                    Positioned(
                      bottom: AppSpacing.sm,
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: PhotoAngle.values.map((angle) {
                          final hasPhoto = photoSet.photoPathFor(angle) != null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasPhoto
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(photoSet.date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (photoSet.weight != null) ...[
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 12,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${photoSet.weight!.toStringAsFixed(1)}kg',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      if (photoSet.weight != null &&
                          photoSet.bodyFatPercentage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          child: Text(
                            '\u2022',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.textDisabledDark
                                  : AppColors.textDisabledLight,
                            ),
                          ),
                        ),
                      if (photoSet.bodyFatPercentage != null) ...[
                        Text(
                          '${photoSet.bodyFatPercentage!.toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path, bool isDark) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Center(
      child: Icon(
        Icons.image_rounded,
        size: 28,
        color: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
    );
  }
}
