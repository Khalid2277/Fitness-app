import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/muscles/providers/muscle_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Body Map Widget — Premium anatomical muscle map with FRONT/BACK toggle
// ─────────────────────────────────────────────────────────────────────────────

class BodyMap extends ConsumerStatefulWidget {
  const BodyMap({super.key});

  @override
  ConsumerState<BodyMap> createState() => _BodyMapState();
}

class _BodyMapState extends ConsumerState<BodyMap>
    with SingleTickerProviderStateMixin {
  bool _showFront = true;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleView() {
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final volume = ref.watch(muscleVolumeProvider);
    final selectedMuscle = ref.watch(selectedMuscleProvider);

    return Column(
      children: [
        // Body map canvas with 3D flip
        Expanded(
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final showBack = angle > math.pi / 2;
              final isFront = !showBack;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isFront
                    ? _BodyMapCanvas(
                        isFront: true,
                        volume: volume,
                        selectedMuscle: selectedMuscle,
                        isDark: isDark,
                        onMuscleSelected: (muscle) {
                          ref.read(selectedMuscleProvider.notifier).state =
                              muscle;
                        },
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _BodyMapCanvas(
                          isFront: false,
                          volume: volume,
                          selectedMuscle: selectedMuscle,
                          isDark: isDark,
                          onMuscleSelected: (muscle) {
                            ref.read(selectedMuscleProvider.notifier).state =
                                muscle;
                          },
                        ),
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // FRONT / BACK toggle
        _FrontBackToggle(
          isFront: _showFront,
          isDark: isDark,
          onToggle: _toggleView,
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body Map Canvas — wraps CustomPainter with GestureDetector for hit testing
// ─────────────────────────────────────────────────────────────────────────────

class _BodyMapCanvas extends StatelessWidget {
  const _BodyMapCanvas({
    required this.isFront,
    required this.volume,
    required this.selectedMuscle,
    required this.isDark,
    required this.onMuscleSelected,
  });

  final bool isFront;
  final Map<MuscleGroup, int> volume;
  final MuscleGroup? selectedMuscle;
  final bool isDark;
  final ValueChanged<MuscleGroup> onMuscleSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final regions = isFront
            ? _BodyPathData.frontRegions(size)
            : _BodyPathData.backRegions(size);

        return GestureDetector(
          onTapDown: (details) {
            final pos = details.localPosition;
            // Iterate in reverse so top-layer muscles get priority
            for (int i = regions.length - 1; i >= 0; i--) {
              if (regions[i].path.contains(pos)) {
                onMuscleSelected(regions[i].muscle);
                return;
              }
            }
          },
          child: CustomPaint(
            size: size,
            painter: _BodyMapPainter(
              isFront: isFront,
              volume: volume,
              selectedMuscle: selectedMuscle,
              isDark: isDark,
              regions: regions,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRONT / BACK Toggle — pill-shaped segmented control
// ─────────────────────────────────────────────────────────────────────────────

class _FrontBackToggle extends StatelessWidget {
  const _FrontBackToggle({
    required this.isFront,
    required this.isDark,
    required this.onToggle,
  });

  final bool isFront;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surfaceLight2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TogglePill(
              label: 'FRONT',
              isActive: isFront,
              isDark: isDark,
              onTap: isFront ? null : onToggle,
              theme: theme,
            ),
            _TogglePill(
              label: 'BACK',
              isActive: !isFront,
              isDark: isDark,
              onTap: isFront ? onToggle : null,
              theme: theme,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: isActive
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muscle Region — a named path region for hit testing & painting
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleRegion {
  const _MuscleRegion({required this.muscle, required this.path});
  final MuscleGroup muscle;
  final Path path;
}

// ─────────────────────────────────────────────────────────────────────────────
// Heatmap Color Utility — continuous gradient interpolation
// ─────────────────────────────────────────────────────────────────────────────

Color _heatmapColor(int sets, bool isDark) {
  if (sets == 0) {
    return isDark ? const Color(0xFF1E2028) : const Color(0xFFE8EBF0);
  }
  final t = (sets / 20.0).clamp(0.0, 1.0);
  // Smooth interpolation through: teal -> blue -> amber -> coral
  final colors = isDark
      ? const [
          Color(0xFF1A4D3A),
          Color(0xFF1E3A5F),
          Color(0xFF5C4813),
          Color(0xFF6B2020),
        ]
      : const [
          Color(0xFF86EFAC),
          Color(0xFF93C5FD),
          Color(0xFFFCD34D),
          Color(0xFFFCA5A5),
        ];
  if (t < 0.33) return Color.lerp(colors[0], colors[1], t / 0.33)!;
  if (t < 0.66) return Color.lerp(colors[1], colors[2], (t - 0.33) / 0.33)!;
  return Color.lerp(colors[2], colors[3], (t - 0.66) / 0.34)!;
}

Color _heatmapGlow(int sets) {
  if (sets == 0) return Colors.transparent;
  final t = (sets / 20.0).clamp(0.0, 1.0);
  if (t < 0.25) {
    return AppColors.success.withValues(alpha: 0.15 + t * 0.4);
  }
  if (t < 0.5) {
    return AppColors.primaryBlue.withValues(alpha: 0.2 + (t - 0.25) * 0.4);
  }
  if (t < 0.75) {
    return AppColors.warning.withValues(alpha: 0.2 + (t - 0.5) * 0.4);
  }
  return AppColors.error.withValues(alpha: 0.25 + (t - 0.75) * 0.4);
}

// ─────────────────────────────────────────────────────────────────────────────
// Body Map CustomPainter — renders silhouette, muscles, glows, and selections
// ─────────────────────────────────────────────────────────────────────────────

class _BodyMapPainter extends CustomPainter {
  _BodyMapPainter({
    required this.isFront,
    required this.volume,
    required this.selectedMuscle,
    required this.isDark,
    required this.regions,
  });

  final bool isFront;
  final Map<MuscleGroup, int> volume;
  final MuscleGroup? selectedMuscle;
  final bool isDark;
  final List<_MuscleRegion> regions;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background glow
    _drawBackgroundGlow(canvas, size);
    // 2. Body silhouette
    _drawBodyOutline(canvas, size);
    // 3. Muscle regions with gradient fills
    _drawMuscleRegions(canvas, size);
  }

  void _drawBackgroundGlow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.height * 0.4,
        [
          AppColors.primaryBlue.withValues(alpha: isDark ? 0.06 : 0.03),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  void _drawBodyOutline(Canvas canvas, Size size) {
    final outlinePath = isFront
        ? _BodyPathData.frontOutline(size)
        : _BodyPathData.backOutline(size);

    final outlinePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outlinePath, outlinePaint);
  }

  void _drawMuscleRegions(Canvas canvas, Size size) {
    // First pass: draw all non-selected muscles
    for (final region in regions) {
      final isSelected = region.muscle == selectedMuscle;
      if (isSelected) continue;
      _drawMuscle(canvas, size, region, false);
    }

    // Second pass: draw selected muscle on top with glow
    for (final region in regions) {
      final isSelected = region.muscle == selectedMuscle;
      if (!isSelected) continue;
      _drawMuscle(canvas, size, region, true);
    }
  }

  void _drawMuscle(
      Canvas canvas, Size size, _MuscleRegion region, bool isSelected) {
    final sets = volume[region.muscle] ?? 0;
    final baseColor = _heatmapColor(sets, isDark);
    final glow = _heatmapGlow(sets);
    final bounds = region.path.getBounds();

    // Glow effect for muscles with volume
    if (sets > 0) {
      final glowPaint = Paint()
        ..color = glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(region.path, glowPaint);
    }

    // Selection glow (drawn before fill for layering)
    if (isSelected) {
      final selectedGlow = Paint()
        ..color = AppColors.primaryBlue.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(region.path, selectedGlow);
    }

    // Per-muscle gradient fill for 3D depth effect
    final fillColor = isSelected
        ? Color.lerp(baseColor, AppColors.primaryBlue, 0.45)!
        : baseColor;
    final lighterColor = Color.lerp(fillColor, Colors.white, 0.12)!;
    final darkerColor = Color.lerp(fillColor, Colors.black, 0.10)!;

    final gradient = ui.Gradient.linear(
      Offset(bounds.left, bounds.top),
      Offset(bounds.left, bounds.bottom),
      [lighterColor, fillColor, darkerColor],
      [0.0, 0.5, 1.0],
    );

    final fillPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(region.path, fillPaint);

    // Subtle inner highlight for 3D curvature
    if (sets > 0 || isSelected) {
      final highlightGradient = ui.Gradient.linear(
        Offset(bounds.center.dx, bounds.top),
        Offset(bounds.center.dx, bounds.top + bounds.height * 0.4),
        [
          Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
          Colors.transparent,
        ],
      );
      final highlightPaint = Paint()
        ..shader = highlightGradient
        ..style = PaintingStyle.fill;
      canvas.drawPath(region.path, highlightPaint);
    }

    // Muscle fiber detail lines
    _drawMuscleFibers(canvas, size, region);

    // Border for definition
    final borderPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: isSelected ? 0.30 : 0.08)
          : Colors.black.withValues(alpha: isSelected ? 0.22 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.5 : 0.6;
    canvas.drawPath(region.path, borderPaint);

    // Extra bright border for selected muscle
    if (isSelected) {
      final selectionBorder = Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(region.path, selectionBorder);
    }
  }

  void _drawMuscleFibers(Canvas canvas, Size size, _MuscleRegion region) {
    final bounds = region.path.getBounds();
    if (bounds.isEmpty) return;

    final fiberAlpha = isDark ? 0.05 : 0.06;
    final fiberPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black)
          .withValues(alpha: fiberAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.save();
    canvas.clipPath(region.path);

    final muscle = region.muscle;
    final cx = bounds.center.dx;
    final w = bounds.width;
    final h = bounds.height;

    if (muscle == MuscleGroup.chest) {
      // Radiating fibers from inner edge toward armpit
      for (double t = 0.15; t < 0.85; t += 0.12) {
        final startY = bounds.top + h * t;
        // Determine if left or right pec based on position
        final isLeft = cx < size.width / 2;
        final startX = isLeft ? bounds.right - w * 0.1 : bounds.left + w * 0.1;
        final endX = isLeft ? bounds.left + w * 0.1 : bounds.right - w * 0.1;
        final endY = startY + h * 0.08 * (t - 0.5);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), fiberPaint);
      }
    } else if (muscle == MuscleGroup.biceps ||
        muscle == MuscleGroup.triceps ||
        muscle == MuscleGroup.hamstrings) {
      // Vertical fibers along muscle length
      for (double t = 0.2; t < 0.8; t += 0.15) {
        final x = bounds.left + w * t;
        canvas.drawLine(
          Offset(x, bounds.top + h * 0.1),
          Offset(x + w * 0.02, bounds.bottom - h * 0.1),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.quadriceps) {
      // Slightly converging vertical fibers
      for (double t = 0.15; t < 0.85; t += 0.14) {
        final x = bounds.left + w * t;
        canvas.drawLine(
          Offset(x, bounds.top + h * 0.08),
          Offset(cx + (x - cx) * 0.7, bounds.bottom - h * 0.08),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.lats) {
      // Diagonal fibers sweeping from upper-inner to lower-outer
      for (double t = 0.15; t < 0.85; t += 0.12) {
        final isLeft = cx < size.width / 2;
        final startX = isLeft ? bounds.right - w * 0.1 : bounds.left + w * 0.1;
        final endX = isLeft ? bounds.left + w * 0.2 : bounds.right - w * 0.2;
        canvas.drawLine(
          Offset(startX, bounds.top + h * t),
          Offset(endX, bounds.top + h * (t + 0.15).clamp(0.0, 1.0)),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.shoulders) {
      // Curved fibers following deltoid direction
      for (double t = 0.2; t < 0.8; t += 0.15) {
        final y = bounds.top + h * t;
        canvas.drawLine(
          Offset(bounds.left + w * 0.15, y),
          Offset(bounds.right - w * 0.15, y + h * 0.05),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.core) {
      // Horizontal fibers for abs segmentation
      for (double t = 0.18; t < 0.85; t += 0.16) {
        final y = bounds.top + h * t;
        canvas.drawLine(
          Offset(bounds.left + w * 0.1, y),
          Offset(bounds.right - w * 0.1, y),
          fiberPaint,
        );
      }
      // Vertical center line (linea alba)
      canvas.drawLine(
        Offset(cx, bounds.top + h * 0.05),
        Offset(cx, bounds.bottom - h * 0.05),
        fiberPaint,
      );
    } else if (muscle == MuscleGroup.traps) {
      // Diagonal fibers converging toward spine
      for (double t = 0.2; t < 0.8; t += 0.15) {
        final y = bounds.top + h * t;
        canvas.drawLine(
          Offset(bounds.left + w * 0.1, y),
          Offset(cx, y + h * 0.1),
          fiberPaint,
        );
        canvas.drawLine(
          Offset(bounds.right - w * 0.1, y),
          Offset(cx, y + h * 0.1),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.glutes) {
      // Radiating fibers from hip joint
      for (double t = 0.15; t < 0.85; t += 0.12) {
        final angle = -0.6 + t * 1.2;
        canvas.drawLine(
          Offset(cx, bounds.top + h * 0.3),
          Offset(
            cx + w * 0.4 * math.cos(angle),
            bounds.top + h * 0.3 + h * 0.5 * math.sin(angle),
          ),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.calves) {
      // Converging vertical fibers (gastrocnemius shape)
      for (double t = 0.2; t < 0.8; t += 0.15) {
        final x = bounds.left + w * t;
        canvas.drawLine(
          Offset(x, bounds.top + h * 0.08),
          Offset(cx + (x - cx) * 0.5, bounds.bottom - h * 0.1),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.forearms) {
      // Angled fibers along forearm
      for (double t = 0.2; t < 0.8; t += 0.15) {
        final x = bounds.left + w * t;
        canvas.drawLine(
          Offset(x, bounds.top + h * 0.1),
          Offset(x - w * 0.05, bounds.bottom - h * 0.1),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.obliques) {
      // Diagonal fibers
      for (double t = 0.15; t < 0.85; t += 0.14) {
        canvas.drawLine(
          Offset(bounds.left + w * 0.1, bounds.top + h * t),
          Offset(bounds.right - w * 0.1, bounds.top + h * (t + 0.2)),
          fiberPaint,
        );
      }
    } else if (muscle == MuscleGroup.back) {
      // Vertical fibers for erector spinae
      for (double t = 0.2; t < 0.8; t += 0.2) {
        final x = bounds.left + w * t;
        canvas.drawLine(
          Offset(x, bounds.top + h * 0.08),
          Offset(x, bounds.bottom - h * 0.08),
          fiberPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.volume != volume;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG Path Parser — converts compact SVG path data into Flutter Path objects
// ─────────────────────────────────────────────────────────────────────────────

class _SvgPathParser {
  _SvgPathParser._();

  /// Parse an SVG path data string into a Flutter [Path], scaling all
  /// coordinates by [sx] (width) and [sy] (height).
  ///
  /// Supports commands: M, L, C, S, Q, T, Z (absolute only).
  /// Coordinates in the path string should be normalized (0.0 to 1.0).
  static Path parse(String data, double sx, double sy) {
    final path = Path();
    final tokens = _tokenize(data);
    int i = 0;
    double lastCX = 0, lastCY = 0; // Last control point for S/T commands
    String lastCmd = '';

    while (i < tokens.length) {
      final token = tokens[i];
      if (_isCommand(token)) {
        final cmd = token;
        i++;
        switch (cmd) {
          case 'M':
            final x = double.parse(tokens[i++]) * sx;
            final y = double.parse(tokens[i++]) * sy;
            path.moveTo(x, y);
            lastCmd = cmd;
          case 'L':
            while (i < tokens.length && !_isCommand(tokens[i])) {
              final x = double.parse(tokens[i++]) * sx;
              final y = double.parse(tokens[i++]) * sy;
              path.lineTo(x, y);
            }
            lastCmd = cmd;
          case 'C':
            while (i < tokens.length && !_isCommand(tokens[i])) {
              final x1 = double.parse(tokens[i++]) * sx;
              final y1 = double.parse(tokens[i++]) * sy;
              final x2 = double.parse(tokens[i++]) * sx;
              final y2 = double.parse(tokens[i++]) * sy;
              final x = double.parse(tokens[i++]) * sx;
              final y = double.parse(tokens[i++]) * sy;
              path.cubicTo(x1, y1, x2, y2, x, y);
              lastCX = x2;
              lastCY = y2;
            }
            lastCmd = cmd;
          case 'S':
            while (i < tokens.length && !_isCommand(tokens[i])) {
              // Reflect previous control point
              final metrics = path.computeMetrics().last;
              final tangent =
                  metrics.getTangentForOffset(metrics.length)!.position;
              double rx1, ry1;
              if (lastCmd == 'C' || lastCmd == 'S') {
                rx1 = 2 * tangent.dx - lastCX * sx;
                ry1 = 2 * tangent.dy - lastCY * sy;
              } else {
                rx1 = tangent.dx;
                ry1 = tangent.dy;
              }
              final x2 = double.parse(tokens[i++]) * sx;
              final y2 = double.parse(tokens[i++]) * sy;
              final x = double.parse(tokens[i++]) * sx;
              final y = double.parse(tokens[i++]) * sy;
              path.cubicTo(rx1, ry1, x2, y2, x, y);
              lastCX = x2 / sx;
              lastCY = y2 / sy;
            }
            lastCmd = cmd;
          case 'Q':
            while (i < tokens.length && !_isCommand(tokens[i])) {
              final x1 = double.parse(tokens[i++]) * sx;
              final y1 = double.parse(tokens[i++]) * sy;
              final x = double.parse(tokens[i++]) * sx;
              final y = double.parse(tokens[i++]) * sy;
              path.quadraticBezierTo(x1, y1, x, y);
              lastCX = x1 / sx;
              lastCY = y1 / sy;
            }
            lastCmd = cmd;
          case 'Z':
            path.close();
            lastCmd = cmd;
          default:
            i++; // Skip unknown commands
        }
      } else {
        i++; // Skip unexpected tokens
      }
    }
    return path;
  }

  static List<String> _tokenize(String data) {
    final result = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < data.length; i++) {
      final c = data[i];
      if (_isCommandChar(c)) {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
        result.add(c);
      } else if (c == ',' || c == ' ' || c == '\n' || c == '\r' || c == '\t') {
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
      } else if (c == '-' && buffer.isNotEmpty) {
        // Negative sign starts a new number
        result.add(buffer.toString());
        buffer.clear();
        buffer.write(c);
      } else {
        buffer.write(c);
      }
    }
    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }

  static bool _isCommandChar(String c) {
    return 'MLCSQTZmlcsqtz'.contains(c);
  }

  static bool _isCommand(String token) {
    return token.length == 1 && _isCommandChar(token);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anatomical Path Data — detailed muscle region paths using SVG notation
//
// All coordinates are normalized (0.0 - 1.0) relative to canvas size.
// The figure uses an 8-head-canon proportion system centered horizontally.
//
// Key Landmarks (normalized):
//   Head center:      (0.50, 0.06)
//   Neck base:        (0.50, 0.105)
//   Shoulder tips:    (0.28, 0.145) / (0.72, 0.145)
//   Armpits:          (0.33, 0.195) / (0.67, 0.195)
//   Chest center:     (0.50, 0.19)
//   Elbows:           (0.22, 0.325) / (0.78, 0.325)
//   Navel:            (0.50, 0.365)
//   Waist sides:      (0.37, 0.365) / (0.63, 0.365)
//   Wrists:           (0.19, 0.44) / (0.81, 0.44)
//   Hip crease:       (0.37, 0.42) / (0.63, 0.42)
//   Crotch:           (0.50, 0.47)
//   Knees:            (0.39, 0.66) / (0.61, 0.66)
//   Ankles:           (0.42, 0.90) / (0.58, 0.90)
// ─────────────────────────────────────────────────────────────────────────────

class _BodyPathData {
  _BodyPathData._();

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Offset _p(Size s, double rx, double ry) =>
      Offset(s.width * rx, s.height * ry);

  /// Build a Path from normalized SVG path data scaled to canvas size.
  static Path _svg(Size s, String data) =>
      _SvgPathParser.parse(data, s.width, s.height);

  // ── Full body outline (silhouette fill behind muscles) ──────────────────

  static Path frontOutline(Size s) {
    final p = Path();
    // Head
    p.addOval(Rect.fromCenter(
      center: _p(s, 0.50, 0.06),
      width: s.width * 0.11,
      height: s.height * 0.072,
    ));
    // Neck
    p.addRect(Rect.fromLTRB(
      s.width * 0.465, s.height * 0.093,
      s.width * 0.535, s.height * 0.13,
    ));
    // Torso + arms + legs
    p.addPath(_svg(s,
      // Right shoulder to right hand, down right leg, across to left leg, up left hand to left shoulder
      'M 0.465 0.13 '
      // Left shoulder slope
      'C 0.42 0.125, 0.36 0.125, 0.28 0.145 '
      // Left deltoid outer curve
      'C 0.255 0.155, 0.245 0.175, 0.24 0.20 '
      // Left upper arm outer
      'C 0.235 0.23, 0.23 0.27, 0.225 0.31 '
      // Left elbow
      'C 0.22 0.33, 0.215 0.34, 0.215 0.35 '
      // Left forearm
      'C 0.21 0.37, 0.205 0.40, 0.195 0.43 '
      // Left wrist/hand
      'C 0.185 0.45, 0.18 0.46, 0.175 0.47 '
      'C 0.185 0.475, 0.20 0.47, 0.21 0.46 '
      // Left forearm inner
      'C 0.22 0.44, 0.23 0.41, 0.24 0.38 '
      // Left inner elbow
      'C 0.25 0.35, 0.255 0.34, 0.26 0.33 '
      // Left upper arm inner
      'C 0.27 0.30, 0.28 0.26, 0.29 0.23 '
      // Left armpit
      'C 0.30 0.21, 0.315 0.20, 0.33 0.195 '
      // Left torso
      'C 0.34 0.25, 0.35 0.32, 0.36 0.37 '
      // Left waist
      'C 0.365 0.39, 0.37 0.41, 0.375 0.42 '
      // Left hip
      'C 0.38 0.44, 0.385 0.45, 0.39 0.46 '
      // Crotch left
      'C 0.41 0.47, 0.44 0.475, 0.46 0.478 '
      // Left inner thigh
      'L 0.46 0.48 '
      'C 0.455 0.53, 0.45 0.58, 0.445 0.62 '
      // Left inner knee
      'C 0.44 0.64, 0.44 0.655, 0.44 0.66 '
      // Left inner lower leg
      'C 0.44 0.70, 0.435 0.76, 0.43 0.82 '
      // Left inner ankle
      'C 0.425 0.87, 0.42 0.90, 0.415 0.92 '
      // Left foot
      'C 0.41 0.935, 0.40 0.94, 0.39 0.945 '
      'L 0.44 0.945 '
      // Left outer ankle
      'C 0.44 0.93, 0.435 0.91, 0.43 0.89 '
      // Left outer lower leg
      'C 0.425 0.84, 0.42 0.78, 0.41 0.72 '
      // Left outer knee
      'C 0.405 0.69, 0.40 0.67, 0.395 0.66 '
      // Left outer thigh
      'C 0.385 0.62, 0.375 0.56, 0.37 0.50 '
      'C 0.368 0.48, 0.375 0.46, 0.38 0.45 '
      // Crotch bottom
      'C 0.42 0.475, 0.48 0.485, 0.50 0.488 '
      // Mirror right side
      'C 0.52 0.485, 0.58 0.475, 0.62 0.45 '
      'C 0.625 0.46, 0.632 0.48, 0.63 0.50 '
      'C 0.625 0.56, 0.615 0.62, 0.605 0.66 '
      'C 0.60 0.67, 0.595 0.69, 0.59 0.72 '
      'C 0.58 0.78, 0.575 0.84, 0.57 0.89 '
      'C 0.565 0.91, 0.56 0.93, 0.56 0.945 '
      'L 0.61 0.945 '
      'C 0.60 0.94, 0.59 0.935, 0.585 0.92 '
      'C 0.58 0.90, 0.575 0.87, 0.57 0.82 '
      'C 0.565 0.76, 0.56 0.70, 0.56 0.66 '
      'C 0.56 0.655, 0.56 0.64, 0.555 0.62 '
      'C 0.55 0.58, 0.545 0.53, 0.54 0.48 '
      'L 0.54 0.478 '
      'C 0.56 0.475, 0.59 0.47, 0.61 0.46 '
      'C 0.615 0.45, 0.62 0.44, 0.625 0.42 '
      'C 0.63 0.41, 0.635 0.39, 0.64 0.37 '
      'C 0.65 0.32, 0.66 0.25, 0.67 0.195 '
      'C 0.685 0.20, 0.70 0.21, 0.71 0.23 '
      'C 0.72 0.26, 0.73 0.30, 0.74 0.33 '
      'C 0.745 0.34, 0.75 0.35, 0.76 0.38 '
      'C 0.77 0.41, 0.78 0.44, 0.79 0.46 '
      'C 0.80 0.47, 0.815 0.475, 0.825 0.47 '
      'C 0.82 0.46, 0.815 0.45, 0.805 0.43 '
      'C 0.795 0.40, 0.79 0.37, 0.785 0.35 '
      'C 0.785 0.34, 0.78 0.33, 0.775 0.31 '
      'C 0.77 0.27, 0.765 0.23, 0.76 0.20 '
      'C 0.755 0.175, 0.745 0.155, 0.72 0.145 '
      'C 0.64 0.125, 0.58 0.125, 0.535 0.13 '
      'Z'
    ), Offset.zero);
    return p;
  }

  static Path backOutline(Size s) {
    // Back outline is the same silhouette shape
    return frontOutline(s);
  }

  // ── FRONT VIEW muscle regions ─────────────────────────────────────────────

  static List<_MuscleRegion> frontRegions(Size s) {
    return [
      // Traps (front view — visible as sloping from mid-neck to shoulders)
      _MuscleRegion(
        muscle: MuscleGroup.traps,
        path: _svg(s,
          'M 0.465 0.105 '
          'C 0.45 0.11, 0.42 0.12, 0.38 0.13 '
          'C 0.35 0.138, 0.32 0.145, 0.30 0.155 '
          'L 0.33 0.17 '
          'C 0.37 0.155, 0.41 0.148, 0.44 0.145 '
          'L 0.465 0.14 '
          'L 0.535 0.14 '
          'L 0.56 0.145 '
          'C 0.59 0.148, 0.63 0.155, 0.67 0.17 '
          'L 0.70 0.155 '
          'C 0.68 0.145, 0.65 0.138, 0.62 0.13 '
          'C 0.58 0.12, 0.55 0.11, 0.535 0.105 '
          'Z'
        ),
      ),

      // Left Shoulder (Anterior Deltoid) — rounded cap shape
      _MuscleRegion(
        muscle: MuscleGroup.shoulders,
        path: _svg(s,
          'M 0.33 0.14 '
          'C 0.32 0.135, 0.30 0.133, 0.285 0.14 '
          'C 0.265 0.148, 0.25 0.16, 0.245 0.175 '
          'C 0.24 0.19, 0.24 0.20, 0.245 0.21 '
          'L 0.255 0.215 '
          'C 0.26 0.21, 0.265 0.20, 0.27 0.195 '
          'C 0.285 0.205, 0.30 0.21, 0.315 0.20 '
          'C 0.33 0.19, 0.34 0.175, 0.345 0.16 '
          'C 0.34 0.15, 0.335 0.143, 0.33 0.14 '
          'Z'
        ),
      ),

      // Right Shoulder (Anterior Deltoid)
      _MuscleRegion(
        muscle: MuscleGroup.shoulders,
        path: _svg(s,
          'M 0.67 0.14 '
          'C 0.68 0.135, 0.70 0.133, 0.715 0.14 '
          'C 0.735 0.148, 0.75 0.16, 0.755 0.175 '
          'C 0.76 0.19, 0.76 0.20, 0.755 0.21 '
          'L 0.745 0.215 '
          'C 0.74 0.21, 0.735 0.20, 0.73 0.195 '
          'C 0.715 0.205, 0.70 0.21, 0.685 0.20 '
          'C 0.67 0.19, 0.66 0.175, 0.655 0.16 '
          'C 0.66 0.15, 0.665 0.143, 0.67 0.14 '
          'Z'
        ),
      ),

      // Left Chest (Pectoralis) — fan/shield shape
      _MuscleRegion(
        muscle: MuscleGroup.chest,
        path: _svg(s,
          'M 0.49 0.155 '
          // Upper edge along clavicle toward shoulder
          'C 0.47 0.152, 0.44 0.148, 0.41 0.15 '
          'C 0.39 0.152, 0.37 0.158, 0.35 0.165 '
          'C 0.34 0.17, 0.335 0.178, 0.33 0.19 '
          // Outer edge — curves down to pec line
          'C 0.325 0.205, 0.33 0.22, 0.34 0.235 '
          // Lower pec line — the distinctive curved underline
          'C 0.355 0.245, 0.38 0.25, 0.41 0.248 '
          'C 0.44 0.245, 0.46 0.24, 0.48 0.232 '
          'C 0.485 0.228, 0.49 0.22, 0.49 0.215 '
          // Inner edge back up along sternum
          'C 0.49 0.20, 0.49 0.18, 0.49 0.155 '
          'Z'
        ),
      ),

      // Right Chest (Pectoralis)
      _MuscleRegion(
        muscle: MuscleGroup.chest,
        path: _svg(s,
          'M 0.51 0.155 '
          'C 0.53 0.152, 0.56 0.148, 0.59 0.15 '
          'C 0.61 0.152, 0.63 0.158, 0.65 0.165 '
          'C 0.66 0.17, 0.665 0.178, 0.67 0.19 '
          'C 0.675 0.205, 0.67 0.22, 0.66 0.235 '
          'C 0.645 0.245, 0.62 0.25, 0.59 0.248 '
          'C 0.56 0.245, 0.54 0.24, 0.52 0.232 '
          'C 0.515 0.228, 0.51 0.22, 0.51 0.215 '
          'C 0.51 0.20, 0.51 0.18, 0.51 0.155 '
          'Z'
        ),
      ),

      // Left Bicep — elongated with peak shape
      _MuscleRegion(
        muscle: MuscleGroup.biceps,
        path: _svg(s,
          'M 0.285 0.215 '
          // Outer edge of bicep
          'C 0.275 0.225, 0.265 0.245, 0.26 0.265 '
          'C 0.255 0.285, 0.252 0.30, 0.25 0.315 '
          // Bicep peak (outward bulge)
          'C 0.248 0.32, 0.25 0.325, 0.255 0.325 '
          // Inner edge
          'C 0.26 0.325, 0.268 0.32, 0.275 0.31 '
          'C 0.28 0.295, 0.285 0.275, 0.29 0.255 '
          'C 0.295 0.24, 0.30 0.225, 0.305 0.215 '
          // Top
          'C 0.30 0.21, 0.29 0.21, 0.285 0.215 '
          'Z'
        ),
      ),

      // Right Bicep
      _MuscleRegion(
        muscle: MuscleGroup.biceps,
        path: _svg(s,
          'M 0.715 0.215 '
          'C 0.725 0.225, 0.735 0.245, 0.74 0.265 '
          'C 0.745 0.285, 0.748 0.30, 0.75 0.315 '
          'C 0.752 0.32, 0.75 0.325, 0.745 0.325 '
          'C 0.74 0.325, 0.732 0.32, 0.725 0.31 '
          'C 0.72 0.295, 0.715 0.275, 0.71 0.255 '
          'C 0.705 0.24, 0.70 0.225, 0.695 0.215 '
          'C 0.70 0.21, 0.71 0.21, 0.715 0.215 '
          'Z'
        ),
      ),

      // Left Forearm — tapered from elbow to wrist
      _MuscleRegion(
        muscle: MuscleGroup.forearms,
        path: _svg(s,
          'M 0.25 0.33 '
          // Outer edge (brachioradialis - wider)
          'C 0.245 0.34, 0.24 0.355, 0.235 0.37 '
          'C 0.23 0.385, 0.225 0.40, 0.22 0.415 '
          'C 0.215 0.425, 0.21 0.435, 0.20 0.445 '
          // Wrist
          'C 0.195 0.45, 0.195 0.45, 0.20 0.45 '
          // Inner edge (thinner)
          'C 0.205 0.445, 0.215 0.435, 0.225 0.42 '
          'C 0.23 0.41, 0.24 0.39, 0.245 0.375 '
          'C 0.25 0.36, 0.255 0.345, 0.26 0.335 '
          'C 0.258 0.33, 0.255 0.328, 0.25 0.33 '
          'Z'
        ),
      ),

      // Right Forearm
      _MuscleRegion(
        muscle: MuscleGroup.forearms,
        path: _svg(s,
          'M 0.75 0.33 '
          'C 0.755 0.34, 0.76 0.355, 0.765 0.37 '
          'C 0.77 0.385, 0.775 0.40, 0.78 0.415 '
          'C 0.785 0.425, 0.79 0.435, 0.80 0.445 '
          'C 0.805 0.45, 0.805 0.45, 0.80 0.45 '
          'C 0.795 0.445, 0.785 0.435, 0.775 0.42 '
          'C 0.77 0.41, 0.76 0.39, 0.755 0.375 '
          'C 0.75 0.36, 0.745 0.345, 0.74 0.335 '
          'C 0.742 0.33, 0.745 0.328, 0.75 0.33 '
          'Z'
        ),
      ),

      // Core (Abs) — rectangular with slight taper, six-pack outline
      _MuscleRegion(
        muscle: MuscleGroup.core,
        path: _svg(s,
          'M 0.455 0.24 '
          // Upper abs (wider)
          'C 0.455 0.245, 0.455 0.26, 0.455 0.28 '
          // Slight lateral curve
          'C 0.454 0.30, 0.452 0.32, 0.45 0.34 '
          // Lower abs (narrower)
          'C 0.448 0.355, 0.445 0.37, 0.445 0.385 '
          // Bottom — V-line at hip crease
          'C 0.45 0.40, 0.46 0.41, 0.47 0.415 '
          'C 0.48 0.418, 0.49 0.42, 0.50 0.42 '
          'C 0.51 0.42, 0.52 0.418, 0.53 0.415 '
          'C 0.54 0.41, 0.55 0.40, 0.555 0.385 '
          // Right side going up
          'C 0.555 0.37, 0.552 0.355, 0.55 0.34 '
          'C 0.548 0.32, 0.546 0.30, 0.545 0.28 '
          'C 0.545 0.26, 0.545 0.245, 0.545 0.24 '
          // Top edge
          'L 0.455 0.24 '
          'Z'
        ),
      ),

      // Left Oblique — angled flank shape
      _MuscleRegion(
        muscle: MuscleGroup.obliques,
        path: _svg(s,
          'M 0.35 0.24 '
          'C 0.355 0.26, 0.36 0.29, 0.365 0.32 '
          'C 0.368 0.34, 0.37 0.36, 0.37 0.38 '
          'C 0.372 0.40, 0.375 0.41, 0.38 0.42 '
          // Bottom connects to hip crease
          'L 0.445 0.39 '
          // Inner edge follows abs contour
          'C 0.448 0.37, 0.45 0.35, 0.452 0.33 '
          'C 0.454 0.31, 0.455 0.28, 0.455 0.26 '
          'L 0.455 0.24 '
          // Top connects along rib line
          'C 0.43 0.235, 0.39 0.235, 0.35 0.24 '
          'Z'
        ),
      ),

      // Right Oblique
      _MuscleRegion(
        muscle: MuscleGroup.obliques,
        path: _svg(s,
          'M 0.65 0.24 '
          'C 0.645 0.26, 0.64 0.29, 0.635 0.32 '
          'C 0.632 0.34, 0.63 0.36, 0.63 0.38 '
          'C 0.628 0.40, 0.625 0.41, 0.62 0.42 '
          'L 0.555 0.39 '
          'C 0.552 0.37, 0.55 0.35, 0.548 0.33 '
          'C 0.546 0.31, 0.545 0.28, 0.545 0.26 '
          'L 0.545 0.24 '
          'C 0.57 0.235, 0.61 0.235, 0.65 0.24 '
          'Z'
        ),
      ),

      // Hip Flexors — small area at hip crease
      _MuscleRegion(
        muscle: MuscleGroup.hipFlexors,
        path: _svg(s,
          'M 0.42 0.42 '
          'C 0.43 0.425, 0.44 0.43, 0.45 0.44 '
          'C 0.46 0.45, 0.475 0.455, 0.50 0.455 '
          'C 0.525 0.455, 0.54 0.45, 0.55 0.44 '
          'C 0.56 0.43, 0.57 0.425, 0.58 0.42 '
          'C 0.56 0.415, 0.54 0.418, 0.53 0.415 '
          'C 0.52 0.418, 0.51 0.42, 0.50 0.42 '
          'C 0.49 0.42, 0.48 0.418, 0.47 0.415 '
          'C 0.46 0.418, 0.44 0.415, 0.42 0.42 '
          'Z'
        ),
      ),

      // Left Quadricep — teardrop/leaf shape with distinct quad sweep
      _MuscleRegion(
        muscle: MuscleGroup.quadriceps,
        path: _svg(s,
          'M 0.41 0.455 '
          // Outer edge — the "quad sweep" bulge
          'C 0.39 0.47, 0.38 0.49, 0.375 0.51 '
          'C 0.37 0.535, 0.368 0.555, 0.37 0.575 '
          'C 0.372 0.595, 0.375 0.61, 0.38 0.625 '
          'C 0.385 0.635, 0.39 0.645, 0.395 0.65 '
          // Knee cap area
          'C 0.40 0.655, 0.405 0.66, 0.41 0.665 '
          // Bottom — slight notch above knee
          'C 0.415 0.665, 0.42 0.665, 0.43 0.665 '
          'C 0.44 0.665, 0.445 0.66, 0.445 0.655 '
          // Inner edge — straighter, less bulge (vastus medialis teardrop)
          'C 0.448 0.645, 0.45 0.63, 0.45 0.615 '
          'C 0.452 0.59, 0.455 0.565, 0.455 0.54 '
          'C 0.455 0.52, 0.455 0.50, 0.455 0.48 '
          // Top — connects at hip crease
          'C 0.45 0.47, 0.44 0.46, 0.43 0.455 '
          'L 0.41 0.455 '
          'Z'
        ),
      ),

      // Right Quadricep
      _MuscleRegion(
        muscle: MuscleGroup.quadriceps,
        path: _svg(s,
          'M 0.59 0.455 '
          'C 0.61 0.47, 0.62 0.49, 0.625 0.51 '
          'C 0.63 0.535, 0.632 0.555, 0.63 0.575 '
          'C 0.628 0.595, 0.625 0.61, 0.62 0.625 '
          'C 0.615 0.635, 0.61 0.645, 0.605 0.65 '
          'C 0.60 0.655, 0.595 0.66, 0.59 0.665 '
          'C 0.585 0.665, 0.58 0.665, 0.57 0.665 '
          'C 0.56 0.665, 0.555 0.66, 0.555 0.655 '
          'C 0.552 0.645, 0.55 0.63, 0.55 0.615 '
          'C 0.548 0.59, 0.545 0.565, 0.545 0.54 '
          'C 0.545 0.52, 0.545 0.50, 0.545 0.48 '
          'C 0.55 0.47, 0.56 0.46, 0.57 0.455 '
          'L 0.59 0.455 '
          'Z'
        ),
      ),

      // Left Adductor — inner thigh triangular shape
      _MuscleRegion(
        muscle: MuscleGroup.adductors,
        path: _svg(s,
          'M 0.455 0.46 '
          'C 0.46 0.47, 0.465 0.475, 0.47 0.48 '
          // Inner edge toward crotch
          'C 0.475 0.49, 0.48 0.50, 0.48 0.51 '
          // Down along inner thigh
          'C 0.475 0.55, 0.47 0.59, 0.465 0.62 '
          'C 0.46 0.64, 0.455 0.65, 0.45 0.655 '
          // Connect to quad inner edge
          'C 0.452 0.63, 0.455 0.59, 0.455 0.55 '
          'C 0.455 0.52, 0.455 0.49, 0.455 0.46 '
          'Z'
        ),
      ),

      // Right Adductor
      _MuscleRegion(
        muscle: MuscleGroup.adductors,
        path: _svg(s,
          'M 0.545 0.46 '
          'C 0.54 0.47, 0.535 0.475, 0.53 0.48 '
          'C 0.525 0.49, 0.52 0.50, 0.52 0.51 '
          'C 0.525 0.55, 0.53 0.59, 0.535 0.62 '
          'C 0.54 0.64, 0.545 0.65, 0.55 0.655 '
          'C 0.548 0.63, 0.545 0.59, 0.545 0.55 '
          'C 0.545 0.52, 0.545 0.49, 0.545 0.46 '
          'Z'
        ),
      ),

      // Calves are only shown in the BACK view (gastrocnemius)
    ];
  }

  // ── BACK VIEW muscle regions ──────────────────────────────────────────────

  static List<_MuscleRegion> backRegions(Size s) {
    return [
      // Traps (back view) — large diamond/kite from neck to mid-back
      _MuscleRegion(
        muscle: MuscleGroup.traps,
        path: _svg(s,
          'M 0.50 0.105 '
          // Upper traps — slope from neck to shoulder tips
          'C 0.47 0.11, 0.42 0.12, 0.36 0.135 '
          'C 0.33 0.145, 0.31 0.155, 0.30 0.16 '
          // Outer edge — curves down along scapula
          'C 0.32 0.175, 0.34 0.19, 0.36 0.20 '
          // Lower traps — diamond point
          'C 0.40 0.22, 0.44 0.24, 0.50 0.26 '
          // Mirror right side
          'C 0.56 0.24, 0.60 0.22, 0.64 0.20 '
          'C 0.66 0.19, 0.68 0.175, 0.70 0.16 '
          'C 0.69 0.155, 0.67 0.145, 0.64 0.135 '
          'C 0.58 0.12, 0.53 0.11, 0.50 0.105 '
          'Z'
        ),
      ),

      // Left Rear Deltoid — cap visible from behind
      _MuscleRegion(
        muscle: MuscleGroup.shoulders,
        path: _svg(s,
          'M 0.33 0.14 '
          'C 0.315 0.135, 0.295 0.14, 0.28 0.15 '
          'C 0.26 0.16, 0.25 0.175, 0.245 0.19 '
          'C 0.245 0.20, 0.25 0.21, 0.255 0.215 '
          'C 0.27 0.21, 0.285 0.205, 0.30 0.20 '
          'C 0.315 0.195, 0.33 0.185, 0.34 0.175 '
          'C 0.34 0.165, 0.34 0.155, 0.335 0.145 '
          'L 0.33 0.14 '
          'Z'
        ),
      ),

      // Right Rear Deltoid
      _MuscleRegion(
        muscle: MuscleGroup.shoulders,
        path: _svg(s,
          'M 0.67 0.14 '
          'C 0.685 0.135, 0.705 0.14, 0.72 0.15 '
          'C 0.74 0.16, 0.75 0.175, 0.755 0.19 '
          'C 0.755 0.20, 0.75 0.21, 0.745 0.215 '
          'C 0.73 0.21, 0.715 0.205, 0.70 0.20 '
          'C 0.685 0.195, 0.67 0.185, 0.66 0.175 '
          'C 0.66 0.165, 0.66 0.155, 0.665 0.145 '
          'L 0.67 0.14 '
          'Z'
        ),
      ),

      // Left Lat — large wing shape creating V-taper
      _MuscleRegion(
        muscle: MuscleGroup.lats,
        path: _svg(s,
          'M 0.34 0.19 '
          // From armpit area curving outward
          'C 0.335 0.20, 0.33 0.215, 0.33 0.23 '
          // Wide sweep outward
          'C 0.33 0.25, 0.335 0.27, 0.34 0.29 '
          'C 0.345 0.31, 0.35 0.33, 0.355 0.35 '
          // Lower lat sweeps inward toward spine
          'C 0.36 0.365, 0.37 0.375, 0.38 0.38 '
          'C 0.40 0.39, 0.42 0.395, 0.45 0.39 '
          // Inner edge along spine
          'C 0.46 0.37, 0.47 0.34, 0.475 0.31 '
          'C 0.48 0.28, 0.485 0.26, 0.49 0.245 '
          // Top connects at mid-back
          'C 0.47 0.24, 0.43 0.225, 0.40 0.215 '
          'C 0.38 0.205, 0.36 0.20, 0.34 0.19 '
          'Z'
        ),
      ),

      // Right Lat
      _MuscleRegion(
        muscle: MuscleGroup.lats,
        path: _svg(s,
          'M 0.66 0.19 '
          'C 0.665 0.20, 0.67 0.215, 0.67 0.23 '
          'C 0.67 0.25, 0.665 0.27, 0.66 0.29 '
          'C 0.655 0.31, 0.65 0.33, 0.645 0.35 '
          'C 0.64 0.365, 0.63 0.375, 0.62 0.38 '
          'C 0.60 0.39, 0.58 0.395, 0.55 0.39 '
          'C 0.54 0.37, 0.53 0.34, 0.525 0.31 '
          'C 0.52 0.28, 0.515 0.26, 0.51 0.245 '
          'C 0.53 0.24, 0.57 0.225, 0.60 0.215 '
          'C 0.62 0.205, 0.64 0.20, 0.66 0.19 '
          'Z'
        ),
      ),

      // Back (Rhomboids / Erectors) — central back between lats
      _MuscleRegion(
        muscle: MuscleGroup.back,
        path: _svg(s,
          'M 0.47 0.26 '
          // Left side of spine
          'C 0.465 0.28, 0.46 0.31, 0.455 0.34 '
          'C 0.45 0.36, 0.45 0.37, 0.455 0.385 '
          // Lower back
          'C 0.46 0.40, 0.47 0.41, 0.48 0.415 '
          'C 0.49 0.42, 0.50 0.42, 0.50 0.42 '
          'C 0.50 0.42, 0.51 0.42, 0.52 0.415 '
          'C 0.53 0.41, 0.54 0.40, 0.545 0.385 '
          // Right side of spine going up
          'C 0.55 0.37, 0.55 0.36, 0.545 0.34 '
          'C 0.54 0.31, 0.535 0.28, 0.53 0.26 '
          // Top
          'L 0.47 0.26 '
          'Z'
        ),
      ),

      // Left Tricep — horseshoe shape on back of upper arm
      _MuscleRegion(
        muscle: MuscleGroup.triceps,
        path: _svg(s,
          'M 0.28 0.215 '
          // Outer head
          'C 0.27 0.23, 0.26 0.25, 0.255 0.27 '
          'C 0.25 0.29, 0.248 0.305, 0.248 0.32 '
          // Elbow
          'C 0.25 0.325, 0.252 0.33, 0.255 0.33 '
          // Inner (long) head
          'C 0.26 0.33, 0.27 0.325, 0.275 0.315 '
          'C 0.28 0.30, 0.285 0.28, 0.29 0.26 '
          'C 0.295 0.245, 0.30 0.23, 0.305 0.22 '
          // Lateral head top
          'C 0.30 0.215, 0.29 0.212, 0.28 0.215 '
          'Z'
        ),
      ),

      // Right Tricep
      _MuscleRegion(
        muscle: MuscleGroup.triceps,
        path: _svg(s,
          'M 0.72 0.215 '
          'C 0.73 0.23, 0.74 0.25, 0.745 0.27 '
          'C 0.75 0.29, 0.752 0.305, 0.752 0.32 '
          'C 0.75 0.325, 0.748 0.33, 0.745 0.33 '
          'C 0.74 0.33, 0.73 0.325, 0.725 0.315 '
          'C 0.72 0.30, 0.715 0.28, 0.71 0.26 '
          'C 0.705 0.245, 0.70 0.23, 0.695 0.22 '
          'C 0.70 0.215, 0.71 0.212, 0.72 0.215 '
          'Z'
        ),
      ),

      // Left Forearm (back view)
      _MuscleRegion(
        muscle: MuscleGroup.forearms,
        path: _svg(s,
          'M 0.248 0.335 '
          'C 0.243 0.35, 0.238 0.365, 0.233 0.38 '
          'C 0.228 0.395, 0.223 0.41, 0.215 0.425 '
          'C 0.21 0.435, 0.205 0.44, 0.20 0.445 '
          'C 0.197 0.448, 0.197 0.448, 0.20 0.45 '
          'C 0.21 0.445, 0.22 0.435, 0.23 0.42 '
          'C 0.24 0.40, 0.245 0.385, 0.25 0.37 '
          'C 0.255 0.355, 0.258 0.345, 0.26 0.335 '
          'C 0.257 0.333, 0.252 0.333, 0.248 0.335 '
          'Z'
        ),
      ),

      // Right Forearm (back view)
      _MuscleRegion(
        muscle: MuscleGroup.forearms,
        path: _svg(s,
          'M 0.752 0.335 '
          'C 0.757 0.35, 0.762 0.365, 0.767 0.38 '
          'C 0.772 0.395, 0.777 0.41, 0.785 0.425 '
          'C 0.79 0.435, 0.795 0.44, 0.80 0.445 '
          'C 0.803 0.448, 0.803 0.448, 0.80 0.45 '
          'C 0.79 0.445, 0.78 0.435, 0.77 0.42 '
          'C 0.76 0.40, 0.755 0.385, 0.75 0.37 '
          'C 0.745 0.355, 0.742 0.345, 0.74 0.335 '
          'C 0.743 0.333, 0.748 0.333, 0.752 0.335 '
          'Z'
        ),
      ),

      // Left Oblique (back view)
      _MuscleRegion(
        muscle: MuscleGroup.obliques,
        path: _svg(s,
          'M 0.355 0.35 '
          'C 0.36 0.365, 0.365 0.375, 0.37 0.385 '
          'C 0.375 0.395, 0.38 0.405, 0.385 0.415 '
          'L 0.45 0.39 '
          'C 0.455 0.375, 0.455 0.36, 0.455 0.345 '
          'L 0.355 0.35 '
          'Z'
        ),
      ),

      // Right Oblique (back view)
      _MuscleRegion(
        muscle: MuscleGroup.obliques,
        path: _svg(s,
          'M 0.645 0.35 '
          'C 0.64 0.365, 0.635 0.375, 0.63 0.385 '
          'C 0.625 0.395, 0.62 0.405, 0.615 0.415 '
          'L 0.55 0.39 '
          'C 0.545 0.375, 0.545 0.36, 0.545 0.345 '
          'L 0.645 0.35 '
          'Z'
        ),
      ),

      // Left Glute — large rounded shape
      _MuscleRegion(
        muscle: MuscleGroup.glutes,
        path: _svg(s,
          'M 0.50 0.425 '
          // Inner upper edge
          'C 0.48 0.425, 0.46 0.42, 0.44 0.42 '
          // Outer curve — hip/glute sweep
          'C 0.42 0.425, 0.40 0.435, 0.39 0.445 '
          'C 0.38 0.455, 0.375 0.465, 0.375 0.475 '
          // Bottom of glute — gluteal fold
          'C 0.38 0.485, 0.39 0.49, 0.41 0.492 '
          'C 0.43 0.494, 0.45 0.49, 0.47 0.485 '
          'C 0.48 0.482, 0.49 0.478, 0.50 0.47 '
          // Inner edge up
          'C 0.50 0.455, 0.50 0.44, 0.50 0.425 '
          'Z'
        ),
      ),

      // Right Glute
      _MuscleRegion(
        muscle: MuscleGroup.glutes,
        path: _svg(s,
          'M 0.50 0.425 '
          'C 0.52 0.425, 0.54 0.42, 0.56 0.42 '
          'C 0.58 0.425, 0.60 0.435, 0.61 0.445 '
          'C 0.62 0.455, 0.625 0.465, 0.625 0.475 '
          'C 0.62 0.485, 0.61 0.49, 0.59 0.492 '
          'C 0.57 0.494, 0.55 0.49, 0.53 0.485 '
          'C 0.52 0.482, 0.51 0.478, 0.50 0.47 '
          'C 0.50 0.455, 0.50 0.44, 0.50 0.425 '
          'Z'
        ),
      ),

      // Left Hamstring — long shape from glute to knee
      _MuscleRegion(
        muscle: MuscleGroup.hamstrings,
        path: _svg(s,
          'M 0.39 0.495 '
          // Outer edge — biceps femoris
          'C 0.385 0.52, 0.38 0.545, 0.378 0.57 '
          'C 0.375 0.59, 0.375 0.61, 0.38 0.625 '
          'C 0.385 0.64, 0.39 0.65, 0.395 0.655 '
          // Knee insertion
          'C 0.40 0.66, 0.405 0.665, 0.41 0.665 '
          'C 0.42 0.665, 0.43 0.665, 0.44 0.66 '
          'C 0.445 0.655, 0.45 0.65, 0.45 0.645 '
          // Inner edge — semitendinosus
          'C 0.452 0.63, 0.455 0.61, 0.455 0.585 '
          'C 0.455 0.56, 0.455 0.54, 0.455 0.52 '
          'C 0.455 0.505, 0.45 0.498, 0.44 0.495 '
          'C 0.42 0.49, 0.40 0.49, 0.39 0.495 '
          'Z'
        ),
      ),

      // Right Hamstring
      _MuscleRegion(
        muscle: MuscleGroup.hamstrings,
        path: _svg(s,
          'M 0.61 0.495 '
          'C 0.615 0.52, 0.62 0.545, 0.622 0.57 '
          'C 0.625 0.59, 0.625 0.61, 0.62 0.625 '
          'C 0.615 0.64, 0.61 0.65, 0.605 0.655 '
          'C 0.60 0.66, 0.595 0.665, 0.59 0.665 '
          'C 0.58 0.665, 0.57 0.665, 0.56 0.66 '
          'C 0.555 0.655, 0.55 0.65, 0.55 0.645 '
          'C 0.548 0.63, 0.545 0.61, 0.545 0.585 '
          'C 0.545 0.56, 0.545 0.54, 0.545 0.52 '
          'C 0.545 0.505, 0.55 0.498, 0.56 0.495 '
          'C 0.58 0.49, 0.60 0.49, 0.61 0.495 '
          'Z'
        ),
      ),

      // Left Calf (back view — gastrocnemius diamond)
      _MuscleRegion(
        muscle: MuscleGroup.calves,
        path: _svg(s,
          'M 0.40 0.675 '
          // Outer head — prominent bulge
          'C 0.395 0.69, 0.39 0.71, 0.39 0.73 '
          // Peak of diamond
          'C 0.39 0.745, 0.393 0.755, 0.395 0.765 '
          // Taper toward Achilles
          'C 0.40 0.785, 0.41 0.81, 0.415 0.835 '
          'C 0.42 0.855, 0.425 0.87, 0.425 0.885 '
          // Inner edge
          'C 0.43 0.87, 0.435 0.85, 0.438 0.83 '
          'C 0.44 0.805, 0.44 0.78, 0.44 0.76 '
          // Inner head
          'C 0.44 0.74, 0.438 0.72, 0.435 0.705 '
          'C 0.43 0.69, 0.425 0.68, 0.42 0.675 '
          'L 0.40 0.675 '
          'Z'
        ),
      ),

      // Right Calf (back view)
      _MuscleRegion(
        muscle: MuscleGroup.calves,
        path: _svg(s,
          'M 0.60 0.675 '
          'C 0.605 0.69, 0.61 0.71, 0.61 0.73 '
          'C 0.61 0.745, 0.607 0.755, 0.605 0.765 '
          'C 0.60 0.785, 0.59 0.81, 0.585 0.835 '
          'C 0.58 0.855, 0.575 0.87, 0.575 0.885 '
          'C 0.57 0.87, 0.565 0.85, 0.562 0.83 '
          'C 0.56 0.805, 0.56 0.78, 0.56 0.76 '
          'C 0.56 0.74, 0.562 0.72, 0.565 0.705 '
          'C 0.57 0.69, 0.575 0.68, 0.58 0.675 '
          'L 0.60 0.675 '
          'Z'
        ),
      ),
    ];
  }
}
