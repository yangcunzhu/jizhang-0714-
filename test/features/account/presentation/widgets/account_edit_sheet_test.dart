// AccountEditSheet widget 测试(ADR-0026 重做 — 5 大类 × 23 子类)。
//
// 覆盖:
// - 标题(添加 vs 编辑)
// - 5 大类 chip 全部渲染 + 默认资金大类子类渲染
// - 切换大类 → 子类列表随之切换
// - 信用大类子类才显示信用字段(额度/起始欠款/可用额度/出账日/还款日)
// - 借贷大类子类显示借款人 + 日期字段
// - 可用额度自动计算(额度 - 起始欠款)
// - 取消 / 保存回调 + 校验失败阻止保存 + subType 落库

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
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
          home: Scaffold(body: AccountEditSheet(existingId: existingId)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('新建场景:标题「添加账户」', (tester) async {
    await pumpSheet(tester);
    expect(find.text('添加账户'), findsOneWidget);
  });

  testWidgets('编辑场景:标题「编辑账户」', (tester) async {
    final id = await db.accountDao.insertAccount(
      AccountsCompanion.insert(name: '原账户'),
    );
    await pumpSheet(tester, existingId: id);
    expect(find.text('编辑账户'), findsOneWidget);
  });

  testWidgets('5 大类 chip 都渲染', (tester) async {
    await pumpSheet(tester);
    for (final cat in ['fund', 'credit', 'recharge', 'investment', 'loan']) {
      expect(find.byKey(Key('account-category-$cat')), findsOneWidget,
          reason: '大类 $cat chip 应渲染');
    }
  });

  testWidgets('默认资金大类 → 显示资金子类(储蓄卡/微信/支付宝/现金/自定义)',
      (tester) async {
    await pumpSheet(tester);
    for (final sub in ['savingsCard', 'wechat', 'alipay', 'cash', 'fundCustom']) {
      expect(find.byKey(Key('account-type-$sub')), findsOneWidget);
    }
    // 默认不显示信用字段
    expect(find.byKey(const Key('account-edit-credit-limit')), findsNothing);
  });

  testWidgets('切到信用大类 → 显示信用子类 + 选信用卡后显示信用字段', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-category-credit')));
    await tester.pump();
    // 信用子类渲染
    expect(find.byKey(const Key('account-type-creditCard')), findsOneWidget);
    expect(find.byKey(const Key('account-type-huabei')), findsOneWidget);
    expect(find.byKey(const Key('account-type-douyinLoan')), findsOneWidget);
    // 切信用大类默认选中第一个子类(信用卡) → 信用字段出现
    expect(find.byKey(const Key('account-edit-credit-limit')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-initial-debt')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-billing-day')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-due-day')), findsOneWidget);
  });

  testWidgets('可用额度自动计算 = 额度 - 起始欠款', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-category-credit')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('account-edit-credit-limit')), '50000');
    await tester.enterText(
        find.byKey(const Key('account-edit-initial-debt')), '12000');
    await tester.pump();
    // 可用额度 = 50000 - 12000 = 38000
    final availText = tester.widget<Text>(
        find.byKey(const Key('account-edit-available')));
    expect(availText.data, '38000.00');
  });

  testWidgets('切回资金大类 → 信用字段消失', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-category-credit')));
    await tester.pump();
    expect(find.byKey(const Key('account-edit-credit-limit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-category-fund')));
    await tester.pump();
    expect(find.byKey(const Key('account-edit-credit-limit')), findsNothing);
    expect(find.byKey(const Key('account-edit-balance')), findsOneWidget);
  });

  testWidgets('切到借贷大类 → 显示借款人 + 日期字段', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('account-category-loan')));
    await tester.pump();
    expect(find.byKey(const Key('account-type-lendOut')), findsOneWidget);
    expect(find.byKey(const Key('account-type-borrowIn')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-counterparty')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-start-date')), findsOneWidget);
    expect(find.byKey(const Key('account-edit-due-date')), findsOneWidget);
  });

  testWidgets('4 个 toggle 都渲染', (tester) async {
    await pumpSheet(tester);
    for (final k in [
      'account-edit-include-networth',
      'account-edit-pinned',
      'account-edit-default-income',
      'account-edit-default-expense',
    ]) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
  });

  testWidgets('名称为空点保存 → 不写库', (tester) async {
    await pumpSheet(tester);
    await tester.ensureVisible(find.byKey(const Key('account-edit-save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));
    final accounts = await db.accountDao.getAll();
    expect(accounts, hasLength(1));
    expect(accounts.single.name, '现金');
  });

  testWidgets('选微信子类 + 输名保存 → 落库 subType=wechat', (tester) async {
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

    await tester.tap(find.byKey(const Key('account-type-wechat')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('account-edit-name')), '零钱');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('account-edit-save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(popResult, isTrue);
    final accounts = await db.accountDao.getAll();
    final wechat = accounts.firstWhere((a) => a.name == '零钱');
    expect(wechat.subType, AccountSubType.wechat);
    expect(wechat.type, AccountType.savings, reason: '微信派生旧 type=savings');
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
    await tester.ensureVisible(find.byKey(const Key('account-edit-cancel')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-edit-cancel')));
    await tester.pump();
    expect(popResult, isFalse);
  });
}
