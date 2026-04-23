import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/exercises/data/local/seed_exercise_source.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';
import 'package:gym_coach/features/today/domain/adaptation_rules.dart';

void main() {
  test('scores exercised lower when repeatedly skipped', () {
    const rules = AdaptationRules();
    final exercise =
        SeedExerciseSource.exercises.firstWhere((item) => item.id == 'db_bench_press');
    final heavySkipHistory = List.generate(
      4,
      (index) => SessionLog(
        date: DateTime.now().subtract(Duration(days: index)),
        exercises: const [
          SessionExerciseLog(
            exerciseId: 'db_bench_press',
            completed: false,
            swappedToExerciseId: null,
            skipped: true,
          ),
        ],
        userDifficulty: 4,
        notes: null,
      ),
    );
    final positiveHistory = List.generate(
      4,
      (index) => SessionLog(
        date: DateTime.now().subtract(Duration(days: index)),
        exercises: const [
          SessionExerciseLog(
            exerciseId: 'db_bench_press',
            completed: true,
            swappedToExerciseId: null,
            skipped: false,
          ),
        ],
        userDifficulty: 2,
        notes: null,
      ),
    );

    final skippedScore = rules.scoreExercise(
      exercise: exercise,
      history: heavySkipHistory,
    );
    final completedScore = rules.scoreExercise(
      exercise: exercise,
      history: positiveHistory,
    );
    expect(completedScore, greaterThan(skippedScore));
  });
}
