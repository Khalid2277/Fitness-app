import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/features/progress/providers/progress_photo_providers.dart';

/// Guided capture flow for taking 4 progress photos.
class CaptureProgressPhotoScreen extends ConsumerStatefulWidget {
  const CaptureProgressPhotoScreen({super.key});

  @override
  ConsumerState<CaptureProgressPhotoScreen> createState() =>
      _CaptureProgressPhotoScreenState();
}

class _CaptureProgressPhotoScreenState
    extends ConsumerState<CaptureProgressPhotoScreen> {
  int _currentStep = 0;
  final Map<String, String> _photos = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  bool _isSaving = false;

  static const _angles = PhotoAngle.values;

  PhotoAngle get _currentAngle => _angles[_currentStep];

  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked == null) return;

    // Copy image to app's documents directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/progress_photos');
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = picked.path.split('.').last;
    final fileName = 'progress_${_currentAngle.key}_$timestamp.$ext';
    final savedPath = '${photosDir.path}/$fileName';

    await File(picked.path).copy(savedPath);

    setState(() {
      _photos[_currentAngle.key] = savedPath;
      // Auto-advance to next uncaptured angle
      if (_currentStep < _angles.length - 1) {
        _currentStep++;
      }
    });
  }

  Future<void> _savePhotoSet() async {
    if (_photos.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final id = 'ps_${now.millisecondsSinceEpoch}';
      final weight = double.tryParse(_weightController.text.trim());
      final bodyFat = double.tryParse(_bodyFatController.text.trim());

      final photoSet = ProgressPhotoSet(
        id: id,
        date: now,
        photos: Map<String, String>.from(_photos),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        weight: weight,
        bodyFatPercentage: bodyFat,
        createdAt: now,
      );

      final repo = ref.read(progressPhotoRepositoryProvider);
      await repo.savePhotoSet(photoSet.toJson());
      ref.invalidate(allProgressPhotosProvider);
      ref.invalidate(latestProgressPhotoProvider);

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
            // ── Top bar ─────────────────────────────────────────────────
            _buildTopBar(theme, isDark),
            const SizedBox(height: AppSpacing.sm),

            // ── Step progress ───────────────────────────────────────────
            _buildStepProgress(theme, isDark),
            const SizedBox(height: AppSpacing.lg),

            // ── Scrollable content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  children: [
                    _buildAngleGuide(theme, isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPhotoArea(theme, isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAngleSelector(theme, isDark),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildOptionalFields(theme, isDark),
                    const SizedBox(height: AppSpacing.xxxl),
                    _buildSaveButton(theme, isDark),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Top bar ──────────────────────────────────────

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showDiscardDialog(context, theme, isDark),
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
                Icons.close_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'CAPTURE',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                'Progress Photos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Balance spacing
          const SizedBox(width: 40),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _showDiscardDialog(
      BuildContext context, ThemeData theme, bool isDark) {
    if (_photos.isEmpty) {
      context.pop();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: const Text('Discard photos?'),
        content: const Text(
          'You have unsaved progress photos. They will be lost if you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Discard',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Step progress ────────────────────────────────

  Widget _buildStepProgress(ThemeData theme, bool isDark) {
    final capturedCount = _photos.length;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_currentStep + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'of ${_angles.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: capturedCount > 0
                      ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
                child: Text(
                  '$capturedCount photo${capturedCount == 1 ? '' : 's'} taken',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: capturedCount > 0
                        ? AppColors.accent
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(_angles.length, (i) {
              final hasCaptured = _photos.containsKey(_angles[i].key);
              final isActive = i == _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < _angles.length - 1 ? AppSpacing.xs : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.borderRadiusPill,
                      gradient: hasCaptured
                          ? const LinearGradient(
                              colors: [AppColors.accent, AppColors.accentLight],
                            )
                          : isActive
                              ? AppColors.primaryGradient
                              : null,
                      color: hasCaptured || isActive
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.dividerLight),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Angle guide ──────────────────────────────────

  Widget _buildAngleGuide(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                  AppColors.surfaceLight,
                ],
              ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusMd,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _iconForAngle(_currentAngle),
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAngle.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _currentAngle.poseGuide,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  IconData _iconForAngle(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return Icons.accessibility_new_rounded;
      case PhotoAngle.leftSide:
        return Icons.turn_left_rounded;
      case PhotoAngle.rightSide:
        return Icons.turn_right_rounded;
      case PhotoAngle.back:
        return Icons.airline_seat_flat_rounded;
    }
  }

  // ─────────────────────────── Photo area ───────────────────────────────────

  Widget _buildPhotoArea(ThemeData theme, bool isDark) {
    final currentPath = _photos[_currentAngle.key];
    final hasPhoto = currentPath != null;

    return GestureDetector(
      onTap: _pickPhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 360,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: hasPhoto
                ? AppColors.accent.withValues(alpha: 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.dividerLight),
            width: hasPhoto ? 2 : 1.5,
          ),
          boxShadow: [
            if (hasPhoto)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ...isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
          ],
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.borderRadiusXl,
          child: hasPhoto
              ? _buildPhotoPreview(currentPath, theme, isDark)
              : _buildEmptyPhotoArea(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(String path, ThemeData theme, bool isDark) {
    final file = File(path);
    if (file.existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          // Overlay for retake
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.borderRadiusPill,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tap to retake',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Angle label
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppSpacing.borderRadiusPill,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _currentAngle.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // File path saved but file not found — show placeholder
    return _buildEmptyPhotoArea(theme, isDark);
  }

  Widget _buildEmptyPhotoArea(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gradient ring around icon
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.12),
                AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            _iconForAngle(_currentAngle),
            size: 40,
            color: AppColors.primaryBlue.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _currentAngle.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap to select from your photo library',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusPill,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Choose Photo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Angle selector ───────────────────────────────

  Widget _buildAngleSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALL ANGLES',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: List.generate(_angles.length, (i) {
            final angle = _angles[i];
            final hasCaptured = _photos.containsKey(angle.key);
            final isSelected = i == _currentStep;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: i < _angles.length - 1 ? AppSpacing.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _currentStep = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(
                              alpha: isDark ? 0.15 : 0.1)
                          : hasCaptured
                              ? AppColors.accent.withValues(
                                  alpha: isDark ? 0.08 : 0.05)
                              : (isDark
                                  ? AppColors.surfaceDark1
                                  : AppColors.surfaceLight),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.5)
                            : hasCaptured
                                ? AppColors.accent.withValues(alpha: 0.3)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : AppColors.dividerLight),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        if (hasCaptured)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            _iconForAngle(angle),
                            size: 20,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          angle.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isSelected || hasCaptured
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : hasCaptured
                                    ? AppColors.accent
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────── Optional fields ──────────────────────────────

  Widget _buildOptionalFields(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPTIONAL DETAILS',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Weight + Body fat row
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                theme: theme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildTextField(
                controller: _bodyFatController,
                label: 'Body fat %',
                icon: Icons.percent_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                theme: theme,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Notes
        _buildTextField(
          controller: _notesController,
          label: 'Notes (e.g. morning, fasted, post-workout)',
          icon: Icons.notes_rounded,
          maxLines: 2,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required ThemeData theme,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  // ─────────────────────────── Save button ──────────────────────────────────

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    final hasPhotos = _photos.isNotEmpty;
    final photoCount = _photos.length;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: hasPhotos ? AppColors.primaryGradient : null,
          color: hasPhotos
              ? null
              : (isDark
                  ? AppColors.surfaceDark2
                  : AppColors.surfaceLight3),
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: hasPhotos
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: hasPhotos && !_isSaving ? _savePhotoSet : null,
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
                    Icon(
                      hasPhotos
                          ? Icons.check_rounded
                          : Icons.camera_alt_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      hasPhotos
                          ? 'Save Progress Photos ($photoCount/4)'
                          : 'Take at least 1 photo to save',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasPhotos
                            ? Colors.white
                            : (isDark
                                ? AppColors.textDisabledDark
                                : AppColors.textDisabledLight),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
