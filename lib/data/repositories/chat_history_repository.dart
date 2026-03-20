import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:alfanutrition/data/models/ai_chat_message.dart';
import 'package:alfanutrition/data/models/chat_session.dart';
import 'package:alfanutrition/data/models/user_memory.dart';

/// Manages chat sessions, messages, and user memories locally via Hive.
class ChatHistoryRepository {
  static const String _sessionsBox = 'chat_sessions';
  static const String _messagesBox = 'ai_chat_history';
  static const String _memoriesBox = 'user_memories';

  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
      );
    } else if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  // ─────────────────────────── Sessions ──────────────────────────────────────

  /// Returns all chat sessions, sorted by last message time (newest first).
  Future<List<ChatSession>> getSessions() async {
    final box = Hive.box(_sessionsBox);
    final sessions = <ChatSession>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        try {
          sessions.add(ChatSession.fromJson(_deepConvert(raw) as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping corrupted chat record: $e');
        }
      }
    }
    sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return sessions;
  }

  /// Get a single session by ID.
  Future<ChatSession?> getSession(String sessionId) async {
    final box = Hive.box(_sessionsBox);
    final raw = box.get(sessionId);
    if (raw is Map) {
      try {
        return ChatSession.fromJson(_deepConvert(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Failed to deserialize session $sessionId: $e');
      }
    }
    return null;
  }

  /// Save or update a session.
  Future<void> saveSession(ChatSession session) async {
    final box = Hive.box(_sessionsBox);
    await box.put(session.id, session.toJson());
  }

  /// Delete a session and all its messages.
  Future<void> deleteSession(String sessionId) async {
    final box = Hive.box(_sessionsBox);
    await box.delete(sessionId);
    // Also delete all messages for this session
    await deleteMessagesForSession(sessionId);
  }

  // ─────────────────────────── Messages ──────────────────────────────────────

  /// Returns all messages for a session, sorted by timestamp.
  Future<List<AiChatMessage>> getMessages(String sessionId) async {
    final box = Hive.box(_messagesBox);
    final messages = <AiChatMessage>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        try {
          final msg = AiChatMessage.fromJson(_deepConvert(raw) as Map<String, dynamic>);
          // Messages are stored with key: "sessionId_messageId"
          if (key.toString().startsWith('${sessionId}_')) {
            messages.add(msg);
          }
        } catch (e) {
          debugPrint('Skipping corrupted chat record: $e');
        }
      }
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  /// Save a message to a session.
  Future<void> saveMessage(String sessionId, AiChatMessage message) async {
    final box = Hive.box(_messagesBox);
    final key = '${sessionId}_${message.id}';
    await box.put(key, message.toJson());
  }

  /// Delete all messages for a session.
  Future<void> deleteMessagesForSession(String sessionId) async {
    final box = Hive.box(_messagesBox);
    final keysToDelete = box.keys
        .where((key) => key.toString().startsWith('${sessionId}_'))
        .toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  // ─────────────────────────── Memories ──────────────────────────────────────

  /// Returns all user memories, sorted by most recently referenced.
  Future<List<UserMemory>> getMemories() async {
    final box = Hive.box(_memoriesBox);
    final memories = <UserMemory>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        try {
          memories.add(UserMemory.fromJson(_deepConvert(raw) as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping corrupted chat record: $e');
        }
      }
    }
    memories.sort((a, b) => b.lastReferencedAt.compareTo(a.lastReferencedAt));
    return memories;
  }

  /// Save or update a memory.
  Future<void> saveMemory(UserMemory memory) async {
    final box = Hive.box(_memoriesBox);
    await box.put(memory.id, memory.toJson());
  }

  /// Delete a memory.
  Future<void> deleteMemory(String memoryId) async {
    final box = Hive.box(_memoriesBox);
    await box.delete(memoryId);
  }

  /// Get memories as a formatted string for AI context.
  Future<String> getMemorySummary() async {
    final memories = await getMemories();
    if (memories.isEmpty) return '';

    // Group by category
    final grouped = <String, List<UserMemory>>{};
    for (final m in memories) {
      grouped.putIfAbsent(m.category, () => []).add(m);
    }

    final buffer = StringBuffer();
    buffer.writeln('Things you remember about this user:');
    for (final entry in grouped.entries) {
      for (final m in entry.value) {
        buffer.writeln('- ${m.fact}');
      }
    }
    return buffer.toString();
  }

  /// Clear all chat data (sessions + messages + memories).
  Future<void> clearAll() async {
    final sessionsBox = Hive.box(_sessionsBox);
    final messagesBox = Hive.box(_messagesBox);
    final memoriesBox = Hive.box(_memoriesBox);
    await sessionsBox.clear();
    await messagesBox.clear();
    await memoriesBox.clear();
  }
}
