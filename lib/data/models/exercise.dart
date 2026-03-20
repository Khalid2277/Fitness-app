import 'package:hive/hive.dart';

import 'enums.dart';

@HiveType(typeId: 8)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String instructions;

  @HiveField(4)
  final List<String> tips;

  @HiveField(5)
  final List<String> commonMistakes;

  @HiveField(6)
  final MuscleGroup primaryMuscle;

  @HiveField(7)
  final List<MuscleGroup> secondaryMuscles;

  @HiveField(8)
  final EquipmentType equipment;

  @HiveField(9)
  final ExerciseDifficulty difficulty;

  @HiveField(10)
  final ExerciseCategory category;

  @HiveField(11)
  final String? videoUrl;

  @HiveField(12)
  final String? imageUrl;

  @HiveField(13)
  final List<String> bestForGoals;

  @HiveField(14)
  final String? setupInstructions;

  @HiveField(15)
  final String? safetyTips;

  @HiveField(16)
  final String suggestedRepRange;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.commonMistakes,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.category,
    this.videoUrl,
    this.imageUrl,
    required this.bestForGoals,
    this.setupInstructions,
    this.safetyTips,
    required this.suggestedRepRange,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? instructions,
    List<String>? tips,
    List<String>? commonMistakes,
    MuscleGroup? primaryMuscle,
    List<MuscleGroup>? secondaryMuscles,
    EquipmentType? equipment,
    ExerciseDifficulty? difficulty,
    ExerciseCategory? category,
    String? videoUrl,
    String? imageUrl,
    List<String>? bestForGoals,
    String? setupInstructions,
    String? safetyTips,
    String? suggestedRepRange,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      tips: tips ?? this.tips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      bestForGoals: bestForGoals ?? this.bestForGoals,
      setupInstructions: setupInstructions ?? this.setupInstructions,
      safetyTips: safetyTips ?? this.safetyTips,
      suggestedRepRange: suggestedRepRange ?? this.suggestedRepRange,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'tips': tips,
      'commonMistakes': commonMistakes,
      'primaryMuscle': primaryMuscle.name,
      'secondaryMuscles': secondaryMuscles.map((m) => m.name).toList(),
      'equipment': equipment.name,
      'difficulty': difficulty.name,
      'category': category.name,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'bestForGoals': bestForGoals,
      'setupInstructions': setupInstructions,
      'safetyTips': safetyTips,
      'suggestedRepRange': suggestedRepRange,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,
      tips: List<String>.from(json['tips'] as List),
      commonMistakes: List<String>.from(json['commonMistakes'] as List),
      primaryMuscle: MuscleGroup.values.byName(json['primaryMuscle'] as String),
      secondaryMuscles: (json['secondaryMuscles'] as List)
          .map((m) => MuscleGroup.values.byName(m as String))
          .toList(),
      equipment: EquipmentType.values.byName(json['equipment'] as String),
      difficulty:
          ExerciseDifficulty.values.byName(json['difficulty'] as String),
      category: ExerciseCategory.values.byName(json['category'] as String),
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      bestForGoals: List<String>.from(json['bestForGoals'] as List),
      setupInstructions: json['setupInstructions'] as String?,
      safetyTips: json['safetyTips'] as String?,
      suggestedRepRange: json['suggestedRepRange'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Exercise(id: $id, name: $name)';
}

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 8;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Exercise(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      instructions: fields[3] as String,
      tips: (fields[4] as List).cast<String>(),
      commonMistakes: (fields[5] as List).cast<String>(),
      primaryMuscle: fields[6] as MuscleGroup,
      secondaryMuscles: (fields[7] as List).cast<MuscleGroup>(),
      equipment: fields[8] as EquipmentType,
      difficulty: fields[9] as ExerciseDifficulty,
      category: fields[10] as ExerciseCategory,
      videoUrl: fields[11] as String?,
      imageUrl: fields[12] as String?,
      bestForGoals: (fields[13] as List).cast<String>(),
      setupInstructions: fields[14] as String?,
      safetyTips: fields[15] as String?,
      suggestedRepRange: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.instructions)
      ..writeByte(4)
      ..write(obj.tips)
      ..writeByte(5)
      ..write(obj.commonMistakes)
      ..writeByte(6)
      ..write(obj.primaryMuscle)
      ..writeByte(7)
      ..write(obj.secondaryMuscles)
      ..writeByte(8)
      ..write(obj.equipment)
      ..writeByte(9)
      ..write(obj.difficulty)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.videoUrl)
      ..writeByte(12)
      ..write(obj.imageUrl)
      ..writeByte(13)
      ..write(obj.bestForGoals)
      ..writeByte(14)
      ..write(obj.setupInstructions)
      ..writeByte(15)
      ..write(obj.safetyTips)
      ..writeByte(16)
      ..write(obj.suggestedRepRange);
  }
}
