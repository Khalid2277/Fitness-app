import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/reminder.dart';
import 'package:alfanutrition/features/reminders/providers/reminder_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: theme.colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTIFICATIONS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Reminders',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reminder count badge
                  remindersAsync.maybeWhen(
                    data: (reminders) {
                      if (reminders.isEmpty) return const SizedBox.shrink();
                      final active = reminders.where((r) => r.isEnabled).length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '$active active',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: remindersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Text(
                      'Failed to load reminders.\n$e',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                data: (reminders) {
                  if (reminders.isEmpty) {
                    return _EmptyState(
                      onAdd: () => _showAddReminderSheet(context, ref),
                    );
                  }

                  // Group by type.
                  final weightReminders = reminders
                      .where((r) => r.type == ReminderType.weight)
                      .toList();
                  final foodReminders = reminders
                      .where((r) => r.type == ReminderType.food)
                      .toList();
                  final exerciseReminders = reminders
                      .where((r) => r.type == ReminderType.exercise)
                      .toList();

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                    ),
                    children: [
                      if (weightReminders.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Weight',
                          icon: Icons.monitor_weight_outlined,
                          color: AppColors.primaryBlue,
                          count: weightReminders.length,
                        ),
                        ...weightReminders.asMap().entries.map(
                          (entry) => _ReminderCard(
                            reminder: entry.value,
                            index: entry.key,
                            onToggle: () => ref
                                .read(reminderActionsProvider)
                                .toggleReminder(entry.value),
                            onEdit: () => _showAddReminderSheet(
                              context,
                              ref,
                              existing: entry.value,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, entry.value),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (foodReminders.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Food Log',
                          icon: Icons.restaurant_outlined,
                          color: AppColors.accent,
                          count: foodReminders.length,
                        ),
                        ...foodReminders.asMap().entries.map(
                          (entry) => _ReminderCard(
                            reminder: entry.value,
                            index: entry.key,
                            onToggle: () => ref
                                .read(reminderActionsProvider)
                                .toggleReminder(entry.value),
                            onEdit: () => _showAddReminderSheet(
                              context,
                              ref,
                              existing: entry.value,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, entry.value),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (exerciseReminders.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Exercise',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.warning,
                          count: exerciseReminders.length,
                        ),
                        ...exerciseReminders.asMap().entries.map(
                          (entry) => _ReminderCard(
                            reminder: entry.value,
                            index: entry.key,
                            onToggle: () => ref
                                .read(reminderActionsProvider)
                                .toggleReminder(entry.value),
                            onEdit: () => _showAddReminderSheet(
                              context,
                              ref,
                              existing: entry.value,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, ref, entry.value),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: remindersAsync.maybeWhen(
        data: (reminders) {
          if (reminders.isEmpty) return null;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddReminderSheet(context, ref),
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add Reminder',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  void _showAddReminderSheet(
    BuildContext context,
    WidgetRef ref, {
    Reminder? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(
        existing: existing,
        onSave: (reminder) {
          ref.read(reminderActionsProvider).saveReminder(reminder);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Reminder reminder) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          'Delete Reminder',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(reminderActionsProvider).deleteReminder(reminder);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with layered rings
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.06 : 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.12 : 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No Reminders Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Set up reminders to stay on track with your\nweight logging, meals, and workouts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Create Your First Reminder',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _colorForType(reminder.type);
    final typeIcon = _iconForType(reminder.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      child: GestureDetector(
        onTap: onEdit,
        onLongPress: onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: reminder.isEnabled
                  ? typeColor.withValues(alpha: isDark ? 0.2 : 0.15)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.dividerLight),
              width: 1,
            ),
            boxShadow: isDark
                ? AppColors.cardShadowDark
                : AppColors.cardShadowLight,
          ),
          child: Row(
            children: [
              // Type icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: reminder.isEnabled
                      ? typeColor.withValues(alpha: isDark ? 0.15 : 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.surfaceLight2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  typeIcon,
                  size: 20,
                  color: reminder.isEnabled
                      ? typeColor
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Time and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.timeString,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: reminder.isEnabled
                            ? theme.colorScheme.onSurface
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reminder.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          reminder.frequencyString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: reminder.isEnabled
                                ? (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle
              Switch.adaptive(
                value: reminder.isEnabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accent,
                inactiveThumbColor: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 80).ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: (index * 80).ms);
  }

  Color _colorForType(ReminderType type) {
    switch (type) {
      case ReminderType.weight:
        return AppColors.primaryBlue;
      case ReminderType.food:
        return AppColors.accent;
      case ReminderType.exercise:
        return AppColors.warning;
    }
  }

  IconData _iconForType(ReminderType type) {
    switch (type) {
      case ReminderType.weight:
        return Icons.monitor_weight_outlined;
      case ReminderType.food:
        return Icons.restaurant_outlined;
      case ReminderType.exercise:
        return Icons.fitness_center_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Reminder Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  final Reminder? existing;
  final ValueChanged<Reminder> onSave;

  const _AddReminderSheet({
    this.existing,
    required this.onSave,
  });

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  late ReminderType _type;
  late TimeOfDay _time;
  late ReminderFrequency _frequency;
  late Set<int> _customDays; // 1=Mon .. 7=Sun

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _type = r.type;
      _time = TimeOfDay(hour: r.hour, minute: r.minute);
      _frequency = r.frequency;
      _customDays = Set<int>.from(r.customDays);
    } else {
      _type = ReminderType.weight;
      _time = const TimeOfDay(hour: 8, minute: 0);
      _frequency = ReminderFrequency.daily;
      _customDays = {};
    }
  }

  String _defaultTitle() {
    switch (_type) {
      case ReminderType.weight:
        return 'Time to weigh in!';
      case ReminderType.food:
        return 'Log your meals';
      case ReminderType.exercise:
        return 'Time to work out!';
    }
  }

  String _defaultBody() {
    switch (_type) {
      case ReminderType.weight:
        return 'Track your progress by logging your weight today.';
      case ReminderType.food:
        return "Don't forget to log what you ate today.";
      case ReminderType.exercise:
        return 'Stay consistent and get your workout in today!';
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _save() {
    final reminder = Reminder(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      title: _defaultTitle(),
      body: _defaultBody(),
      hour: _time.hour,
      minute: _time.minute,
      frequency: _frequency,
      customDays: _customDays.toList()..sort(),
      isEnabled: widget.existing?.isEnabled ?? true,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(reminder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          MediaQuery.of(context).padding.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              _isEditing ? 'Edit Reminder' : 'New Reminder',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Reminder type selector
            Text(
              'TYPE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: ReminderType.values.map((type) {
                final isSelected = _type == type;
                final color = _colorForType(type);
                final icon = _iconForType(type);
                final label = _labelForType(type);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type != ReminderType.exercise
                          ? AppSpacing.sm
                          : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.surfaceLight2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              color: isSelected
                                  ? color
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight),
                              size: 22,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Time picker
            Text(
              'TIME',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.surfaceLight2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.dividerLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _time.format(context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
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
            const SizedBox(height: AppSpacing.xxl),

            // Frequency selector
            Text(
              'FREQUENCY',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ReminderFrequency.values.map((freq) {
                final isSelected = _frequency == freq;
                final label = _frequencyLabel(freq);

                return GestureDetector(
                  onTap: () => setState(() => _frequency = freq),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlueSurface
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.surfaceLight2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppColors.primaryBlueLight
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom day selector
            if (_frequency == ReminderFrequency.custom) ...[
              const SizedBox(height: AppSpacing.lg),
              _CustomDaySelector(
                selectedDays: _customDays,
                onChanged: (days) => setState(() => _customDays = days),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _frequency == ReminderFrequency.custom &&
                          _customDays.isEmpty
                      ? null
                      : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor:
                        Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update Reminder' : 'Save Reminder',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _frequency == ReminderFrequency.custom &&
                              _customDays.isEmpty
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(ReminderType type) {
    switch (type) {
      case ReminderType.weight:
        return AppColors.primaryBlue;
      case ReminderType.food:
        return AppColors.accent;
      case ReminderType.exercise:
        return AppColors.warning;
    }
  }

  IconData _iconForType(ReminderType type) {
    switch (type) {
      case ReminderType.weight:
        return Icons.monitor_weight_outlined;
      case ReminderType.food:
        return Icons.restaurant_outlined;
      case ReminderType.exercise:
        return Icons.fitness_center_rounded;
    }
  }

  String _labelForType(ReminderType type) {
    switch (type) {
      case ReminderType.weight:
        return 'Weight';
      case ReminderType.food:
        return 'Food';
      case ReminderType.exercise:
        return 'Exercise';
    }
  }

  String _frequencyLabel(ReminderFrequency freq) {
    switch (freq) {
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekdays:
        return 'Weekdays';
      case ReminderFrequency.weekends:
        return 'Weekends';
      case ReminderFrequency.custom:
        return 'Custom';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Day Selector (Mon-Sun checkboxes)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomDaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  const _CustomDaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = index + 1; // 1=Mon, 7=Sun
        final isSelected = selectedDays.contains(day);

        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selectedDays);
            if (isSelected) {
              updated.remove(day);
            } else {
              updated.add(day);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.surfaceLight2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
