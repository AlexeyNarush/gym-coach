import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_coach/core/providers.dart';
import 'package:gym_coach/features/settings/data/schedule_repository.dart';
import 'package:gym_coach/features/settings/domain/user_schedule.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _selectedWeekdays = <int>{1, 3, 5};
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });
    final schedule = UserSchedule(
      gymWeekdays: _selectedWeekdays.toList()..sort(),
      preferredHour: _time.hour,
      preferredMinute: _time.minute,
      reminderPrefs: const ReminderPreferences(
        mode: ReminderMode.off,
        minutesBefore: 60,
        enabled: false,
      ),
    );
    await ref.read(scheduleRepositoryProvider).saveSchedule(schedule);
    ref.invalidate(userScheduleProvider);
    await ref.read(notificationServiceProvider).syncSchedule(schedule);
    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabels = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Gym Coach')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set your gym days and preferred time.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: weekdayLabels.entries.map((entry) {
              final selected = _selectedWeekdays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedWeekdays.add(entry.key);
                    } else {
                      _selectedWeekdays.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Preferred training time'),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final selected = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (selected == null) {
                return;
              }
              setState(() {
                _time = selected;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                _selectedWeekdays.isEmpty || _isSaving ? null : () => _save(),
            child: Text(_isSaving ? 'Saving...' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
