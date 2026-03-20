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
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';
import 'package:alfanutrition/features/workouts/widgets/exercise_picker_sheet.dart';
import 'package:alfanutrition/features/workouts/widgets/set_row.dart';

/// Structured workout logging screen.
///
/// This is a CRUD form — not a live session. Users fill in their workout
/// details (date, name, exercises, sets/reps/weight, notes) and tap Save.
/// All sets are marked `isCompleted: true` on save.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  /// Pass an existing [Workout] to edit it instead of creating a new one.
  final Workout? editingWorkout;

  const LogWorkoutScreen({super.key, this.editingWorkout});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  static const _uuid = Uuid();

  late DateTime _selectedDate;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  List<WorkoutExercise> _exercises = [];
  bool _isSaving = false;

  bool get _isEditing => widget.editingWorkout != null;

  @override
  void initState() {
    super.initState();
    final workout = widget.editingWorkout;
    if (workout != null) {
      _selectedDate = workout.date;
      _nameController = TextEditingController(text: workout.name);
      _notesController = TextEditingController(text: workout.notes ?? '');
      _durationController = TextEditingController(
        text: workout.durationSeconds > 0
            ? workout.duration.inMinutes.toString()
            : '',
      );
      _exercises = workout.exercises
          .map((e) => e.copyWith(sets: List.from(e.sets)))
          .toList();
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _nameController = TextEditingController(text: 'Workout');
      _notesController = TextEditingController();
      _durationController = TextEditingController();
      _exercises = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ── Date Picker ──────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Exercise Management ──────────────────────────────────────────────

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        onExerciseSelected: (exercise) {
          setState(() {
            _exercises.add(
              WorkoutExercise(
                id: _uuid.v4(),
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                sets: [ExerciseSet(setNumber: 1)],
                primaryMuscle: exercise.primaryMuscle,
              ),
            );
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _exercises.removeAt(index));
  }

  // ── Set Management ───────────────────────────────────────────────────

  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
      final newSet = ExerciseSet(
        setNumber: exercise.sets.length + 1,
        weight: lastSet?.weight,
        reps: lastSet?.reps,
      );
      _exercises[exerciseIndex] = exercise.copyWith(
        sets: [...exercise.sets, newSet],
      );
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final sets = List<ExerciseSet>.from(exercise.sets);
      sets.removeAt(setIndex);
      // Re-number
      for (int i = 0; i < sets.length; i++) {
        sets[i] = sets[i].copyWith(setNumber: i + 1);
      }
      _exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    });
  }

  void _updateSet(int exerciseIndex, int setIndex, ExerciseSet updated) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final sets = List<ExerciseSet>.from(exercise.sets);
      sets[setIndex] = updated;
      _exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    });
  }

  void _updateExerciseNotes(int exerciseIndex, String notes) {
    setState(() {
      _exercises[exerciseIndex] =
          _exercises[exerciseIndex].copyWith(notes: notes.isEmpty ? null : notes);
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Mark all sets as completed (this is a log, not a live session)
      final completedExercises = _exercises.map((exercise) {
        final completedSets = exercise.sets
            .map((s) => s.copyWith(isCompleted: true))
            .toList();
        return exercise.copyWith(sets: completedSets);
      }).toList();

      final durationMinutes = int.tryParse(_durationController.text) ?? 0;

      final workout = Workout(
        id: widget.editingWorkout?.id ?? _uuid.v4(),
        name: _nameController.text.trim().isEmpty
            ? 'Workout'
            : _nameController.text.trim(),
        date: _selectedDate,
        durationSeconds: durationMinutes * 60,
        exercises: completedExercises,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isCompleted: true,
      );

      await ref.read(workoutHistoryProvider.notifier).addWorkout(workout);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Workout updated' : 'Workout saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Discard Confirmation ──────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (_exercises.isEmpty && _notesController.text.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _exercises.isEmpty && _notesController.text.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Workout' : 'Log Workout',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (_exercises.isEmpty && _notesController.text.isEmpty) {
                context.pop();
              } else {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) context.pop();
              }
            },
          ),
          actions: [
            // Save button in app bar
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              // ── Date Selector Card ──
              _SectionCard(
                isDark: isDark,
                theme: theme,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: AppSpacing.borderRadiusLg,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy')
                                    .format(_selectedDate),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),

              const SizedBox(height: AppSpacing.md),

              // ── Workout Name & Duration ──
              _SectionCard(
                isDark: isDark,
                theme: theme,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workout name
                      TextField(
                        controller: _nameController,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Workout Name',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          hintText: 'e.g. Push Day, Leg Day...',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Duration
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          hintText: 'e.g. 60',
                          prefixIcon: const Icon(
                            Icons.timer_outlined,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 50.ms).slideY(begin: 0.03),

              const SizedBox(height: AppSpacing.xl),

              // ── Exercises Header ──
              Row(
                children: [
                  Text(
                    'EXERCISES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (_exercises.isNotEmpty)
                    Text(
                      '${_exercises.length} exercise${_exercises.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: AppSpacing.md),

              // ── Exercise Cards ──
              ..._exercises.asMap().entries.map((entry) {
                final exIdx = entry.key;
                final exercise = entry.value;
                return _ExerciseCard(
                  key: ValueKey(exercise.id),
                  exerciseIndex: exIdx,
                  exercise: exercise,
                  isDark: isDark,
                  theme: theme,
                  onAddSet: () => _addSet(exIdx),
                  onRemoveSet: (setIdx) => _removeSet(exIdx, setIdx),
                  onUpdateSet: (setIdx, updated) =>
                      _updateSet(exIdx, setIdx, updated),
                  onUpdateNotes: (notes) =>
                      _updateExerciseNotes(exIdx, notes),
                  onRemoveExercise: () => _removeExercise(exIdx),
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: (100 + 50 * exIdx).ms,
                    ).slideY(begin: 0.03);
              }),

              const SizedBox(height: AppSpacing.md),

              // ── Add Exercise Button ──
              _AddExerciseButton(
                isDark: isDark,
                theme: theme,
                onTap: _addExercise,
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

              const SizedBox(height: AppSpacing.xl),

              // ── Notes ──
              _SectionCard(
                isDark: isDark,
                theme: theme,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Workout Notes (optional)',
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      hintText: 'How did it feel? Anything to remember...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save Button ──
              DecoratedBox(
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Workout' : 'Save Workout',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.theme,
    required this.child,
  });
  final bool isDark;
  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise Card
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    super.key,
    required this.exerciseIndex,
    required this.exercise,
    required this.isDark,
    required this.theme,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onUpdateNotes,
    required this.onRemoveExercise,
  });

  final int exerciseIndex;
  final WorkoutExercise exercise;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int setIndex, ExerciseSet updated) onUpdateSet;
  final ValueChanged<String> onUpdateNotes;
  final VoidCallback onRemoveExercise;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showNotes = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.exercise.notes ?? '');
    _showNotes = widget.exercise.notes != null &&
        widget.exercise.notes!.isNotEmpty;
  }

  @override
  void didUpdateWidget(_ExerciseCard old) {
    super.didUpdateWidget(old);
    if (old.exercise.notes != widget.exercise.notes) {
      _notesController.text = widget.exercise.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForMuscle(widget.exercise.primaryMuscle);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow: widget.isDark
            ? AppColors.cardShadowDark
            : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.exerciseIndex + 1}',
                      style: widget.theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.exerciseName,
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.exercise.primaryMuscle.displayName,
                        style: widget.theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notes toggle
                IconButton(
                  icon: Icon(
                    _showNotes
                        ? Icons.sticky_note_2_rounded
                        : Icons.sticky_note_2_outlined,
                    size: 20,
                    color: _showNotes
                        ? AppColors.primaryBlue
                        : widget.isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                  ),
                  onPressed: () => setState(() => _showNotes = !_showNotes),
                  tooltip: 'Exercise notes',
                ),
                // Delete exercise
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: widget.onRemoveExercise,
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
          ),

          // Notes field (collapsible)
          if (_showNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _notesController,
                style: widget.theme.textTheme.bodySmall,
                maxLines: 2,
                onChanged: widget.onUpdateNotes,
                decoration: InputDecoration(
                  hintText: 'Exercise notes...',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),

          // Set header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    'SET',
                    textAlign: TextAlign.center,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: widget.isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 3,
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: widget.isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: widget.isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Text(
                    'RPE',
                    textAlign: TextAlign.center,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: widget.isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 32), // checkbox space
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Set rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: widget.exercise.sets.asMap().entries.map((setEntry) {
                final sIdx = setEntry.key;
                final set = setEntry.value;
                return SetRow(
                  exerciseSet: set,
                  onChanged: (updated) =>
                      widget.onUpdateSet(sIdx, updated),
                  onDismissed: widget.exercise.sets.length > 1
                      ? () => widget.onRemoveSet(sIdx)
                      : null,
                );
              }).toList(),
            ),
          ),

          // Add set button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: GestureDetector(
              onTap: widget.onAddSet,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  color: AppColors.primaryBlue.withValues(alpha: 0.04),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Add Set',
                      style: widget.theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Exercise Button
// ─────────────────────────────────────────────────────────────────────────────

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({
    required this.isDark,
    required this.theme,
    required this.onTap,
  });
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            width: 1.5,
          ),
          color: AppColors.primaryBlue.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.primaryBlue,
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
    );
  }
}
