import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:alfanutrition/data/models/reminder.dart';

/// Wraps flutter_local_notifications to schedule and cancel reminders.
///
/// Delivers real OS-level notifications that appear in the notification center,
/// on the lock screen, and with sound/badge — even when the app is closed.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsGranted = false;

  /// Initialize the notification plugin and timezone data.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database and set device local timezone.
    tz_data.initializeTimeZones();
    _setLocalTimezone();

    const iosSettings = DarwinInitializationSettings(
      // Don't request on init — we'll request when the user creates a reminder.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    _initialized = true;
  }

  /// Callback when a user taps a notification.
  void _onNotificationTapped(NotificationResponse response) {
    // Can be used to navigate to a specific screen based on payload.
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Set the local timezone based on the device's current offset.
  void _setLocalTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Find a timezone location that matches the device's current UTC offset.
      final knownZones = tz.timeZoneDatabase.locations;
      for (final entry in knownZones.entries) {
        final loc = entry.value;
        final locNow = tz.TZDateTime.now(loc);
        if (locNow.timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          return;
        }
      }
      // Fallback: use UTC offset-based lookup.
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint('Failed to set local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Request notification permissions on iOS.
  ///
  /// This triggers the system permission dialog. Must be called before
  /// scheduling any notifications. Returns true if granted.
  Future<bool> requestPermissions() async {
    if (_permissionsGranted) return true;

    if (Platform.isIOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionsGranted = granted ?? false;
        return _permissionsGranted;
      }
    } else if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionsGranted = granted ?? false;
        return _permissionsGranted;
      }
    }
    _permissionsGranted = true;
    return true;
  }

  /// Whether permissions have been granted.
  bool get hasPermissions => _permissionsGranted;

  /// Schedule all notifications for a [Reminder].
  ///
  /// Each active day gets its own scheduled notification, identified by
  /// a unique int derived from the reminder's id and the day number.
  /// Automatically requests permissions if not yet granted.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    // Ensure we have notification permissions before scheduling.
    final granted = await requestPermissions();
    if (!granted) {
      debugPrint('Notification permissions denied — cannot schedule reminder.');
      return;
    }

    final days = reminder.activeDays;
    for (final day in days) {
      final notifId = _notificationId(reminder.id, day);
      await _scheduleWeeklyNotification(
        id: notifId,
        title: reminder.title,
        body: reminder.body,
        hour: reminder.hour,
        minute: reminder.minute,
        weekday: day, // 1=Mon, 7=Sun
      );
    }
  }

  /// Cancel all notifications associated with a [Reminder].
  Future<void> cancelReminder(Reminder reminder) async {
    // Cancel for all 7 possible days to be safe.
    for (int day = 1; day <= 7; day++) {
      final notifId = _notificationId(reminder.id, day);
      await _plugin.cancel(notifId);
    }
  }

  /// Cancel a single notification by its ID.
  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Reschedule a reminder (cancel existing, then schedule new).
  Future<void> rescheduleReminder(Reminder reminder) async {
    await cancelReminder(reminder);
    if (reminder.isEnabled) {
      await scheduleReminder(reminder);
    }
  }

  // ─────────────────────────── Private helpers ─────────────────────────────

  /// Generate a unique int notification ID from reminder id + day.
  int _notificationId(String reminderId, int day) {
    // Use hashCode and combine with day to ensure uniqueness.
    return (reminderId.hashCode.abs() * 10 + day) % 2147483647;
  }

  /// Schedule a weekly repeating notification for a specific weekday.
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    final scheduledDate = _nextInstanceOfWeekdayTime(weekday, hour, minute);

    const notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Fitness reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  /// Returns the next [tz.TZDateTime] for the given weekday and time.
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Find the next occurrence of the target weekday.
    // DateTime weekday: 1=Mon, 7=Sun (same as our convention).
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // If the computed time is in the past, advance by one week.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
