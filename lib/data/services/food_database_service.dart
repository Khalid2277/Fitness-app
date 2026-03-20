import 'package:hive_flutter/hive_flutter.dart';

import 'package:alfanutrition/data/models/food_item.dart';

/// Local food database with 60+ common foods and accurate nutrition data.
///
/// All nutrition values are per the stated serving size (typically 100 g or
/// one standard serving). Data sourced from USDA FoodData Central and
/// nutrition label averages.
///
/// This service also manages custom foods and tracks frequent / recent usage
/// for a personalised search experience.
class FoodDatabaseService {
  static const String _customFoodsBox = 'custom_foods';
  static const String _foodUsageBox = 'food_usage';

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Search the built-in + custom food database.
  ///
  /// Matches against name and brand (case-insensitive substring).
  /// Results are ordered: exact prefix matches first, then contains matches.
  List<FoodItem> searchFoods(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_builtInFoods);

    final q = query.toLowerCase().trim();
    final prefixMatches = <FoodItem>[];
    final containsMatches = <FoodItem>[];

    for (final food in _allFoods) {
      final nameLower = food.name.toLowerCase();
      final brandLower = food.brand?.toLowerCase() ?? '';

      if (nameLower.startsWith(q) || brandLower.startsWith(q)) {
        prefixMatches.add(food);
      } else if (nameLower.contains(q) || brandLower.contains(q)) {
        containsMatches.add(food);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }

  /// Get all foods in a specific category.
  List<FoodItem> getFoodsByCategory(FoodCategory category) {
    return _allFoods.where((f) => f.category == category).toList();
  }

  /// Get a single food by ID, or null.
  FoodItem? getFoodById(String id) {
    try {
      return _allFoods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Custom foods ───────────────────────────────────────────────────────────

  /// Create and persist a custom food entry.
  Future<FoodItem> createCustomFood(FoodItem food) async {
    final box = Hive.box(_customFoodsBox);
    final customFood = food.copyWith(isCustom: true);
    await box.put(customFood.id, customFood.toJson());
    return customFood;
  }

  /// Delete a custom food entry.
  Future<void> deleteCustomFood(String foodId) async {
    final box = Hive.box(_customFoodsBox);
    await box.delete(foodId);
  }

  /// All user-created custom foods.
  List<FoodItem> getCustomFoods() {
    final box = Hive.box(_customFoodsBox);
    return box.values
        .map((v) => FoodItem.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  // ── Usage tracking ─────────────────────────────────────────────────────────

  /// Record that a food was used (for frequent / recent tracking).
  Future<void> saveFrequentFood(String foodId) async {
    final box = Hive.box(_foodUsageBox);
    final existing = box.get(foodId);
    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      final data = Map<String, dynamic>.from(existing as Map);
      data['count'] = ((data['count'] as int?) ?? 0) + 1;
      data['lastUsed'] = now;
      await box.put(foodId, data);
    } else {
      await box.put(foodId, {
        'foodId': foodId,
        'count': 1,
        'lastUsed': now,
      });
    }
  }

  /// Most-used foods, sorted by usage count descending.
  List<FoodItem> getFrequentFoods({int limit = 10}) {
    final box = Hive.box(_foodUsageBox);
    final entries = box.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList()
      ..sort((a, b) =>
          ((b['count'] as int?) ?? 0).compareTo((a['count'] as int?) ?? 0));

    final result = <FoodItem>[];
    for (final entry in entries.take(limit)) {
      final food = getFoodById(entry['foodId'] as String);
      if (food != null) result.add(food);
    }
    return result;
  }

  /// Recently logged foods, sorted by last-used timestamp descending.
  List<FoodItem> getRecentFoods({int limit = 10}) {
    final box = Hive.box(_foodUsageBox);
    final entries = box.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList()
      ..sort((a, b) {
        final aTime = a['lastUsed'] as String? ?? '';
        final bTime = b['lastUsed'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

    final result = <FoodItem>[];
    for (final entry in entries.take(limit)) {
      final food = getFoodById(entry['foodId'] as String);
      if (food != null) result.add(food);
    }
    return result;
  }

  // ── Combined list ──────────────────────────────────────────────────────────

  List<FoodItem> get _allFoods => [..._builtInFoods, ...getCustomFoods()];

  /// All built-in foods for external access (e.g., AI suggestions).
  List<FoodItem> get allBuiltInFoods => List.unmodifiable(_builtInFoods);

  // ── Hive box initialization ────────────────────────────────────────────────

  /// Open required Hive boxes. Call during app startup.
  static Future<void> initialize() async {
    await Future.wait([
      Hive.openBox(_customFoodsBox),
      Hive.openBox(_foodUsageBox),
    ]);
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // Built-in food database — 65 common foods with accurate nutrition data
  //
  // Sources: USDA FoodData Central, nutrition label averages.
  // Values are per the stated serving size.
  // ═════════════════════════════════════════════════════════════════════════════

  static final List<FoodItem> _builtInFoods = [
    // ── Proteins ────────────────────────────────────────────────────────────
    FoodItem(
      id: 'chicken_breast',
      name: 'Chicken Breast',
      brand: null,
      calories: 165,
      protein: 31.0,
      carbs: 0.0,
      fats: 3.6,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'salmon_atlantic',
      name: 'Atlantic Salmon',
      brand: null,
      calories: 208,
      protein: 20.4,
      carbs: 0.0,
      fats: 13.4,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'whole_egg',
      name: 'Whole Egg',
      brand: null,
      calories: 78,
      protein: 6.3,
      carbs: 0.6,
      fats: 5.3,
      fiber: 0.0,
      servingSize: 50,
      servingUnit: 'g (1 large)',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'greek_yogurt',
      name: 'Greek Yogurt (Plain, Nonfat)',
      brand: null,
      calories: 59,
      protein: 10.2,
      carbs: 3.6,
      fats: 0.4,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'whey_protein',
      name: 'Whey Protein Powder',
      brand: null,
      calories: 120,
      protein: 24.0,
      carbs: 3.0,
      fats: 1.5,
      fiber: 0.0,
      servingSize: 30,
      servingUnit: 'g (1 scoop)',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'tuna_canned',
      name: 'Tuna (Canned in Water)',
      brand: null,
      calories: 116,
      protein: 25.5,
      carbs: 0.0,
      fats: 0.8,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'ground_beef_90',
      name: 'Ground Beef (90% Lean)',
      brand: null,
      calories: 176,
      protein: 20.0,
      carbs: 0.0,
      fats: 10.0,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'turkey_breast',
      name: 'Turkey Breast',
      brand: null,
      calories: 135,
      protein: 30.0,
      carbs: 0.0,
      fats: 1.0,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'tofu_firm',
      name: 'Tofu (Firm)',
      brand: null,
      calories: 144,
      protein: 17.3,
      carbs: 2.8,
      fats: 8.7,
      fiber: 2.3,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'shrimp',
      name: 'Shrimp (Cooked)',
      brand: null,
      calories: 99,
      protein: 24.0,
      carbs: 0.2,
      fats: 0.3,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),
    FoodItem(
      id: 'egg_whites',
      name: 'Egg Whites',
      brand: null,
      calories: 52,
      protein: 10.9,
      carbs: 0.7,
      fats: 0.2,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.protein,
    ),

    // ── Dairy ───────────────────────────────────────────────────────────────
    FoodItem(
      id: 'whole_milk',
      name: 'Whole Milk',
      brand: null,
      calories: 149,
      protein: 8.0,
      carbs: 12.0,
      fats: 8.0,
      fiber: 0.0,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'skim_milk',
      name: 'Skim Milk',
      brand: null,
      calories: 83,
      protein: 8.3,
      carbs: 12.2,
      fats: 0.2,
      fiber: 0.0,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'cheddar_cheese',
      name: 'Cheddar Cheese',
      brand: null,
      calories: 403,
      protein: 24.9,
      carbs: 1.3,
      fats: 33.1,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'cottage_cheese',
      name: 'Cottage Cheese (Low Fat)',
      brand: null,
      calories: 98,
      protein: 11.1,
      carbs: 3.4,
      fats: 4.3,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.dairy,
    ),
    FoodItem(
      id: 'mozzarella',
      name: 'Mozzarella Cheese',
      brand: null,
      calories: 280,
      protein: 27.5,
      carbs: 3.1,
      fats: 17.1,
      fiber: 0.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.dairy,
    ),

    // ── Grains & Starches ───────────────────────────────────────────────────
    FoodItem(
      id: 'white_rice',
      name: 'White Rice (Cooked)',
      brand: null,
      calories: 130,
      protein: 2.7,
      carbs: 28.2,
      fats: 0.3,
      fiber: 0.4,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'brown_rice',
      name: 'Brown Rice (Cooked)',
      brand: null,
      calories: 123,
      protein: 2.7,
      carbs: 25.6,
      fats: 1.0,
      fiber: 1.6,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'oats',
      name: 'Rolled Oats (Dry)',
      brand: null,
      calories: 389,
      protein: 16.9,
      carbs: 66.3,
      fats: 6.9,
      fiber: 10.6,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'whole_wheat_bread',
      name: 'Whole Wheat Bread',
      brand: null,
      calories: 82,
      protein: 4.0,
      carbs: 13.8,
      fats: 1.1,
      fiber: 1.9,
      servingSize: 30,
      servingUnit: 'g (1 slice)',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'pasta_cooked',
      name: 'Pasta (Cooked)',
      brand: null,
      calories: 157,
      protein: 5.8,
      carbs: 30.6,
      fats: 0.9,
      fiber: 1.8,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'quinoa',
      name: 'Quinoa (Cooked)',
      brand: null,
      calories: 120,
      protein: 4.4,
      carbs: 21.3,
      fats: 1.9,
      fiber: 2.8,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'sweet_potato',
      name: 'Sweet Potato (Baked)',
      brand: null,
      calories: 90,
      protein: 2.0,
      carbs: 20.7,
      fats: 0.1,
      fiber: 3.3,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'potato',
      name: 'Potato (Baked)',
      brand: null,
      calories: 93,
      protein: 2.5,
      carbs: 21.2,
      fats: 0.1,
      fiber: 2.2,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.grains,
    ),
    FoodItem(
      id: 'white_bread',
      name: 'White Bread',
      brand: null,
      calories: 79,
      protein: 2.7,
      carbs: 14.3,
      fats: 1.0,
      fiber: 0.6,
      servingSize: 30,
      servingUnit: 'g (1 slice)',
      category: FoodCategory.grains,
    ),

    // ── Fruits ──────────────────────────────────────────────────────────────
    FoodItem(
      id: 'banana',
      name: 'Banana',
      brand: null,
      calories: 105,
      protein: 1.3,
      carbs: 27.0,
      fats: 0.4,
      fiber: 3.1,
      servingSize: 118,
      servingUnit: 'g (1 medium)',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'apple',
      name: 'Apple',
      brand: null,
      calories: 95,
      protein: 0.5,
      carbs: 25.1,
      fats: 0.3,
      fiber: 4.4,
      servingSize: 182,
      servingUnit: 'g (1 medium)',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'orange',
      name: 'Orange',
      brand: null,
      calories: 62,
      protein: 1.2,
      carbs: 15.4,
      fats: 0.2,
      fiber: 3.1,
      servingSize: 131,
      servingUnit: 'g (1 medium)',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'blueberries',
      name: 'Blueberries',
      brand: null,
      calories: 57,
      protein: 0.7,
      carbs: 14.5,
      fats: 0.3,
      fiber: 2.4,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'strawberries',
      name: 'Strawberries',
      brand: null,
      calories: 32,
      protein: 0.7,
      carbs: 7.7,
      fats: 0.3,
      fiber: 2.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'avocado',
      name: 'Avocado',
      brand: null,
      calories: 240,
      protein: 3.0,
      carbs: 12.8,
      fats: 22.0,
      fiber: 10.0,
      servingSize: 150,
      servingUnit: 'g (1 medium)',
      category: FoodCategory.fruits,
    ),
    FoodItem(
      id: 'mango',
      name: 'Mango',
      brand: null,
      calories: 99,
      protein: 1.4,
      carbs: 24.7,
      fats: 0.6,
      fiber: 2.6,
      servingSize: 165,
      servingUnit: 'g (1 cup sliced)',
      category: FoodCategory.fruits,
    ),

    // ── Vegetables ──────────────────────────────────────────────────────────
    FoodItem(
      id: 'broccoli',
      name: 'Broccoli',
      brand: null,
      calories: 34,
      protein: 2.8,
      carbs: 6.6,
      fats: 0.4,
      fiber: 2.6,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'spinach',
      name: 'Spinach (Raw)',
      brand: null,
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fats: 0.4,
      fiber: 2.2,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'kale',
      name: 'Kale (Raw)',
      brand: null,
      calories: 49,
      protein: 4.3,
      carbs: 8.8,
      fats: 0.9,
      fiber: 3.6,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'bell_pepper',
      name: 'Bell Pepper (Red)',
      brand: null,
      calories: 31,
      protein: 1.0,
      carbs: 6.0,
      fats: 0.3,
      fiber: 2.1,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'tomato',
      name: 'Tomato',
      brand: null,
      calories: 18,
      protein: 0.9,
      carbs: 3.9,
      fats: 0.2,
      fiber: 1.2,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'cucumber',
      name: 'Cucumber',
      brand: null,
      calories: 15,
      protein: 0.7,
      carbs: 3.6,
      fats: 0.1,
      fiber: 0.5,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'carrots',
      name: 'Carrots',
      brand: null,
      calories: 41,
      protein: 0.9,
      carbs: 9.6,
      fats: 0.2,
      fiber: 2.8,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),
    FoodItem(
      id: 'asparagus',
      name: 'Asparagus',
      brand: null,
      calories: 20,
      protein: 2.2,
      carbs: 3.9,
      fats: 0.1,
      fiber: 2.1,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.vegetables,
    ),

    // ── Fats & Oils ─────────────────────────────────────────────────────────
    FoodItem(
      id: 'olive_oil',
      name: 'Olive Oil',
      brand: null,
      calories: 119,
      protein: 0.0,
      carbs: 0.0,
      fats: 13.5,
      fiber: 0.0,
      servingSize: 15,
      servingUnit: 'ml (1 tbsp)',
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'peanut_butter',
      name: 'Peanut Butter',
      brand: null,
      calories: 188,
      protein: 8.0,
      carbs: 6.0,
      fats: 16.0,
      fiber: 1.8,
      servingSize: 32,
      servingUnit: 'g (2 tbsp)',
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'almond_butter',
      name: 'Almond Butter',
      brand: null,
      calories: 196,
      protein: 6.8,
      carbs: 6.0,
      fats: 17.8,
      fiber: 3.3,
      servingSize: 32,
      servingUnit: 'g (2 tbsp)',
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'almonds',
      name: 'Almonds',
      brand: null,
      calories: 164,
      protein: 6.0,
      carbs: 6.1,
      fats: 14.2,
      fiber: 3.5,
      servingSize: 28,
      servingUnit: 'g (1 oz)',
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'walnuts',
      name: 'Walnuts',
      brand: null,
      calories: 185,
      protein: 4.3,
      carbs: 3.9,
      fats: 18.5,
      fiber: 1.9,
      servingSize: 28,
      servingUnit: 'g (1 oz)',
      category: FoodCategory.fats,
    ),
    FoodItem(
      id: 'coconut_oil',
      name: 'Coconut Oil',
      brand: null,
      calories: 121,
      protein: 0.0,
      carbs: 0.0,
      fats: 13.5,
      fiber: 0.0,
      servingSize: 15,
      servingUnit: 'ml (1 tbsp)',
      category: FoodCategory.fats,
    ),

    // ── Beverages ───────────────────────────────────────────────────────────
    FoodItem(
      id: 'black_coffee',
      name: 'Black Coffee',
      brand: null,
      calories: 2,
      protein: 0.3,
      carbs: 0.0,
      fats: 0.0,
      fiber: 0.0,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'orange_juice',
      name: 'Orange Juice',
      brand: null,
      calories: 112,
      protein: 1.7,
      carbs: 25.8,
      fats: 0.5,
      fiber: 0.5,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'protein_shake',
      name: 'Protein Shake',
      brand: null,
      calories: 160,
      protein: 30.0,
      carbs: 5.0,
      fats: 2.5,
      fiber: 1.0,
      servingSize: 350,
      servingUnit: 'ml (1 shake)',
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'coconut_water',
      name: 'Coconut Water',
      brand: null,
      calories: 46,
      protein: 1.7,
      carbs: 8.9,
      fats: 0.5,
      fiber: 2.6,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.beverages,
    ),
    FoodItem(
      id: 'green_tea',
      name: 'Green Tea',
      brand: null,
      calories: 2,
      protein: 0.5,
      carbs: 0.0,
      fats: 0.0,
      fiber: 0.0,
      servingSize: 240,
      servingUnit: 'ml (1 cup)',
      category: FoodCategory.beverages,
    ),

    // ── Snacks ──────────────────────────────────────────────────────────────
    FoodItem(
      id: 'dark_chocolate',
      name: 'Dark Chocolate (70–85%)',
      brand: null,
      calories: 170,
      protein: 2.2,
      carbs: 13.0,
      fats: 12.0,
      fiber: 3.1,
      servingSize: 28,
      servingUnit: 'g (1 oz)',
      category: FoodCategory.snacks,
    ),
    FoodItem(
      id: 'granola_bar',
      name: 'Granola Bar',
      brand: null,
      calories: 190,
      protein: 3.0,
      carbs: 29.0,
      fats: 7.0,
      fiber: 2.0,
      servingSize: 42,
      servingUnit: 'g (1 bar)',
      category: FoodCategory.snacks,
    ),
    FoodItem(
      id: 'rice_cakes',
      name: 'Rice Cakes',
      brand: null,
      calories: 35,
      protein: 0.7,
      carbs: 7.3,
      fats: 0.3,
      fiber: 0.4,
      servingSize: 9,
      servingUnit: 'g (1 cake)',
      category: FoodCategory.snacks,
    ),
    FoodItem(
      id: 'trail_mix',
      name: 'Trail Mix',
      brand: null,
      calories: 462,
      protein: 13.0,
      carbs: 44.0,
      fats: 29.0,
      fiber: 4.0,
      servingSize: 100,
      servingUnit: 'g',
      category: FoodCategory.snacks,
    ),
    FoodItem(
      id: 'protein_bar',
      name: 'Protein Bar',
      brand: null,
      calories: 230,
      protein: 20.0,
      carbs: 25.0,
      fats: 8.0,
      fiber: 3.0,
      servingSize: 60,
      servingUnit: 'g (1 bar)',
      category: FoodCategory.snacks,
    ),

    // ── Meals (pre-composed) ────────────────────────────────────────────────
    FoodItem(
      id: 'chicken_salad',
      name: 'Chicken Salad',
      brand: null,
      calories: 320,
      protein: 28.0,
      carbs: 12.0,
      fats: 18.0,
      fiber: 3.5,
      servingSize: 250,
      servingUnit: 'g (1 bowl)',
      category: FoodCategory.meals,
    ),
    FoodItem(
      id: 'grilled_chicken_sandwich',
      name: 'Grilled Chicken Sandwich',
      brand: null,
      calories: 420,
      protein: 35.0,
      carbs: 38.0,
      fats: 14.0,
      fiber: 3.0,
      servingSize: 220,
      servingUnit: 'g (1 sandwich)',
      category: FoodCategory.meals,
    ),
    FoodItem(
      id: 'protein_bowl',
      name: 'Protein Bowl',
      brand: null,
      calories: 480,
      protein: 40.0,
      carbs: 45.0,
      fats: 14.0,
      fiber: 6.0,
      servingSize: 350,
      servingUnit: 'g (1 bowl)',
      category: FoodCategory.meals,
    ),
    FoodItem(
      id: 'tuna_wrap',
      name: 'Tuna Wrap',
      brand: null,
      calories: 360,
      protein: 28.0,
      carbs: 32.0,
      fats: 12.0,
      fiber: 2.0,
      servingSize: 200,
      servingUnit: 'g (1 wrap)',
      category: FoodCategory.meals,
    ),
    FoodItem(
      id: 'overnight_oats',
      name: 'Overnight Oats with Berries',
      brand: null,
      calories: 350,
      protein: 14.0,
      carbs: 52.0,
      fats: 10.0,
      fiber: 7.0,
      servingSize: 300,
      servingUnit: 'g (1 jar)',
      category: FoodCategory.meals,
    ),
    FoodItem(
      id: 'steak_and_rice',
      name: 'Steak and Rice',
      brand: null,
      calories: 550,
      protein: 38.0,
      carbs: 48.0,
      fats: 20.0,
      fiber: 1.5,
      servingSize: 350,
      servingUnit: 'g (1 plate)',
      category: FoodCategory.meals,
    ),
  ];
}
