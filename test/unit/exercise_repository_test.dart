import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';

void main() {
  test('all exercises have at least one alternative mapping target', () {
    final repository = ExerciseRepository();
    final alternatives = repository.allAlternatives;

    final ids = repository.getAllExercises().map((e) => e.id).toSet();
    for (final mapping in alternatives) {
      expect(ids.contains(mapping.exerciseId), isTrue);
      expect(ids.contains(mapping.alternativeExerciseId), isTrue);
      expect(mapping.reasonTags, isNotEmpty);
    }
  });

  test('every exercise has at least one alternative option', () {
    final repository = ExerciseRepository();
    for (final exercise in repository.getAllExercises()) {
      expect(
        repository.alternativesFor(exercise.id),
        isNotEmpty,
        reason: 'Missing alternatives for ${exercise.id}',
      );
    }
  });
}
