import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:alfanutrition/data/models/food_search_result.dart';

/// Service for searching foods via the USDA FoodData Central API.
///
/// Provides access to 400K+ whole and generic food items (Foundation,
/// SR Legacy) with per-100g nutrition data.
class UsdaFoodService {
  /// USDA FoodData Central base URL.
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// API key — reads from .env, falls back to DEMO_KEY (rate-limited).
  static String get _apiKey => dotenv.env['USDA_API_KEY'] ?? 'DEMO_KEY';

  /// HTTP client (injectable for testing).
  final http.Client _client;

  /// Request timeout duration.
  static const Duration _timeout = Duration(seconds: 10);

  UsdaFoodService({http.Client? client}) : _client = client ?? http.Client();

  // ─────────────────────────── Search ──────────────────────────────────────

  /// Searches USDA FoodData Central for foods matching [query].
  ///
  /// By default searches Foundation and SR Legacy data types (whole /
  /// generic foods). Returns up to [pageSize] results for [page] (1-indexed).
  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    int page = 1,
    int pageSize = 20,
    List<String> dataTypes = const ['Foundation', 'SR Legacy'],
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/foods/search?api_key=$_apiKey');
      final body = jsonEncode({
        'query': query,
        'pageSize': pageSize,
        'pageNumber': page,
        'dataType': dataTypes,
      });

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> foods = json['foods'] as List<dynamic>? ?? [];

      return foods
          .map((f) => _mapFood(f as Map<String, dynamic>))
          .where((food) => food != null)
          .cast<FoodSearchResult>()
          .toList();
    } catch (e) {
      // Network, timeout, or parsing error — fail gracefully.
      return [];
    }
  }

  // ─────────────────────────── Detail lookup ───────────────────────────────

  /// Fetches detailed nutrition data for a single food by its FDC ID.
  Future<FoodSearchResult?> getFoodDetails(String fdcId) async {
    if (fdcId.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> json = jsonDecode(response.body);
      return _mapFood(json);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────── Mapping ─────────────────────────────────────

  /// Maps a USDA food JSON object to our unified [FoodSearchResult].
  ///
  /// USDA nutrient IDs:
  ///   1008 = Energy (kcal)
  ///   1003 = Protein
  ///   1004 = Total lipid (fat)
  ///   1005 = Carbohydrate, by difference
  ///   1079 = Fiber, total dietary
  FoodSearchResult? _mapFood(Map<String, dynamic> json) {
    final String? description = json['description'] as String?;
    if (description == null || description.trim().isEmpty) return null;

    final String fdcId = (json['fdcId'] as num?)?.toString() ?? '';
    if (fdcId.isEmpty) return null;

    // Nutrients may be in `foodNutrients` as a list of objects.
    final List<dynamic> nutrients =
        json['foodNutrients'] as List<dynamic>? ?? [];

    double calories = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;
    double? fiber;

    for (final n in nutrients) {
      if (n is! Map) continue;
      final nutrientMap = n as Map<String, dynamic>;

      // The nutrientId can be nested inside a `nutrient` object or at
      // the top level (search endpoint vs detail endpoint).
      final int? nutrientId = _extractNutrientId(nutrientMap);
      final double value = _extractNutrientValue(nutrientMap);

      switch (nutrientId) {
        case 1008:
          calories = value;
        case 1003:
          protein = value;
        case 1004:
          fat = value;
        case 1005:
          carbs = value;
        case 1079:
          fiber = value;
      }
    }

    final String? brandOwner = json['brandOwner'] as String?;
    final String name = description.trim();

    // If calories is 0 but macros exist, compute from macros
    // (USDA sometimes omits the energy nutrient for certain entries).
    if (calories == 0 && (protein > 0 || carbs > 0 || fat > 0)) {
      calories = (protein * 4) + (carbs * 4) + (fat * 9);
    }

    // Skip foods with no meaningful nutrition data at all.
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) return null;

    return FoodSearchResult(
      id: 'usda_$fdcId',
      name: _formatName(name),
      brand: (brandOwner != null && brandOwner.trim().isNotEmpty)
          ? brandOwner.trim()
          : null,
      calories: _round(calories),
      protein: _round(protein),
      carbs: _round(carbs),
      fat: _round(fat),
      fiber: fiber != null ? _round(fiber) : null,
      servingSize: 100.0, // USDA reports per 100g
      servingUnit: 'g',
      imageUrl: null, // USDA does not provide images
      source: 'usda',
      barcode: null,
    );
  }

  /// Extracts the nutrient ID from either the search or detail response
  /// format.
  int? _extractNutrientId(Map<String, dynamic> nutrientMap) {
    // Search endpoint: { "nutrientId": 1008, "value": ... }
    if (nutrientMap.containsKey('nutrientId')) {
      return (nutrientMap['nutrientId'] as num?)?.toInt();
    }
    // Detail endpoint: { "nutrient": { "id": 1008, ... }, "amount": ... }
    final nested = nutrientMap['nutrient'];
    if (nested is Map<String, dynamic>) {
      return (nested['id'] as num?)?.toInt();
    }
    return null;
  }

  /// Extracts the numeric nutrient value from either format.
  double _extractNutrientValue(Map<String, dynamic> nutrientMap) {
    // Search: "value", Detail: "amount"
    final raw = nutrientMap['value'] ?? nutrientMap['amount'];
    if (raw is num) return raw.toDouble();
    return 0.0;
  }

  /// Formats a USDA food name from ALL-CAPS to Title Case.
  String _formatName(String name) {
    // USDA entries are often uppercase (e.g. "CHICKEN, BREAST, ROASTED").
    if (name == name.toUpperCase() && name.length > 3) {
      return name
          .split(RegExp(r'[\s,]+'))
          .where((w) => w.isNotEmpty)
          .map((word) {
        if (word.length <= 2) return word.toLowerCase();
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }).join(' ');
    }
    return name;
  }

  /// Rounds a double to one decimal place.
  double _round(double value) => (value * 10).roundToDouble() / 10;

  /// Closes the HTTP client. Call when the service is no longer needed.
  void dispose() {
    _client.close();
  }
}
