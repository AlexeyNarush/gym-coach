// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_coach/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shows onboarding and navigates to plan tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymCoachApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Gym Coach'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your 3-day split'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
