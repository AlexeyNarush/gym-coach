import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';
import 'package:gym_coach/features/today/domain/adaptation_rules.dart';
import 'package:gym_coach/features/today/domain/workout_generator_service.dart';

void main() {
  test('generateFromMuscleGroup returns exercises for core', () {
    final repo = ExerciseRepository();
    final service = WorkoutGeneratorService(
      exerciseRepository: repo,
      adaptationRules: const AdaptationRules(),
    );
    final workout = service.generateFromMuscleGroup(
      muscleGroup: MuscleGroup.core,
      history: const [],
    );
    expect(workout.source, SessionSource.muscleGroup);
    expect(workout.exercises, isNotEmpty);
    for (final exercise in workout.exercises) {
      expect(exercise.muscleGroups, contains(MuscleGroup.core));
    }
  });

  test('generateFromHistory respects template ids', () {
    final repo = ExerciseRepository();
    final service = WorkoutGeneratorService(
      exerciseRepository: repo,
      adaptationRules: const AdaptationRules(),
    );
    final templateIds = [
      'plank',
      'dead_bug',
      'bw_squat',
      'db_bench_press',
    ];
    final workout = service.generateFromHistory(
      templateExerciseIds: templateIds,
      history: const [],
    );
    expect(workout.source, SessionSource.history);
    expect(workout.exercises.length, lessThanOrEqualTo(6));
    final ids = workout.exercises.map((e) => e.id).toSet();
    for (final id in ids) {
      expect(repo.getAllExercises().any((e) => e.id == id), isTrue);
    }
  });
}
