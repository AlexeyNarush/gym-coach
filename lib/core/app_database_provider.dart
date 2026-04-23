import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/core/storage/app_database.dart';

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.create();
});
