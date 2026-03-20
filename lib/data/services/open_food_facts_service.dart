import 'package:openfoodfacts/openfoodfacts.dart';

import 'package:alfanutrition/data/models/food_search_result.dart';

/// Service for searching foods via the Open Food Facts API.
///
/// Provides access to 2.9M+ packaged and branded food products with
/// nutrition data, barcodes, and product images.
class OpenFoodFactsService {
  static bool _configured = false;

  /// Configures the Open Food Facts API client.
  ///
  /// Must be called once before any API requests. Safe to call multiple times.
  static void configure() {
    if (_configured) return;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'AlfaNutrition',
      url: 'https://alfatechlabs.com',
    );
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    // No country filter — search all regions for maximum coverage.
    _configured = true;
  }

  OpenFoodFactsService() {
    configure();
  }

  // ─────────────────────────── Search ──────────────────────────────────────

  /// Searches Open Food Facts for products matching [query].
  ///
  /// Returns up to [pageSize] results for the given [page] (1-indexed).
  Future<List<FoodSearchResult>> searchFoods(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final configuration = ProductSearchQueryConfiguration(
        parametersList: <Parameter>[
          SearchTerms(terms: query.split(' ')),
          PageNumber(page: page),
          PageSize(size: pageSize),
        ],
        fields: <ProductField>[
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.SERVING_QUANTITY,
          ProductField.IMAGE_FRONT_SMALL_URL,
          ProductField.QUANTITY,
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
      );

      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null,
        configuration,
      );

      if (result.products == null || result.products!.isEmpty) return [];

      return result.products!
          .map(_mapProduct)
          .where((food) => food != null)
          .cast<FoodSearchResult>()
          .toList();
    } on TooManyRequestsException {
      // Rate limited — return empty so the caller can retry later.
      return [];
    } catch (e) {
      // Network or parsing error — fail gracefully.
      return [];
    }
  }

  // ─────────────────────────── Barcode lookup ──────────────────────────────

  /// Looks up a single product by its barcode.
  Future<FoodSearchResult?> getFoodByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    return getFoodDetails(barcode);
  }

  /// Fetches detailed product data for a given [barcode].
  Future<FoodSearchResult?> getFoodDetails(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    try {
      final configuration = ProductQueryConfiguration(
        barcode,
        version: ProductQueryVersion.v3,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: <ProductField>[
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.SERVING_SIZE,
          ProductField.SERVING_QUANTITY,
          ProductField.IMAGE_FRONT_SMALL_URL,
          ProductField.IMAGE_FRONT_URL,
          ProductField.QUANTITY,
        ],
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );

      if (result.product == null) return null;
      return _mapProduct(result.product!);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────── Mapping ─────────────────────────────────────

  /// Maps an OFF [Product] to our unified [FoodSearchResult] model.
  ///
  /// Returns `null` if the product lacks both a name and meaningful
  /// nutrition data.
  FoodSearchResult? _mapProduct(Product product) {
    final name = product.productName?.trim();
    if (name == null || name.isEmpty) return null;

    final nutriments = product.nutriments;

    // Extract per-serving values first, fall back to per-100g.
    double calories = _nutrientValue(
          nutriments,
          Nutrient.energyKCal,
          PerSize.serving,
        ) ??
        _nutrientValue(nutriments, Nutrient.energyKCal, PerSize.oneHundredGrams) ??
        0.0;

    double protein = _nutrientValue(
          nutriments,
          Nutrient.proteins,
          PerSize.serving,
        ) ??
        _nutrientValue(nutriments, Nutrient.proteins, PerSize.oneHundredGrams) ??
        0.0;

    double carbs = _nutrientValue(
          nutriments,
          Nutrient.carbohydrates,
          PerSize.serving,
        ) ??
        _nutrientValue(
          nutriments,
          Nutrient.carbohydrates,
          PerSize.oneHundredGrams,
        ) ??
        0.0;

    double fat = _nutrientValue(
          nutriments,
          Nutrient.fat,
          PerSize.serving,
        ) ??
        _nutrientValue(nutriments, Nutrient.fat, PerSize.oneHundredGrams) ??
        0.0;

    double? fiber = _nutrientValue(
          nutriments,
          Nutrient.fiber,
          PerSize.serving,
        ) ??
        _nutrientValue(nutriments, Nutrient.fiber, PerSize.oneHundredGrams);

    // Determine serving size in grams.
    double servingSize = product.servingQuantity ?? 100.0;

    // If we only got per-100g values, scale to the serving size.
    final bool hadPerServing = _nutrientValue(
          nutriments,
          Nutrient.energyKCal,
          PerSize.serving,
        ) !=
        null;
    if (!hadPerServing && servingSize != 100.0) {
      // Values are per 100g — scale them to the actual serving.
      final ratio = servingSize / 100.0;
      calories *= ratio;
      protein *= ratio;
      carbs *= ratio;
      fat *= ratio;
      if (fiber != null) fiber *= ratio;
    }

    // If calories is 0 but macros exist, compute from macros.
    if (calories == 0 && (protein > 0 || carbs > 0 || fat > 0)) {
      calories = (protein * 4) + (carbs * 4) + (fat * 9);
    }

    // Skip foods with no meaningful nutrition data.
    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) return null;

    final brand = product.brands?.trim();
    final imageUrl =
        product.imageFrontSmallUrl ?? product.imageFrontUrl;

    return FoodSearchResult(
      id: product.barcode ?? name.hashCode.toString(),
      name: name,
      brand: (brand != null && brand.isNotEmpty) ? brand : null,
      calories: _round(calories),
      protein: _round(protein),
      carbs: _round(carbs),
      fat: _round(fat),
      fiber: fiber != null ? _round(fiber) : null,
      servingSize: servingSize,
      servingUnit: 'g',
      imageUrl: imageUrl,
      source: 'openfoodfacts',
      barcode: product.barcode,
    );
  }

  /// Safely reads a nutrient value from [nutriments].
  double? _nutrientValue(
    Nutriments? nutriments,
    Nutrient nutrient,
    PerSize perSize,
  ) {
    if (nutriments == null) return null;
    return nutriments.getValue(nutrient, perSize);
  }

  /// Rounds a double to one decimal place.
  double _round(double value) => (value * 10).roundToDouble() / 10;
}
