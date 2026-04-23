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
    required this.prescriptionsByExerciseId,
  });

  final SessionSource source;
  final List<Exercise> exercises;
  final Map<String, ExercisePrescription> prescriptionsByExerciseId;
}

class ExercisePrescription {
  const ExercisePrescription({
    required this.plannedSets,
    this.plannedReps,
    this.plannedDurationSeconds,
  });

  final int plannedSets;
  final int? plannedReps;
  final int? plannedDurationSeconds;
}

class WorkoutGeneratorService {
  WorkoutGeneratorService({
    required ExerciseRepository exerciseRepository,
    required AdaptationRules adaptationRules,
  })  : _exerciseRepository = exerciseRepository,
        _adaptationRules = adaptationRules;

  final ExerciseRepository _exerciseRepository;
  final AdaptationRules _adaptationRules;
  static const Set<String> _timedPatterns = {
    'core_stability',
    'core_dynamic',
    'carry',
    'back_extension',
  };

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

    final selected = output.take(6).toList(growable: false);
    return GeneratedWorkout(
      source: SessionSource.history,
      exercises: selected,
      prescriptionsByExerciseId: _buildPrescriptions(
        exercises: selected,
        history: history,
        source: SessionSource.history,
      ),
    );
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
    final selected = output.take(6).toList(growable: false);
    return GeneratedWorkout(
      source: SessionSource.muscleGroup,
      exercises: selected,
      prescriptionsByExerciseId: _buildPrescriptions(
        exercises: selected,
        history: history,
        source: SessionSource.muscleGroup,
      ),
    );
  }

  GeneratedWorkout generateFromTemplate({
    required List<String> templateExerciseIds,
    required List<SessionLog> history,
  }) {
    final selected = templateExerciseIds
        .map(_exerciseRepository.byId)
        .toList(growable: false);
    return GeneratedWorkout(
      source: SessionSource.manualTemplate,
      exercises: selected,
      prescriptionsByExerciseId: _buildPrescriptions(
        exercises: selected,
        history: history,
        source: SessionSource.manualTemplate,
      ),
    );
  }

  Map<String, ExercisePrescription> _buildPrescriptions({
    required List<Exercise> exercises,
    required List<SessionLog> history,
    required SessionSource source,
  }) {
    return {
      for (final exercise in exercises)
        exercise.id: _prescriptionForExercise(
          exercise: exercise,
          history: history,
          source: source,
        ),
    };
  }

  ExercisePrescription _prescriptionForExercise({
    required Exercise exercise,
    required List<SessionLog> history,
    required SessionSource source,
  }) {
    final baseline = _baselinePrescription(exercise, source);
    final lastLog = _lastExerciseLog(history: history, exerciseId: exercise.id);
    if (lastLog == null) {
      return baseline;
    }

    final adjustedSets = _adjustSets(
      baselineSets: baseline.plannedSets,
      exercise: exercise,
      lastLog: lastLog,
    );

    if (_timedPatterns.contains(exercise.movementPattern)) {
      final baselineSeconds = baseline.plannedDurationSeconds ?? 30;
      final adjustedSeconds = _adjustTimedTarget(
        baselineSeconds: baselineSeconds,
        exercise: exercise,
        lastLog: lastLog,
      );
      return ExercisePrescription(
        plannedSets: adjustedSets,
        plannedDurationSeconds: adjustedSeconds,
      );
    }

    final baselineReps = baseline.plannedReps ?? 10;
    final adjustedReps = _adjustRepTarget(
      baselineReps: baselineReps,
      exercise: exercise,
      lastLog: lastLog,
    );
    return ExercisePrescription(
      plannedSets: adjustedSets,
      plannedReps: adjustedReps,
    );
  }

  ExercisePrescription _baselinePrescription(
    Exercise exercise,
    SessionSource source,
  ) {
    final setOffset = source == SessionSource.manualTemplate ? 1 : 0;
    if (_timedPatterns.contains(exercise.movementPattern)) {
      return switch (exercise.difficulty) {
        ExerciseDifficulty.beginner => ExercisePrescription(
            plannedSets: 3 + setOffset,
            plannedDurationSeconds: 30,
          ),
        ExerciseDifficulty.easyModerate => ExercisePrescription(
            plannedSets: 3 + setOffset,
            plannedDurationSeconds: 40,
          ),
        ExerciseDifficulty.moderate => ExercisePrescription(
            plannedSets: 4 + setOffset,
            plannedDurationSeconds: 45,
          ),
      };
    }
    return switch (exercise.difficulty) {
      ExerciseDifficulty.beginner => ExercisePrescription(
          plannedSets: 2 + setOffset,
          plannedReps: 12,
        ),
      ExerciseDifficulty.easyModerate => ExercisePrescription(
          plannedSets: 3 + setOffset,
          plannedReps: 10,
        ),
      ExerciseDifficulty.moderate => ExercisePrescription(
          plannedSets: 4 + setOffset,
          plannedReps: 8,
        ),
    };
  }

  SessionExerciseLog? _lastExerciseLog({
    required List<SessionLog> history,
    required String exerciseId,
  }) {
    for (final session in history) {
      final match = session.exercises.firstWhereOrNull(
        (exercise) => exercise.exerciseId == exerciseId,
      );
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  int _adjustSets({
    required int baselineSets,
    required Exercise exercise,
    required SessionExerciseLog lastLog,
  }) {
    var sets = baselineSets;
    if (lastLog.skipped) {
      sets -= 1;
    } else if (lastLog.completed) {
      final performed = lastLog.completedSets;
      if (performed >= baselineSets) {
        sets += 1;
      }
    }
    final maxSets = exercise.difficulty == ExerciseDifficulty.moderate ? 6 : 5;
    return sets.clamp(2, maxSets);
  }

  int _adjustRepTarget({
    required int baselineReps,
    required Exercise exercise,
    required SessionExerciseLog lastLog,
  }) {
    var reps = baselineReps;
    final performedReps = _lastPerformedReps(lastLog);
    if (lastLog.skipped) {
      reps -= 2;
    } else if (lastLog.completed && performedReps != null) {
      if (performedReps >= baselineReps) {
        reps += 1;
      } else if (performedReps < baselineReps - 1) {
        reps -= 1;
      }
    } else if (lastLog.completed) {
      reps += 1;
    }
    final bounds = switch (exercise.difficulty) {
      ExerciseDifficulty.beginner => (min: 8, max: 15),
      ExerciseDifficulty.easyModerate => (min: 6, max: 12),
      ExerciseDifficulty.moderate => (min: 5, max: 10),
    };
    return reps.clamp(bounds.min, bounds.max);
  }

  int _adjustTimedTarget({
    required int baselineSeconds,
    required Exercise exercise,
    required SessionExerciseLog lastLog,
  }) {
    var seconds = baselineSeconds;
    final performedSeconds = _lastPerformedSeconds(lastLog);
    if (lastLog.skipped) {
      seconds -= 10;
    } else if (lastLog.completed && performedSeconds != null) {
      if (performedSeconds >= baselineSeconds) {
        seconds += 5;
      } else if (performedSeconds < baselineSeconds - 5) {
        seconds -= 5;
      }
    } else if (lastLog.completed) {
      seconds += 5;
    }
    final bounds = switch (exercise.difficulty) {
      ExerciseDifficulty.beginner => (min: 20, max: 60),
      ExerciseDifficulty.easyModerate => (min: 25, max: 70),
      ExerciseDifficulty.moderate => (min: 30, max: 80),
    };
    return seconds.clamp(bounds.min, bounds.max);
  }

  int? _lastPerformedReps(SessionExerciseLog log) {
    if (log.performedSets.isEmpty) {
      return null;
    }
    final reps = log.performedSets
        .map((set) => set.reps)
        .whereType<int>()
        .toList(growable: false);
    if (reps.isEmpty) {
      return null;
    }
    return reps.reduce((a, b) => a + b) ~/ reps.length;
  }

  int? _lastPerformedSeconds(SessionExerciseLog log) {
    if (log.performedSets.isEmpty) {
      return null;
    }
    final seconds = log.performedSets
        .map((set) => set.durationSeconds)
        .whereType<int>()
        .toList(growable: false);
    if (seconds.isEmpty) {
      return null;
    }
    return seconds.reduce((a, b) => a + b) ~/ seconds.length;
  }
}
