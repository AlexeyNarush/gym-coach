import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/core/notifications/notification_service.dart';
import 'package:gym_coach/core/sync/sync_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return DisabledNotificationService();
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return NoOpSyncRepository();
});
