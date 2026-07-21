// BorrowRecordPage widget 测试(D25 ADR-0029 借贷字段修补)。
//
// 覆盖:
// - 「起始欠款」TextField 存在(D25 新加,key=borrow-initial-balance)
// - 「起始欠款」黄框内「之前的记录不计入余额统计」提示存在
// - 「起始时间」必填提示存在
// - 「借入金额」+「账户名称」+「出借人姓名」TextField 存在(沿用 D22)

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/borrow/presentation/borrow_record_page.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: BorrowRecordPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('D25 新加:起始欠款 TextField 存在(borrow-initial-balance)',
      (tester) async {
    await db.accountDao.getDefault();
    await pump(tester);
    expect(find.byKey(const Key('borrow-initial-balance')), findsOneWidget,
        reason: 'D25 ADR-0029:起始欠款字段独立可编辑 input,账户级与 transaction 金额分离');
  });

  testWidgets('起始欠款黄框内提示 + 起始时间必填 + 沿用字段都在',
      (tester) async {
    await db.accountDao.getDefault();
    await pump(tester);
    expect(find.text('该时间之前的记录不计入余额统计'), findsWidgets);
    expect(find.byKey(const Key('borrow-amount')), findsOneWidget);
    expect(find.byKey(const Key('borrow-account-name')), findsOneWidget);
    expect(find.byKey(const Key('borrow-counterparty')), findsOneWidget);
    expect(find.text('起始时间'), findsOneWidget);
    expect(find.text('借入日期'), findsOneWidget);
  });
}
