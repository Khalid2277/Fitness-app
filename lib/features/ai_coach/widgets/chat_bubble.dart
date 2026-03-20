import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/ai_coach/providers/ai_coach_providers.dart';
import 'package:alfanutrition/features/ai_coach/widgets/suggestion_chip.dart';

/// Renders a single chat message — either a user bubble (right-aligned,
/// primary fill) or an AI bubble (left-aligned, dark surface) with optional
/// insight card header and suggestion chips.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String suggestion) onSuggestionTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isUser) {
      return _UserBubble(message: message, theme: theme);
    }

    return _AiBubble(
      message: message,
      theme: theme,
      isDark: isDark,
      onSuggestionTap: onSuggestionTap,
    );
  }
}

// ─────────────────────────── User Bubble ───────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;

  const _UserBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
        right: AppSpacing.xl,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.xs),
              ),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(
              DateFormat.jm().format(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────── AI Bubble ─────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;
  final bool isDark;
  final void Function(String) onSuggestionTap;

  const _AiBubble({
    required this.message,
    required this.theme,
    required this.isDark,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasInsight = message.insightTitle != null;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: 60,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bot indicator ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${AppConstants.appName} AI',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryBlueLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Message card ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.xs),
                topRight: Radius.circular(AppSpacing.radiusLg),
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.radiusLg),
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Insight header
                if (hasInsight) ...[
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Icon(
                          message.insightIcon ?? Icons.lightbulb_rounded,
                          size: 18,
                          color: AppColors.primaryBlueLight,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          message.insightTitle!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primaryBlueLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Message body — renders tables, bold, bullets
                _RichContent(
                  content: message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ) ?? const TextStyle(),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Timestamp ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              DateFormat.jm().format(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ),

          // ── Suggestion chips ────────────────────────────────────────────
          if (message.suggestions != null &&
              message.suggestions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: message.suggestions!
                  .map(
                    (s) => SuggestionChip(
                      label: s,
                      onTap: () => onSuggestionTap(s),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.05, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────── Rich Content ──────────────────────────────────

/// Parses and renders simple markdown-like content: **bold**, - bullets,
/// numbered lists, and pipe-delimited tables.
class _RichContent extends StatelessWidget {
  final String content;
  final TextStyle style;
  final bool isDark;

  const _RichContent({
    required this.content,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // ── Table detection (lines starting with |)
      if (line.trimLeft().startsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trimLeft().startsWith('|')) {
          tableLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildTable(tableLines, context));
        continue;
      }

      // ── Empty line → spacing
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
        i++;
        continue;
      }

      // ── Bullet point (- or •)
      final bulletMatch = RegExp(r'^(\s*)([-•])\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: style.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: _buildRichText(bulletMatch.group(3)!)),
            ],
          ),
        ));
        i++;
        continue;
      }

      // ── Numbered list (1. 2. etc.)
      final numMatch = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(line);
      if (numMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${numMatch.group(1)}.',
                  style: style.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(child: _buildRichText(numMatch.group(2)!)),
            ],
          ),
        ));
        i++;
        continue;
      }

      // ── Regular text
      widgets.add(_buildRichText(line));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Builds a RichText widget with **bold** and regular spans.
  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }

  /// Builds a table widget from pipe-delimited lines.
  Widget _buildTable(List<String> lines, BuildContext context) {
    // Parse rows, skip separator lines (|---|---|)
    final rows = <List<String>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      // Skip separator lines
      if (RegExp(r'^[|\s:-]+$').hasMatch(trimmed)) continue;
      final cells = trimmed
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) rows.add(cells);
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final isHeader = rows.length > 1;
    final headerColor = AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08);
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusSm,
        child: Table(
          border: TableBorder.all(color: borderColor, width: 0.5),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows.asMap().entries.map((entry) {
            final isFirstRow = entry.key == 0 && isHeader;
            return TableRow(
              decoration: isFirstRow
                  ? BoxDecoration(color: headerColor)
                  : null,
              children: entry.value.map((cell) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: Text(
                    cell,
                    style: style.copyWith(
                      fontWeight: isFirstRow ? FontWeight.w700 : null,
                      fontSize: (style.fontSize ?? 14) - 1,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
