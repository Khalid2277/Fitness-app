import 'package:hive/hive.dart';

import 'enums.dart';

@HiveType(typeId: 12)
class Meal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final MealType mealType;

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
  final DateTime dateTime;

  @HiveField(9)
  final double servingSize;

  @HiveField(10)
  final String? servingUnit;

  @HiveField(11)
  final String? notes;

  Meal({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.fiber = 0.0,
    required this.dateTime,
    this.servingSize = 1.0,
    this.servingUnit,
    this.notes,
  });

  /// Total macros in grams (protein + carbs + fats).
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

  Meal copyWith({
    String? id,
    String? name,
    MealType? mealType,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    double? fiber,
    DateTime? dateTime,
    double? servingSize,
    String? servingUnit,
    String? notes,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      dateTime: dateTime ?? this.dateTime,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'dateTime': dateTime.toIso8601String(),
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'notes': notes,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      mealType: MealType.values.byName(json['mealType'] as String),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(json['dateTime'] as String),
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 1.0,
      servingUnit: json['servingUnit'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Meal && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Meal(id: $id, name: $name, calories: $calories)';
}

class MealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 12;

  @override
  Meal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Meal(
      id: fields[0] as String,
      name: fields[1] as String,
      mealType: fields[2] as MealType,
      calories: fields[3] as double,
      protein: fields[4] as double,
      carbs: fields[5] as double,
      fats: fields[6] as double,
      fiber: fields[7] as double? ?? 0.0,
      dateTime: fields[8] as DateTime,
      servingSize: fields[9] as double? ?? 1.0,
      servingUnit: fields[10] as String?,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mealType)
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
      ..write(obj.dateTime)
      ..writeByte(9)
      ..write(obj.servingSize)
      ..writeByte(10)
      ..write(obj.servingUnit)
      ..writeByte(11)
      ..write(obj.notes);
  }
}
