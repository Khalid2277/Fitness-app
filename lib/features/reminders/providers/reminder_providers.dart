import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/reminder.dart';
import 'package:alfanutrition/data/repositories/reminder_repository.dart';
import 'package:alfanutrition/data/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Singletons
// ─────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// All reminders (read-only, invalidate to refresh)
// ─────────────────────────────────────────────────────────────────────────────

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  final rawList = await repo.getAll();
  return rawList.map((m) => Reminder.fromJson(m)).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Reminder notifier for mutations
// ─────────────────────────────────────────────────────────────────────────────

final reminderActionsProvider = Provider<ReminderActions>((ref) {
  return ReminderActions(ref);
});

class ReminderActions {
  final Ref _ref;

  ReminderActions(this._ref);

  ReminderRepository get _repo => _ref.read(reminderRepositoryProvider);
  NotificationService get _notif => _ref.read(notificationServiceProvider);

  /// Save a new or updated reminder and schedule its notifications.
  Future<void> saveReminder(Reminder reminder) async {
    await _repo.save(reminder.toJson());
    await _notif.rescheduleReminder(reminder);
    _ref.invalidate(remindersProvider);
  }

  /// Delete a reminder and cancel its notifications.
  Future<void> deleteReminder(Reminder reminder) async {
    await _notif.cancelReminder(reminder);
    await _repo.delete(reminder.id);
    _ref.invalidate(remindersProvider);
  }

  /// Toggle a reminder's enabled state and reschedule/cancel accordingly.
  Future<void> toggleReminder(Reminder reminder) async {
    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await _repo.save(updated.toJson());
    await _notif.rescheduleReminder(updated);
    _ref.invalidate(remindersProvider);
  }
}
