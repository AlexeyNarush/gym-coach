import 'package:collection/collection.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';
import 'package:gym_coach/features/today/domain/adaptation_rules.dart';

class GeneratedWorkout {
  const GeneratedWorkout({
    required this.source,
    required this.exercises,
  });

  final SessionSource source;
  final List<Exercise> exercises;
}

class WorkoutGeneratorService {
  WorkoutGeneratorService({
    required ExerciseRepository exerciseRepository,
    required AdaptationRules adaptationRules,
  })  : _exerciseRepository = exerciseRepository,
        _adaptationRules = adaptationRules;

  final ExerciseRepository _exerciseRepository;
  final AdaptationRules _adaptationRules;

  GeneratedWorkout generateFromHistory({
    required List<String> templateExerciseIds,
    required List<SessionLog> history,
  }) {
    final base = templateExerciseIds
        .map(_exerciseRepository.byId)
        .toList(growable: false);
    final selectedPatterns = <String>[];
    final ranked = [...base]
      ..sort((a, b) => _adaptationRules
          .scoreExercise(exercise: b, history: history)
          .compareTo(_adaptationRules.scoreExercise(exercise: a, history: history)));

    final output = <Exercise>[];
    for (final exercise in ranked) {
      if (_adaptationRules.isMovementPatternOverused(
        movementPattern: exercise.movementPattern,
        selectedPatterns: selectedPatterns,
      )) {
        final fallback = _exerciseRepository
            .alternativesFor(exercise.id)
            .firstWhereOrNull((candidate) {
          return !_adaptationRules.isMovementPatternOverused(
            movementPattern: candidate.movementPattern,
            selectedPatterns: selectedPatterns,
          );
        });
        if (fallback != null) {
          output.add(fallback);
          selectedPatterns.add(fallback.movementPattern);
          continue;
        }
      }
      output.add(exercise);
      selectedPatterns.add(exercise.movementPattern);
    }

    return GeneratedWorkout(source: SessionSource.history, exercises: output.take(6).toList());
  }

  GeneratedWorkout generateFromMuscleGroup({
    required MuscleGroup muscleGroup,
    required List<SessionLog> history,
  }) {
    final base = _exerciseRepository.byMuscleGroup(muscleGroup);
    final sorted = [...base]
      ..sort((a, b) => _adaptationRules
          .scoreExercise(exercise: b, history: history)
          .compareTo(_adaptationRules.scoreExercise(exercise: a, history: history)));
    final minimumEquipmentFallbacks = sorted
        .where((e) =>
            e.equipmentType == EquipmentType.bodyweight ||
            e.equipmentType == EquipmentType.dumbbells)
        .take(2)
        .toList();

    final output = [...sorted.take(4), ...minimumEquipmentFallbacks]
        .fold<List<Exercise>>([], (acc, exercise) {
      if (acc.any((e) => e.id == exercise.id)) {
        return acc;
      }
      return [...acc, exercise];
    });
    return GeneratedWorkout(source: SessionSource.muscleGroup, exercises: output.take(6).toList());
  }
}
