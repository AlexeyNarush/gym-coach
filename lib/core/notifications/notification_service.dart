import 'package:gym_coach/features/settings/domain/user_schedule.dart';

abstract class NotificationService {
  Future<void> syncSchedule(UserSchedule schedule);
}

class DisabledNotificationService implements NotificationService {
  @override
  Future<void> syncSchedule(UserSchedule schedule) async {
    // Reminder delivery is intentionally out of MVP scope.
  }
}
