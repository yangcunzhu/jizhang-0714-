import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/home/presentation/home_page.dart';
import 'package:jizhang_app/features/home/presentation/home_page_keys.dart';

void main() {
  late AppDatabase db;

  /// 构造一个外部 ProviderContainer,预先 .future 同步拿到 stream 首个 event,
  /// 避免 widget tree 在 fake_async 中等待 Drift 真 timer 卡死。
  Future<ProviderContainer> bootContainer(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);
    return container;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('空态主页显示净资产占位 + 提示文案 + 记一笔按钮', (tester) async {
    final container = await bootContainer(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('审计官'), findsOneWidget);
    expect(find.text('净资产'), findsOneWidget);
    // BUG-1 用户反馈修复(2026-08-12):主页 _NetWorthCard 改用账户 SUM 聚合
    // (v4 §P0-12 真「净资产」),空态账户余额 0 → 显示「¥0.00」
    expect(find.byKey(const Key('net-worth-balance')), findsOneWidget);
    expect(find.text('¥0.00'), findsOneWidget,
        reason: 'BUG-1 修:空态账户余额聚合 = 0,显示「¥0.00」');
    expect(find.text('还没有记账'), findsOneWidget);
    expect(find.text('记一笔 / 还款'), findsOneWidget);
  });

  testWidgets('有数据主页：交易列表渲染分类名 + 金额 + 备注', (tester) async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 1299,
        type: TransactionType.expense,
        categoryId: cats.first.id,
        accountId: acc!.id,
        note: const Value('午饭'),
      ),
    );

    final container = await bootContainer(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('医疗健康'), findsOneWidget,
        reason: 'D27 seed sortOrder=1 第 0 个分类是「医疗健康」');
    expect(find.textContaining('午饭'), findsOneWidget);
    expect(find.text('-¥12.99'), findsOneWidget);
    expect(find.text('还没有记账'), findsNothing);
  });

  testWidgets('Day 7 回归:主页交易列表头像用 emoji 渲染(🍔)', (tester) async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 888,
        type: TransactionType.expense,
        categoryId: cats.first.id, // 医疗健康 💊(D27 sortOrder=1)
        accountId: acc!.id,
      ),
    );

    final container = await bootContainer(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    // ADR-0013: emoji 直接存 iconName,TransactionTile 用 Text 渲染。
    expect(find.text('💊'), findsOneWidget);
    expect(find.byIcon(Icons.label_outline), findsNothing,
        reason: 'Day 6 的占位 Icon 应已被 emoji Text 替代');
  });

  testWidgets('「+」菜单显示 5 类入口(有欠款 + 可转账账户时)', (tester) async {
    // seed:默认现金(fund)+ 储蓄卡(fund,→ 可转账 ≥2)+ 信用卡(debt,→ 还款)
    await db.accountDao.insertAccount(AccountsCompanion.insert(
      name: '储蓄卡',
      subType: const Value(AccountSubType.savingsCard),
      balanceCents: const Value(100000),
    ));
    await db.accountDao.insertAccount(AccountsCompanion.insert(
      name: '信用卡',
      type: const Value(AccountType.creditCard),
      subType: const Value(AccountSubType.creditCard),
      dueDay: const Value(20),
    ));

    final container = await bootContainer(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(recordFabKey));
    await tester.pump(); // 触发异步 provider 读取
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byKey(const Key('plus-menu-record')), findsOneWidget);
    expect(find.byKey(const Key('plus-menu-transfer')), findsOneWidget);
    expect(find.byKey(const Key('plus-menu-repayment')), findsOneWidget);
    expect(find.byKey(const Key('plus-menu-lend')), findsOneWidget);
    expect(find.byKey(const Key('plus-menu-borrow')), findsOneWidget);
  });
}