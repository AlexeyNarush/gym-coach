import 'package:gym_coach/features/exercises/domain/exercise.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';

class AdaptationRules {
  const AdaptationRules();

  double scoreExercise({
    required Exercise exercise,
    required List<SessionLog> history,
  }) {
    double score = 0;
    final recentLogs = history.take(8).toList();
    var repeats = 0;
    var completes = 0;
    var skips = 0;
    var hardRatings = 0;

    for (final log in recentLogs) {
      for (final ex in log.exercises) {
        if (ex.exerciseId != exercise.id) {
          continue;
        }
        repeats++;
        if (ex.completed) {
          completes++;
        }
        if (ex.skipped) {
          skips++;
        }
        if (log.userDifficulty >= 4) {
          hardRatings++;
        }
      }
    }

    score += completes * 1.5;
    score -= skips * 1.8;
    score -= hardRatings * 1.0;
    score -= repeats * 0.4;

    if (exercise.equipmentType == EquipmentType.bodyweight ||
        exercise.equipmentType == EquipmentType.dumbbells) {
      score += 0.5;
    }
    if (exercise.difficulty == ExerciseDifficulty.beginner) {
      score += 0.6;
    }
    return score;
  }

  bool isMovementPatternOverused({
    required String movementPattern,
    required List<String> selectedPatterns,
  }) {
    return selectedPatterns.where((item) => item == movementPattern).length >= 2;
  }
}
