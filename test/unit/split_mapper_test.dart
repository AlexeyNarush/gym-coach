import 'package:flutter_test/flutter_test.dart';
import 'package:gym_coach/features/plans/domain/split_mapper.dart';
import 'package:gym_coach/features/plans/domain/workout_plan.dart';

void main() {
  test('maps weekdays into A/B/C split correctly', () {
    expect(workoutDayTypeForWeekday(DateTime.monday), WorkoutDayType.dayA);
    expect(workoutDayTypeForWeekday(DateTime.wednesday), WorkoutDayType.dayB);
    expect(workoutDayTypeForWeekday(DateTime.friday), WorkoutDayType.dayC);
    expect(workoutDayTypeForWeekday(DateTime.sunday), WorkoutDayType.dayC);
  });
}
