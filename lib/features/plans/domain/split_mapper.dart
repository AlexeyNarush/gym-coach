import 'package:gym_coach/features/plans/domain/workout_plan.dart';

WorkoutDayType workoutDayTypeForWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
    case DateTime.tuesday:
      return WorkoutDayType.dayA;
    case DateTime.wednesday:
    case DateTime.thursday:
      return WorkoutDayType.dayB;
    default:
      return WorkoutDayType.dayC;
  }
}
