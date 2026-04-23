import 'package:gym_coach/features/exercises/domain/exercise.dart';

enum WorkoutDayType { dayA, dayB, dayC }

enum SessionSource { history, muscleGroup, manualTemplate }

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.dayType,
    required this.title,
    required this.warmupExerciseIds,
    required this.mainExerciseIds,
    required this.finisherExerciseIds,
  });

  final WorkoutDayType dayType;
  final String title;
  final List<String> warmupExerciseIds;
  final List<String> mainExerciseIds;
  final List<String> finisherExerciseIds;

  List<String> get orderedExerciseIds => [
        ...warmupExerciseIds,
        ...mainExerciseIds,
        ...finisherExerciseIds,
      ];
}

class PlannedSession {
  const PlannedSession({
    required this.date,
    required this.templateDayType,
    required this.generatedFrom,
    required this.exercises,
  });

  final DateTime date;
  final WorkoutDayType templateDayType;
  final SessionSource generatedFrom;
  final List<Exercise> exercises;
}
