import 'package:gym_coach/features/history/domain/session_log.dart';
import 'package:gym_coach/features/settings/domain/user_schedule.dart';

/// Future cloud sync boundary. MVP uses [NoOpSyncRepository].
abstract class SyncRepository {
  Future<void> pushLocalChanges({
    required UserSchedule schedule,
    required List<SessionLog> logs,
  });

  Future<void> pullRemoteChanges();
}

/// Guest-mode default: no network, no accounts.
class NoOpSyncRepository implements SyncRepository {
  @override
  Future<void> pullRemoteChanges() async {}

  @override
  Future<void> pushLocalChanges({
    required UserSchedule schedule,
    required List<SessionLog> logs,
  }) async {}
}
