// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:attendance/main.dart';

void main() {
  testWidgets('Attendance app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AttendanceApp());

    // Verify that our title and toggles are present on login screen.
    expect(find.text('勤怠管理'), findsWidgets);
    expect(find.text('利用者'), findsWidgets);
    expect(find.text('管理者'), findsWidgets);
  });
}
