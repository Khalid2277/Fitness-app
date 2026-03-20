import 'package:hive/hive.dart';

/// Types of reminders the user can configure.
enum ReminderType {
  weight,    // Weigh-in reminder
  food,      // Log food reminder
  exercise,  // Exercise/workout reminder
}

/// Frequency options for reminders.
enum ReminderFrequency {
  daily,
  weekdays,   // Mon-Fri
  weekends,   // Sat-Sun
  custom,     // Specific days
}

/// A user-configured reminder with time, frequency, and enabled state.
class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String body;
  final int hour;      // 0-23
  final int minute;    // 0-59
  final ReminderFrequency frequency;
  final List<int> customDays; // 1=Mon, 7=Sun (for custom frequency)
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.frequency = ReminderFrequency.daily,
    this.customDays = const [],
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Reminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? body,
    int? hour,
    int? minute,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'frequency': frequency.index,
    'customDays': customDays,
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    type: ReminderType.values[json['type'] as int],
    title: json['title'] as String,
    body: json['body'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    frequency: ReminderFrequency.values[json['frequency'] as int],
    customDays: (json['customDays'] as List<dynamic>?)?.cast<int>() ?? [],
    isEnabled: json['isEnabled'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// Display-friendly time string (e.g. "8:30 AM").
  String get timeString {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// Display-friendly frequency string.
  String get frequencyString {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'Every day';
      case ReminderFrequency.weekdays:
        return 'Weekdays';
      case ReminderFrequency.weekends:
        return 'Weekends';
      case ReminderFrequency.custom:
        if (customDays.isEmpty) return 'No days selected';
        const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final sorted = List<int>.from(customDays)..sort();
        return sorted.map((d) => dayNames[d]).join(', ');
    }
  }

  /// Label for the reminder type.
  String get typeLabel {
    switch (type) {
      case ReminderType.weight:
        return 'Weight';
      case ReminderType.food:
        return 'Food Log';
      case ReminderType.exercise:
        return 'Exercise';
    }
  }

  /// Returns the days of the week this reminder should fire on.
  /// 1=Monday, 7=Sunday (ISO weekday).
  List<int> get activeDays {
    switch (frequency) {
      case ReminderFrequency.daily:
        return [1, 2, 3, 4, 5, 6, 7];
      case ReminderFrequency.weekdays:
        return [1, 2, 3, 4, 5];
      case ReminderFrequency.weekends:
        return [6, 7];
      case ReminderFrequency.custom:
        return customDays;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hive TypeAdapter — typeId 24
// ─────────────────────────────────────────────────────────────────────────────

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 24;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Reminder(
      id: fields[0] as String,
      type: ReminderType.values[fields[1] as int],
      title: fields[2] as String,
      body: fields[3] as String,
      hour: fields[4] as int,
      minute: fields[5] as int,
      frequency: ReminderFrequency.values[fields[6] as int],
      customDays: (fields[7] as List?)?.cast<int>() ?? [],
      isEnabled: fields[8] as bool? ?? true,
      createdAt: fields[9] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(10) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.index)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.hour)
      ..writeByte(5)
      ..write(obj.minute)
      ..writeByte(6)
      ..write(obj.frequency.index)
      ..writeByte(7)
      ..write(obj.customDays)
      ..writeByte(8)
      ..write(obj.isEnabled)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
