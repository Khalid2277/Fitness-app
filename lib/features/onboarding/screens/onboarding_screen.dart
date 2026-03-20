import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/onboarding/providers/onboarding_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _checkedProfile = false;

  // Form data
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  WorkoutGoal? _selectedGoal;
  Gender? _selectedGender;
  ActivityLevel? _selectedActivityLevel;
  ExperienceLevel? _selectedLevel;
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prefillNameFromAuth();
    _checkExistingProfile();
  }

  /// Pre-fill the name field from the Supabase auth user_metadata
  /// (set during sign-up).
  void _prefillNameFromAuth() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata;
        final displayName = meta?['display_name'] as String? ??
            meta?['full_name'] as String? ??
            '';
        if (displayName.isNotEmpty) {
          _nameController.text = displayName;
        }
      }
    } catch (_) {
      // Auth not available — leave name empty
    }
  }

  Future<void> _checkExistingProfile() async {
    try {
      final hasProfile =
          await ref.read(hasCompletedOnboardingProvider.future);
      if (hasProfile && mounted) {
        context.go('/home');
        return;
      }
    } catch (_) {
      // No profile — continue with onboarding
    }
    if (mounted) setState(() => _checkedProfile = true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() {
    // Dismiss the keyboard when navigating to the next page.
    FocusScope.of(context).unfocus();

    // Page 0 = Welcome (handled by its own CTA)
    // Page 1 = Goal Selection
    if (_currentPage == 1 && _selectedGoal == null) {
      _showSnackBar('Please select a fitness goal');
      return;
    }
    // Page 2 = Basic Info
    if (_currentPage == 2) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedDob == null) {
        _showSnackBar('Please select your date of birth');
        return;
      }
    }
    // Page 3 = Gender & Activity Level
    if (_currentPage == 3) {
      if (_selectedGender == null) {
        _showSnackBar('Please select your gender');
        return;
      }
      if (_selectedActivityLevel == null) {
        _showSnackBar('Please select your activity level');
        return;
      }
    }
    if (_currentPage < 4) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_selectedLevel == null) {
      _showSnackBar('Please select your experience level');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Compute age from DOB
      int? computedAge;
      if (_selectedDob != null) {
        final now = DateTime.now();
        computedAge = now.year - _selectedDob!.year;
        if (now.month < _selectedDob!.month ||
            (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
          computedAge--;
        }
      }

      final profile = UserProfile(
        name: _nameController.text.trim(),
        age: computedAge,
        dateOfBirth: _selectedDob,
        height: double.tryParse(_heightController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        goal: _selectedGoal ?? WorkoutGoal.generalFitness,
        level: _selectedLevel ?? ExperienceLevel.beginner,
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        joinDate: DateTime.now(),
      );

      // Save to Supabase if online, otherwise local Hive
      final source = ref.read(dataSourceProvider);
      if (source == DataSourceType.supabase) {
        final sbRepo = ref.read(sbProfileRepositoryProvider);
        await sbRepo.updateProfile(profile);
      } else {
        final repo = ref.read(userRepositoryProvider);
        await repo.saveProfile(profile.toJson());
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(hasCompletedOnboardingProvider);

      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('Onboarding save error: $e');
      if (mounted) {
        _showSnackBar('Something went wrong. Please try again.\n$e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_checkedProfile) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar — only pages 1-4
              AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedSlide(
                  offset: _currentPage > 0
                      ? Offset.zero
                      : const Offset(0, -0.5),
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: _currentPage == 0,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                      ),
                      child: _GradientProgressBar(
                        currentStep: _currentPage,
                        totalSteps: 4,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) =>
                      setState(() => _currentPage = page),
                  children: [
                    _WelcomePage(onGetStarted: () => _goToPage(1)),
                    _GoalSelectionPage(
                      selectedGoal: _selectedGoal,
                      onGoalSelected: (goal) =>
                          setState(() => _selectedGoal = goal),
                    ),
                    _BasicInfoPage(
                      formKey: _formKey,
                      nameController: _nameController,
                      heightController: _heightController,
                      weightController: _weightController,
                      selectedDob: _selectedDob,
                      onDobSelected: (dob) =>
                          setState(() => _selectedDob = dob),
                    ),
                    _GenderActivityPage(
                      selectedGender: _selectedGender,
                      selectedActivityLevel: _selectedActivityLevel,
                      onGenderSelected: (gender) =>
                          setState(() => _selectedGender = gender),
                      onActivityLevelSelected: (level) =>
                          setState(() => _selectedActivityLevel = level),
                    ),
                    _ExperienceLevelPage(
                      selectedLevel: _selectedLevel,
                      onLevelSelected: (level) =>
                          setState(() => _selectedLevel = level),
                    ),
                  ],
                ),
              ),

              // Bottom nav — ONLY pages 1-4
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
                child: _currentPage > 0
                    ? _BottomNavigation(
                        key: const ValueKey('bottom-nav'),
                        currentPage: _currentPage,
                        totalPages: 4,
                        isSaving: _isSaving,
                        onBack: _previousPage,
                        onContinue: _currentPage == 4
                            ? _completeOnboarding
                            : _nextPage,
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Gradient Progress Bar — thin bar with gradient fill for steps 1-4
// =============================================================================

class _GradientProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _GradientProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fraction = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      children: [
        // Step counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(fraction * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Bar track
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusPill,
            color: isDark ? AppColors.surfaceDark3 : AppColors.surfaceLight3,
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                widthFactor: fraction,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppSpacing.borderRadiusPill,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Welcome Page — full screen, single CTA
// =============================================================================

class _WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _WelcomePage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Background glow
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  AppColors.primaryBlue
                      .withValues(alpha: isDark ? 0.1 : 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(flex: 3),

              // App logo with animated glow ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
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
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.surfaceLight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: AppSpacing.xxxl),

              // Headline
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Let's set up\nyour ",
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'profile',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                        foreground: Paint()
                          ..shader = AppColors.primaryGradient.createShader(
                            const Rect.fromLTWH(0, 0, 200, 60),
                          ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(
                      begin: 0.3, end: 0, delay: 200.ms, duration: 500.ms),

              const SizedBox(height: AppSpacing.lg),

              // Subtitle
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'We\'ll personalize your nutrition targets, training plans, and insights based on your goals.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.6,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(
                      begin: 0.3, end: 0, delay: 400.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // Feature pills row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeaturePill(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    delay: 500,
                  ),
                  _FeaturePill(
                    icon: Icons.pie_chart_rounded,
                    label: 'Macros',
                    delay: 600,
                  ),
                  _FeaturePill(
                    icon: Icons.fitness_center_rounded,
                    label: 'Workouts',
                    delay: 700,
                  ),
                  _FeaturePill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Insights',
                    delay: 800,
                  ),
                ],
              ),

              const Spacer(),

              // Single CTA
              SizedBox(
                width: double.infinity,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppSpacing.borderRadiusLg,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms)
                  .slideY(
                      begin: 0.2, end: 0, delay: 700.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Feature Pill — compact chip with icon + label
// =============================================================================

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int delay;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.primaryBlue.withValues(alpha: 0.07),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(
          begin: 0.3,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }
}

// =============================================================================
// Goal Selection Page (Step 1 of 4)
// =============================================================================

class _GoalSelectionPage extends StatelessWidget {
  final WorkoutGoal? selectedGoal;
  final ValueChanged<WorkoutGoal> onGoalSelected;

  const _GoalSelectionPage({
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  static const _goals = [
    WorkoutGoal.fatLoss,
    WorkoutGoal.hypertrophy,
    WorkoutGoal.generalFitness,
  ];

  static const _goalDescriptions = {
    WorkoutGoal.fatLoss: 'Burn calories and preserve lean muscle',
    WorkoutGoal.hypertrophy: 'Hypertrophy training and surplus fueling',
    WorkoutGoal.generalFitness: 'Optimize performance and body composition',
  };

  static const _goalLabels = {
    WorkoutGoal.fatLoss: 'Fat Loss',
    WorkoutGoal.hypertrophy: 'Muscle Gain',
    WorkoutGoal.generalFitness: 'Maintenance',
  };

  static const _goalIcons = {
    WorkoutGoal.fatLoss: Icons.local_fire_department_rounded,
    WorkoutGoal.hypertrophy: Icons.fitness_center_rounded,
    WorkoutGoal.generalFitness: Icons.favorite_rounded,
  };

  static const _goalColors = {
    WorkoutGoal.fatLoss: AppColors.warning,
    WorkoutGoal.hypertrophy: AppColors.primaryBlue,
    WorkoutGoal.generalFitness: AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Section icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 400.ms,
                  curve: Curves.easeOutBack),

          const SizedBox(height: AppSpacing.xl),

          Text(
            "What's your\nprimary goal?",
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0, delay: 100.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'This determines your default calorie targets and training splits.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxl),

          ...List.generate(_goals.length, (index) {
            final goal = _goals[index];
            final isSelected = selectedGoal == goal;
            final accentColor = _goalColors[goal]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SelectionCard(
                title: _goalLabels[goal]!,
                subtitle: _goalDescriptions[goal]!,
                icon: _goalIcons[goal]!,
                isSelected: isSelected,
                isDark: isDark,
                accentColor: accentColor,
                onTap: () => onGoalSelected(goal),
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 300 + index * 100),
                  duration: 400.ms,
                )
                .slideY(
                  begin: 0.08,
                  end: 0,
                  delay: Duration(milliseconds: 300 + index * 100),
                  duration: 400.ms,
                );
          }),

          const SizedBox(height: AppSpacing.xl),

          // Tip card
          _TipCard(
            text: 'You can adjust your primary goal anytime in settings.',
            isDark: isDark,
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// =============================================================================
// Selection Card — premium redesign
// =============================================================================

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? accentColor;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.trailing,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = accentColor ?? theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isSelected
              ? primary.withValues(alpha: 0.7)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : (isDark ? null : AppColors.cardShadowLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Icon container with gradient when selected
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary,
                              primary.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.surfaceLight2),
                    borderRadius: AppSpacing.borderRadiusMd,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? Colors.white : primary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),
                _RadioCircle(
                  isSelected: isSelected,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Radio Circle
// =============================================================================

class _RadioCircle extends StatelessWidget {
  final bool isSelected;
  final Color color;

  const _RadioCircle({
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? color
              : (isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight),
          width: isSelected ? 0 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

// =============================================================================
// Tip Card
// =============================================================================

class _TipCard extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryBlue.withValues(alpha: 0.06)
            : AppColors.primaryBlue.withValues(alpha: 0.04),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isDark
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : AppColors.primaryBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.primaryBlueLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Basic Info Page (Step 2 of 4)
// =============================================================================

class _BasicInfoPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final DateTime? selectedDob;
  final ValueChanged<DateTime> onDobSelected;

  const _BasicInfoPage({
    required this.formKey,
    required this.nameController,
    required this.heightController,
    required this.weightController,
    required this.selectedDob,
    required this.onDobSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Section icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent,
                    AppColors.accent.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 400.ms,
                    curve: Curves.easeOutBack),

            const SizedBox(height: AppSpacing.xl),

            Text(
              "Let's get to\nknow you",
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideX(begin: -0.05, end: 0, delay: 100.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'This helps us personalize your calorie targets and training plans.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.xxxl),

            _FieldLabel(text: 'Your Name'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Alex',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            _FieldLabel(text: 'Date of Birth'),
            const SizedBox(height: AppSpacing.sm),
            _DobPickerField(
              selectedDob: selectedDob,
              onDobSelected: onDobSelected,
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 400.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            // Height & Weight in metric cards
            Row(
              children: [
                Expanded(
                  child: _MetricInputCard(
                    label: 'HEIGHT',
                    unit: 'cm',
                    hint: '175',
                    icon: Icons.height_rounded,
                    controller: heightController,
                    isDark: isDark,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final h = double.tryParse(value.trim());
                        if (h == null || h < 50 || h > 300) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricInputCard(
                    label: 'WEIGHT',
                    unit: 'kg',
                    hint: '70',
                    icon: Icons.monitor_weight_outlined,
                    controller: weightController,
                    isDark: isDark,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final w = double.tryParse(value.trim());
                        if (w == null || w < 20 || w > 500) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Metric Input Card — visual card wrapper for height/weight inputs
// =============================================================================

class _MetricInputCard extends StatelessWidget {
  final String label;
  final String unit;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final String? Function(String?)? validator;

  const _MetricInputCard({
    required this.label,
    required this.unit,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow: isDark ? null : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDisabledDark
                    : AppColors.textDisabledLight,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}

// =============================================================================
// Date of Birth Picker Field
// =============================================================================

class _DobPickerField extends StatelessWidget {
  final DateTime? selectedDob;
  final ValueChanged<DateTime> onDobSelected;

  const _DobPickerField({
    required this.selectedDob,
    required this.onDobSelected,
  });

  int? get _age {
    if (selectedDob == null) return null;
    final now = DateTime.now();
    int years = now.year - selectedDob!.year;
    if (now.month < selectedDob!.month ||
        (now.month == selectedDob!.month && now.day < selectedDob!.day)) {
      years--;
    }
    return years;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDob ?? DateTime(now.year - 25, now.month, now.day),
          firstDate: DateTime(1900),
          lastDate: DateTime(now.year - 13, now.month, now.day),
          helpText: 'SELECT YOUR DATE OF BIRTH',
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  surface: isDark
                      ? AppColors.surfaceDark1
                      : AppColors.surfaceLight,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDobSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Select your date of birth',
          prefixIcon: const Icon(Icons.cake_outlined),
          suffixIcon: _age != null
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    widthFactor: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: Text(
                        '$_age yrs',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        child: Text(
          selectedDob != null
              ? DateFormat('d MMM yyyy').format(selectedDob!)
              : 'Select your date of birth',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: selectedDob != null
                ? null
                : (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Gender & Activity Level Page (Step 3 of 4)
// =============================================================================

class _GenderActivityPage extends StatelessWidget {
  final Gender? selectedGender;
  final ActivityLevel? selectedActivityLevel;
  final ValueChanged<Gender> onGenderSelected;
  final ValueChanged<ActivityLevel> onActivityLevelSelected;

  const _GenderActivityPage({
    required this.selectedGender,
    required this.selectedActivityLevel,
    required this.onGenderSelected,
    required this.onActivityLevelSelected,
  });

  static const _genderIcons = {
    Gender.male: Icons.male_rounded,
    Gender.female: Icons.female_rounded,
    Gender.other: Icons.transgender_rounded,
  };

  static const _genderDescriptions = {
    Gender.male: 'Biological male',
    Gender.female: 'Biological female',
    Gender.other: 'Prefer not to specify',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Section icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.copper,
                  AppColors.copperLight,
                ],
              ),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 400.ms,
                  curve: Curves.easeOutBack),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'About you',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0, delay: 100.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Used to calculate your basal metabolic rate and daily calorie needs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxl),

          // Gender Section
          _SectionLabel(text: 'Gender', isDark: isDark)
              .animate().fadeIn(delay: 250.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.md),

          ...List.generate(Gender.values.length, (index) {
            final gender = Gender.values[index];
            final isSelected = selectedGender == gender;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SelectionCard(
                title: gender.displayName,
                subtitle: _genderDescriptions[gender]!,
                icon: _genderIcons[gender]!,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onGenderSelected(gender),
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 300 + index * 80),
                  duration: 400.ms,
                )
                .slideY(
                  begin: 0.06,
                  end: 0,
                  delay: Duration(milliseconds: 300 + index * 80),
                  duration: 400.ms,
                );
          }),

          const SizedBox(height: AppSpacing.xl),

          // Activity Level Section
          _SectionLabel(text: 'Activity Level', isDark: isDark)
              .animate().fadeIn(delay: 550.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.md),

          ...List.generate(ActivityLevel.values.length, (index) {
            final level = ActivityLevel.values[index];
            final isSelected = selectedActivityLevel == level;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SelectionCard(
                title: level.displayName,
                subtitle: level.description,
                icon: level.icon,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onActivityLevelSelected(level),
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 600 + index * 80),
                  duration: 400.ms,
                )
                .slideY(
                  begin: 0.06,
                  end: 0,
                  delay: Duration(milliseconds: 600 + index * 80),
                  duration: 400.ms,
                );
          }),

          const SizedBox(height: AppSpacing.xl),

          _TipCard(
            text: 'We use this for more accurate calorie calculations.',
            isDark: isDark,
          ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// =============================================================================
// Section Label
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusPill,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Experience Level Page (Step 4 of 4)
// =============================================================================

class _ExperienceLevelPage extends StatelessWidget {
  final ExperienceLevel? selectedLevel;
  final ValueChanged<ExperienceLevel> onLevelSelected;

  const _ExperienceLevelPage({
    required this.selectedLevel,
    required this.onLevelSelected,
  });

  static const _levelDescriptions = {
    ExperienceLevel.beginner: 'New to fitness or returning after a break',
    ExperienceLevel.intermediate: 'Consistent training for 6+ months',
    ExperienceLevel.advanced: 'Experienced lifter with 2+ years',
  };

  static const _levelIcons = {
    ExperienceLevel.beginner: Icons.emoji_nature_rounded,
    ExperienceLevel.intermediate: Icons.trending_up_rounded,
    ExperienceLevel.advanced: Icons.military_tech_rounded,
  };

  static const _levelColors = {
    ExperienceLevel.beginner: AppColors.accent,
    ExperienceLevel.intermediate: AppColors.primaryBlue,
    ExperienceLevel.advanced: AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Section icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning,
                  AppColors.warning.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 400.ms,
                  curve: Curves.easeOutBack),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Your experience\nlevel?',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0, delay: 100.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'This helps us set the right intensity for your training plans.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xxxl),

          ...List.generate(ExperienceLevel.values.length, (index) {
            final level = ExperienceLevel.values[index];
            final isSelected = selectedLevel == level;
            final accentColor = _levelColors[level]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SelectionCard(
                title: level.displayName,
                subtitle: _levelDescriptions[level]!,
                icon: _levelIcons[level]!,
                isSelected: isSelected,
                isDark: isDark,
                accentColor: accentColor,
                onTap: () => onLevelSelected(level),
                trailing: _LevelBars(
                  barCount: index + 1,
                  isSelected: isSelected,
                  isDark: isDark,
                  color: accentColor,
                ),
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 300 + index * 120),
                  duration: 400.ms,
                )
                .slideY(
                  begin: 0.08,
                  end: 0,
                  delay: Duration(milliseconds: 300 + index * 120),
                  duration: 400.ms,
                );
          }),

          const Spacer(),

          // Final step encouragement
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: AppSpacing.borderRadiusPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Almost done! One last step.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// =============================================================================
// Level Bars
// =============================================================================

class _LevelBars extends StatelessWidget {
  final int barCount;
  final bool isSelected;
  final bool isDark;
  final Color? color;

  const _LevelBars({
    required this.barCount,
    required this.isSelected,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      children: List.generate(3, (i) {
        final isActive = i < barCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 4),
          width: 28,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusPill,
            gradient: isActive && isSelected
                ? LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.7)],
                  )
                : null,
            color: isActive && !isSelected
                ? (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight)
                : (!isActive
                    ? (isDark
                        ? AppColors.surfaceDark3
                        : AppColors.surfaceLight3)
                    : null),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Bottom Navigation — pages 1-4 only
// =============================================================================

class _BottomNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _BottomNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isSaving,
    required this.onBack,
    required this.onContinue,
  });

  String get _buttonLabel {
    if (currentPage == totalPages) return 'Complete Setup';
    return 'Continue';
  }

  IconData? get _buttonIcon {
    if (currentPage == totalPages) return Icons.celebration_rounded;
    return Icons.chevron_right_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : AppColors.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: isSaving ? null : onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.dividerLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Main CTA
          Expanded(
            child: SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isSaving ? null : AppColors.primaryGradient,
                  color: isSaving
                      ? (isDark
                          ? AppColors.surfaceDark2
                          : AppColors.surfaceLight3)
                      : null,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow: isSaving
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: isSaving ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _buttonLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (_buttonIcon != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                _buttonIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
