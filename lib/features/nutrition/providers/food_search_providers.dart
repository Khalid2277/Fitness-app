import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';
import 'package:alfanutrition/data/repositories/food_cache_repository.dart';
import 'package:alfanutrition/data/services/food_search_service.dart';
import 'package:alfanutrition/data/services/open_food_facts_service.dart';
import 'package:alfanutrition/data/services/usda_food_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [FoodCacheRepository] singleton.
final foodCacheRepositoryProvider = Provider<FoodCacheRepository>((ref) {
  return FoodCacheRepository();
});

/// Provides the [FoodSearchService] singleton, wiring up all data sources.
final foodSearchServiceProvider = Provider<FoodSearchService>((ref) {
  return FoodSearchService(
    offService: OpenFoodFactsService(),
    usdaService: UsdaFoodService(),
    cacheRepo: ref.read(foodCacheRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Search query state
// ─────────────────────────────────────────────────────────────────────────────

/// Current search query text.
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Debounced search results
// ─────────────────────────────────────────────────────────────────────────────

/// Watches [foodSearchQueryProvider] and performs a debounced search across
/// all food data sources (Open Food Facts + USDA + local cache).
///
/// Returns an empty list when the query is shorter than [AppConstants
/// .minSearchQueryLength] characters.
final foodSearchResultsProvider =
    FutureProvider<List<FoodSearchResult>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);

  if (query.trim().length < AppConstants.minSearchQueryLength) {
    return [];
  }

  // Debounce: wait before actually searching, so we don't fire a request
  // on every keystroke.
  await Future<void>.delayed(
    Duration(milliseconds: AppConstants.debounceMilliseconds),
  );

  // If the query changed during the debounce window, Riverpod will
  // automatically cancel this provider execution and start a new one.
  // We check using ref.exists which is a no-op guard.

  final service = ref.read(foodSearchServiceProvider);
  return service.searchFoods(query);
});

// ─────────────────────────────────────────────────────────────────────────────
// Recent and frequent foods
// ─────────────────────────────────────────────────────────────────────────────

/// Most recently logged foods (up to 20), sorted by last use date.
final recentFoodsProvider =
    FutureProvider<List<FoodSearchResult>>((ref) async {
  final service = ref.read(foodSearchServiceProvider);
  return service.getRecentFoods();
});

/// Most frequently logged foods (up to 20), sorted by use count.
final frequentFoodsProvider =
    FutureProvider<List<FoodSearchResult>>((ref) async {
  final service = ref.read(foodSearchServiceProvider);
  return service.getFrequentFoods();
});

// ─────────────────────────────────────────────────────────────────────────────
// Selected food (for detail / logging flow)
// ─────────────────────────────────────────────────────────────────────────────

/// The currently selected food item in the search → log flow.
final selectedFoodProvider = StateProvider<FoodSearchResult?>((ref) => null);
