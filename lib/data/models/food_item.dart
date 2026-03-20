import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FoodCategory
// ─────────────────────────────────────────────────────────────────────────────

enum FoodCategory {
  protein,
  dairy,
  grains,
  fruits,
  vegetables,
  fats,
  beverages,
  snacks,
  meals,
  custom;

  String get displayName {
    switch (this) {
      case FoodCategory.protein:
        return 'Protein';
      case FoodCategory.dairy:
        return 'Dairy';
      case FoodCategory.grains:
        return 'Grains & Starches';
      case FoodCategory.fruits:
        return 'Fruits';
      case FoodCategory.vegetables:
        return 'Vegetables';
      case FoodCategory.fats:
        return 'Fats & Oils';
      case FoodCategory.beverages:
        return 'Beverages';
      case FoodCategory.snacks:
        return 'Snacks';
      case FoodCategory.meals:
        return 'Meals';
      case FoodCategory.custom:
        return 'Custom';
    }
  }
}

class FoodCategoryAdapter extends TypeAdapter<FoodCategory> {
  @override
  final int typeId = 21;

  @override
  FoodCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return FoodCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, FoodCategory obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FoodItem — typeId 19
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 19)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? brand;

  @HiveField(3)
  final double calories;

  @HiveField(4)
  final double protein;

  @HiveField(5)
  final double carbs;

  @HiveField(6)
  final double fats;

  @HiveField(7)
  final double fiber;

  @HiveField(8)
  final double servingSize;

  @HiveField(9)
  final String servingUnit;

  @HiveField(10)
  final FoodCategory category;

  @HiveField(11)
  final bool isCustom;

  @HiveField(12)
  final DateTime createdAt;

  FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.fiber = 0.0,
    required this.servingSize,
    this.servingUnit = 'g',
    required this.category,
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calories per gram of this food item.
  double get caloriesPerGram =>
      servingSize > 0 ? calories / servingSize : 0;

  /// Total macros in grams.
  double get totalMacros => protein + carbs + fats;

  /// Protein percentage of total calories.
  double get proteinPercentage =>
      calories > 0 ? (protein * 4 / calories) * 100 : 0;

  /// Carbs percentage of total calories.
  double get carbsPercentage =>
      calories > 0 ? (carbs * 4 / calories) * 100 : 0;

  /// Fats percentage of total calories.
  double get fatsPercentage =>
      calories > 0 ? (fats * 9 / calories) * 100 : 0;

  FoodItem copyWith({
    String? id,
    String? name,
    String? brand,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    double? fiber,
    double? servingSize,
    String? servingUnit,
    FoodCategory? category,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'category': category.name,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      servingSize: (json['servingSize'] as num).toDouble(),
      servingUnit: json['servingUnit'] as String? ?? 'g',
      category: FoodCategory.values.byName(json['category'] as String),
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FoodItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FoodItem(id: $id, name: $name, calories: $calories)';
}

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 19;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return FoodItem(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String?,
      calories: fields[3] as double,
      protein: fields[4] as double,
      carbs: fields[5] as double,
      fats: fields[6] as double,
      fiber: fields[7] as double? ?? 0.0,
      servingSize: fields[8] as double,
      servingUnit: fields[9] as String? ?? 'g',
      category: fields[10] as FoodCategory,
      isCustom: fields[11] as bool? ?? false,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.protein)
      ..writeByte(5)
      ..write(obj.carbs)
      ..writeByte(6)
      ..write(obj.fats)
      ..writeByte(7)
      ..write(obj.fiber)
      ..writeByte(8)
      ..write(obj.servingSize)
      ..writeByte(9)
      ..write(obj.servingUnit)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.isCustom)
      ..writeByte(12)
      ..write(obj.createdAt);
  }
}
