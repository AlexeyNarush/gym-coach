enum MuscleGroup {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  fullBody,
}

enum EquipmentType {
  bodyweight,
  dumbbells,
  barbell,
  cable,
  machine,
  kettlebell,
  bench,
}

enum ExerciseDifficulty { beginner, easyModerate, moderate }

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.equipmentType,
    required this.difficulty,
    required this.instructionsShort,
    required this.safetyTips,
    required this.imageAssetPath,
    required this.movementPattern,
  });

  final String id;
  final String name;
  final List<MuscleGroup> muscleGroups;
  final EquipmentType equipmentType;
  final ExerciseDifficulty difficulty;
  final String instructionsShort;
  final String safetyTips;
  final String imageAssetPath;
  final String movementPattern;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroups': muscleGroups.map((e) => e.name).toList(),
      'equipmentType': equipmentType.name,
      'difficulty': difficulty.name,
      'instructionsShort': instructionsShort,
      'safetyTips': safetyTips,
      'imageAssetPath': imageAssetPath,
      'movementPattern': movementPattern,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroups: (json['muscleGroups'] as List<dynamic>)
          .map((e) => MuscleGroup.values.byName(e as String))
          .toList(),
      equipmentType: EquipmentType.values.byName(json['equipmentType'] as String),
      difficulty:
          ExerciseDifficulty.values.byName(json['difficulty'] as String),
      instructionsShort: json['instructionsShort'] as String,
      safetyTips: json['safetyTips'] as String,
      imageAssetPath: json['imageAssetPath'] as String,
      movementPattern: json['movementPattern'] as String,
    );
  }
}

class ExerciseAlternative {
  const ExerciseAlternative({
    required this.exerciseId,
    required this.alternativeExerciseId,
    required this.reasonTags,
  });

  final String exerciseId;
  final String alternativeExerciseId;
  final List<String> reasonTags;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'alternativeExerciseId': alternativeExerciseId,
      'reasonTags': reasonTags,
    };
  }

  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) {
    return ExerciseAlternative(
      exerciseId: json['exerciseId'] as String,
      alternativeExerciseId: json['alternativeExerciseId'] as String,
      reasonTags:
          (json['reasonTags'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
