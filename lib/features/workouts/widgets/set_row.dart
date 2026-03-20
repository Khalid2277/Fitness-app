import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';

/// A compact, tappable row for a single set in the active workout.
class SetRow extends StatelessWidget {
  final ExerciseSet exerciseSet;
  final ValueChanged<ExerciseSet> onChanged;
  final VoidCallback? onDismissed;

  const SetRow({
    super.key,
    required this.exerciseSet,
    required this.onChanged,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = exerciseSet.isCompleted;
    final isWarmup = exerciseSet.isWarmup;

    final rowColor = isCompleted
        ? AppColors.accent.withValues(alpha: 0.08)
        : isWarmup
            ? AppColors.warning.withValues(alpha: 0.06)
            : Colors.transparent;

    Widget row = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isCompleted
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.15))
            : null,
      ),
      child: Row(
        children: [
          // Set number / warmup toggle
          GestureDetector(
            onTap: () => onChanged(
              exerciseSet.copyWith(isWarmup: !exerciseSet.isWarmup),
            ),
            child: Container(
              width: 36,
              alignment: Alignment.center,
              child: isWarmup
                  ? Text(
                      'W',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      '${exerciseSet.setNumber}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isCompleted
                            ? AppColors.accent
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Weight input
          Expanded(
            flex: 3,
            child: _CompactInput(
              value: exerciseSet.weight?.toString() ?? '',
              hint: 'kg',
              isDecimal: true,
              isDark: isDark,
              onChanged: (v) {
                final w = double.tryParse(v);
                onChanged(exerciseSet.copyWith(weight: w));
              },
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Reps input
          Expanded(
            flex: 3,
            child: _CompactInput(
              value: exerciseSet.reps?.toString() ?? '',
              hint: 'reps',
              isDecimal: false,
              isDark: isDark,
              onChanged: (v) {
                final r = int.tryParse(v);
                onChanged(exerciseSet.copyWith(reps: r));
              },
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // RPE input (optional)
          Expanded(
            flex: 2,
            child: _CompactInput(
              value: exerciseSet.rpe?.toString() ?? '',
              hint: 'RPE',
              isDecimal: true,
              isDark: isDark,
              onChanged: (v) {
                final rpe = double.tryParse(v);
                onChanged(exerciseSet.copyWith(rpe: rpe));
              },
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Completion checkbox
          GestureDetector(
            onTap: () => onChanged(
              exerciseSet.copyWith(isCompleted: !exerciseSet.isCompleted),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.accent
                      : isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : cs.outline.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );

    if (onDismissed != null) {
      row = Dismissible(
        key: ValueKey('set_${exerciseSet.setNumber}_${exerciseSet.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
        ),
        onDismissed: (_) => onDismissed!(),
        child: row,
      );
    }

    return row;
  }
}

class _CompactInput extends StatefulWidget {
  final String value;
  final String hint;
  final bool isDecimal;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CompactInput({
    required this.value,
    required this.hint,
    required this.isDecimal,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_CompactInput> createState() => _CompactInputState();
}

class _CompactInputState extends State<_CompactInput> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_CompactInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onFocusChange: (focused) {
        setState(() => _hasFocus = focused);
        if (!focused) {
          widget.onChanged(_controller.text);
        }
      },
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
        inputFormatters: [
          if (widget.isDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          filled: true,
          fillColor: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surfaceLight2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
        ),
        onSubmitted: widget.onChanged,
      ),
    );
  }
}
