import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/features/exercises/data/local/seed_exercise_source.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

class ExerciseRepository {
  final List<Exercise> _exercises = SeedExerciseSource.exercises;
  final List<ExerciseAlternative> _alternatives = SeedExerciseSource.alternatives;

  List<Exercise> getAllExercises() => _exercises;

  Exercise byId(String id) => _exercises.firstWhere((exercise) => exercise.id == id);

  List<Exercise> byMuscleGroup(MuscleGroup group) {
    return _exercises.where((exercise) => exercise.muscleGroups.contains(group)).toList();
  }

  List<Exercise> alternativesFor(String exerciseId) {
    final alternativeIds = _alternatives
        .where((alt) => alt.exerciseId == exerciseId)
        .map((alt) => alt.alternativeExerciseId)
        .toSet();
    return _exercises.where((exercise) => alternativeIds.contains(exercise.id)).toList();
  }

  List<ExerciseAlternative> get allAlternatives => _alternatives;
}
