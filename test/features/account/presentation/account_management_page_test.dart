// AccountManagementPage widget 测试。
//
// 决策依据:ADR-0018 — 列表 + 添加按钮。
// 覆盖:列表渲染、空态、添加 FAB、点击账户进编辑。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/account/presentation/account_management_page.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 等 onCreate + seed 完成
    await db.accountDao.getDefault();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget wrap() => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountManagementPage()),
      );

  testWidgets('空账户:显示「还没有账户」空态 + 添加按钮', (tester) async {
    // 删除 seed,模拟空账户场景
    await db.accountDao.deleteAccount(1);
    await tester.pumpWidget(wrap());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.text('还没有账户'), findsOneWidget);
    expect(find.byKey(const Key('add-account-fab')), findsOneWidget);
  });

  testWidgets('1 条 seed 现金账户:渲染 1 个卡片', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.text('还没有账户'), findsNothing);
    expect(find.byKey(const Key('account-list-card-1')), findsOneWidget);
    expect(find.text('现金'), findsWidgets);
  });

  testWidgets('多账户:卡片按列表渲染', (tester) async {
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(name: '现金B'),
    );
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(name: '信用卡C', type: Value(AccountType.creditCard)),
    );

    await tester.pumpWidget(wrap());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.byKey(const Key('account-list-card-1')), findsOneWidget);
    expect(find.byKey(const Key('account-list-card-2')), findsOneWidget);
    expect(find.byKey(const Key('account-list-card-3')), findsOneWidget);
    expect(find.text('现金'), findsWidgets);
    expect(find.text('现金B'), findsOneWidget);
    expect(find.text('信用卡C'), findsOneWidget);
  });

  testWidgets('AppBar 标题「账户管理」', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.text('账户管理'), findsOneWidget);
  });

  testWidgets('点 FAB → 弹出 AccountEditSheet(底部弹层)', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-account-fab')));
    await tester.pump(const Duration(milliseconds: 300));
    // "添加账户" 同时出现在 FAB label 和弹层标题
    expect(find.text('添加账户'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('account-type-cash')), findsOneWidget);
  });
}