import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_coach/features/settings/data/schedule_repository.dart';

/// Chooses onboarding vs home based on persisted [UserSchedule].
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final schedule = await ref.read(userScheduleProvider.future);
      if (!mounted) {
        return;
      }
      final target =
          schedule.gymWeekdays.isEmpty ? '/onboarding' : '/home';
      context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
