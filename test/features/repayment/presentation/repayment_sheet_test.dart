// RepaymentSheet widget 测试(D20 — 信用卡还款流)。
//
// 简化版:只验证 UI 元素显示 + canSubmit 状态变化,避免 pumpAndSettle 死循环。
// provider 校验逻辑在单元测试覆盖(repayment_form_provider_test)。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/repayment/application/repayment_form_provider.dart';
import 'package:jizhang_app/features/repayment/presentation/repayment_sheet.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountDao.getDefault();
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '现金',
        type: const Value(AccountType.cash),
        balanceCents: const Value(1000000),
      ),
    );
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '招行信用卡',
        type: const Value(AccountType.creditCard),
        creditLimit: const Value(5000000),
        billingDay: const Value(5),
        dueDay: const Value(25),
      ),
    );
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  testWidgets('弹层打开显示标题 + 区段 + 还款按钮初始 disabled',
      (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );

    // 直接 push RepaymentSheet widget(不用 showModalBottomSheet,避免 pumpAndSettle 死循环)
    // 用 Scaffold 包,提供 Material widget ancestor
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: RepaymentSheet()),
        ),
      ),
    );
    await tester.pump();

    // 标题 + 按钮都是「还款」,至少 1 个
    expect(find.text('还款'), findsWidgets);

    // 4 个区段标题(注意:section title 和 TextField label 文字相同,都至少 1 个 widget)
    expect(find.text('储蓄账户(扣款)'), findsWidgets);
    expect(find.text('还款金额'), findsWidgets);
    expect(find.text('信用卡账户(收款)'), findsWidgets);
    expect(find.text('备注(可选)'), findsWidgets);

    // 还款按钮存在但 disabled
    final submitBtn = find.byKey(const Key('repayment-submit'));
    expect(submitBtn, findsOneWidget);
    final widget = tester.widget<FilledButton>(submitBtn);
    expect(widget.onPressed, isNull, reason: '未填表单时 disabled');
  });

  testWidgets('储蓄 + 信用卡 + 金额 → 还款按钮 enabled', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: RepaymentSheet()),
        ),
      ),
    );
    await tester.pump();

    // 初始 disabled
    final submitBtn = find.byKey(const Key('repayment-submit'));
    var widget = tester.widget<FilledButton>(submitBtn);
    expect(widget.onPressed, isNull);

    // 通过 provider 直接设置(绕过 UI 输入,避免 pump 死循环)
    final innerContainer = ProviderScope.containerOf(
      tester.element(find.byType(RepaymentSheet)),
    );
    final notifier = innerContainer.read(repaymentFormProvider.notifier);
    notifier.setFromSavingsAccount(1); // 现金账户 ID
    notifier.setAmount(50000); // 500 元
    notifier.setToCreditCardAccount(2); // 招行信用卡 ID
    await tester.pump();

    // 现在 enabled
    widget = tester.widget<FilledButton>(submitBtn);
    expect(widget.onPressed, isNotNull,
        reason: '储蓄 + 信用卡 + 金额 → canSubmit = true');
  });
}