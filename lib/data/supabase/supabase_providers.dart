import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_service.dart';
import 'repositories/sb_ai_chat_repository.dart';
import 'repositories/sb_body_metric_repository.dart';
import 'repositories/sb_exercise_repository.dart';
import 'repositories/sb_food_item_repository.dart';
import 'repositories/sb_nutrition_repository.dart';
import 'repositories/sb_plan_repository.dart';
import 'repositories/sb_profile_repository.dart';
import 'repositories/sb_progress_photo_repository.dart';
import 'repositories/sb_settings_repository.dart';
import 'repositories/sb_workout_repository.dart';

// ─────────────────────────── Core client ──────────────────────────────────

/// The singleton [SupabaseClient] instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─────────────────────────── Auth ─────────────────────────────────────────

/// Stream of [AuthState] changes (sign-in, sign-out, token refresh, etc.).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// The currently authenticated [User], or `null`.
final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Whether a user is currently signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// [AuthService] singleton for sign-in / sign-up / sign-out flows.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

// ─────────────────────────── Repositories ─────────────────────────────────

final sbProfileRepositoryProvider = Provider<SbProfileRepository>((ref) {
  return SbProfileRepository(ref.watch(supabaseClientProvider));
});

final sbExerciseRepositoryProvider = Provider<SbExerciseRepository>((ref) {
  return SbExerciseRepository(ref.watch(supabaseClientProvider));
});

final sbWorkoutRepositoryProvider = Provider<SbWorkoutRepository>((ref) {
  return SbWorkoutRepository(ref.watch(supabaseClientProvider));
});

final sbNutritionRepositoryProvider = Provider<SbNutritionRepository>((ref) {
  return SbNutritionRepository(ref.watch(supabaseClientProvider));
});

final sbBodyMetricRepositoryProvider = Provider<SbBodyMetricRepository>((ref) {
  return SbBodyMetricRepository(ref.watch(supabaseClientProvider));
});

final sbPlanRepositoryProvider = Provider<SbPlanRepository>((ref) {
  return SbPlanRepository(ref.watch(supabaseClientProvider));
});

final sbAiChatRepositoryProvider = Provider<SbAiChatRepository>((ref) {
  return SbAiChatRepository(ref.watch(supabaseClientProvider));
});

final sbProgressPhotoRepositoryProvider =
    Provider<SbProgressPhotoRepository>((ref) {
  return SbProgressPhotoRepository(ref.watch(supabaseClientProvider));
});

final sbFoodItemRepositoryProvider = Provider<SbFoodItemRepository>((ref) {
  return SbFoodItemRepository(ref.watch(supabaseClientProvider));
});

final sbSettingsRepositoryProvider = Provider<SbSettingsRepository>((ref) {
  return SbSettingsRepository(ref.watch(supabaseClientProvider));
});
