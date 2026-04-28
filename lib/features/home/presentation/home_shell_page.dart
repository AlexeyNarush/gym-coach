import 'package:flutter/material.dart';
import 'package:gym_coach/features/home/presentation/account_drawer.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';
import 'package:gym_coach/features/plans/presentation/plans_tab.dart';
import 'package:gym_coach/features/today/presentation/today_generator_tab.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;
  WorkoutDayType? _prefillTemplateDayType;
  int _prefillToken = 0;

  void _openTodayWithTemplate(WorkoutDayType dayType) {
    setState(() {
      _prefillTemplateDayType = dayType;
      _prefillToken++;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PlansTab(onStartTemplate: _openTodayWithTemplate),
      TodayGeneratorTab(
        prefillTemplateDayType: _prefillTemplateDayType,
        prefillToken: _prefillToken,
      ),
    ];
    return Scaffold(
      drawer: const AccountDrawer(),
      appBar: AppBar(
        title: const Text('Gym Coach'),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Today',
          ),
        ],
      ),
    );
  }
}
