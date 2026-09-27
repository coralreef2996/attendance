import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/admin_screen.dart';

void main() {
  testWidgets('AdminAttendanceMemosScreen opens from Tab 2 and handles back', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Switch to Tab 2 (分析・職員用メモ)
    final tab2Finder = find.text('分析\n職員用メモ');
    expect(tab2Finder, findsOneWidget);
    await tester.tap(tab2Finder);
    await tester.pumpAndSettle();

    // 2. Find and tap 勤怠メモ表示 button
    final memoBtnFinder = find.text('勤怠メモ表示');
    expect(memoBtnFinder, findsOneWidget);
    await tester.tap(memoBtnFinder);
    await tester.pumpAndSettle();

    // 3. Verify AdminAttendanceMemosScreen content
    expect(find.text('【管理】勤怠メモ (閲覧/代理記録)'), findsOneWidget);
    expect(find.text('勤怠メモを記録する'), findsOneWidget);

    // 4. Test saving a memo
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    final saveBtnFinder = find.widgetWithText(ElevatedButton, '保存する');
    expect(saveBtnFinder, findsOneWidget);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();

    // 5. Verify Back navigation
    final backBtnFinder = find.byIcon(Icons.arrow_back);
    expect(backBtnFinder, findsOneWidget);
    await tester.tap(backBtnFinder);
    await tester.pumpAndSettle();

    // 6. Verify returned to Tab 2 list
    expect(find.text('【管理】勤怠メモ (閲覧/代理記録)'), findsNothing);
    expect(find.text('勤怠メモ表示'), findsOneWidget);
  });
}
