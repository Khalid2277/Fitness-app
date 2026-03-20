import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// The bot avatar + branding card displayed at the top of the AI Coach chat.
class AiWelcomeCard extends StatelessWidget {
  const AiWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),

        // ── Avatar circle with gradient ────────────────────────────────────
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Brand name ─────────────────────────────────────────────────────
        Text(
          'AlfaNutrition Coach',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // ── Subtitle ───────────────────────────────────────────────────────
        Text(
          'Ask about nutrition, training, or recovery',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.1,
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, duration: 500.ms, curve: Curves.easeOut);
  }
}
