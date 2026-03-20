import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';
import 'package:alfanutrition/features/workouts/widgets/exercise_picker_sheet.dart';

// ─────────────────────────── Log Workout Screen ───────────────────────────

/// A premium manual workout logging screen for recording past workouts.
/// Allows selecting a date, naming the workout, setting duration,
/// adding exercises with sets, and saving to history.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  final Workout? editingWorkout;

  const LogWorkoutScreen({super.key, this.editingWorkout});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  static const _uuid = Uuid();

  DateTime _selectedDate = DateTime.now();
  final _nameController = TextEditingController(text: 'Workout');
  final _durationController = TextEditingController(text: '60');
  final _notesController = TextEditingController();
  final List<_LogExercise> _exercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.editingWorkout;
    if (w != null) {
      _selectedDate = w.date;
      _nameController.text = w.name;
      _durationController.text = (w.durationSeconds ~/ 60).toString();
      _notesController.text = w.notes ?? '';
      _exercises.addAll(w.exercises.map((e) => _LogExercise(
            id: e.id,
            exerciseId: e.exerciseId,
            exerciseName: e.exerciseName,
            primaryMuscle: e.primaryMuscle,
            notes: e.notes,
            sets: e.sets
                .map((s) => _LogSet(
                      setNumber: s.setNumber,
                      weight: s.weight,
                      reps: s.reps,
                      rpe: s.rpe,
                      isWarmup: s.isWarmup,
                    ))
                .toList(),
          )));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Date picker ──
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Exercise picker ──
  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        onExerciseSelected: (Exercise exercise) {
          setState(() {
            _exercises.add(
              _LogExercise(
                id: _uuid.v4(),
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                primaryMuscle: exercise.primaryMuscle,
                sets: [_LogSet(setNumber: 1)],
              ),
            );
          });
        },
      ),
    );
  }

  // ── Add set ──
  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
      exercise.sets.add(
        _LogSet(
          setNumber: exercise.sets.length + 1,
          weight: lastSet?.weight,
          reps: lastSet?.reps,
        ),
      );
    });
  }

  // ── Remove set ──
  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      exercise.sets.removeAt(setIndex);
      // Re-number sets
      for (int i = 0; i < exercise.sets.length; i++) {
        exercise.sets[i].setNumber = i + 1;
      }
    });
  }

  // ── Remove exercise ──
  void _removeExercise(int exerciseIndex) {
    setState(() => _exercises.removeAt(exerciseIndex));
  }

  // ── Update set ──
  void _updateSet(int exerciseIndex, int setIndex, _LogSet updatedSet) {
    setState(() {
      _exercises[exerciseIndex].sets[setIndex] = updatedSet;
    });
  }

  // ── Update exercise notes ──
  void _updateExerciseNotes(int exerciseIndex, String notes) {
    _exercises[exerciseIndex].notes = notes;
  }

  // ── Save workout ──
  Future<void> _saveWorkout() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add at least one exercise first'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      );
      return;
    }

    final durationMinutes = int.tryParse(_durationController.text) ?? 60;

    setState(() => _isSaving = true);

    final workout = Workout(
      id: _uuid.v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Workout'
          : _nameController.text.trim(),
      date: _selectedDate,
      durationSeconds: durationMinutes * 60,
      exercises: _exercises.map((e) {
        return WorkoutExercise(
          id: e.id,
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          primaryMuscle: e.primaryMuscle,
          notes: e.notes,
          sets: e.sets.map((s) {
            return ExerciseSet(
              setNumber: s.setNumber,
              weight: s.weight,
              reps: s.reps,
              rpe: s.rpe,
              isCompleted: true,
              isWarmup: s.isWarmup,
            );
          }).toList(),
        );
      }).toList(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isCompleted: true,
    );

    await ref.read(workoutHistoryProvider.notifier).addWorkout(workout);

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _PremiumAppBar(
              isDark: isDark,
              onClose: () => context.pop(),
              onSave: _saveWorkout,
              isSaving: _isSaving,
            ),

            // ── Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxxxl * 2,
                ),
                children: [
                  // ── Date Card ──
                  _DateCard(
                    selectedDate: _selectedDate,
                    onTap: _pickDate,
                    isDark: isDark,
                  ).animate().fadeIn(duration: 400.ms).slideY(
                        begin: 0.05,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Workout Name & Duration ──
                  _WorkoutInfoCard(
                    nameController: _nameController,
                    durationController: _durationController,
                    isDark: isDark,
                  ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(
                        begin: 0.05,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Exercises Section Header ──
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Exercises',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_exercises.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            '${_exercises.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ).animate(delay: 160.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Exercises List or Empty State ──
                  if (_exercises.isEmpty)
                    _EmptyExercisesState(
                      isDark: isDark,
                      onAdd: _showExercisePicker,
                    )
                        .animate(delay: 240.ms)
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        )
                  else ...[
                    ..._exercises.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final exercise = entry.value;
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _ExerciseCard(
                          exercise: exercise,
                          exerciseIndex: idx,
                          isDark: isDark,
                          onAddSet: () => _addSet(idx),
                          onRemoveSet: (setIdx) =>
                              _removeSet(idx, setIdx),
                          onRemoveExercise: () => _removeExercise(idx),
                          onUpdateSet: (setIdx, updated) =>
                              _updateSet(idx, setIdx, updated),
                          onUpdateNotes: (notes) =>
                              _updateExerciseNotes(idx, notes),
                        )
                            .animate(
                                delay: Duration(
                                    milliseconds: 200 + (idx * 80)))
                            .fadeIn(duration: 300.ms)
                            .slideY(
                              begin: 0.03,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                      );
                    }),
                    // ── Add Exercise Button ──
                    _AddExerciseButton(
                      onTap: _showExercisePicker,
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Notes Section ──
                  _NotesSection(
                    controller: _notesController,
                    isDark: isDark,
                  )
                      .animate(delay: 320.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.05,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Save Button ──
                  _SaveButton(
                    onTap: _saveWorkout,
                    isSaving: _isSaving,
                    isDark: isDark,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.05,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DATA MODELS (local to this screen)
// ════════════════════════════════════════════════════════════════════════════

class _LogExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final MuscleGroup primaryMuscle;
  List<_LogSet> sets;
  String? notes;
  bool showNotes;

  _LogExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscle,
    required this.sets,
    this.notes,
    this.showNotes = false,
  });
}

class _LogSet {
  int setNumber;
  double? weight;
  int? reps;
  double? rpe;
  bool isWarmup;

  _LogSet({
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.isWarmup = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// PREMIUM APP BAR
// ════════════════════════════════════════════════════════════════════════════

class _PremiumAppBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool isSaving;

  const _PremiumAppBar({
    required this.isDark,
    required this.onClose,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.dividerLight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.dividerLight,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Log Workout',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Save pill
          GestureDetector(
            onTap: isSaving ? null : onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DATE CARD — Glassmorphism style with gradient tint
// ════════════════════════════════════════════════════════════════════════════

class _DateCard extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final bool isDark;

  const _DateCard({
    required this.selectedDate,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(selectedDate);
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryBlue.withValues(alpha: 0.08),
                        AppColors.surfaceDark1,
                      ]
                    : [
                        AppColors.primaryBlue.withValues(alpha: 0.04),
                        AppColors.surfaceLight.withValues(alpha: 0.95),
                      ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark
                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
              boxShadow:
                  isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
            ),
            child: Row(
              children: [
                // Calendar icon container with gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                        AppColors.primaryBlue.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('d').format(selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(selectedDate).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryBlue.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        isToday ? 'Today' : _relativeDate(selectedDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isToday
                              ? AppColors.accent
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                          fontWeight:
                              isToday ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated chevron
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(2 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return DateFormat('MMM d').format(date);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WORKOUT INFO CARD — Name & Duration grouped together
// ════════════════════════════════════════════════════════════════════════════

class _WorkoutInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController durationController;
  final bool isDark;

  const _WorkoutInfoCard({
    required this.nameController,
    required this.durationController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          // Workout Name
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                        AppColors.primaryBlue.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Workout name',
                      hintStyle: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.dividerLight.withValues(alpha: 0.5),
            ),
          ),

          // Duration
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.15),
                        AppColors.accent.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : AppColors.accentSurface
                                    .withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'minutes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION CARD — Reusable wrapper
// ════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const _SectionCard({
    required this.child,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXERCISE CARD — Premium with gradient accent strip
// ════════════════════════════════════════════════════════════════════════════

class _ExerciseCard extends StatelessWidget {
  final _LogExercise exercise;
  final int exerciseIndex;
  final bool isDark;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onRemoveExercise;
  final void Function(int setIdx, _LogSet updated) onUpdateSet;
  final ValueChanged<String> onUpdateNotes;

  const _ExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.isDark,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onUpdateSet,
    required this.onUpdateNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muscleColor = AppColors.colorForMuscle(exercise.primaryMuscle);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left gradient accent strip
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  muscleColor,
                  muscleColor.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Muscle icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: muscleColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          size: 18,
                          color: muscleColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: muscleColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  exercise.primaryMuscle.displayName
                                      .toUpperCase(),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: muscleColor,
                                    letterSpacing: 1.0,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            onRemoveExercise();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.error),
                                SizedBox(width: AppSpacing.sm),
                                Text('Remove'),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Set header row with tinted background
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.surfaceLight2.withValues(alpha: 0.7),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          'SET',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'KG',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'REPS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'RPE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Space for warmup toggle
                      const SizedBox(width: AppSpacing.xxxl),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Sets
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Column(
                    children: exercise.sets.asMap().entries.map((entry) {
                      final setIdx = entry.key;
                      final set = entry.value;

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _SetRow(
                          set: set,
                          isDark: isDark,
                          canDelete: exercise.sets.length > 1,
                          onChanged: (updated) =>
                              onUpdateSet(setIdx, updated),
                          onDismissed: () => onRemoveSet(setIdx),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Add Set button — filled accent style
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: GestureDetector(
                    onTap: onAddSet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue
                            .withValues(alpha: isDark ? 0.12 : 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Add Set',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Notes toggle & field
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _ExerciseNotesField(
                    initialNotes: exercise.notes,
                    showNotes: exercise.showNotes,
                    isDark: isDark,
                    onToggle: () {
                      // This triggers a rebuild via setState in parent
                      exercise.showNotes = !exercise.showNotes;
                      // Force update
                      onUpdateNotes(exercise.notes ?? '');
                    },
                    onChanged: onUpdateNotes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXERCISE NOTES FIELD
// ════════════════════════════════════════════════════════════════════════════

class _ExerciseNotesField extends StatefulWidget {
  final String? initialNotes;
  final bool showNotes;
  final bool isDark;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _ExerciseNotesField({
    required this.initialNotes,
    required this.showNotes,
    required this.isDark,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_ExerciseNotesField> createState() => _ExerciseNotesFieldState();
}

class _ExerciseNotesFieldState extends State<_ExerciseNotesField> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.showNotes ||
        (widget.initialNotes != null && widget.initialNotes!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onToggle();
            },
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.edit_note_rounded
                      : Icons.add_comment_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _isExpanded ? 'Note' : 'Add note...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              onChanged: widget.onChanged,
              controller:
                  TextEditingController(text: widget.initialNotes ?? ''),
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a note for this exercise...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppColors.surfaceLight2.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.dividerLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: BorderSide(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.dividerLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SET ROW — Compact input row for a single set
// ════════════════════════════════════════════════════════════════════════════

class _SetRow extends StatelessWidget {
  final _LogSet set;
  final bool isDark;
  final bool canDelete;
  final ValueChanged<_LogSet> onChanged;
  final VoidCallback onDismissed;

  const _SetRow({
    required this.set,
    required this.isDark,
    required this.canDelete,
    required this.onChanged,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isWarmup = set.isWarmup;

    final rowColor = isWarmup
        ? AppColors.warning.withValues(alpha: 0.06)
        : Colors.transparent;

    Widget row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: isWarmup
            ? Border.all(
                color: AppColors.warning.withValues(alpha: 0.12))
            : null,
      ),
      child: Row(
        children: [
          // Set number / warmup toggle
          GestureDetector(
            onTap: () => onChanged(
              _LogSet(
                setNumber: set.setNumber,
                weight: set.weight,
                reps: set.reps,
                rpe: set.rpe,
                isWarmup: !set.isWarmup,
              ),
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
                      '${set.setNumber}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Weight
          Expanded(
            flex: 3,
            child: _InlineInput(
              value: set.weight?.toString() ?? '',
              hint: 'kg',
              isDecimal: true,
              isDark: isDark,
              onChanged: (v) {
                final w = double.tryParse(v);
                onChanged(_LogSet(
                  setNumber: set.setNumber,
                  weight: w,
                  reps: set.reps,
                  rpe: set.rpe,
                  isWarmup: set.isWarmup,
                ));
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Reps
          Expanded(
            flex: 3,
            child: _InlineInput(
              value: set.reps?.toString() ?? '',
              hint: 'reps',
              isDecimal: false,
              isDark: isDark,
              onChanged: (v) {
                final r = int.tryParse(v);
                onChanged(_LogSet(
                  setNumber: set.setNumber,
                  weight: set.weight,
                  reps: r,
                  rpe: set.rpe,
                  isWarmup: set.isWarmup,
                ));
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // RPE
          Expanded(
            flex: 2,
            child: _InlineInput(
              value: set.rpe?.toString() ?? '',
              hint: 'RPE',
              isDecimal: true,
              isDark: isDark,
              onChanged: (v) {
                final rpe = double.tryParse(v);
                onChanged(_LogSet(
                  setNumber: set.setNumber,
                  weight: set.weight,
                  reps: set.reps,
                  rpe: rpe,
                  isWarmup: set.isWarmup,
                ));
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Delete button (instead of completion checkbox, since these are logged)
          GestureDetector(
            onTap: canDelete ? onDismissed : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: canDelete
                    ? AppColors.error.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.remove_circle_outline_rounded,
                size: 18,
                color: canDelete
                    ? AppColors.error.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );

    return row;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INLINE INPUT — Compact text field for set values
// ════════════════════════════════════════════════════════════════════════════

class _InlineInput extends StatefulWidget {
  final String value;
  final String hint;
  final bool isDecimal;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _InlineInput({
    required this.value,
    required this.hint,
    required this.isDecimal,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_InlineInput> createState() => _InlineInputState();
}

class _InlineInputState extends State<_InlineInput> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_InlineInput oldWidget) {
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
        keyboardType:
            TextInputType.numberWithOptions(decimal: widget.isDecimal),
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
            color: theme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          filled: true,
          fillColor: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.surfaceLight2,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: widget.onChanged,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADD EXERCISE BUTTON — Premium dashed-outline CTA
// ════════════════════════════════════════════════════════════════════════════

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddExerciseButton({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          radius: AppSpacing.radiusMd,
          strokeWidth: 1.5,
          dashWidth: 8,
          dashSpace: 5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue
                    .withValues(alpha: isDark ? 0.08 : 0.03),
                AppColors.primaryBlue
                    .withValues(alpha: isDark ? 0.04 : 0.01),
              ],
            ),
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primaryBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Add Exercise',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DASHED BORDER PAINTER
// ════════════════════════════════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0, metric.length);
        dashPath.addPath(
          metric.extractPath(start, end.toDouble()),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      strokeWidth != oldDelegate.strokeWidth;
}

// ════════════════════════════════════════════════════════════════════════════
// NOTES SECTION — Premium treatment with icon
// ════════════════════════════════════════════════════════════════════════════

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _NotesSection({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.sticky_note_2_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Workout Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 3,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'How did the workout feel? Any observations...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.surfaceLight2.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.dividerLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.dividerLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SAVE BUTTON — Gradient CTA
// ════════════════════════════════════════════════════════════════════════════

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSaving;
  final bool isDark;

  const _SaveButton({
    required this.onTap,
    required this.isSaving,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSaving ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg + 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Save Workout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY EXERCISES STATE
// ════════════════════════════════════════════════════════════════════════════

class _EmptyExercisesState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyExercisesState({
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxxl,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : AppColors.surfaceLight2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.dividerLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  AppColors.accent
                      .withValues(alpha: isDark ? 0.1 : 0.06),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 30,
              color: AppColors.primaryBlue
                  .withValues(alpha: isDark ? 0.7 : 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No exercises yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add exercises to log your workout',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _AddExerciseButton(onTap: onAdd, isDark: isDark),
        ],
      ),
    );
  }
}
