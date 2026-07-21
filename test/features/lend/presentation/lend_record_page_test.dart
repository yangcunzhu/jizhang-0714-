// LendRecordPage widget 测试(D25 ADR-0029 借贷字段修补)。
//
// 覆盖:
// - 「起始余额」TextField 存在(D25 新加,key=lend-initial-balance)
// - 「起始余额」黄框内「之前的记录不计入余额统计」提示存在
// - 「起始时间」必填提示存在
// - 「借出金额」+「账户名称」+「借款人姓名」TextField 存在(沿用 D22)

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/lend/presentation/lend_record_page.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: LendRecordPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('D25 新加:起始余额 TextField 存在(lend-initial-balance)',
      (tester) async {
    await db.accountDao.getDefault();
    await pump(tester);
    expect(find.byKey(const Key('lend-initial-balance')), findsOneWidget,
        reason: 'D25 ADR-0029:起始余额字段独立可编辑 input,账户级与 transaction 金额分离');
  });

  testWidgets('起始余额黄框内提示 + 起始时间必填 + 沿用字段都在',
      (tester) async {
    await db.accountDao.getDefault();
    await pump(tester);
    // D25:起始余额黄框内「之前的记录不计入余额统计」语义保留
    expect(find.text('该时间之前的记录不计入余额统计'), findsWidgets);
    // D22 沿用字段(屏幕内可见,ListView lazy build off-screen 不测)
    expect(find.byKey(const Key('lend-amount')), findsOneWidget);
    expect(find.byKey(const Key('lend-account-name')), findsOneWidget);
    expect(find.byKey(const Key('lend-counterparty')), findsOneWidget);
    // 起始时间必填 + 借出日期(屏幕内可见)
    expect(find.text('起始时间'), findsOneWidget);
    expect(find.text('借出日期'), findsOneWidget);
  });
}
