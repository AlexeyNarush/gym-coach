import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/exercises/data/local/seed_exercise_source.dart';

void main() {
  test('every seeded exercise image path exists on disk', () {
    for (final exercise in SeedExerciseSource.exercises) {
      final file = File(exercise.imageAssetPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Missing image for ${exercise.id}: ${exercise.imageAssetPath}',
      );
    }
  });

  test('every movement pattern used in seed has a pattern SVG', () {
    final patterns = SeedExerciseSource.exercises
        .map((e) => e.movementPattern)
        .toSet();
    for (final pattern in patterns) {
      final file = File('assets/exercises/patterns/$pattern.svg');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Missing pattern SVG for $pattern',
      );
    }
  });

  test('exercise index metadata file exists', () {
    final indexFile = File('assets/exercises/index.json');
    expect(indexFile.existsSync(), isTrue);
  });
}
