import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/supabase/supabase_config.dart';

class SbAiChatRepository {
  final SupabaseClient _client;

  SbAiChatRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns chat messages, optionally filtered by session ID.
  Future<List<Map<String, dynamic>>> getMessages({
    String? sessionId,
    int limit = 50,
  }) async {
    var query = _client
        .from(SupabaseConfig.aiChatMessagesTable)
        .select()
        .eq('user_id', _uid);

    if (sessionId != null) {
      query = query.eq('session_id', sessionId);
    }

    final rows = await query.order('created_at').limit(limit);
    return rows;
  }

  /// Saves a new chat message.
  Future<void> saveMessage({
    required String role,
    required String content,
    String? sessionId,
    String? agentType,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from(SupabaseConfig.aiChatMessagesTable).insert({
      'user_id': _uid,
      'role': role,
      'content': content,
      'session_id': sessionId,
      'agent_type': agentType,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Deletes all messages in a session.
  Future<void> deleteSession(String sessionId) async {
    await _client
        .from(SupabaseConfig.aiChatMessagesTable)
        .delete()
        .eq('user_id', _uid)
        .eq('session_id', sessionId);
  }

  /// Returns distinct session IDs for the current user.
  Future<List<String>> getSessions() async {
    final rows = await _client
        .from(SupabaseConfig.aiChatMessagesTable)
        .select('session_id')
        .eq('user_id', _uid)
        .not('session_id', 'is', null)
        .order('created_at', ascending: false);

    final seen = <String>{};
    final sessions = <String>[];
    for (final row in rows) {
      final sid = row['session_id'] as String?;
      if (sid != null && seen.add(sid)) {
        sessions.add(sid);
      }
    }
    return sessions;
  }
}
