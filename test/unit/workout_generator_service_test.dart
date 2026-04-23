import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';
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

  test('generateFromTemplate provides prescription for each selected exercise', () {
    final repo = ExerciseRepository();
    final service = WorkoutGeneratorService(
      exerciseRepository: repo,
      adaptationRules: const AdaptationRules(),
    );
    const templateIds = ['db_bench_press', 'plank', 'lat_pulldown'];
    final workout = service.generateFromTemplate(
      templateExerciseIds: templateIds,
      history: const [],
    );

    expect(workout.source, SessionSource.manualTemplate);
    expect(workout.exercises.map((e) => e.id), templateIds);
    expect(
      workout.prescriptionsByExerciseId.keys.toSet(),
      templateIds.toSet(),
    );

    for (final exercise in workout.exercises) {
      final prescription = workout.prescriptionsByExerciseId[exercise.id];
      expect(prescription, isNotNull);
      expect(prescription!.plannedSets, greaterThanOrEqualTo(2));
      final hasRepTarget = prescription.plannedReps != null;
      final hasTimeTarget = prescription.plannedDurationSeconds != null;
      expect(hasRepTarget || hasTimeTarget, isTrue);
    }
  });

  test('generateFromTemplate progresses rep-based targets after successful session', () {
    final repo = ExerciseRepository();
    final service = WorkoutGeneratorService(
      exerciseRepository: repo,
      adaptationRules: const AdaptationRules(),
    );
    final history = [
      _sessionWithExercise(
        exerciseId: 'db_bench_press',
        completed: true,
        completedSets: 4,
        performedSets: const [
          PerformedSetLog(reps: 10, weightKg: 20),
          PerformedSetLog(reps: 10, weightKg: 20),
          PerformedSetLog(reps: 10, weightKg: 20),
          PerformedSetLog(reps: 10, weightKg: 20),
        ],
      ),
    ];

    final workout = service.generateFromTemplate(
      templateExerciseIds: const ['db_bench_press'],
      history: history,
    );
    final prescription = workout.prescriptionsByExerciseId['db_bench_press']!;

    expect(prescription.plannedSets, 5);
    expect(prescription.plannedReps, 11);
    expect(prescription.plannedDurationSeconds, isNull);
  });

  test('generateFromTemplate regresses timed targets after skipped session', () {
    final repo = ExerciseRepository();
    final service = WorkoutGeneratorService(
      exerciseRepository: repo,
      adaptationRules: const AdaptationRules(),
    );
    final history = [
      _sessionWithExercise(
        exerciseId: 'plank',
        completed: false,
        skipped: true,
        completedSets: 0,
      ),
    ];

    final workout = service.generateFromTemplate(
      templateExerciseIds: const ['plank'],
      history: history,
    );
    final prescription = workout.prescriptionsByExerciseId['plank']!;

    expect(prescription.plannedSets, 3);
    expect(prescription.plannedDurationSeconds, 20);
    expect(prescription.plannedReps, isNull);
  });
}

SessionLog _sessionWithExercise({
  required String exerciseId,
  required bool completed,
  bool skipped = false,
  int completedSets = 0,
  List<PerformedSetLog> performedSets = const [],
}) {
  return SessionLog(
    date: DateTime(2026, 1, 1),
    exercises: [
      SessionExerciseLog(
        exerciseId: exerciseId,
        completed: completed,
        swappedToExerciseId: null,
        skipped: skipped,
        completedSets: completedSets,
        performedSets: performedSets,
      ),
    ],
    userDifficulty: 3,
    notes: null,
  );
}
