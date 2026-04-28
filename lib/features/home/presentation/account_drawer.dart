import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/history/data/history_repository.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';
import 'package:gym_coach/features/settings/data/schedule_repository.dart';
import 'package:intl/intl.dart';

class AccountDrawer extends ConsumerWidget {
  const AccountDrawer({super.key});

  static String _exerciseTitle(ExerciseRepository repo, SessionExerciseLog entry) {
    final id = entry.swappedToExerciseId ?? entry.exerciseId;
    try {
      return repo.byId(id).name;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sessionLogsProvider);
    final scheduleAsync = ref.watch(userScheduleProvider);
    final exerciseRepo = ref.watch(exerciseRepositoryProvider);
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your account',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Workouts and preferences stay on this device.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        scheduleAsync.when(
                          data: (schedule) {
                            if (schedule.gymWeekdays.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            const labels = {
                              1: 'Mon',
                              2: 'Tue',
                              3: 'Wed',
                              4: 'Thu',
                              5: 'Fri',
                              6: 'Sat',
                              7: 'Sun',
                            };
                            final sortedDays = [...schedule.gymWeekdays]..sort();
                            final dayStr = sortedDays
                                .map((d) => labels[d] ?? '$d')
                                .join(', ');
                            final t = TimeOfDay(
                              hour: schedule.preferredHour,
                              minute: schedule.preferredMinute,
                            ).format(context);
                            return Text(
                              'Plan: $dayStr · $t',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Workout history',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Could not load history.\n$e'),
                  ),
                ),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No completed sessions yet. Finish a workout on Today and save it to build history.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final subtitle = [
                        '${log.completedCount} done',
                        if (log.skippedCount > 0) '${log.skippedCount} skipped',
                        if (log.swapCount > 0) '${log.swapCount} swaps',
                      ].join(' · ');
                      return ExpansionTile(
                        title: Text(dateFmt.format(log.date)),
                        subtitle: Text(subtitle),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Difficulty: ${log.userDifficulty}/5',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      log.notes!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  ...log.exercises.map((e) {
                                    final name = _exerciseTitle(exerciseRepo, e);
                                    final status = e.skipped
                                        ? 'Skipped'
                                        : e.completed
                                            ? 'Done'
                                            : 'Incomplete';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '· $name — $status',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.tonal(
                onPressed: logsAsync.maybeWhen(
                  data: (logs) => logs.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear workout history?'),
                              content: const Text(
                                'This removes all saved sessions from this device. '
                                'Workout suggestions that use past sessions will reset.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) {
                            return;
                          }
                          await ref.read(historyRepositoryProvider).clearAll();
                          ref.invalidate(sessionLogsProvider);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('History cleared')),
                          );
                        },
                  orElse: () => null,
                ),
                child: const Text('Clear history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
