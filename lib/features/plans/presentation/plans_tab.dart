import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/plans/data/workout_template_repository.dart';
import 'package:gym_coach/features/plans/domain/split_mapper.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';
import 'package:gym_coach/features/settings/data/schedule_repository.dart';

class PlansTab extends ConsumerWidget {
  const PlansTab({super.key, this.onStartTemplate});

  final ValueChanged<WorkoutDayType>? onStartTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates =
        ref.watch(workoutTemplateRepositoryProvider).getTemplates();
    final exerciseRepo = ref.watch(exerciseRepositoryProvider);

    final scheduleAsync = ref.watch(userScheduleProvider);
    return scheduleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Could not load schedule: $error')),
      data: (schedule) {
        final days = schedule.gymWeekdays;
        if (days.isEmpty) {
          return const Center(
            child: Text(
                'No training days configured. Re-open onboarding to add days.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your 3-day split',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: days
                  .map((weekday) => Chip(
                        label: Text(_weekdayLabel(weekday)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ...days.map((weekday) {
              final dayType = workoutDayTypeForWeekday(weekday);
              final template =
                  templates.firstWhere((item) => item.dayType == dayType);
              final exercises =
                  template.orderedExerciseIds.map(exerciseRepo.byId).toList();

              return Card(
                child: ListTile(
                  title: Text(template.title),
                  subtitle: Text(
                    '${exercises.length} exercises • Tap for details',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              template.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onStartTemplate?.call(template.dayType);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start this in Today'),
                            ),
                            const SizedBox(height: 12),
                            ...exercises.map((exercise) => ListTile(
                                  title: Text(exercise.name),
                                  subtitle: Text(exercise.instructionsShort),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _weekdayLabel(int day) {
    const labels = <int, String>{
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return labels[day] ?? 'Day';
  }
}
