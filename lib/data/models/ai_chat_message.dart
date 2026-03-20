import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AiChatMessage — typeId 20
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 20)
class AiChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role; // 'user', 'assistant', 'system'

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String agentType; // 'trainer', 'nutritionist', 'general'

  @HiveField(5)
  final List<String> suggestions;

  @HiveField(6)
  final List<Map<String, dynamic>> actions;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.agentType = 'general',
    this.suggestions = const [],
    this.actions = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  /// Whether this message is from the user.
  bool get isUser => role == 'user';

  /// Whether this message is from the assistant.
  bool get isAssistant => role == 'assistant';

  /// Whether this message is a system message.
  bool get isSystem => role == 'system';

  /// Whether the assistant provided follow-up suggestions.
  bool get hasSuggestions => suggestions.isNotEmpty;

  /// Whether the assistant provided actionable items.
  bool get hasActions => actions.isNotEmpty;

  AiChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    String? agentType,
    List<String>? suggestions,
    List<Map<String, dynamic>>? actions,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      agentType: agentType ?? this.agentType,
      suggestions: suggestions ?? this.suggestions,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'agentType': agentType,
      'suggestions': suggestions,
      'actions': actions,
    };
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      agentType: json['agentType'] as String? ?? 'general',
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'] as List)
          : [],
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList()
          : [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AiChatMessage(id: $id, role: $role, agent: $agentType)';
}

class AiChatMessageAdapter extends TypeAdapter<AiChatMessage> {
  @override
  final int typeId = 20;

  @override
  AiChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return AiChatMessage(
      id: fields[0] as String,
      role: fields[1] as String,
      content: fields[2] as String,
      timestamp: fields[3] as DateTime,
      agentType: fields[4] as String? ?? 'general',
      suggestions: fields[5] != null
          ? (fields[5] as List).cast<String>()
          : [],
      actions: fields[6] != null
          ? (fields[6] as List)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList()
          : [],
    );
  }

  @override
  void write(BinaryWriter writer, AiChatMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.agentType)
      ..writeByte(5)
      ..write(obj.suggestions)
      ..writeByte(6)
      ..write(obj.actions);
  }
}
