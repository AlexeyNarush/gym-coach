import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/core/app_database_provider.dart';
import 'package:gym_coach/core/storage/app_database.dart';
import 'package:gym_coach/features/settings/domain/user_schedule.dart';

const _scheduleStorageKey = 'user_schedule';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(appDatabaseProvider.future));
});

/// Cached user schedule for routing and tabs.
final userScheduleProvider = FutureProvider<UserSchedule>((ref) async {
  return ref.watch(scheduleRepositoryProvider).loadSchedule();
});

class ScheduleRepository {
  ScheduleRepository(this._databaseFuture);

  final Future<AppDatabase> _databaseFuture;

  Future<UserSchedule> loadSchedule() async {
    final database = await _databaseFuture;
    final json = database.readJsonObject(_scheduleStorageKey);
    if (json == null) {
      return UserSchedule.empty;
    }
    return UserSchedule.fromJson(json);
  }

  Future<void> saveSchedule(UserSchedule schedule) async {
    final database = await _databaseFuture;
    await database.writeJsonObject(_scheduleStorageKey, schedule.toJson());
  }
}
