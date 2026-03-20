import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shimmer loading placeholders for skeleton screens.
///
/// Provides factory constructors for common shapes (card, list, circle)
/// and a composable [ShimmerBox] primitive.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
  });

  /// The skeleton widget tree that will be wrapped in a shimmer effect.
  final Widget child;

  // ─────────────────────── Factory constructors ──────────────────────────

  /// A single card-shaped shimmer placeholder.
  factory ShimmerLoading.card({
    Key? key,
    double? width,
    double height = 120,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      key: key,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: ShimmerBox(
          width: width ?? double.infinity,
          height: height,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
    );
  }

  /// A vertical list of shimmer rows (icon + two text lines).
  factory ShimmerLoading.list({
    Key? key,
    int itemCount = 4,
    double itemHeight = 72,
    EdgeInsetsGeometry? padding,
  }) {
    return ShimmerLoading(
      key: key,
      child: Padding(
        padding: padding ?? AppSpacing.screenPadding,
        child: Column(
          children: List.generate(itemCount, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  ShimmerBox(
                    width: itemHeight * 0.65,
                    height: itemHeight * 0.65,
                    borderRadius: BorderRadius.circular(itemHeight * 0.2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: double.infinity,
                          height: 14,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ShimmerBox(
                          width: 120,
                          height: 12,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// A horizontal scrolling list of card shimmers.
  factory ShimmerLoading.horizontalCards({
    Key? key,
    int itemCount = 3,
    double cardWidth = 160,
    double cardHeight = 100,
  }) {
    return ShimmerLoading(
      key: key,
      child: SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, _) => ShimmerBox(
            width: cardWidth,
            height: cardHeight,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      ),
    );
  }

  /// A metric card shimmer (icon + number + subtitle).
  factory ShimmerLoading.metricCard({Key? key}) {
    return ShimmerLoading(
      key: key,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(13),
            ),
            const SizedBox(height: AppSpacing.md),
            ShimmerBox(
              width: 80,
              height: 28,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            const SizedBox(height: AppSpacing.sm),
            ShimmerBox(
              width: 60,
              height: 12,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor:
          isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight2,
      highlightColor:
          isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight,
      child: child,
    );
  }
}

/// A single rectangular shimmer placeholder primitive.
///
/// Must be placed inside a [ShimmerLoading] wrapper for the effect to work.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer replaces this
        borderRadius: borderRadius ?? AppSpacing.borderRadiusSm,
      ),
    );
  }
}
