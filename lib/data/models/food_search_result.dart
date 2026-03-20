import 'package:hive/hive.dart';

/// Unified food search result model used across all food sources
/// (Open Food Facts, USDA FoodData Central, and custom user-created foods).
class FoodSearchResult {
  final String id;
  final String name;
  final String? brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double servingSize;
  final String servingUnit;
  final String? imageUrl;
  final String source;
  final String? barcode;
  final DateTime? lastUsed;
  final int useCount;

  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    this.imageUrl,
    required this.source,
    this.barcode,
    this.lastUsed,
    this.useCount = 0,
  });

  // ─────────────────────────── Computed getters ────────────────────────────

  double get caloriesPer100g =>
      servingSize > 0 ? (calories / servingSize) * 100 : 0;

  double get proteinPer100g =>
      servingSize > 0 ? (protein / servingSize) * 100 : 0;

  double get carbsPer100g =>
      servingSize > 0 ? (carbs / servingSize) * 100 : 0;

  double get fatPer100g =>
      servingSize > 0 ? (fat / servingSize) * 100 : 0;

  double get fiberPer100g =>
      servingSize > 0 ? ((fiber ?? 0) / servingSize) * 100 : 0;

  /// Total macros in grams (protein + carbs + fat).
  double get totalMacros => protein + carbs + fat;

  /// Protein percentage of total calories.
  double get proteinPercentage =>
      calories > 0 ? (protein * 4 / calories) * 100 : 0;

  /// Carbs percentage of total calories.
  double get carbsPercentage =>
      calories > 0 ? (carbs * 4 / calories) * 100 : 0;

  /// Fat percentage of total calories.
  double get fatPercentage =>
      calories > 0 ? (fat * 9 / calories) * 100 : 0;

  /// Display name with optional brand.
  String get displayName =>
      brand != null && brand!.isNotEmpty ? '$name ($brand)' : name;

  // ─────────────────────────── Serving adjustment ──────────────────────────

  /// Returns a copy with all nutrition values scaled to the given serving
  /// in grams.
  FoodSearchResult adjustForServing(double grams) {
    if (servingSize <= 0) return this;
    final ratio = grams / servingSize;
    return copyWith(
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      fiber: fiber != null ? fiber! * ratio : null,
      servingSize: grams,
    );
  }

  // ─────────────────────────── copyWith ────────────────────────────────────

  FoodSearchResult copyWith({
    String? id,
    String? name,
    String? brand,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? servingSize,
    String? servingUnit,
    String? imageUrl,
    String? source,
    String? barcode,
    DateTime? lastUsed,
    int? useCount,
  }) {
    return FoodSearchResult(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      barcode: barcode ?? this.barcode,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
    );
  }

  // ─────────────────────────── JSON serialization ──────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'imageUrl': imageUrl,
      'source': source,
      'barcode': barcode,
      'lastUsed': lastUsed?.toIso8601String(),
      'useCount': useCount,
    };
  }

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100.0,
      servingUnit: json['servingUnit'] as String? ?? 'g',
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String? ?? 'custom',
      barcode: json['barcode'] as String?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodSearchResult && other.id == id && other.source == source;

  @override
  int get hashCode => Object.hash(id, source);

  @override
  String toString() =>
      'FoodSearchResult(id: $id, name: $name, source: $source, '
      'calories: $calories)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Hive TypeAdapter — typeId 22
// ─────────────────────────────────────────────────────────────────────────────

class FoodSearchResultAdapter extends TypeAdapter<FoodSearchResult> {
  @override
  final int typeId = 22;

  @override
  FoodSearchResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return FoodSearchResult(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String?,
      calories: (fields[3] as num?)?.toDouble() ?? 0.0,
      protein: (fields[4] as num?)?.toDouble() ?? 0.0,
      carbs: (fields[5] as num?)?.toDouble() ?? 0.0,
      fat: (fields[6] as num?)?.toDouble() ?? 0.0,
      fiber: (fields[7] as num?)?.toDouble(),
      servingSize: (fields[8] as num?)?.toDouble() ?? 100.0,
      servingUnit: fields[9] as String? ?? 'g',
      imageUrl: fields[10] as String?,
      source: fields[11] as String? ?? 'custom',
      barcode: fields[12] as String?,
      lastUsed: fields[13] as DateTime?,
      useCount: (fields[14] as num?)?.toInt() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, FoodSearchResult obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.fat)
      ..writeByte(7)
      ..write(obj.fiber)
      ..writeByte(8)
      ..write(obj.servingSize)
      ..writeByte(9)
      ..write(obj.servingUnit)
      ..writeByte(10)
      ..write(obj.imageUrl)
      ..writeByte(11)
      ..write(obj.source)
      ..writeByte(12)
      ..write(obj.barcode)
      ..writeByte(13)
      ..write(obj.lastUsed)
      ..writeByte(14)
      ..write(obj.useCount);
  }
}
