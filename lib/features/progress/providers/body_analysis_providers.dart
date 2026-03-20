import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/body_analysis.dart';
import 'package:alfanutrition/data/repositories/body_analysis_repository.dart';
import 'package:alfanutrition/data/services/body_analysis_service.dart';

final bodyAnalysisServiceProvider = Provider<BodyAnalysisService>((ref) {
  return BodyAnalysisService();
});

final bodyAnalysisRepositoryProvider = Provider<BodyAnalysisRepository>((ref) {
  return BodyAnalysisRepository();
});

/// Get cached analysis for a specific photo set.
final photoSetAnalysisProvider =
    FutureProvider.family<BodyAnalysis?, String>((ref, photoSetId) async {
  final repo = ref.read(bodyAnalysisRepositoryProvider);
  return repo.getForPhotoSet(photoSetId);
});

/// All analyses sorted newest first.
final allAnalysesProvider = FutureProvider<List<BodyAnalysis>>((ref) async {
  final repo = ref.read(bodyAnalysisRepositoryProvider);
  return repo.getAll();
});
