import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/supabase/supabase_config.dart';

class SbSettingsRepository {
  final SupabaseClient _client;

  SbSettingsRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns the current user's settings, or `null` if none exist.
  Future<Map<String, dynamic>?> getSettings() async {
    final row = await _client
        .from(SupabaseConfig.userSettingsTable)
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return row;
  }

  /// Creates or updates the current user's settings.
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _client
        .from(SupabaseConfig.userSettingsTable)
        .upsert({'user_id': _uid, ...settings});
  }
}
