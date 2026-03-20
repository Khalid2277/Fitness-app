import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';
import 'package:alfanutrition/features/workouts/widgets/exercise_picker_sheet.dart';
import 'package:alfanutrition/features/workouts/widgets/set_row.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late final TextEditingController _nameController;
  bool _isTimerRunning = false;
  bool _isEditingName = false;

  // Rest timer state
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Workout');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = ref.read(activeWorkoutProvider);
      if (active == null) {
        ref.read(activeWorkoutProvider.notifier).startWorkout();
      } else {
        _nameController.text = active.name;
        // Resume timer if returning to an existing workout
        _startTimer();
      }
    });
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final active = ref.read(activeWorkoutProvider);
      if (active != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(active.startTime);
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = 0;
      _isResting = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _restSeconds++);
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() => _isResting = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedRestTime {
    final m = _restSeconds ~/ 60;
    final s = _restSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: const Icon(Icons.warning_rounded,
                    color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text('Discard Workout?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel this workout? All progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Going'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      ref.read(activeWorkoutProvider.notifier).cancelWorkout();
      return true;
    }
    return false;
  }

  void _finishWorkout() async {
    final active = ref.read(activeWorkoutProvider);
    if (active == null || active.exercises.isEmpty) {
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

    final hasCompletedSets = active.exercises.any(
      (e) => e.sets.any((s) => s.isCompleted),
    );

    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete at least one set first'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      );
      return;
    }

    // Show finish summary dialog
    final shouldFinish = await _showFinishDialog(active);
    if (shouldFinish != true) return;

    final workout = ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (workout != null) {
      await ref.read(workoutHistoryProvider.notifier).addWorkout(workout);
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<bool?> _showFinishDialog(ActiveWorkoutState active) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate summary stats
    int totalSets = 0;
    double totalVolume = 0;
    int completedSets = 0;
    for (final ex in active.exercises) {
      for (final s in ex.sets) {
        totalSets++;
        if (s.isCompleted) {
          completedSets++;
          if (!s.isWarmup) totalVolume += s.volume;
        }
      }
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Great Workout!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: _formattedTime,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryRow(
                icon: Icons.fitness_center_rounded,
                label: 'Exercises',
                value: '${active.exercises.length}',
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryRow(
                icon: Icons.check_circle_rounded,
                label: 'Sets Completed',
                value: '$completedSets / $totalSets',
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryRow(
                icon: Icons.trending_up_rounded,
                label: 'Total Volume',
                value: '${totalVolume.toStringAsFixed(0)} kg',
                color: AppColors.warning,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
            child: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        onExerciseSelected: (exercise) {
          ref.read(activeWorkoutProvider.notifier).addExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                primaryMuscle: exercise.primaryMuscle,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = ref.watch(activeWorkoutProvider);

    if (active == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate total volume
    double totalVolume = 0;
    int completedSets = 0;
    int totalSets = 0;
    for (final ex in active.exercises) {
      for (final s in ex.sets) {
        totalSets++;
        if (s.isCompleted) {
          completedSets++;
          if (!s.isWarmup) {
            totalVolume += s.volume;
          }
        }
      }
    }

    // Determine current exercise info
    final currentExIndex = _findCurrentExerciseIndex(active);
    final currentExercise =
        currentExIndex >= 0 ? active.exercises[currentExIndex] : null;
    final currentSetInfo = currentExercise != null
        ? _getCurrentSetInfo(currentExercise)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ────────── Top Bar ──────────
              _TopBar(
                nameController: _nameController,
                formattedTime: _formattedTime,
                isDark: isDark,
                isTimerRunning: _isTimerRunning,
                isEditingName: _isEditingName,
                onClose: () async {
                  final nav = Navigator.of(context);
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) nav.pop();
                },
                onFinish: _finishWorkout,
                onToggleTimer: _toggleTimer,
                onNameTap: () {
                  setState(() => _isEditingName = true);
                },
                onNameSubmitted: (name) {
                  ref.read(activeWorkoutProvider.notifier).updateName(name);
                  setState(() => _isEditingName = false);
                },
              ),

              // ────────── Rest Timer Banner ──────────
              if (_isResting)
                _RestTimerBanner(
                  restTime: _formattedRestTime,
                  restSeconds: _restSeconds,
                  isDark: isDark,
                  onSkip: _stopRestTimer,
                ),

              // ────────── Scrollable Content ──────────
              Expanded(
                child: active.exercises.isEmpty
                    ? _EmptyExerciseState(
                        theme: theme,
                        isDark: isDark,
                        onAdd: _showExercisePicker,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                        children: [
                          // ── Quick Stats Row ──
                          _QuickStatsRow(
                            exerciseCount: active.exercises.length,
                            completedSets: completedSets,
                            totalSets: totalSets,
                            totalVolume: totalVolume,
                            isDark: isDark,
                          )
                              .animate()
                              .fadeIn(duration: 300.ms),
                          const SizedBox(height: AppSpacing.lg),

                          // ── Exercise Cards ──
                          ...active.exercises.asMap().entries.map((entry) {
                            final exerciseIndex = entry.key;
                            final exercise = entry.value;
                            final isCurrent = exerciseIndex == currentExIndex;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg),
                              child: _ExerciseCard(
                                exerciseIndex: exerciseIndex,
                                exercise: exercise,
                                isDark: isDark,
                                isCurrent: isCurrent,
                                ref: ref,
                                onSetCompleted: _startRestTimer,
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(
                                      begin: 0.03,
                                      duration: 300.ms,
                                      curve: Curves.easeOut),
                            );
                          }),

                          // ── Add Exercise Button ──
                          _AddExerciseButton(
                            onTap: _showExercisePicker,
                            isDark: isDark,
                          ),

                          const SizedBox(height: AppSpacing.xxxxl * 2),
                        ],
                      ),
              ),

              // ── Bottom Action Bar ──
              if (active.exercises.isNotEmpty)
                _BottomActionBar(
                  isDark: isDark,
                  isResting: _isResting,
                  onFinishSet: () {
                    if (_isResting) {
                      _stopRestTimer();
                    } else if (currentExercise != null &&
                        currentSetInfo != null) {
                      // Mark current set as completed
                      final setIdx = currentSetInfo.$1 - 1;
                      if (setIdx >= 0 &&
                          setIdx < currentExercise.sets.length) {
                        final set = currentExercise.sets[setIdx];
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .updateSet(
                              currentExIndex,
                              setIdx,
                              set.copyWith(isCompleted: true),
                            );
                        _startRestTimer();
                      }
                    }
                  },
                  onFinishWorkout: _finishWorkout,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _findCurrentExerciseIndex(ActiveWorkoutState active) {
    for (int i = 0; i < active.exercises.length; i++) {
      final hasIncomplete =
          active.exercises[i].sets.any((s) => !s.isCompleted);
      if (hasIncomplete) return i;
    }
    return active.exercises.isNotEmpty ? active.exercises.length - 1 : -1;
  }

  (int, int)? _getCurrentSetInfo(dynamic exercise) {
    final sets = exercise.sets as List<ExerciseSet>;
    int currentSet = 1;
    for (int i = 0; i < sets.length; i++) {
      if (!sets[i].isCompleted) {
        currentSet = i + 1;
        return (currentSet, sets.length);
      }
    }
    return (sets.length, sets.length);
  }
}

// ─────────────────────────── Top Bar ───────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController nameController;
  final String formattedTime;
  final bool isDark;
  final bool isTimerRunning;
  final bool isEditingName;
  final VoidCallback onClose;
  final VoidCallback onFinish;
  final VoidCallback onToggleTimer;
  final VoidCallback onNameTap;
  final ValueChanged<String> onNameSubmitted;

  const _TopBar({
    required this.nameController,
    required this.formattedTime,
    required this.isDark,
    required this.isTimerRunning,
    required this.isEditingName,
    required this.onClose,
    required this.onFinish,
    required this.onToggleTimer,
    required this.onNameTap,
    required this.onNameSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
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
      child: Column(
        children: [
          // Top row: close, timer, finish
          Row(
            children: [
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark2
                        : AppColors.surfaceLight2,
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

              // Timer pill with pulsing dot
              GestureDetector(
                onTap: onToggleTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTimerRunning)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                            .animate(
                              onPlay: (c) => c.repeat(reverse: true),
                            )
                            .scaleXY(
                              begin: 1.0,
                              end: 0.6,
                              duration: 1000.ms,
                            )
                      else
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isTimerRunning ? formattedTime : 'Start',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [
                            const FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),

              const Spacer(),

              // Finish button with gradient
              GestureDetector(
                onTap: onFinish,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
                  child: Text(
                    'Finish',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Editable workout name
          GestureDetector(
            onTap: isEditingName ? null : onNameTap,
            child: isEditingName
                ? SizedBox(
                    height: 36,
                    child: TextField(
                      controller: nameController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                          borderSide: const BorderSide(
                              color: AppColors.primaryBlue, width: 1.5),
                        ),
                      ),
                      onSubmitted: onNameSubmitted,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nameController.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Rest Timer Banner ───────────────────────────

class _RestTimerBanner extends StatelessWidget {
  final String restTime;
  final int restSeconds;
  final bool isDark;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.restTime,
    required this.restSeconds,
    required this.isDark,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
            AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
          ],
        ),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Circular progress indicator for rest
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: (restSeconds % 90) / 90.0,
                    strokeWidth: 3,
                    backgroundColor:
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REST TIMER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  restTime,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.skip_next_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Skip',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, duration: 300.ms);
  }
}

// ─────────────────────────── Quick Stats Row ───────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final int exerciseCount;
  final int completedSets;
  final int totalSets;
  final double totalVolume;
  final bool isDark;

  const _QuickStatsRow({
    required this.exerciseCount,
    required this.completedSets,
    required this.totalSets,
    required this.totalVolume,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            label: 'Exercises',
            value: '$exerciseCount',
            color: AppColors.primaryBlue,
          ),
          Container(
            width: 1,
            height: 28,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
          _MiniStat(
            label: 'Sets',
            value: '$completedSets/$totalSets',
            color: AppColors.accent,
          ),
          Container(
            width: 1,
            height: 28,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
          _MiniStat(
            label: 'Volume',
            value: '${totalVolume.toStringAsFixed(0)} kg',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Exercise Card ───────────────────────────

class _ExerciseCard extends StatelessWidget {
  final int exerciseIndex;
  final dynamic exercise;
  final bool isDark;
  final bool isCurrent;
  final WidgetRef ref;
  final VoidCallback onSetCompleted;

  const _ExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.isDark,
    required this.isCurrent,
    required this.ref,
    required this.onSetCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muscleColor = AppColors.colorForMuscle(exercise.primaryMuscle);
    final allCompleted = (exercise.sets as List<ExerciseSet>).every((s) => s.isCompleted);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isCurrent && !allCompleted
              ? muscleColor.withValues(alpha: 0.4)
              : allCompleted
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.dividerLight,
          width: isCurrent && !allCompleted ? 1.5 : 1,
        ),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muscle color accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: allCompleted
                    ? [AppColors.accent, AppColors.accent.withValues(alpha: 0.3)]
                    : [muscleColor, muscleColor.withValues(alpha: 0.3)],
              ),
            ),
          ),

          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: allCompleted
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : muscleColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        allCompleted
                            ? Icons.check_circle_rounded
                            : Icons.fitness_center_rounded,
                        size: 18,
                        color: allCompleted ? AppColors.accent : muscleColor,
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
                              decoration: allCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: allCompleted
                                  ? cs.onSurfaceVariant
                                  : null,
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
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
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
                    if (isCurrent && !allCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color:
                              muscleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill),
                        ),
                        child: Text(
                          'CURRENT',
                          style:
                              theme.textTheme.labelSmall?.copyWith(
                            color: muscleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') {
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .removeExercise(exerciseIndex);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18),
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

                const SizedBox(height: AppSpacing.md),

                // Set header labels
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
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
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxxxl),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Sets
                ...exercise.sets
                    .asMap()
                    .entries
                    .map<Widget>((entry) {
                  final setIndex = entry.key;
                  final set = entry.value as ExerciseSet;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SetRow(
                      exerciseSet: set,
                      onChanged: (updatedSet) {
                        final wasCompleted = set.isCompleted;
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .updateSet(
                              exerciseIndex,
                              setIndex,
                              updatedSet,
                            );
                        if (!wasCompleted &&
                            updatedSet.isCompleted) {
                          onSetCompleted();
                        }
                      },
                      onDismissed: exercise.sets.length > 1
                          ? () {
                              ref
                                  .read(activeWorkoutProvider
                                      .notifier)
                                  .removeSet(
                                    exerciseIndex,
                                    setIndex,
                                  );
                            }
                          : null,
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.sm),

                // Add Set button
                GestureDetector(
                  onTap: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .addSet(exerciseIndex),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.surfaceLight2,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Add Set',
                          style:
                              theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Notes
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  onChanged: (v) => ref
                      .read(activeWorkoutProvider.notifier)
                      .updateExerciseNotes(exerciseIndex, v),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add note...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(
                          left: AppSpacing.sm, right: AppSpacing.xs),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 28, minHeight: 0),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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

// ─────────────────────────── Bottom Action Bar ───────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isDark;
  final bool isResting;
  final VoidCallback onFinishSet;
  final VoidCallback onFinishWorkout;

  const _BottomActionBar({
    required this.isDark,
    required this.isResting,
    required this.onFinishSet,
    required this.onFinishWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onFinishSet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: isResting ? null : AppColors.primaryGradient,
            color: isResting
                ? AppColors.accent.withValues(alpha: 0.15)
                : null,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusLg),
            border: isResting
                ? Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3))
                : null,
            boxShadow: isResting
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryBlue
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isResting
                    ? Icons.skip_next_rounded
                    : Icons.check_rounded,
                color:
                    isResting ? AppColors.accent : Colors.white,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isResting ? 'SKIP REST' : 'FINISH SET',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isResting
                      ? AppColors.accent
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Empty State ───────────────────────────

class _EmptyExerciseState extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyExerciseState({
    required this.theme,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
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
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 36,
                color: AppColors.primaryBlue
                    .withValues(alpha: isDark ? 0.7 : 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Ready to Train?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first exercise to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _AddExerciseButton(onTap: onAdd, isDark: isDark),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─────────────────────────── Add Exercise Button ───────────────────────────

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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
              AppColors.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 18, color: Colors.white),
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

// ─────────────────────────── Finish Dialog Summary Row ───────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
