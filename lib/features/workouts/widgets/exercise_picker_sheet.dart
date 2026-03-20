import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/seed/exercise_database.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// Bottom sheet for selecting exercises to add to a workout.
class ExercisePickerSheet extends StatefulWidget {
  final void Function(Exercise exercise) onExerciseSelected;

  const ExercisePickerSheet({
    super.key,
    required this.onExerciseSelected,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;
  EquipmentType? _selectedEquipment;

  List<Exercise> get _filteredExercises {
    return exerciseDatabase.where((exercise) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!exercise.name.toLowerCase().contains(query) &&
            !exercise.primaryMuscle.displayName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Muscle group filter
      if (_selectedMuscle != null &&
          exercise.primaryMuscle != _selectedMuscle) {
        return false;
      }

      // Equipment filter
      if (_selectedEquipment != null &&
          exercise.equipment != _selectedEquipment) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filtered = _filteredExercises;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 36,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Row(
                  children: [
                    Text(
                      'Add Exercise',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Muscle group filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedMuscle == null,
                      onTap: () => setState(() => _selectedMuscle = null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ..._availableMuscles.map((muscle) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: muscle.displayName,
                          isSelected: _selectedMuscle == muscle,
                          color: AppColors.colorForMuscle(muscle),
                          onTap: () => setState(() {
                            _selectedMuscle =
                                _selectedMuscle == muscle ? null : muscle;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Equipment filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  children: [
                    _FilterChip(
                      label: 'All Equipment',
                      isSelected: _selectedEquipment == null,
                      onTap: () => setState(() => _selectedEquipment = null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...EquipmentType.values.map((equipment) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: equipment.displayName,
                          isSelected: _selectedEquipment == equipment,
                          onTap: () => setState(() {
                            _selectedEquipment =
                                _selectedEquipment == equipment
                                    ? null
                                    : equipment;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Exercise list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No exercises found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs / 2),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          final color = AppColors.colorForMuscle(exercise.primaryMuscle);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                              ),
                              child: Icon(
                                exercise.equipment.icon,
                                size: 20,
                                color: color,
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              exercise.primaryMuscle.displayName,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs - 1,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: Text(
                                exercise.primaryMuscle.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () {
                              widget.onExerciseSelected(exercise);
                              Navigator.of(context).pop();
                            },
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 30 * index),
                                duration: const Duration(milliseconds: 300),
                              );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Unique muscle groups from the exercise database.
  List<MuscleGroup> get _availableMuscles {
    final muscles = exerciseDatabase
        .map((e) => e.primaryMuscle)
        .toSet()
        .toList();
    muscles.sort((a, b) => a.displayName.compareTo(b.displayName));
    return muscles;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chipColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm - 1),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.12)
              : cs.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: isSelected
              ? Border.all(color: chipColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? chipColor : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
