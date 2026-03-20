import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

/// Whether the user has already completed onboarding.
///
/// A profile row may exist (e.g. from the Supabase signup trigger) but
/// onboarding is only "complete" when the user has actually filled in their
/// goal, activity level, weight, etc.
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    try {
      final sbRepo = ref.read(sbProfileRepositoryProvider);
      final profile = await sbRepo.getProfile();
      if (profile == null) return false;
      // A profile created by the DB trigger has no goal/weight set.
      // Onboarding is complete only when the user has filled those in.
      return profile.weight != null && profile.weight! > 0;
    } catch (_) {
      return false;
    }
  }

  // Fallback: local Hive
  final repo = ref.watch(userRepositoryProvider);
  return repo.hasProfile();
});
