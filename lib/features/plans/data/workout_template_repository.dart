import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';

final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((ref) {
  return WorkoutTemplateRepository();
});

class WorkoutTemplateRepository {
  final List<WorkoutTemplate> _templates = const [
    WorkoutTemplate(
      dayType: WorkoutDayType.dayA,
      title: 'Monday: Push + Core',
      warmupExerciseIds: ['bw_squat', 'plank'],
      mainExerciseIds: [
        'db_bench_press',
        'machine_chest_press',
        'db_shoulder_press',
        'triceps_pushdown',
      ],
      finisherExerciseIds: ['dead_bug'],
    ),
    WorkoutTemplate(
      dayType: WorkoutDayType.dayB,
      title: 'Wednesday: Pull + Legs',
      warmupExerciseIds: ['glute_bridge', 'dead_bug'],
      mainExerciseIds: [
        'lat_pulldown',
        'seated_cable_row',
        'goblet_squat',
        'db_rdl',
      ],
      finisherExerciseIds: ['walking_lunge'],
    ),
    WorkoutTemplate(
      dayType: WorkoutDayType.dayC,
      title: 'Friday: Full Body Basics',
      warmupExerciseIds: ['bw_squat', 'plank'],
      mainExerciseIds: [
        'bw_push_up',
        'db_row',
        'leg_press',
        'db_curl',
      ],
      finisherExerciseIds: ['bike_crunch'],
    ),
  ];

  List<WorkoutTemplate> getTemplates() => _templates;
}
