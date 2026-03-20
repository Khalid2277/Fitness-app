import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/progress_photo.dart';
import 'package:alfanutrition/data/repositories/progress_photo_repository.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

final progressPhotoRepositoryProvider =
    Provider<ProgressPhotoRepository>((ref) {
  return ProgressPhotoRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// All progress photo sets (newest first)
// ─────────────────────────────────────────────────────────────────────────────

final allProgressPhotosProvider =
    FutureProvider<List<ProgressPhotoSet>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    try {
      final sbRepo = ref.watch(sbProgressPhotoRepositoryProvider);
      final sbPhotos = await sbRepo.getPhotos();
      if (sbPhotos.isNotEmpty) return sbPhotos;
    } catch (_) {
      // Fall through to local
    }
  }

  // Always try local Hive as primary or fallback source
  final repo = ref.watch(progressPhotoRepositoryProvider);
  final raw = await repo.getAllPhotoSets();
  return raw.map((m) => ProgressPhotoSet.fromJson(m)).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Latest (most recent) photo set
// ─────────────────────────────────────────────────────────────────────────────

final latestProgressPhotoProvider =
    FutureProvider<ProgressPhotoSet?>((ref) async {
  final all = await ref.watch(allProgressPhotosProvider.future);
  return all.isNotEmpty ? all.first : null;
});
