import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/food_item.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/nutrition_mapper.dart';

class SbFoodItemRepository {
  final SupabaseClient _client;

  SbFoodItemRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Searches food items by name or brand (case-insensitive).
  Future<List<FoodItem>> searchFoodItems(String query) async {
    final rows = await _client
        .from(SupabaseConfig.foodItemsTable)
        .select()
        .or('name.ilike.%$query%,brand.ilike.%$query%')
        .limit(50);
    return rows.map((r) => NutritionMapper.foodItemFromRow(r)).toList();
  }

  /// Returns all custom food items created by the current user.
  Future<List<FoodItem>> getCustomFoodItems() async {
    final rows = await _client
        .from(SupabaseConfig.foodItemsTable)
        .select()
        .eq('user_id', _uid)
        .order('name');
    return rows.map((r) => NutritionMapper.foodItemFromRow(r)).toList();
  }

  /// Adds a custom food item owned by the current user.
  Future<void> addCustomFoodItem(FoodItem item) async {
    final data = NutritionMapper.foodItemToRow(item, userId: _uid);
    await _client.from(SupabaseConfig.foodItemsTable).insert(data);
  }

  /// Deletes a custom food item owned by the current user.
  Future<void> deleteFoodItem(String id) async {
    await _client
        .from(SupabaseConfig.foodItemsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }
}
