import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/body_metric.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';

class AddBodyMetricScreen extends ConsumerStatefulWidget {
  const AddBodyMetricScreen({super.key});

  @override
  ConsumerState<AddBodyMetricScreen> createState() =>
      _AddBodyMetricScreenState();
}

class _AddBodyMetricScreenState extends ConsumerState<AddBodyMetricScreen> {
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _bicepLeftController = TextEditingController();
  final _bicepRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _neckController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _measurementsExpanded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _bicepLeftController.dispose();
    _bicepRightController.dispose();
    _thighLeftController.dispose();
    _thighRightController.dispose();
    _neckController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Premium header
              _buildHeader(theme, isDark),

              // Scrollable form content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    // Date picker
                    _buildDatePicker(theme, isDark),
                    const SizedBox(height: AppSpacing.xxl),

                    // Weight input (prominent)
                    _buildWeightInput(theme, isDark),
                    const SizedBox(height: AppSpacing.lg),

                    // Body fat percentage
                    _buildBodyFatInput(theme, isDark),
                    const SizedBox(height: AppSpacing.xxl),

                    // Measurements (expandable)
                    _buildMeasurementsSection(theme, isDark),
                    const SizedBox(height: AppSpacing.xxl),

                    // Progress photo placeholder
                    _buildPhotoPlaceholder(theme, isDark),
                    const SizedBox(height: AppSpacing.xxl),

                    // Notes
                    _buildNotesField(theme, isDark),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Save button
                    _buildSaveButton(theme, isDark),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOG METRIC',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  'Body Measurement',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildDatePicker(ThemeData theme, bool isDark) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today' : DateFormat('EEEE').format(_selectedDate),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    DateFormat('MMMM d, yyyy').format(_selectedDate),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildWeightInput(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueSurface.withValues(alpha: 0.4),
                  AppColors.surfaceDark1,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.04),
                  theme.colorScheme.surface,
                ],
              ),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          ...isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Weight', style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  'Primary',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.2),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final v = double.tryParse(value);
                    if (v == null || v <= 0 || v > 500) {
                      return 'Enter a valid weight';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    'kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 500.ms,
            delay: 100.ms,
            curve: Curves.easeOut);
  }

  Widget _buildBodyFatInput(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: const Icon(Icons.percent_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Body Fat', style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  'Optional',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _bodyFatController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '--',
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.2),
                ),
                suffixText: '%',
                suffixStyle: theme.textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                final v = double.tryParse(value);
                if (v == null || v < 1 || v > 70) {
                  return 'Invalid';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 500.ms,
            delay: 200.ms,
            curve: Curves.easeOut);
  }

  Widget _buildMeasurementsSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: _measurementsExpanded
              ? AppColors.info.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight),
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (tap to expand)
          GestureDetector(
            onTap: () =>
                setState(() => _measurementsExpanded = !_measurementsExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          AppColors.info.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(Icons.straighten_rounded,
                        color: AppColors.info, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Measurements',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          'Tap to ${_measurementsExpanded ? 'collapse' : 'expand'} (optional)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _measurementsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.dividerLight,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MeasurementRow(
                    label: 'Chest',
                    icon: Icons.straighten_rounded,
                    controller: _chestController,
                  ),
                  _MeasurementRow(
                    label: 'Waist',
                    icon: Icons.straighten_rounded,
                    controller: _waistController,
                  ),
                  _MeasurementRow(
                    label: 'Hips',
                    icon: Icons.straighten_rounded,
                    controller: _hipsController,
                  ),
                  _MeasurementRow(
                    label: 'Bicep (L)',
                    icon: Icons.fitness_center_rounded,
                    controller: _bicepLeftController,
                  ),
                  _MeasurementRow(
                    label: 'Bicep (R)',
                    icon: Icons.fitness_center_rounded,
                    controller: _bicepRightController,
                  ),
                  _MeasurementRow(
                    label: 'Thigh (L)',
                    icon: Icons.directions_walk_rounded,
                    controller: _thighLeftController,
                  ),
                  _MeasurementRow(
                    label: 'Thigh (R)',
                    icon: Icons.directions_walk_rounded,
                    controller: _thighRightController,
                  ),
                  _MeasurementRow(
                    label: 'Neck',
                    icon: Icons.accessibility_new_rounded,
                    controller: _neckController,
                  ),
                ],
              ),
            ),
            crossFadeState: _measurementsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 500.ms,
            delay: 300.ms,
            curve: Curves.easeOut);
  }

  Widget _buildPhotoPlaceholder(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/capture-progress-photo'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Stack(
          children: [
            // Subtle gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.borderRadiusLg,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: isDark ? 0.06 : 0.03),
                      AppColors.accent.withValues(alpha: isDark ? 0.04 : 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.borderRadiusMd,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Progress Photo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        'Track visible changes over time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildNotesField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
        boxShadow:
            isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Optional',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'How are you feeling today?',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textDisabledDark
                      : AppColors.textDisabledLight,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
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
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: isDark
                ? AppColors.textDisabledDark
                : AppColors.textDisabledLight,
            shadowColor: Colors.transparent,
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
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Save Metric',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 600.ms);
  }

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

  double? _parseOptional(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final metric = BodyMetric(
        id: const Uuid().v4(),
        date: _selectedDate,
        weight: _parseOptional(_weightController),
        bodyFatPercentage: _parseOptional(_bodyFatController),
        chest: _parseOptional(_chestController),
        waist: _parseOptional(_waistController),
        hips: _parseOptional(_hipsController),
        bicepLeft: _parseOptional(_bicepLeftController),
        bicepRight: _parseOptional(_bicepRightController),
        thighLeft: _parseOptional(_thighLeftController),
        thighRight: _parseOptional(_thighRightController),
        neck: _parseOptional(_neckController),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final source = ref.read(dataSourceProvider);
      if (source == DataSourceType.supabase) {
        final sbRepo = ref.read(sbBodyMetricRepositoryProvider);
        await sbRepo.addMetric(metric);
      } else {
        final repo = ref.read(bodyMetricRepositoryProvider);
        await repo.saveMetric(metric.toJson());
      }

      // Invalidate providers to refresh data
      ref.invalidate(bodyMetricsProvider);
      ref.invalidate(latestMetricProvider);
      ref.invalidate(weightHistoryProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text('Body metric saved'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Measurement Row
// ─────────────────────────────────────────────────────────────────────────────

class _MeasurementRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;

  const _MeasurementRow({
    required this.label,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '--',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textDisabledDark
                        : AppColors.textDisabledLight,
                  ),
                  suffixText: 'cm',
                  suffixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
