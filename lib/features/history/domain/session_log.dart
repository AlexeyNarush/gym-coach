class PerformedSetLog {
  const PerformedSetLog({
    this.reps,
    this.weightKg,
    this.durationSeconds,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weightKg': weightKg,
      'durationSeconds': durationSeconds,
    };
  }

  factory PerformedSetLog.fromJson(Map<String, dynamic> json) {
    return PerformedSetLog(
      reps: SessionExerciseLog._asInt(json['reps']),
      weightKg: SessionExerciseLog._asDouble(json['weightKg']),
      durationSeconds: SessionExerciseLog._asInt(json['durationSeconds']),
    );
  }
}

class SessionExerciseLog {
  const SessionExerciseLog({
    required this.exerciseId,
    required this.completed,
    required this.swappedToExerciseId,
    required this.skipped,
    this.completedSets = 0,
    this.plannedSets,
    this.plannedReps,
    this.plannedDurationSeconds,
    this.performedSets = const [],
  });

  final String exerciseId;
  final bool completed;
  final String? swappedToExerciseId;
  final bool skipped;
  final int completedSets;
  final int? plannedSets;
  final int? plannedReps;
  final int? plannedDurationSeconds;
  final List<PerformedSetLog> performedSets;

  SessionExerciseLog copyWith({
    bool? completed,
    String? swappedToExerciseId,
    bool? skipped,
    int? completedSets,
    int? plannedSets,
    int? plannedReps,
    int? plannedDurationSeconds,
    List<PerformedSetLog>? performedSets,
  }) {
    return SessionExerciseLog(
      exerciseId: exerciseId,
      completed: completed ?? this.completed,
      swappedToExerciseId: swappedToExerciseId ?? this.swappedToExerciseId,
      skipped: skipped ?? this.skipped,
      completedSets: completedSets ?? this.completedSets,
      plannedSets: plannedSets ?? this.plannedSets,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedDurationSeconds:
          plannedDurationSeconds ?? this.plannedDurationSeconds,
      performedSets: performedSets ?? this.performedSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'completed': completed,
      'swappedToExerciseId': swappedToExerciseId,
      'skipped': skipped,
      'completedSets': completedSets,
      'plannedSets': plannedSets,
      'plannedReps': plannedReps,
      'plannedDurationSeconds': plannedDurationSeconds,
      'performedSets': performedSets.map((set) => set.toJson()).toList(),
    };
  }

  factory SessionExerciseLog.fromJson(Map<String, dynamic> json) {
    return SessionExerciseLog(
      exerciseId: json['exerciseId'] as String,
      completed: json['completed'] as bool? ?? false,
      swappedToExerciseId: json['swappedToExerciseId'] as String?,
      skipped: json['skipped'] as bool? ?? false,
      completedSets: _asInt(json['completedSets']) ?? 0,
      plannedSets: _asInt(json['plannedSets']),
      plannedReps: _asInt(json['plannedReps']),
      plannedDurationSeconds: _asInt(json['plannedDurationSeconds']),
      performedSets: (json['performedSets'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .map(PerformedSetLog.fromJson)
          .toList(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}

class SessionLog {
  const SessionLog({
    required this.date,
    required this.exercises,
    required this.userDifficulty,
    required this.notes,
  });

  final DateTime date;
  final List<SessionExerciseLog> exercises;
  final int userDifficulty;
  final String? notes;

  int get completedCount => exercises.where((e) => e.completed).length;
  int get skippedCount => exercises.where((e) => e.skipped).length;
  int get swapCount => exercises.where((e) => e.swappedToExerciseId != null).length;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'userDifficulty': userDifficulty,
      'notes': notes,
    };
  }

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      date: DateTime.parse(json['date'] as String),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => SessionExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      userDifficulty: json['userDifficulty'] as int? ?? 3,
      notes: json['notes'] as String?,
    );
  }
}
