// AccountEditSheet widget 测试。
//
// 决策依据:ADR-0018 — 底部弹层 + 6 类型切换 + 字段动态。
// 覆盖:
// - 显示标题(添加 vs 编辑)
// - 6 种类型 chip 全部渲染
// - 信用卡类型才显示 creditLimit/billingDay/dueDay
// - 类型切换时字段动态显示/隐藏
// - 取消 / 保存回调
// - 校验失败阻止保存

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/account/presentation/widgets/account_edit_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSheet(WidgetTester tester, {int? existingId}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: AccountEditSheet(existingId: existingId),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('新建场景:标题显示「添加账户」', (tester) async {
    await pumpSheet(tester);
    expect(find.text('添加账户'), findsOneWidget);
  });

  testWidgets('编辑场景:标题显示「编辑账户」', (tester) async {
    // 先 seed 一个账户
    final id = await db.accountDao.insertAccount(
      AccountsCompanion.insert(name: '原账户'),
    );
    await pumpSheet(tester, existingId: id);
    expect(find.text('编辑账户'), findsOneWidget);
  });

  testWidgets('6 种类型 chip 都渲染', (tester) async {
    await pumpSheet(tester);
    // AccountType.values 长度 = 6
    for (final type in [
      'cash',
      'savings',
      'creditCard',
      'huabei',
      'onlineLoan',
      'investment',
    ]) {
      expect(find.byKey(Key('account-type-$type')), findsOneWidget,
          reason: '类型 $type chip 应渲染');
    }
  });

  testWidgets('默认 cash 类型 → 不显示信用卡字段', (tester) async {
    await pumpSheet(tester);
    expect(find.byKey(const Key('account-edit-credit-limit')), findsNothing);
    expect(find.byKey(const Key('account-edit-billing-day')), findsNothing);
    expect(find.byKey(const Key('account-edit-due-day')), findsNothing);
  });

  testWidgets('点击信用卡 chip → 显示信用卡字段', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-type-creditCard')));
    await tester.pump();
    expect(find.byKey(const Key('account-edit-credit-limit')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-billing-day')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-due-day')), findsOneWidget);
  });

  testWidgets('从信用卡切回储蓄 → 信用卡字段消失', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-type-creditCard')));
    await tester.pump();
    expect(find.byKey(const Key('account-edit-credit-limit')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-type-savings')));
    await tester.pump();
    expect(find.byKey(const Key('account-edit-credit-limit')), findsNothing);
  });

  testWidgets('点保存但名称为空 → 不弹回(校验失败)', (tester) async {
    await pumpSheet(tester);
    // 不输入名称,直接点保存
    await tester.tap(find.byKey(const Key('account-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));
    // 数据库不应新增
    final accounts = await db.accountDao.getAll();
    expect(accounts, hasLength(1)); // 只有 seed 现金
    expect(accounts.single.name, '现金');
  });

  testWidgets('输入名称后保存 → 数据库新增一行 + Navigator.pop(true)',
      (tester) async {
    bool? popResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const AccountEditSheet(existingId: null),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(); // 让弹层动画完成

    // 输入名称
    await tester.enterText(find.byKey(const Key('account-edit-name')), '招行卡');
    await tester.pump();

    // 保存
    await tester.tap(find.byKey(const Key('account-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));

    // pop 应返回 true
    expect(popResult, isTrue);

    final accounts = await db.accountDao.getAll();
    expect(accounts.length, 2);
    expect(accounts.any((a) => a.name == '招行卡'), isTrue);
  });

  testWidgets('点取消 → Navigator.pop(false)', (tester) async {
    bool? popResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const AccountEditSheet(existingId: null),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-edit-cancel')));
    await tester.pump();
    expect(popResult, isFalse);
  });
}