import 'package:hive/hive.dart';

/// A chat session containing messages between the user and AI coach.
class ChatSession {
  final String id;
  final String title;
  final String agentType; // 'trainer' or 'nutritionist'
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.title,
    required this.agentType,
    required this.createdAt,
    required this.lastMessageAt,
    this.messageCount = 0,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    String? agentType,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      agentType: agentType ?? this.agentType,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'agentType': agentType,
    'createdAt': createdAt.toIso8601String(),
    'lastMessageAt': lastMessageAt.toIso8601String(),
    'messageCount': messageCount,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'New Chat',
    agentType: json['agentType'] as String? ?? 'trainer',
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
    messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// Hive TypeAdapter — typeId 25
class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final int typeId = 25;

  @override
  ChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ChatSession(
      id: fields[0] as String,
      title: fields[1] as String? ?? 'New Chat',
      agentType: fields[2] as String? ?? 'trainer',
      createdAt: fields[3] as DateTime? ?? DateTime.now(),
      lastMessageAt: fields[4] as DateTime? ?? DateTime.now(),
      messageCount: (fields[5] as num?)?.toInt() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.agentType)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastMessageAt)
      ..writeByte(5)
      ..write(obj.messageCount);
  }
}
