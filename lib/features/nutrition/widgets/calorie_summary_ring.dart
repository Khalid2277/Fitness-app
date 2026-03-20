import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// Circular calorie progress ring.
///
/// When [showLabel] is true, displays [labelText] in the center (e.g. "62%").
/// When false, shows consumed/remaining text like the old design.
class CalorieSummaryRing extends StatelessWidget {
  const CalorieSummaryRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 200,
    this.strokeWidth = 14,
    this.showLabel = false,
    this.labelText,
  });

  final double consumed;
  final double target;
  final double size;
  final double strokeWidth;
  final bool showLabel;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = (target - consumed).clamp(0.0, target);
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              trackColor: isDark
                  ? AppColors.surfaceDark3
                  : AppColors.surfaceLight2,
              isDark: isDark,
              strokeWidth: strokeWidth,
            ),
          ),
          if (showLabel && labelText != null)
            Text(
              labelText!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.18,
              ),
            )
          else if (!showLabel)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consumed.toInt().toString(),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  'kcal consumed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    '${remaining.toInt()} left',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.isDark,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final bool isDark;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final rect = Rect.fromCircle(center: center, radius: radius);

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: const [
            AppColors.primaryBlue,
            AppColors.accent,
          ],
          stops: const [0.0, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
