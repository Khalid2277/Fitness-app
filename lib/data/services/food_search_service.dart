import 'package:alfanutrition/data/models/food_search_result.dart';
import 'package:alfanutrition/data/repositories/food_cache_repository.dart';
import 'package:alfanutrition/data/services/open_food_facts_service.dart';
import 'package:alfanutrition/data/services/usda_food_service.dart';

/// Orchestrates food search across multiple data sources with caching.
///
/// Strategy:
/// 1. Check Hive cache for exact query match (instant, offline-capable).
/// 2. Search Open Food Facts AND USDA in parallel.
/// 3. Merge, deduplicate, and cache the combined results.
class FoodSearchService {
  final OpenFoodFactsService _offService;
  final UsdaFoodService _usdaService;
  final FoodCacheRepository _cacheRepo;

  FoodSearchService({
    OpenFoodFactsService? offService,
    UsdaFoodService? usdaService,
    FoodCacheRepository? cacheRepo,
  })  : _offService = offService ?? OpenFoodFactsService(),
        _usdaService = usdaService ?? UsdaFoodService(),
        _cacheRepo = cacheRepo ?? FoodCacheRepository();

  // ─────────────────────────── Search ──────────────────────────────────────

  /// Searches all sources for foods matching [query].
  ///
  /// Returns a merged, deduplicated list with Open Food Facts results first
  /// (branded/packaged) followed by USDA results (whole/generic).
  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // 1. Check cache first (for page 1 only).
    if (page == 1) {
      final cached = await _cacheRepo.getCachedResults(trimmed);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    // 2. Search both sources in parallel.
    final results = await Future.wait([
      _offService.searchFoods(trimmed, page: page).catchError((_) => <FoodSearchResult>[]),
      _usdaService.searchFoods(trimmed, page: page).catchError((_) => <FoodSearchResult>[]),
    ]);

    final List<FoodSearchResult> offResults = results[0];
    final List<FoodSearchResult> usdaResults = results[1];

    // 3. Merge: OFF first (branded), then USDA (generic), deduplicated.
    final merged = _mergeAndDeduplicate(offResults, usdaResults);

    // 4. Cache the results (page 1 only).
    if (page == 1 && merged.isNotEmpty) {
      await _cacheRepo.cacheSearchResults(trimmed, merged);
    }

    return merged;
  }

  // ─────────────────────────── Barcode lookup ──────────────────────────────

  /// Looks up a product by barcode (Open Food Facts only).
  Future<FoodSearchResult?> getFoodByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    // Check cache first.
    final cached = await _cacheRepo.getCachedFood(barcode);
    if (cached != null) return cached;

    // Query OFF.
    final result = await _offService.getFoodByBarcode(barcode);
    if (result != null) {
      await _cacheRepo.cacheFood(result);
    }
    return result;
  }

  // ─────────────────────────── Recent / Frequent ───────────────────────────

  /// Logs a food as recently used and increments its usage count.
  Future<void> logFoodToRecent(FoodSearchResult food) async {
    await _cacheRepo.logFoodUsage(food);
  }

  /// Returns the most recently logged foods (up to 20).
  Future<List<FoodSearchResult>> getRecentFoods() async {
    return _cacheRepo.getRecentFoods(limit: 20);
  }

  /// Returns the most frequently logged foods, sorted by usage count.
  Future<List<FoodSearchResult>> getFrequentFoods() async {
    return _cacheRepo.getFrequentFoods(limit: 20);
  }

  // ─────────────────────────── Custom foods ────────────────────────────────

  /// Saves a user-created custom food.
  Future<void> createCustomFood(FoodSearchResult food) async {
    await _cacheRepo.saveCustomFood(food);
  }

  /// Returns all user-created custom foods.
  Future<List<FoodSearchResult>> getCustomFoods() async {
    return _cacheRepo.getCustomFoods();
  }

  // ─────────────────────────── Deduplication ───────────────────────────────

  /// Merges OFF and USDA results, removing likely duplicates by name
  /// similarity. OFF results are placed first.
  List<FoodSearchResult> _mergeAndDeduplicate(
    List<FoodSearchResult> offResults,
    List<FoodSearchResult> usdaResults,
  ) {
    final merged = <FoodSearchResult>[...offResults];
    final existingNames =
        offResults.map((f) => _normalizeForComparison(f.name)).toSet();

    for (final usda in usdaResults) {
      final normalizedName = _normalizeForComparison(usda.name);
      // Skip if there is a sufficiently similar name already.
      if (!existingNames.any((n) => _isSimilar(n, normalizedName))) {
        merged.add(usda);
        existingNames.add(normalizedName);
      }
    }

    return merged;
  }

  /// Normalizes a food name for deduplication comparison.
  String _normalizeForComparison(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns `true` if two normalized names are considered similar enough
  /// to be duplicates.
  bool _isSimilar(String a, String b) {
    if (a == b) return true;
    // One name contains the other.
    if (a.contains(b) || b.contains(a)) return true;
    // Check word overlap. If >70% of words match, consider duplicate.
    final wordsA = a.split(' ').toSet();
    final wordsB = b.split(' ').toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return false;
    final overlap = wordsA.intersection(wordsB).length;
    final smaller = wordsA.length < wordsB.length ? wordsA.length : wordsB.length;
    return smaller > 0 && overlap / smaller >= 0.7;
  }
}
