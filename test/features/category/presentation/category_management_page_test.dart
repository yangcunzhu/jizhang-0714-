// CategoryManagementPage widget 测试(Day 14 — 决策 ADR-0019 ListView + ↑↓ 排序)。
//
// 覆盖:
// - 10 个 seed 分类都渲染
// - 末尾「+新增分类」入口
// - 上下箭头按钮(首/尾禁用)
// - 长按弹菜单(编辑/删除)
// - 引用计数 > 0 时删除禁用

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/category/presentation/category_management_page.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CategoryManagementPage(),
        ),
      ),
    );
    // 让 FutureProvider 完成 + ListView build
    await tester.pump();
    await tester.pump();
  }

  testWidgets('10 个 seed 分类都渲染', (tester) async {
    await pumpPage(tester);

    const names = ['餐饮', '交通', '购物', '娱乐', '居住',
                   '医疗', '通讯', '学习', '其他', '工资'];
    for (final n in names) {
      // ListView 懒构建,屏幕外的 item 用 skipOffstage: false 仍可断言存在
      expect(find.text(n, skipOffstage: false), findsOneWidget,
          reason: '分类 $n 应渲染');
    }
  });

  testWidgets('末尾「+新增分类」入口渲染', (tester) async {
    await pumpPage(tester);
    expect(
      find.byKey(const Key('category-add-entry'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('新增分类', skipOffstage: false), findsOneWidget);
  });

  testWidgets('第一个分类的「上移」禁用,「下移」启用', (tester) async {
    await pumpPage(tester);
    final food = (await db.categoryDao.getAll()).first;
    // food.id == 1(第一个 seed),上移应禁用
    final upBtn = find.byKey(Key('category-up-${food.id}'));
    final downBtn = find.byKey(Key('category-down-${food.id}'));
    expect(upBtn, findsOneWidget);
    expect(downBtn, findsOneWidget);

    final upWidget = tester.widget<IconButton>(upBtn);
    expect(upWidget.onPressed, isNull);
    final downWidget = tester.widget<IconButton>(downBtn);
    expect(downWidget.onPressed, isNotNull);
  });

  testWidgets('最后一个分类的「下移」禁用', (tester) async {
    await pumpPage(tester);
    final all = await db.categoryDao.getAll();
    final last = all.last;
    // ListView 懒构建,最后一个 item 可能在屏幕外,用 skipOffstage: false 查找
    final upBtn = find.byKey(Key('category-up-${last.id}'), skipOffstage: false);
    final downBtn = find.byKey(Key('category-down-${last.id}'), skipOffstage: false);
    final upWidget = tester.widget<IconButton>(upBtn);
    expect(upWidget.onPressed, isNotNull);
    final downWidget = tester.widget<IconButton>(downBtn);
    expect(downWidget.onPressed, isNull);
  });

  testWidgets('点「下移」第一个分类 → 顺序交换', (tester) async {
    await pumpPage(tester);
    final all = await db.categoryDao.getAll();
    final firstId = all[0].id;
    final secondId = all[1].id;

    await tester.tap(find.byKey(Key('category-down-$firstId')));
    await tester.pump();

    final after = await db.categoryDao.getAll();
    expect(after[0].id, secondId);
    expect(after[1].id, firstId);
  });

  testWidgets('长按第一个分类 → 弹出菜单(编辑/删除)', (tester) async {
    await pumpPage(tester);
    final food = (await db.categoryDao.getAll()).first;

    await tester.longPress(
      find.byKey(Key('category-row-${food.id}'), skipOffstage: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(Key('category-action-edit-${food.id}')), findsOneWidget);
    expect(find.byKey(Key('category-action-delete-${food.id}')), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('有交易引用时 → 长按菜单删除项禁用 + 文案提示引用数',
      (tester) async {
    final food = (await db.categoryDao.getAll())
        .firstWhere((c) => c.name == '餐饮');
    final acc = (await db.accountDao.getAll()).first;
    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 1000,
        type: TransactionType.expense,
        categoryId: food.id,
        accountId: acc.id,
      ),
    );

    await pumpPage(tester);

    await tester.longPress(
      find.byKey(Key('category-row-${food.id}'), skipOffstage: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('删除(有 1 笔交易引用)'), findsOneWidget);
    // ListTile enabled=false → 不可点
    final deleteTile = tester.widget<ListTile>(
      find.byKey(Key('category-action-delete-${food.id}')),
    );
    expect(deleteTile.enabled, isFalse);
  });

  testWidgets('无引用时 → 长按菜单删除项启用', (tester) async {
    await pumpPage(tester);
    final food = (await db.categoryDao.getAll())
        .firstWhere((c) => c.name == '餐饮');

    await tester.longPress(
      find.byKey(Key('category-row-${food.id}'), skipOffstage: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final deleteTile = tester.widget<ListTile>(
      find.byKey(Key('category-action-delete-${food.id}')),
    );
    expect(deleteTile.enabled, isTrue);
    expect(find.text('删除'), findsOneWidget);
  });
}