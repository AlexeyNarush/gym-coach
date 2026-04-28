import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/core/providers.dart';
import 'package:gym_coach/features/exercises/data/exercise_repository.dart';
import 'package:gym_coach/features/exercises/domain/exercise.dart';
import 'package:gym_coach/features/exercises/presentation/exercise_illustration.dart';
import 'package:gym_coach/features/history/data/history_repository.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';
import 'package:gym_coach/features/plans/data/workout_template_repository.dart';
import 'package:gym_coach/features/plans/domain/split_mapper.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';
import 'package:gym_coach/features/settings/data/schedule_repository.dart';
import 'package:gym_coach/features/today/domain/adaptation_rules.dart';
import 'package:gym_coach/features/today/domain/workout_generator_service.dart';

enum GenerationMode { history, muscleGroup, plannedTemplate }

class ExercisePlanTarget {
  const ExercisePlanTarget({
    required this.plannedSets,
    this.plannedReps,
    this.plannedDurationSeconds,
  });

  final int plannedSets;
  final int? plannedReps;
  final int? plannedDurationSeconds;
}

class TodayGeneratorTab extends ConsumerStatefulWidget {
  const TodayGeneratorTab({
    super.key,
    this.prefillTemplateDayType,
    this.prefillToken = 0,
  });

  final WorkoutDayType? prefillTemplateDayType;
  final int prefillToken;

  @override
  ConsumerState<TodayGeneratorTab> createState() => _TodayGeneratorTabState();
}

class _TodayGeneratorTabState extends ConsumerState<TodayGeneratorTab> {
  GenerationMode _mode = GenerationMode.history;
  MuscleGroup _selectedGroup = MuscleGroup.core;
  WorkoutDayType _selectedTemplateDayType = WorkoutDayType.dayA;
  int _lastHandledPrefillToken = 0;
  GeneratedWorkout? _generatedWorkout;
  final Map<String, SessionExerciseLog> _draftLog = {};
  int _difficulty = 3;
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lastHandledPrefillToken = widget.prefillToken;
    final dayType = widget.prefillTemplateDayType;
    if (dayType != null) {
      _selectedTemplateDayType = dayType;
      _mode = GenerationMode.plannedTemplate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _generate();
      });
    }
  }

  @override
  void didUpdateWidget(covariant TodayGeneratorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasNewPrefill = widget.prefillToken != _lastHandledPrefillToken;
    final dayType = widget.prefillTemplateDayType;
    if (hasNewPrefill && dayType != null) {
      _lastHandledPrefillToken = widget.prefillToken;
      setState(() {
        _selectedTemplateDayType = dayType;
        _mode = GenerationMode.plannedTemplate;
      });
      _generate();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final templateRepo = ref.read(workoutTemplateRepositoryProvider);
    final historyRepo = ref.read(historyRepositoryProvider);
    final history = await historyRepo.loadLogs();
    final service = WorkoutGeneratorService(
      exerciseRepository: exerciseRepo,
      adaptationRules: const AdaptationRules(),
    );

    GeneratedWorkout generated;
    if (_mode == GenerationMode.history) {
      final todayTemplate = _templateForToday(templateRepo.getTemplates());
      generated = service.generateFromHistory(
        templateExerciseIds: todayTemplate.orderedExerciseIds,
        history: history,
      );
    } else if (_mode == GenerationMode.muscleGroup) {
      generated = service.generateFromMuscleGroup(
        muscleGroup: _selectedGroup,
        history: history,
      );
    } else {
      final selectedTemplate = _templateForDayType(
          templateRepo.getTemplates(), _selectedTemplateDayType);
      generated = service.generateFromTemplate(
        templateExerciseIds: selectedTemplate.orderedExerciseIds,
        history: history,
      );
    }

    setState(() {
      _generatedWorkout = generated;
      _draftLog
        ..clear()
        ..addEntries(
          generated.exercises.map(
            (exercise) {
              final target = _targetForGeneratedExercise(
                generatedWorkout: generated,
                exercise: exercise,
              );
              return MapEntry(
                exercise.id,
                SessionExerciseLog(
                  exerciseId: exercise.id,
                  completed: false,
                  swappedToExerciseId: null,
                  skipped: false,
                  completedSets: 0,
                  plannedSets: target.plannedSets,
                  plannedReps: target.plannedReps,
                  plannedDurationSeconds: target.plannedDurationSeconds,
                  performedSets: const [],
                ),
              );
            },
          ),
        );
    });
  }

  WorkoutTemplate _templateForToday(List<WorkoutTemplate> templates) {
    final weekday = DateTime.now().weekday;
    final dayType = workoutDayTypeForWeekday(weekday);
    return templates.firstWhere((t) => t.dayType == dayType);
  }

  WorkoutTemplate _templateForDayType(
    List<WorkoutTemplate> templates,
    WorkoutDayType dayType,
  ) {
    return templates.firstWhere((template) => template.dayType == dayType);
  }

  ExercisePlanTarget _targetForGeneratedExercise({
    required GeneratedWorkout generatedWorkout,
    required Exercise exercise,
  }) {
    final generatedTarget =
        generatedWorkout.prescriptionsByExerciseId[exercise.id];
    if (generatedTarget != null) {
      return ExercisePlanTarget(
        plannedSets: generatedTarget.plannedSets,
        plannedReps: generatedTarget.plannedReps,
        plannedDurationSeconds: generatedTarget.plannedDurationSeconds,
      );
    }
    return _defaultTargetFor(exercise);
  }

  Future<void> _saveSession() async {
    if (_generatedWorkout == null || _draftLog.isEmpty) {
      return;
    }
    setState(() {
      _saving = true;
    });
    final log = SessionLog(
      date: DateTime.now(),
      exercises: _draftLog.values.toList(),
      userDifficulty: _difficulty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await ref.read(historyRepositoryProvider).appendLog(log);
    ref.invalidate(sessionLogsProvider);
    final schedule = await ref.read(scheduleRepositoryProvider).loadSchedule();
    final logs = await ref.read(historyRepositoryProvider).loadLogs();
    await ref.read(syncRepositoryProvider).pushLocalChanges(
          schedule: schedule,
          logs: logs,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session saved to history')),
    );
    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesRepo = ref.watch(exerciseRepositoryProvider);
    final templates =
        ref.watch(workoutTemplateRepositoryProvider).getTemplates();
    final generatedExercises =
        _generatedWorkout?.exercises ?? const <Exercise>[];
    final completedCount =
        _draftLog.values.where((exercise) => exercise.completed).length;
    final totalCount = generatedExercises.length;
    final completionProgress =
        totalCount == 0 ? 0.0 : completedCount / totalCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Generate workout for today',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SegmentedButton<GenerationMode>(
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (value) {
            if (value.isEmpty) {
              return;
            }
            setState(() {
              _mode = value.first;
            });
          },
          segments: const [
            ButtonSegment(
              value: GenerationMode.history,
              label: Text('Use my history', textAlign: TextAlign.center),
            ),
            ButtonSegment(
              value: GenerationMode.muscleGroup,
              label: Text('Select muscle group', textAlign: TextAlign.center),
            ),
            ButtonSegment(
              value: GenerationMode.plannedTemplate,
              label: Text('Use planned template', textAlign: TextAlign.center),
            ),
          ],
        ),
        if (_mode == GenerationMode.muscleGroup) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<MuscleGroup>(
            key: ValueKey(_selectedGroup),
            initialValue: _selectedGroup,
            items: MuscleGroup.values
                .map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(_muscleGroupLabel(group)),
                    ))
                .toList(),
            onChanged: (group) {
              if (group == null) return;
              setState(() {
                _selectedGroup = group;
              });
            },
          ),
        ],
        if (_mode == GenerationMode.plannedTemplate) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<WorkoutDayType>(
            key: ValueKey(_selectedTemplateDayType),
            initialValue: _selectedTemplateDayType,
            items: templates
                .map(
                  (template) => DropdownMenuItem(
                    value: template.dayType,
                    child: Text(template.title),
                  ),
                )
                .toList(),
            onChanged: (dayType) {
              if (dayType == null) {
                return;
              }
              setState(() {
                _selectedTemplateDayType = dayType;
              });
            },
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _generate,
          child: const Text('Generate now'),
        ),
        if (_generatedWorkout != null) ...[
          const SizedBox(height: 12),
          Text(
            'Completion: $completedCount / $totalCount exercises',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: completionProgress),
        ],
        const SizedBox(height: 16),
        ...generatedExercises.map((exercise) {
          final alternatives = exercisesRepo.alternativesFor(exercise.id);
          final currentState = _draftLog[exercise.id];
          final completed = currentState?.completed ?? false;
          final skipped = currentState?.skipped ?? false;
          final swappedTo = currentState?.swappedToExerciseId;
          final plannedSets = currentState?.plannedSets;
          final completedSets = currentState?.completedSets ?? 0;
          final planLabel =
              currentState == null ? null : _planLabel(currentState);
          final performedSets =
              currentState?.performedSets ?? const <PerformedSetLog>[];
          final isTimedExercise =
              (currentState?.plannedDurationSeconds ?? 0) > 0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showExerciseDetails(
                            context, exercise, alternatives),
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  Text(exercise.instructionsShort),
                  if (planLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Plan: $planLabel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (plannedSets != null && plannedSets > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Sets: $completedSets / $plannedSets',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        if (performedSets.isNotEmpty)
                          Text(
                            '(logged: ${performedSets.length})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Decrease completed sets',
                          onPressed: completedSets <= 0
                              ? null
                              : () {
                                  _updateExerciseProgress(
                                    exerciseId: exercise.id,
                                    completedSets: completedSets - 1,
                                  );
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'Increase completed sets',
                          onPressed: completedSets >= plannedSets
                              ? null
                              : () {
                                  _updateExerciseProgress(
                                    exerciseId: exercise.id,
                                    completedSets: completedSets + 1,
                                  );
                                },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(plannedSets, (setIndex) {
                        final setLog = setIndex < performedSets.length
                            ? performedSets[setIndex]
                            : null;
                        final hasLog = setLog != null;
                        return ActionChip(
                          avatar: Icon(
                            hasLog ? Icons.check_circle : Icons.edit_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _setChipLabel(
                              setNumber: setIndex + 1,
                              setLog: setLog,
                              isTimed: isTimedExercise,
                            ),
                          ),
                          onPressed: () => _editSetForExercise(
                            context,
                            exerciseId: exercise.id,
                            setIndex: setIndex,
                          ),
                        );
                      }),
                    ),
                  ],
                  if (swappedTo != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Swapped to: ${exercisesRepo.byId(swappedTo).name}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: completed,
                        label: const Text('Completed'),
                        onSelected: (value) {
                          _setCompletion(
                            exerciseId: exercise.id,
                            completed: value,
                          );
                        },
                      ),
                      FilterChip(
                        selected: skipped,
                        label: const Text('Skipped'),
                        onSelected: (value) {
                          _setSkipped(
                            exerciseId: exercise.id,
                            skipped: value,
                          );
                        },
                      ),
                      if (alternatives.isNotEmpty)
                        ActionChip(
                          label: const Text('Swap exercise'),
                          onPressed: () => _pickAlternative(
                            context,
                            exercise: exercise,
                            alternatives: alternatives,
                            completed: completed,
                            skipped: skipped,
                          ),
                        ),
                      if (plannedSets != null && plannedSets > 0)
                        ActionChip(
                          label: const Text('Log sets'),
                          onPressed: () => _showSetLogger(
                            context,
                            exerciseId: exercise.id,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (_generatedWorkout != null) ...[
          const SizedBox(height: 8),
          Text(
            'How difficult was this session?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: _difficulty.toDouble(),
            label: _difficulty.toString(),
            onChanged: (value) {
              setState(() {
                _difficulty = value.toInt();
              });
            },
          ),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Session notes (optional)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveSession,
            child: Text(_saving ? 'Saving...' : 'Save session'),
          ),
        ],
      ],
    );
  }

  String _muscleGroupLabel(MuscleGroup group) {
    return switch (group) {
      MuscleGroup.chest => 'Chest',
      MuscleGroup.back => 'Back',
      MuscleGroup.legs => 'Legs',
      MuscleGroup.shoulders => 'Shoulders',
      MuscleGroup.arms => 'Arms',
      MuscleGroup.core => 'Core',
      MuscleGroup.fullBody => 'Full body',
    };
  }

  Future<void> _pickAlternative(
    BuildContext context, {
    required Exercise exercise,
    required List<Exercise> alternatives,
    required bool completed,
    required bool skipped,
  }) async {
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: const Text('Keep original'),
                subtitle: Text(exercise.name),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(),
              ...alternatives.map(
                (alt) => ListTile(
                  title: Text(alt.name),
                  subtitle: Text(alt.instructionsShort),
                  onTap: () => Navigator.of(context).pop(alt),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      final existing = _draftLog[exercise.id];
      if (existing == null) {
        return;
      }
      _draftLog[exercise.id] = existing.copyWith(
        completed: completed,
        swappedToExerciseId: selected.id,
        skipped: skipped,
      );
    });
  }

  void _setCompletion({
    required String exerciseId,
    required bool completed,
  }) {
    setState(() {
      final existing = _draftLog[exerciseId];
      if (existing == null) {
        return;
      }
      final plannedSets = existing.plannedSets ?? 0;
      final performedSets = completed
          ? _fillPerformedSetsToTarget(existing)
          : existing.performedSets;
      _draftLog[exerciseId] = existing.copyWith(
        completed: completed,
        skipped: false,
        completedSets: completed
            ? (plannedSets > 0 ? plannedSets : existing.completedSets)
            : existing.completedSets,
        performedSets: performedSets,
      );
    });
  }

  void _setSkipped({
    required String exerciseId,
    required bool skipped,
  }) {
    setState(() {
      final existing = _draftLog[exerciseId];
      if (existing == null) {
        return;
      }
      _draftLog[exerciseId] = existing.copyWith(
        completed: false,
        skipped: skipped,
        // Preserve progress/logs to prevent accidental data loss on mis-taps.
        completedSets: existing.completedSets,
        performedSets: existing.performedSets,
      );
    });
  }

  void _updateExerciseProgress({
    required String exerciseId,
    required int completedSets,
  }) {
    setState(() {
      final existing = _draftLog[exerciseId];
      if (existing == null) {
        return;
      }
      final plannedSets = existing.plannedSets ?? 0;
      final clampedSets = completedSets.clamp(0, plannedSets);
      final updatedPerformedSets = [...existing.performedSets];
      while (updatedPerformedSets.length < clampedSets) {
        updatedPerformedSets.add(_defaultPerformedSet(existing));
      }
      _draftLog[exerciseId] = existing.copyWith(
        completedSets: clampedSets,
        completed: plannedSets > 0 && clampedSets >= plannedSets,
        skipped: false,
        performedSets: updatedPerformedSets,
      );
    });
  }

  Future<void> _showSetLogger(
    BuildContext context, {
    required String exerciseId,
  }) async {
    final state = _draftLog[exerciseId];
    if (state == null) {
      return;
    }
    final plannedSets = state.plannedSets ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Log sets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(plannedSets, (setIndex) {
              final setLog = setIndex < state.performedSets.length
                  ? state.performedSets[setIndex]
                  : null;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${setIndex + 1}')),
                title: Text('Set ${setIndex + 1}'),
                subtitle: Text(
                  _buildSetSubtitle(
                    setLog: setLog,
                    isTimed: (state.plannedDurationSeconds ?? 0) > 0,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editSetForExercise(
                  context,
                  exerciseId: exerciseId,
                  setIndex: setIndex,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _editSetForExercise(
    BuildContext context, {
    required String exerciseId,
    required int setIndex,
  }) async {
    final state = _draftLog[exerciseId];
    if (state == null) {
      return;
    }
    final existingSet = setIndex < state.performedSets.length
        ? state.performedSets[setIndex]
        : null;
    final isTimed = (state.plannedDurationSeconds ?? 0) > 0;
    final repsController = TextEditingController(
      text:
          existingSet?.reps?.toString() ?? state.plannedReps?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: existingSet?.durationSeconds?.toString() ??
          state.plannedDurationSeconds?.toString() ??
          '',
    );
    final weightController = TextEditingController(
      text: existingSet?.weightKg?.toString() ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set ${setIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isTimed)
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
            if (isTimed)
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (seconds)'),
              ),
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Weight (kg, optional)'),
            ),
          ],
        ),
        actions: [
          if (existingSet != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('clear'),
              child: const Text('Clear set'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final parsedReps = int.tryParse(repsController.text.trim());
    final parsedDurationSeconds = int.tryParse(durationController.text.trim());
    final parsedWeightKg = double.tryParse(weightController.text.trim());
    repsController.dispose();
    durationController.dispose();
    weightController.dispose();

    if (!mounted || result == null || result == 'cancel') {
      return;
    }

    setState(() {
      final current = _draftLog[exerciseId];
      if (current == null) {
        return;
      }
      final updated = [...current.performedSets];
      if (result == 'clear') {
        if (setIndex < updated.length) {
          updated.removeAt(setIndex);
        }
      } else {
        while (updated.length <= setIndex) {
          updated.add(_defaultPerformedSet(current));
        }
        updated[setIndex] = PerformedSetLog(
          reps: isTimed ? null : (parsedReps ?? current.plannedReps),
          durationSeconds: isTimed
              ? (parsedDurationSeconds ?? current.plannedDurationSeconds)
              : null,
          weightKg: parsedWeightKg,
        );
      }

      final plannedSets = current.plannedSets ?? 0;
      final completedSets = updated.length.clamp(0, plannedSets);
      _draftLog[exerciseId] = current.copyWith(
        performedSets: updated,
        completedSets: completedSets,
        completed: plannedSets > 0 && completedSets >= plannedSets,
        skipped: false,
      );
    });
  }

  ExercisePlanTarget _defaultTargetFor(Exercise exercise) {
    final timedPatterns = {
      'core_stability',
      'core_dynamic',
      'carry',
      'back_extension'
    };
    if (timedPatterns.contains(exercise.movementPattern)) {
      return switch (exercise.difficulty) {
        ExerciseDifficulty.beginner => const ExercisePlanTarget(
            plannedSets: 3,
            plannedDurationSeconds: 30,
          ),
        ExerciseDifficulty.easyModerate => const ExercisePlanTarget(
            plannedSets: 3,
            plannedDurationSeconds: 40,
          ),
        ExerciseDifficulty.moderate => const ExercisePlanTarget(
            plannedSets: 4,
            plannedDurationSeconds: 45,
          ),
      };
    }
    return switch (exercise.difficulty) {
      ExerciseDifficulty.beginner => const ExercisePlanTarget(
          plannedSets: 2,
          plannedReps: 12,
        ),
      ExerciseDifficulty.easyModerate => const ExercisePlanTarget(
          plannedSets: 3,
          plannedReps: 10,
        ),
      ExerciseDifficulty.moderate => const ExercisePlanTarget(
          plannedSets: 4,
          plannedReps: 8,
        ),
    };
  }

  String _planLabel(SessionExerciseLog state) {
    final sets = state.plannedSets ?? 0;
    if (sets <= 0) {
      return 'No target';
    }
    if (state.plannedDurationSeconds != null) {
      return '$sets x ${state.plannedDurationSeconds}s';
    }
    if (state.plannedReps != null) {
      return '$sets x ${state.plannedReps} reps';
    }
    return '$sets sets';
  }

  String _setChipLabel({
    required int setNumber,
    required PerformedSetLog? setLog,
    required bool isTimed,
  }) {
    if (setLog == null) {
      return 'Set $setNumber';
    }
    if (isTimed) {
      final seconds = setLog.durationSeconds;
      return seconds == null ? 'Set $setNumber' : 'S$setNumber ${seconds}s';
    }
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    if (reps == null && weight == null) {
      return 'Set $setNumber';
    }
    if (weight == null) {
      return 'S$setNumber ${reps ?? '-'}r';
    }
    return 'S$setNumber ${reps ?? '-'}r @ ${weight.toStringAsFixed(1)}kg';
  }

  String _buildSetSubtitle({
    required PerformedSetLog? setLog,
    required bool isTimed,
  }) {
    if (setLog == null) {
      return 'Not logged yet';
    }
    if (isTimed) {
      final seconds = setLog.durationSeconds;
      final weight = setLog.weightKg;
      if (weight == null) {
        return '${seconds ?? 0}s';
      }
      return '${seconds ?? 0}s @ ${weight.toStringAsFixed(1)}kg';
    }
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    if (weight == null) {
      return '${reps ?? 0} reps';
    }
    return '${reps ?? 0} reps @ ${weight.toStringAsFixed(1)}kg';
  }

  List<PerformedSetLog> _fillPerformedSetsToTarget(SessionExerciseLog state) {
    final target = state.plannedSets ?? 0;
    if (target <= 0) {
      return const [];
    }
    final output = [...state.performedSets];
    while (output.length < target) {
      output.add(_defaultPerformedSet(state));
    }
    if (output.length > target) {
      output.removeRange(target, output.length);
    }
    return output;
  }

  PerformedSetLog _defaultPerformedSet(SessionExerciseLog state) {
    if ((state.plannedDurationSeconds ?? 0) > 0) {
      return PerformedSetLog(durationSeconds: state.plannedDurationSeconds);
    }
    return PerformedSetLog(reps: state.plannedReps);
  }

  void _showExerciseDetails(
    BuildContext context,
    Exercise exercise,
    List<Exercise> alternatives,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.grey.shade100,
                child: ExerciseIllustration(
                  exercise: exercise,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(exercise.instructionsShort),
            const SizedBox(height: 6),
            Text('Safety: ${exercise.safetyTips}'),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Alternatives',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...alternatives.map((alt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(alt.name),
                    subtitle: Text(alt.instructionsShort),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
