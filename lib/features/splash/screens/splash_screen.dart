import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _particleController;
  late final AnimationController _progressController;

  bool _showTagline = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    // Show tagline after logo animates in
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showTagline = true);
    });

    // Navigate after splash completes
    Future.delayed(const Duration(milliseconds: 2800), _navigateAway);
  }

  void _navigateAway() {
    if (!mounted || _navigating) return;
    _navigating = true;
    context.go('/auth');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Immersive status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.primaryDark,
                    AppColors.primaryDarkElevated,
                    AppColors.primaryBlueSurface,
                  ]
                : [
                    const Color(0xFFF0F0FF),
                    const Color(0xFFE8E5FF),
                    const Color(0xFFDDD8FF),
                  ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated background particles
            _FloatingParticles(
              controller: _particleController,
              isDark: isDark,
            ),

            // Main content column — centered on screen
            Center(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with glowing orb and spinning ring behind it
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing orb behind logo
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.2);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.18),
                                  AppColors.primaryBlue.withValues(alpha: 0.06),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Spinning ring
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _ringController.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(170, 170),
                            painter: _OrbitRingPainter(
                              progress: _ringController.value,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        );
                      },
                    ),

                    // Logo with gradient border
                    _LogoWidget(isDark: isDark),
                  ],
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: AppSpacing.xxl),

                // "ALFA" gradient text
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'ALFA',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.4, delay: 300.ms, duration: 700.ms,
                        curve: Curves.easeOutCubic),

                const SizedBox(height: AppSpacing.xs),

                // "NUTRITION" subtitle
                Text(
                  'NUTRITION',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: 0.3, delay: 500.ms, duration: 600.ms),

                const SizedBox(height: AppSpacing.lg),

                // Tagline
                AnimatedOpacity(
                  opacity: _showTagline ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: _showTagline ? Offset.zero : const Offset(0, 0.3),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: Text(
                      'Your AI-Powered Fitness Companion',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                                letterSpacing: 0.5,
                              ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxxl),

                // Gradient progress bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Container(
                      width: 180,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.borderRadiusPill,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.borderRadiusPill,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms),
              ],
            ),
            ),

            // Bottom branding
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              child: Text(
                'by Alfa Tech Labs',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      letterSpacing: 1.0,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 1400.ms, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo widget with gradient border and inner glow
// ---------------------------------------------------------------------------

class _LogoWidget extends StatelessWidget {
  final bool isDark;
  const _LogoWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
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
            color: AppColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppColors.backgroundDark
              : AppColors.surfaceLight,
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orbit ring painter
// ---------------------------------------------------------------------------

class _OrbitRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dotted orbit ring
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, dotPaint);

    // Draw accent arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, progress * 2 * math.pi, math.pi * 0.4, false, arcPaint);

    // Draw small orbiting dot
    final dotAngle = progress * 2 * math.pi;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(dotX, dotY), 5, glowPaint);

    final solidPaint = Paint()..color = color;
    canvas.drawCircle(Offset(dotX, dotY), 3, solidPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Floating particles background
// ---------------------------------------------------------------------------

class _FloatingParticles extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _FloatingParticles({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            progress: controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  static final List<_Particle> _particles = List.generate(25, (i) {
    final rng = math.Random(i * 42);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.5 + rng.nextDouble() * 3,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * 2 * math.pi,
    );
  });

  _ParticlePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final yOffset = math.sin(progress * 2 * math.pi * p.speed + p.phase) * 20;
      final alpha = 0.08 + 0.12 * math.sin(progress * 2 * math.pi * p.speed + p.phase).abs();

      final paint = Paint()
        ..color = (isDark ? AppColors.primaryBlueLight : AppColors.primaryBlue)
            .withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + yOffset),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
