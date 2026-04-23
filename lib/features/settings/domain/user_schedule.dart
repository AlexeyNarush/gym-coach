enum ReminderMode { off, eveningBefore, minutesBefore }

class ReminderPreferences {
  const ReminderPreferences({
    required this.mode,
    required this.minutesBefore,
    required this.enabled,
  });

  final ReminderMode mode;
  final int minutesBefore;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'minutesBefore': minutesBefore,
      'enabled': enabled,
    };
  }

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    return ReminderPreferences(
      mode: ReminderMode.values.byName(json['mode'] as String? ?? 'off'),
      minutesBefore: json['minutesBefore'] as int? ?? 60,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}

class UserSchedule {
  const UserSchedule({
    required this.gymWeekdays,
    required this.preferredHour,
    required this.preferredMinute,
    required this.reminderPrefs,
  });

  final List<int> gymWeekdays;
  final int preferredHour;
  final int preferredMinute;
  final ReminderPreferences reminderPrefs;

  Map<String, dynamic> toJson() {
    return {
      'gymWeekdays': gymWeekdays,
      'preferredHour': preferredHour,
      'preferredMinute': preferredMinute,
      'reminderPrefs': reminderPrefs.toJson(),
    };
  }

  factory UserSchedule.fromJson(Map<String, dynamic> json) {
    return UserSchedule(
      gymWeekdays:
          (json['gymWeekdays'] as List<dynamic>).map((e) => e as int).toList(),
      preferredHour: json['preferredHour'] as int,
      preferredMinute: json['preferredMinute'] as int,
      reminderPrefs: ReminderPreferences.fromJson(
        json['reminderPrefs'] as Map<String, dynamic>,
      ),
    );
  }

  UserSchedule copyWith({
    List<int>? gymWeekdays,
    int? preferredHour,
    int? preferredMinute,
    ReminderPreferences? reminderPrefs,
  }) {
    return UserSchedule(
      gymWeekdays: gymWeekdays ?? this.gymWeekdays,
      preferredHour: preferredHour ?? this.preferredHour,
      preferredMinute: preferredMinute ?? this.preferredMinute,
      reminderPrefs: reminderPrefs ?? this.reminderPrefs,
    );
  }

  static const UserSchedule empty = UserSchedule(
    gymWeekdays: [],
    preferredHour: 18,
    preferredMinute: 0,
    reminderPrefs: ReminderPreferences(
      mode: ReminderMode.off,
      minutesBefore: 60,
      enabled: false,
    ),
  );
}
