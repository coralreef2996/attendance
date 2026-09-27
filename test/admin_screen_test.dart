import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/admin_screen.dart';

void main() {
  testWidgets('PersonalDataTab contains 休憩場所使用状況 at the bottom', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab 1 (個人データ一覧)
    expect(find.text('勤怠ダッシュボード'), findsOneWidget);
    expect(find.text('個人データ 一覧 (選択で閲覧モード起動)'), findsOneWidget);

    // Scroll to bottom of Tab 1
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify 休憩場所使用状況 is present in Tab 1
    expect(find.text('休憩場所使用状況'), findsOneWidget);
    expect(find.text('ソファー1'), findsOneWidget);
    expect(find.text('ソファー2'), findsOneWidget);
    expect(find.text('和室スペース'), findsOneWidget);
  });

  testWidgets('AnalysisTab contains 管理者用メモ and AI分析のヒント, but NOT 出勤アラート or 休憩場所使用状況', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Tab 2
    final tab2Finder = find.text('分析\n職員用メモ');
    expect(tab2Finder, findsOneWidget);
    await tester.tap(tab2Finder);
    await tester.pumpAndSettle();

    // Tab 2 should contain 管理者用メモ and 勤怠メモ表示
    expect(find.text('管理者用メモ'), findsOneWidget);
    expect(find.text('勤怠メモ表示'), findsOneWidget);

    // Tab 2 should contain 「案内ひろば」AI分析のヒント
    expect(find.text('「案内ひろば」AI分析のヒント'), findsOneWidget);
    expect(find.text('Gemini連携'), findsOneWidget);

    // Tab 2 should NOT contain 出勤アラートの設定・履歴
    expect(find.text('出勤アラートの設定・履歴'), findsNothing);
    expect(find.text('遅刻検知アラート (10:15以降無連絡)'), findsNothing);
    expect(find.text('休憩時間超過アラート (60分超過)'), findsNothing);
    expect(find.text('残業オーバーアラート (15:30以降滞在)'), findsNothing);

    // Tab 2 should NOT contain 休憩場所使用状況
    expect(find.text('休憩場所使用状況'), findsNothing);
  });
}
