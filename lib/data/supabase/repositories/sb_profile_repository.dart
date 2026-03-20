import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/profile_mapper.dart';

class SbProfileRepository {
  final SupabaseClient _client;

  SbProfileRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Fetches the current user's profile.
  /// The profiles table uses `id` (= auth.users.id) as primary key.
  Future<UserProfile?> getProfile() async {
    final row = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', _uid)
        .maybeSingle();
    if (row == null) return null;
    return ProfileMapper.fromRow(row);
  }

  /// Updates the current user's profile via upsert.
  Future<void> updateProfile(UserProfile profile) async {
    final data = ProfileMapper.toRow(profile);
    await _client
        .from(SupabaseConfig.profilesTable)
        .upsert({'id': _uid, ...data});
  }
}
