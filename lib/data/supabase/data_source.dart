import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Indicates whether data should be read from / written to Supabase or
/// the local Hive store.
enum DataSourceType {
  /// Remote Supabase Postgres + Storage.
  supabase,

  /// Local-only Hive storage (offline / not configured).
  local,
}

/// Resolves the active data source based on Supabase configuration
/// *and* the current authentication state.
///
/// - If Supabase is not configured (missing env vars) -> [DataSourceType.local]
/// - If the user is not authenticated               -> [DataSourceType.local]
/// - Otherwise                                       -> [DataSourceType.supabase]
final dataSourceProvider = Provider<DataSourceType>((ref) {
  if (!SupabaseConfig.isConfigured) return DataSourceType.local;

  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return DataSourceType.local;
    return DataSourceType.supabase;
  } catch (_) {
    return DataSourceType.local;
  }
});

/// Convenience provider that returns `true` when the app should use the
/// remote Supabase backend.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(dataSourceProvider) == DataSourceType.supabase;
});
