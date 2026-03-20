import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

/// Full-screen editor for all user goals and preferences.
///
/// When the user saves, the updated [UserProfile] is persisted and all
/// dependent providers are invalidated — so the dashboard, nutrition targets,
/// AI coach context, and everything else refresh automatically.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _workoutDaysController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;

  // State
  WorkoutGoal _goal = WorkoutGoal.generalFitness;
  ExperienceLevel _level = ExperienceLevel.beginner;
  Gender? _gender;
  ActivityLevel? _activityLevel;
  DateTime? _dateOfBirth;
  bool _useCustomTargetWeight = false;
  bool _useCustomNutrition = false;
  bool _macroPercentageMode = false;
  bool _saving = false;
  bool _initialized = false;

  // Track what changed for the summary
  UserProfile? _originalProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _workoutDaysController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _workoutDaysController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _originalProfile = profile;

    _nameController.text = profile.name ?? '';
    _heightController.text =
        profile.height != null ? profile.height!.toStringAsFixed(1) : '';
    _weightController.text =
        profile.weight != null ? profile.weight!.toStringAsFixed(1) : '';
    _workoutDaysController.text = profile.workoutDaysPerWeek.toString();

    _goal = profile.goal;
    _level = profile.level;
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _dateOfBirth = profile.dateOfBirth;

    _useCustomTargetWeight = profile.targetWeight != null;
    if (profile.targetWeight != null) {
      _targetWeightController.text =
          profile.targetWeight!.toStringAsFixed(1);
    } else if (profile.computedTargetWeight != null) {
      _targetWeightController.text =
          profile.computedTargetWeight!.toStringAsFixed(1);
    }

    // Nutrition: check if the user had manual overrides stored
    _useCustomNutrition = profile.hasStoredNutritionOverrides;
    _caloriesController.text =
        profile.dailyCalorieTarget.toInt().toString();
    _proteinController.text = profile.proteinTarget.toInt().toString();
    _carbsController.text = profile.carbsTarget.toInt().toString();
    _fatsController.text = profile.fatsTarget.toInt().toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      final workoutDays = int.tryParse(_workoutDaysController.text) ?? 4;
      final targetWeight = _useCustomTargetWeight
          ? double.tryParse(_targetWeightController.text)
          : null;

      // Custom nutrition values (only used when toggle is on)
      final customCalories = _useCustomNutrition
          ? double.tryParse(_caloriesController.text)
          : null;
      final customProtein = _useCustomNutrition
          ? double.tryParse(_proteinController.text)
          : null;
      final customCarbs = _useCustomNutrition
          ? double.tryParse(_carbsController.text)
          : null;
      final customFats = _useCustomNutrition
          ? double.tryParse(_fatsController.text)
          : null;

      final updated = _originalProfile!.copyWith(
        name: _nameController.text.trim(),
        height: height,
        weight: weight,
        goal: _goal,
        level: _level,
        gender: _gender,
        activityLevel: _activityLevel,
        dateOfBirth: _dateOfBirth,
        workoutDaysPerWeek: workoutDays,
        targetWeight: targetWeight,
        clearTargetWeight: !_useCustomTargetWeight,
        // When custom nutrition is off, clear stored overrides so
        // the science-backed computed targets are used instead.
        dailyCalorieTarget: customCalories,
        proteinTarget: customProtein,
        carbsTarget: customCarbs,
        fatsTarget: customFats,
        clearCalorieTarget: !_useCustomNutrition,
        clearProteinTarget: !_useCustomNutrition,
        clearCarbsTarget: !_useCustomNutrition,
        clearFatsTarget: !_useCustomNutrition,
      );

      await saveProfileAndRefresh(ref, updated);

      if (mounted) {
        _showChangeSummary(updated);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showChangeSummary(UserProfile updated) {
    final changes = <String>[];

    if (updated.goal != _originalProfile!.goal) {
      changes.add('Goal: ${updated.goal.displayName}');
    }
    if (updated.activityLevel != _originalProfile!.activityLevel) {
      changes.add(
          'Activity: ${updated.activityLevel?.displayName ?? "Not set"}');
    }
    if (updated.weight != _originalProfile!.weight) {
      changes.add('Weight: ${updated.weight?.toStringAsFixed(1)} kg');
    }
    if (updated.level != _originalProfile!.level) {
      changes.add('Level: ${updated.level.displayName}');
    }
    if (updated.workoutDaysPerWeek != _originalProfile!.workoutDaysPerWeek) {
      changes.add('Training days: ${updated.workoutDaysPerWeek}/week');
    }

    final msg = changes.isEmpty
        ? 'Profile updated'
        : 'Updated: ${changes.join(", ")}. All targets recalculated.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          _initFromProfile(profile);
          return _buildForm(context, theme, isDark, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UserProfile profile,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          surfaceTintColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          title: Column(
            children: [
              Text(
                'Edit Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ─────── Avatar Section ───────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue.withValues(alpha: 0.15),
                                    AppColors.accent.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (_nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : '?'),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Your Name',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _nameController.text.isNotEmpty
                                ? null
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Personal Info ───────
                  _SectionTitle(title: 'Personal Info', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.md),

                  _buildTextField(
                    theme,
                    isDark,
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          theme,
                          isDark,
                          controller: _heightController,
                          label: 'Height (cm)',
                          icon: Icons.height_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,1}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildTextField(
                          theme,
                          isDark,
                          controller: _weightController,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,1}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date of Birth picker
                  _buildDobPicker(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Fitness Goal ───────
                  _SectionTitle(title: 'Fitness Goal', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Changing your goal recalculates all nutrition targets automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildGoalSelector(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Activity Level ───────
                  _SectionTitle(title: 'Activity Level', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your activity level directly affects your daily calorie target (TDEE).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildActivityLevelSelector(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Experience Level ───────
                  _SectionTitle(title: 'Experience Level', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.md),

                  _buildExperienceLevelSelector(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Gender ───────
                  _SectionTitle(title: 'Gender', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Used for accurate BMR calculation (Mifflin-St Jeor).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildGenderSelector(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Training ───────
                  _SectionTitle(title: 'Training Preferences', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.md),

                  _buildTextField(
                    theme,
                    isDark,
                    controller: _workoutDaysController,
                    label: 'Workout days per week',
                    icon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _RangeTextInputFormatter(min: 1, max: 7),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Target Weight ───────
                  _SectionTitle(title: 'Target Weight', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),

                  _buildTargetWeightSection(theme, isDark),

                  const SizedBox(height: AppSpacing.xxl),

                  // ─────── Nutrition Targets ───────
                  _SectionTitle(
                      title: 'Calories & Macros', theme: theme, isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  _buildNutritionExplainer(theme, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildNutritionToggle(theme, isDark),
                  const SizedBox(height: AppSpacing.md),
                  if (_useCustomNutrition)
                    _buildCustomNutritionFields(theme, isDark)
                  else
                    _buildAutoNutritionPreview(theme, isDark),

                  const SizedBox(height: AppSpacing.xxxl),

                  // Save button
                  _buildSaveButton(theme),

                  const SizedBox(height: AppSpacing.xxxxl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── DOB Picker ──────────────────────────────────

  Widget _buildDobPicker(ThemeData theme, bool isDark) {
    final formatted = _dateOfBirth != null
        ? DateFormat('MMM d, yyyy').format(_dateOfBirth!)
        : 'Select date of birth';
    final age = _dateOfBirth != null ? _computeAge(_dateOfBirth!) : null;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime(1998, 1, 1),
          firstDate: DateTime(1940),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
          builder: (context, child) {
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
          setState(() => _dateOfBirth = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(
            Icons.cake_outlined,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          suffixIcon: age != null
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Chip(
                    label: Text('$age yrs'),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor:
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        ),
        child: Text(
          formatted,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _dateOfBirth != null
                ? null
                : (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
          ),
        ),
      ),
    );
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  // ─────────────────────────── Goal Selector ───────────────────────────────

  Widget _buildGoalSelector(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: WorkoutGoal.values.map((g) {
        final selected = _goal == g;
        return _SelectionChip(
          label: g.displayName,
          icon: g.icon,
          selected: selected,
          onTap: () => setState(() => _goal = g),
          theme: theme,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  // ─────────────────────────── Activity Level ──────────────────────────────

  Widget _buildActivityLevelSelector(ThemeData theme, bool isDark) {
    return Column(
      children: ActivityLevel.values.map((al) {
        final selected = _activityLevel == al;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryBlue.withValues(alpha: 0.08)
                  : (isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: selected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                al.icon,
                color: selected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                size: 22,
              ),
              title: Text(
                al.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primaryBlue : null,
                ),
              ),
              subtitle: Text(
                al.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              trailing: Text(
                '${al.multiplier}x',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.primaryBlue
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => setState(() => _activityLevel = al),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────── Experience Level ────────────────────────────

  Widget _buildExperienceLevelSelector(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ExperienceLevel.values.map((el) {
        final selected = _level == el;
        return _SelectionChip(
          label: el.displayName,
          icon: el.icon,
          selected: selected,
          onTap: () => setState(() => _level = el),
          theme: theme,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  // ─────────────────────────── Gender ──────────────────────────────────────

  Widget _buildGenderSelector(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: Gender.values.map((g) {
        final selected = _gender == g;
        return _SelectionChip(
          label: g.displayName,
          icon: g.icon,
          selected: selected,
          onTap: () => setState(() => _gender = g),
          theme: theme,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  // ─────────────────────────── Target Weight ───────────────────────────────

  Widget _buildTargetWeightSection(ThemeData theme, bool isDark) {
    // Compute what the auto value would be
    final w = double.tryParse(_weightController.text);
    final autoTarget = w != null
        ? switch (_goal) {
            WorkoutGoal.fatLoss => w * 0.95,
            WorkoutGoal.hypertrophy => w * 1.03,
            WorkoutGoal.generalFitness => w,
            _ => w,
          }
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        Row(
          children: [
            Expanded(
              child: Text(
                _useCustomTargetWeight
                    ? 'Custom target weight'
                    : 'Auto-calculated from goal${autoTarget != null ? " (${autoTarget.toStringAsFixed(1)} kg)" : ""}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Switch.adaptive(
              value: _useCustomTargetWeight,
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (v) {
                setState(() {
                  _useCustomTargetWeight = v;
                  if (!v && autoTarget != null) {
                    _targetWeightController.text =
                        autoTarget.toStringAsFixed(1);
                  }
                });
              },
            ),
          ],
        ),
        if (_useCustomTargetWeight) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(
            theme,
            isDark,
            controller: _targetWeightController,
            label: 'Target weight (kg)',
            icon: Icons.flag_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
          ),
        ],
      ],
    );
  }

  // ─────────────────────────── Nutrition Section ────────────────────────────

  /// Builds a temporary [UserProfile] from the current form state so we can
  /// show live computed values.
  UserProfile _buildPreviewProfile() {
    final w = double.tryParse(_weightController.text) ?? 70;
    final h = double.tryParse(_heightController.text) ?? 170;
    final age = _dateOfBirth != null ? _computeAge(_dateOfBirth!) : 25;
    return UserProfile(
      weight: w,
      height: h,
      age: age,
      goal: _goal,
      gender: _gender,
      activityLevel: _activityLevel,
      dateOfBirth: _dateOfBirth,
    );
  }

  /// Explanation card that teaches the user what BMR / TDEE mean.
  Widget _buildNutritionExplainer(ThemeData theme, bool isDark) {
    final preview = _buildPreviewProfile();
    final subtextColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BMR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hotel_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BMR (Basal Metabolic Rate)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${preview.bmr.toInt()} kcal',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      'Calories your body burns at complete rest — just to keep your organs, brain, and cells functioning.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // TDEE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.directions_run_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TDEE (Total Daily Energy)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${preview.tdee.toInt()} kcal',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      'BMR multiplied by your activity level (${_activityLevel?.multiplier ?? 1.55}x). This is the total calories you burn in a day including exercise.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Goal adjustment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.adjust_rounded,
                  size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Daily Target',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${preview.dailyCalorieTarget.toInt()} kcal',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      _goalExplanation(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: subtextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03);
  }

  String _goalExplanation() {
    return switch (_goal) {
      WorkoutGoal.fatLoss =>
        'TDEE minus 500 kcal — a moderate deficit for sustainable fat loss while preserving muscle.',
      WorkoutGoal.hypertrophy =>
        'TDEE plus 300 kcal — a lean surplus to fuel muscle growth without excessive fat gain.',
      WorkoutGoal.strength =>
        'TDEE — eating at maintenance to support strength gains.',
      WorkoutGoal.generalFitness =>
        'TDEE — eating at maintenance to sustain your current activity level.',
      WorkoutGoal.endurance =>
        'TDEE — eating at maintenance to fuel endurance training.',
    };
  }

  /// Toggle between auto-calculated and custom nutrition.
  Widget _buildNutritionToggle(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _useCustomNutrition
                ? 'Custom targets (your values)'
                : 'Auto-calculated from your profile',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Switch.adaptive(
          value: _useCustomNutrition,
          activeTrackColor: AppColors.primaryBlue,
          onChanged: (v) {
            setState(() {
              _useCustomNutrition = v;
              _macroPercentageMode = false;
              if (v) {
                // Pre-fill with current computed values so the user
                // has a starting point to edit from.
                final preview = _buildPreviewProfile();
                _proteinController.text =
                    preview.proteinTarget.toInt().toString();
                _carbsController.text =
                    preview.carbsTarget.toInt().toString();
                _fatsController.text =
                    preview.fatsTarget.toInt().toString();
                // Calories derived from macros (source of truth)
                _syncCaloriesFromMacros();
              }
            });
          },
        ),
      ],
    );
  }

  /// Recalculates calories from macros (macros are the source of truth).
  void _syncCaloriesFromMacros() {
    final p = int.tryParse(_proteinController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final f = int.tryParse(_fatsController.text) ?? 0;
    final total = (p * 4) + (c * 4) + (f * 9);
    _caloriesController.text = total.toString();
  }

  /// Recalculates macro grams from percentages when in percentage mode.
  void _syncMacrosFromPercentages(
      int proteinPct, int carbsPct, int fatsPct) {
    final cals = int.tryParse(_caloriesController.text) ?? 0;
    if (cals <= 0) return;
    _proteinController.text = ((cals * proteinPct / 100) / 4).round().toString();
    _carbsController.text = ((cals * carbsPct / 100) / 4).round().toString();
    _fatsController.text = ((cals * fatsPct / 100) / 9).round().toString();
  }

  /// Editable fields for calories, protein, carbs, fats.
  Widget _buildCustomNutritionFields(ThemeData theme, bool isDark) {
    // Compute current percentages from grams
    final p = int.tryParse(_proteinController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final f = int.tryParse(_fatsController.text) ?? 0;
    final macroCalories = (p * 4) + (c * 4) + (f * 9);
    final pPct = macroCalories > 0 ? (p * 4 / macroCalories * 100).round() : 30;
    final cPct = macroCalories > 0 ? (c * 4 / macroCalories * 100).round() : 40;
    final fPct = macroCalories > 0 ? (f * 9 / macroCalories * 100).round() : 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Calories field ─────────────────────────────────────────────
        // In grams mode: read-only (auto-computed from macros)
        // In percentage mode: editable (macros adjust to match)
        _macroPercentageMode
            ? _buildTextField(
                theme,
                isDark,
                controller: _caloriesController,
                label: 'Daily calories (kcal)',
                icon: Icons.local_fire_department_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  setState(() {
                    _syncMacrosFromPercentages(pPct, cPct, fPct);
                  });
                },
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily calories (auto-calculated)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                          Text(
                            '${_caloriesController.text} kcal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'from macros',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

        const SizedBox(height: AppSpacing.md),

        // ── Mode toggle: Grams vs Percentages ──────────────────────────
        Row(
          children: [
            Text(
              'Set macros by',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ModeChip(
              label: 'Grams',
              isSelected: !_macroPercentageMode,
              onTap: () => setState(() => _macroPercentageMode = false),
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ModeChip(
              label: 'Percentages',
              isSelected: _macroPercentageMode,
              onTap: () => setState(() => _macroPercentageMode = true),
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        if (_macroPercentageMode) ...[
          // ── Percentage sliders ─────────────────────────────────────────
          _PercentageSlider(
            label: 'Protein',
            percentage: pPct,
            color: AppColors.primaryBlue,
            theme: theme,
            isDark: isDark,
            onChanged: (val) {
              setState(() {
                // Adjust carbs to compensate, keep fats stable
                final newPPct = val;
                final remaining = 100 - newPPct;
                final ratio = (cPct + fPct) > 0 ? remaining / (cPct + fPct) : 0.5;
                final newCPct = (cPct * ratio).round().clamp(0, 100);
                final newFPct = (100 - newPPct - newCPct).clamp(0, 100);
                _syncMacrosFromPercentages(newPPct, newCPct, newFPct);
                _syncCaloriesFromMacros();
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _PercentageSlider(
            label: 'Carbs',
            percentage: cPct,
            color: AppColors.accent,
            theme: theme,
            isDark: isDark,
            onChanged: (val) {
              setState(() {
                final newCPct = val;
                final remaining = 100 - newCPct;
                final ratio = (pPct + fPct) > 0 ? remaining / (pPct + fPct) : 0.5;
                final newPPct = (pPct * ratio).round().clamp(0, 100);
                final newFPct = (100 - newCPct - newPPct).clamp(0, 100);
                _syncMacrosFromPercentages(newPPct, newCPct, newFPct);
                _syncCaloriesFromMacros();
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _PercentageSlider(
            label: 'Fats',
            percentage: fPct,
            color: AppColors.warning,
            theme: theme,
            isDark: isDark,
            onChanged: (val) {
              setState(() {
                final newFPct = val;
                final remaining = 100 - newFPct;
                final ratio = (pPct + cPct) > 0 ? remaining / (pPct + cPct) : 0.5;
                final newPPct = (pPct * ratio).round().clamp(0, 100);
                final newCPct = (100 - newFPct - newPPct).clamp(0, 100);
                _syncMacrosFromPercentages(newPPct, newCPct, newFPct);
                _syncCaloriesFromMacros();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Show computed grams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroSummaryChip(label: 'Protein', grams: p, color: AppColors.primaryBlue, theme: theme),
              _MacroSummaryChip(label: 'Carbs', grams: c, color: AppColors.accent, theme: theme),
              _MacroSummaryChip(label: 'Fats', grams: f, color: AppColors.warning, theme: theme),
            ],
          ),
        ] else ...[
          // ── Gram fields ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  theme,
                  isDark,
                  controller: _proteinController,
                  label: 'Protein (g)',
                  icon: Icons.egg_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(_syncCaloriesFromMacros),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextField(
                  theme,
                  isDark,
                  controller: _carbsController,
                  label: 'Carbs (g)',
                  icon: Icons.grain_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(_syncCaloriesFromMacros),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextField(
                  theme,
                  isDark,
                  controller: _fatsController,
                  label: 'Fats (g)',
                  icon: Icons.water_drop_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(_syncCaloriesFromMacros),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.sm),

        // Macro calorie total — always consistent
        Text(
          'Total: $macroCalories kcal from macros '
          '(P:$pPct% C:$cPct% F:$fPct%)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Read-only preview showing the auto-calculated macro breakdown.
  Widget _buildAutoNutritionPreview(ThemeData theme, bool isDark) {
    final preview = _buildPreviewProfile();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Auto-Calculated Targets',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PreviewRow(
            label: 'Daily Calories',
            value: '${preview.dailyCalorieTarget.toInt()} kcal',
            theme: theme,
            isDark: isDark,
            highlight: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PreviewRow(
            label: 'Protein (${_goal == WorkoutGoal.fatLoss ? "2.2" : _goal == WorkoutGoal.hypertrophy ? "2.0" : "1.8"}g/kg)',
            value: '${preview.proteinTarget.toInt()}g',
            theme: theme,
            isDark: isDark,
            color: AppColors.primaryBlue,
          ),
          _PreviewRow(
            label: 'Carbs (remaining calories)',
            value: '${preview.carbsTarget.toInt()}g',
            theme: theme,
            isDark: isDark,
            color: AppColors.accent,
          ),
          _PreviewRow(
            label: 'Fats (25% of calories)',
            value: '${preview.fatsTarget.toInt()}g',
            theme: theme,
            isDark: isDark,
            color: AppColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03);
  }

  // ─────────────────────────── Save Button ─────────────────────────────────

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Save Changes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ─────────────────────────── Text field helper ───────────────────────────

  Widget _buildTextField(
    ThemeData theme,
    bool isDark, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.theme,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.primaryBlue
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
        checkmarkColor: AppColors.primaryBlue,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: selected
              ? AppColors.primaryBlue
              : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(
            color: selected
                ? AppColors.primaryBlue
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isDark;
  final bool highlight;
  final Color? color;

  const _PreviewRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.isDark,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: (highlight
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.bodySmall)
                ?.copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.primaryBlue : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clamps typed integers to [min, max].
class _RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null) return oldValue;
    if (val < min || val > max) return oldValue;
    return newValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro editing helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
        ),
      ),
    );
  }
}

class _PercentageSlider extends StatefulWidget {
  final String label;
  final int percentage;
  final Color color;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _PercentageSlider({
    required this.label,
    required this.percentage,
    required this.color,
    required this.theme,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_PercentageSlider> createState() => _PercentageSliderState();
}

class _PercentageSliderState extends State<_PercentageSlider> {
  bool _isEditing = false;
  late TextEditingController _editController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitEdit();
      }
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.percentage.toString();
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _commitEdit() {
    final parsed = int.tryParse(_editController.text);
    if (parsed != null) {
      widget.onChanged(parsed.clamp(5, 80));
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            widget.label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: widget.color,
              inactiveTrackColor: widget.color.withValues(alpha: 0.15),
              thumbColor: widget.color,
              overlayColor: widget.color.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: widget.percentage.toDouble().clamp(5, 80),
              min: 5,
              max: 80,
              divisions: 75,
              onChanged: (v) => widget.onChanged(v.round()),
            ),
          ),
        ),
        GestureDetector(
          onTap: _startEditing,
          child: SizedBox(
            width: 48,
            height: 28,
            child: _isEditing
                ? TextField(
                    controller: _editController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                        borderSide: BorderSide(
                          color: widget.color.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                        borderSide: BorderSide(
                          color: widget.color.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusSm,
                        borderSide: BorderSide(color: widget.color),
                      ),
                      suffixText: '%',
                      suffixStyle: widget.theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                    onSubmitted: (_) => _commitEdit(),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${widget.percentage}%',
                      textAlign: TextAlign.end,
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        decoration: TextDecoration.underline,
                        decorationColor: widget.color.withValues(alpha: 0.3),
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _MacroSummaryChip extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;
  final ThemeData theme;

  const _MacroSummaryChip({
    required this.label,
    required this.grams,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${grams}g',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
