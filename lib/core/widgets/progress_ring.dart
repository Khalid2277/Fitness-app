import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// An animated circular progress indicator with center label support,
/// customizable colors, stroke width, and optional gradient stroke.
///
/// ```dart
/// ProgressRing(
///   progress: 0.72,
///   size: 120,
///   centerLabel: Text('72%'),
///   gradient: AppColors.progressGradient,
/// )
/// ```
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.centerLabel,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
    this.animate = true,
    this.strokeCap = StrokeCap.round,
  });

  /// Progress value between 0.0 and 1.0.
  final double progress;

  /// Outer diameter of the ring.
  final double size;

  /// Thickness of the ring stroke.
  final double strokeWidth;

  /// Color of the unfilled track.
  final Color? backgroundColor;

  /// Solid color for the progress arc (ignored when [gradient] is set).
  final Color? foregroundColor;

  /// Gradient shader applied to the progress arc.
  final Gradient? gradient;

  /// Widget displayed in the center of the ring.
  final Widget? centerLabel;

  /// Duration of the fill animation.
  final Duration animationDuration;

  /// Curve for the fill animation.
  final Curve animationCurve;

  /// Whether to animate from 0 on first build.
  final bool animate;

  /// End-cap style of the progress arc.
  final StrokeCap strokeCap;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _buildAnimation();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  void _buildAnimation() {
    _animation = Tween<double>(
      begin: _previousProgress,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = _animation.value;
      _controller.duration = widget.animationDuration;
      _buildAnimation();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              strokeWidth: widget.strokeWidth,
              backgroundColor: widget.backgroundColor ??
                  (isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight3),
              foregroundColor:
                  widget.foregroundColor ?? AppColors.primaryBlue,
              gradient: widget.gradient,
              strokeCap: widget.strokeCap,
            ),
            child: Center(child: widget.centerLabel),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeCap,
    this.gradient,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;
  final Gradient? gradient;
  final StrokeCap strokeCap;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background track
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Foreground arc
    final double sweepAngle = 2 * math.pi * progress;
    const double startAngle = -math.pi / 2; // 12 o'clock

    final Paint fgPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    if (gradient != null) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      fgPaint.shader = gradient!.createShader(rect);
    } else {
      fgPaint.color = foregroundColor;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      strokeWidth != oldDelegate.strokeWidth ||
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor;
}
