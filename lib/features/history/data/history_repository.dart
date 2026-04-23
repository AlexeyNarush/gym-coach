import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/core/app_database_provider.dart';
import 'package:gym_coach/core/storage/app_database.dart';
import 'package:gym_coach/features/history/domain/session_log.dart';

const _historyStorageKey = 'session_logs';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(appDatabaseProvider.future));
});

class HistoryRepository {
  HistoryRepository(this._databaseFuture);

  final Future<AppDatabase> _databaseFuture;

  Future<List<SessionLog>> loadLogs() async {
    final database = await _databaseFuture;
    final logs = database.readJsonList(_historyStorageKey);
    return logs.map(SessionLog.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> appendLog(SessionLog log) async {
    final existing = await loadLogs();
    final updated = [log, ...existing];
    final database = await _databaseFuture;
    await database.writeJsonList(
      _historyStorageKey,
      updated.map((entry) => entry.toJson()).toList(),
    );
  }
}
