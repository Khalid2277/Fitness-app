import 'package:hive/hive.dart';

import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';

/// Repository for caching food search results and managing recent /
/// frequent / custom foods using Hive.
class FoodCacheRepository {
  Future<Box> get _box async =>
      await Hive.openBox(AppConstants.foodCacheBox);

  // ────────────────────── Cache key helpers ─────────────────────────────────

  /// Key for a cached search query.
  static String _queryKey(String query) =>
      'search_${query.trim().toLowerCase()}';

  /// Key for a cached individual food item.
  static String _foodKey(String foodId) => 'food_$foodId';

  /// Key for the custom foods list.
  static const String _customFoodsKey = 'custom_foods';

  /// Deep-converts Hive internal map/list types to standard Dart types.
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

  // ────────────────────── Search result caching ────────────────────────────

  /// Caches a list of search results for [query].
  Future<void> cacheSearchResults(
    String query,
    List<FoodSearchResult> results,
  ) async {
    final box = await _box;
    final data = {
      'cachedAt': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };
    await box.put(_queryKey(query), data);
  }

  /// Returns cached results for [query], or `null` if the cache is empty
  /// or has expired (older than 24 hours).
  Future<List<FoodSearchResult>?> getCachedResults(String query) async {
    final box = await _box;
    final raw = box.get(_queryKey(query));
    if (raw == null) return null;

    final data = _deepConvert(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(data['cachedAt'] as String? ?? '');
    if (cachedAt == null) return null;

    // Expire after 24 hours.
    if (DateTime.now().difference(cachedAt).inHours >= 24) {
      await box.delete(_queryKey(query));
      return null;
    }

    final List<dynamic> rawResults = data['results'] as List<dynamic>? ?? [];
    return rawResults
        .map((r) => FoodSearchResult.fromJson(_deepConvert(r) as Map<String, dynamic>))
        .toList();
  }

  // ────────────────────── Individual food caching ──────────────────────────

  /// Caches a single [food] item for quick retrieval.
  Future<void> cacheFood(FoodSearchResult food) async {
    final box = await _box;
    await box.put(_foodKey(food.id), food.toJson());
  }

  /// Retrieves a cached food by [foodId], or `null` if not found.
  Future<FoodSearchResult?> getCachedFood(String foodId) async {
    final box = await _box;
    final raw = box.get(_foodKey(foodId));
    if (raw == null) return null;
    return FoodSearchResult.fromJson(_deepConvert(raw) as Map<String, dynamic>);
  }

  // ────────────────────── Recent foods ─────────────────────────────────────

  /// Returns the most recently used foods, sorted by [lastUsed] descending.
  Future<List<FoodSearchResult>> getRecentFoods({int limit = 20}) async {
    final allFoods = await _getAllLoggedFoods();
    allFoods.sort((a, b) {
      final aDate = a.lastUsed ?? DateTime(2000);
      final bDate = b.lastUsed ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return allFoods.take(limit).toList();
  }

  // ────────────────────── Frequent foods ───────────────────────────────────

  /// Returns the most frequently used foods, sorted by [useCount] descending.
  Future<List<FoodSearchResult>> getFrequentFoods({int limit = 20}) async {
    final allFoods = await _getAllLoggedFoods();
    allFoods.sort((a, b) => b.useCount.compareTo(a.useCount));
    return allFoods.where((f) => f.useCount > 0).take(limit).toList();
  }

  // ────────────────────── Custom foods ─────────────────────────────────────

  /// Returns all user-created custom foods.
  Future<List<FoodSearchResult>> getCustomFoods() async {
    final box = await _box;
    final List<dynamic> ids =
        (box.get(_customFoodsKey) as List<dynamic>?) ?? [];

    final results = <FoodSearchResult>[];
    for (final id in ids) {
      final food = await getCachedFood(id as String);
      if (food != null) results.add(food);
    }
    return results;
  }

  /// Saves a user-created custom food.
  Future<void> saveCustomFood(FoodSearchResult food) async {
    final box = await _box;
    await cacheFood(food);

    // Track the ID in the custom foods list.
    final List<dynamic> ids =
        List<dynamic>.from((box.get(_customFoodsKey) as List<dynamic>?) ?? []);
    if (!ids.contains(food.id)) {
      ids.add(food.id);
      await box.put(_customFoodsKey, ids);
    }
  }

  // ────────────────────── Use count tracking ───────────────────────────────

  /// Increments the use count for a food and updates its [lastUsed]
  /// timestamp.
  Future<void> incrementUseCount(String foodId) async {
    final food = await getCachedFood(foodId);
    if (food == null) return;

    final updated = food.copyWith(
      useCount: food.useCount + 1,
      lastUsed: DateTime.now(),
    );
    await cacheFood(updated);
  }

  /// Logs a food as used — caches it and increments its use count.
  Future<void> logFoodUsage(FoodSearchResult food) async {
    final existing = await getCachedFood(food.id);
    final updated = food.copyWith(
      useCount: (existing?.useCount ?? 0) + 1,
      lastUsed: DateTime.now(),
    );
    await cacheFood(updated);
  }

  // ────────────────────── Internal helpers ──────────────────────────────────

  /// Retrieves all individually cached foods (those with a `food_` key
  /// prefix).
  Future<List<FoodSearchResult>> _getAllLoggedFoods() async {
    final box = await _box;
    final results = <FoodSearchResult>[];

    for (final key in box.keys) {
      if (key is String && key.startsWith('food_')) {
        try {
          final raw = box.get(key);
          if (raw != null) {
            final food = FoodSearchResult.fromJson(
              _deepConvert(raw) as Map<String, dynamic>,
            );
            // Only return foods that have been used at least once.
            if (food.lastUsed != null) {
              results.add(food);
            }
          }
        } catch (_) {
          // Skip malformed entries.
        }
      }
    }

    return results;
  }
}
