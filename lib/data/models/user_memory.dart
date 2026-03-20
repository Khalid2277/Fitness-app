import 'package:hive/hive.dart';

/// A single memory fact extracted from AI conversations.
/// Examples: "User prefers morning workouts", "User is lactose intolerant",
/// "User's max bench press is 100kg"
class UserMemory {
  final String id;
  final String fact;
  final String category; // 'preference', 'health', 'goal', 'achievement', 'diet', 'training'
  final DateTime createdAt;
  final DateTime lastReferencedAt;
  final String sourceSessionId; // which chat session it came from

  const UserMemory({
    required this.id,
    required this.fact,
    required this.category,
    required this.createdAt,
    required this.lastReferencedAt,
    required this.sourceSessionId,
  });

  UserMemory copyWith({
    String? id,
    String? fact,
    String? category,
    DateTime? createdAt,
    DateTime? lastReferencedAt,
    String? sourceSessionId,
  }) {
    return UserMemory(
      id: id ?? this.id,
      fact: fact ?? this.fact,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      lastReferencedAt: lastReferencedAt ?? this.lastReferencedAt,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fact': fact,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'lastReferencedAt': lastReferencedAt.toIso8601String(),
    'sourceSessionId': sourceSessionId,
  };

  factory UserMemory.fromJson(Map<String, dynamic> json) => UserMemory(
    id: json['id'] as String,
    fact: json['fact'] as String,
    category: json['category'] as String? ?? 'preference',
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastReferencedAt: DateTime.parse(json['lastReferencedAt'] as String),
    sourceSessionId: json['sourceSessionId'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserMemory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// Hive TypeAdapter — typeId 26
class UserMemoryAdapter extends TypeAdapter<UserMemory> {
  @override
  final int typeId = 26;

  @override
  UserMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return UserMemory(
      id: fields[0] as String,
      fact: fields[1] as String? ?? '',
      category: fields[2] as String? ?? 'preference',
      createdAt: fields[3] as DateTime? ?? DateTime.now(),
      lastReferencedAt: fields[4] as DateTime? ?? DateTime.now(),
      sourceSessionId: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, UserMemory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fact)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastReferencedAt)
      ..writeByte(5)
      ..write(obj.sourceSessionId);
  }
}
