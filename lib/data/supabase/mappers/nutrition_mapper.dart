import 'package:alfanutrition/data/models/food_item.dart';
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/models/food_search_result.dart';

import 'enum_mappers.dart';

/// Maps between Supabase nutrition-related rows and the app-side
/// [Meal], [FoodItem], and [FoodSearchResult] models.
abstract final class NutritionMapper {
  // ─────────────────────────── Meal ──────────────────────────────────────

  static Meal mealFromRow(Map<String, dynamic> row) {
    return Meal(
      id: row['id'] as String,
      name: row['name'] as String,
      mealType: EnumMappers.mealTypeFromDb(row['meal_type'] as String),
      calories: (row['calories'] as num).toDouble(),
      protein: (row['protein'] as num).toDouble(),
      carbs: (row['carbs'] as num).toDouble(),
      fats: (row['fats'] as num).toDouble(),
      fiber: (row['fiber'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(row['date_time'] as String),
      servingSize: (row['serving_size'] as num?)?.toDouble() ?? 1.0,
      servingUnit: row['serving_unit'] as String?,
      notes: row['notes'] as String?,
    );
  }

  static Map<String, dynamic> mealToRow(Meal meal, {required String userId}) {
    return {
      'id': meal.id,
      'user_id': userId,
      'name': meal.name,
      'meal_type': EnumMappers.mealTypeToDb(meal.mealType),
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fats': meal.fats,
      'fiber': meal.fiber,
      'date_time': meal.dateTime.toIso8601String(),
      'serving_size': meal.servingSize,
      'serving_unit': meal.servingUnit,
      'notes': meal.notes,
    };
  }

  // ─────────────────────────── FoodItem ──────────────────────────────────

  static FoodItem foodItemFromRow(Map<String, dynamic> row) {
    return FoodItem(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      calories: (row['calories'] as num).toDouble(),
      protein: (row['protein'] as num).toDouble(),
      carbs: (row['carbs'] as num).toDouble(),
      fats: (row['fats'] as num).toDouble(),
      fiber: (row['fiber'] as num?)?.toDouble() ?? 0.0,
      servingSize: (row['serving_size'] as num).toDouble(),
      servingUnit: row['serving_unit'] as String? ?? 'g',
      category: EnumMappers.foodCategoryFromDb(row['category'] as String),
      isCustom: row['is_custom'] as bool? ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> foodItemToRow(
    FoodItem item, {
    required String userId,
  }) {
    return {
      'id': item.id,
      'user_id': userId,
      'name': item.name,
      'brand': item.brand,
      'calories': item.calories,
      'protein': item.protein,
      'carbs': item.carbs,
      'fats': item.fats,
      'fiber': item.fiber,
      'serving_size': item.servingSize,
      'serving_unit': item.servingUnit,
      'category': EnumMappers.foodCategoryToDb(item.category),
      'is_custom': item.isCustom,
      'created_at': item.createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────── FoodSearchResult ──────────────────────────

  static FoodSearchResult foodSearchResultFromRow(Map<String, dynamic> row) {
    return FoodSearchResult(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      calories: (row['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (row['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (row['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (row['fats'] as num?)?.toDouble() ?? 0.0,
      fiber: (row['fiber'] as num?)?.toDouble(),
      servingSize: (row['serving_size'] as num?)?.toDouble() ?? 100.0,
      servingUnit: row['serving_unit'] as String? ?? 'g',
      imageUrl: row['image_url'] as String?,
      source: row['source'] as String? ?? 'custom',
      barcode: row['barcode'] as String?,
      lastUsed: row['last_used_at'] != null
          ? DateTime.parse(row['last_used_at'] as String)
          : null,
      useCount: (row['use_count'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> foodSearchResultToRow(
    FoodSearchResult result, {
    required String userId,
  }) {
    return {
      'id': result.id,
      'user_id': userId,
      'name': result.name,
      'brand': result.brand,
      'calories': result.calories,
      'protein': result.protein,
      'carbs': result.carbs,
      'fats': result.fat,
      'fiber': result.fiber,
      'serving_size': result.servingSize,
      'serving_unit': result.servingUnit,
      'image_url': result.imageUrl,
      'source': result.source,
      'barcode': result.barcode,
      'last_used_at': result.lastUsed?.toIso8601String(),
      'use_count': result.useCount,
    };
  }
}
