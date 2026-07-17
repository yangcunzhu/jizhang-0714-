// Stage 2 集成测试(Day 16) — S02 全链路验证。
//
// 覆盖:
// 1. 信用卡账户字段完整持久化(5 个新字段)
// 2. 多账户下记账可选不同账户(transaction.accountId 正确)
// 3. 应用模板「极简」覆盖空分类 → 5 个新分类
// 4. 应用模板覆盖 + 引用保护(有交易分类保留 + 新增)
// 5. 应用模板追加模式(已有不删 + 新增)
// 6. 完整 widget 旅程:主页记账 → 应用模板覆盖 → toast 显示
//
// 设计:沿用 home_page_test.dart 的 bootContainer 模式避开 Drift stream 在
// fake_async 下卡死。本地跑通即可,不进 CI(参考 G-003 E2E 卡死教训)。
//
// 决策:ADR-0015 (S02 写集) / ADR-0017 (账户 UI) / ADR-0019 (分类 UI) /
//      ADR-0020 (模板设计)。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/daos/category_template_dao.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/account/application/account_form_provider.dart';
import 'package:jizhang_app/features/category/application/category_template_provider.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/home/presentation/home_page.dart';

void main() {
  late AppDatabase db;

  /// bootContainer 模式:预先 .future 同步拿 stream 首个 event,
  /// 避开 Drift stream 在 fake_async 下卡 Drift timer。
  Future<ProviderContainer> bootContainer(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);
    await container.read(accountListProvider.future);
    await container.read(templateListProvider.future);
    return container;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('账户层', () {
    test('新建信用卡账户 → 5 个新字段(creditLimit / billingDay / dueDay)完整持久化',
        () async {
      final acc = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: Value(AccountType.creditCard),
          creditLimit: const Value(50000_00),
          billingDay: const Value(5),
          dueDay: const Value(25),
          includeInNetWorth: const Value(false),
        ),
      );

      final read = await db.accountDao.getById(acc);
      expect(read, isNotNull);
      expect(read!.name, '招行信用卡');
      expect(read.type, AccountType.creditCard);
      expect(read.creditLimit, 50000_00);
      expect(read.billingDay, 5);
      expect(read.dueDay, 25);
      expect(read.includeInNetWorth, false);
    });

    test('多账户场景下记账可指向不同账户', () async {
      // seed 默认已有 1 个「现金」账户,新建 1 个「招行信用卡」
      final cashId = (await db.accountDao.getDefault())!.id;
      final ccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: const Value(AccountType.creditCard),
        ),
      );
      final cats = await db.categoryDao.getAll();
      final food = cats.first;

      // 记账 1 → 现金
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 3000,
          type: TransactionType.expense,
          categoryId: food.id,
          accountId: cashId,
        ),
      );
      // 记账 2 → 信用卡
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 8888,
          type: TransactionType.expense,
          categoryId: food.id,
          accountId: ccId,
        ),
      );

      final list = await db.transactionDao.getAll();
      expect(list, hasLength(2));
      expect(list[0].accountId, cashId);
      expect(list[1].accountId, ccId);
    });
  });

  group('模板层', () {
    test('应用模板「极简」覆盖空分类 → 5 个新分类 + 删除 0', () async {
      // 删除默认 10 个 seed,模拟空分类场景
      final all = await db.categoryDao.getAll();
      for (final c in all) {
        await db.categoryDao.deleteCategory(c.id);
      }
      expect((await db.categoryDao.getAll()), isEmpty);

      final result = await db.categoryTemplateDao
          .applyTemplate('minimal', TemplateApplyMode.overwrite);

      expect(result.deletedCount, 0);
      expect(result.preservedCount, 0);
      expect(result.insertedCount, 5);
      expect(result.skippedDuplicateCount, 0);

      final cats = await db.categoryDao.getAll();
      expect(cats, hasLength(5));
      expect(cats.map((c) => c.name).toSet(),
          containsAll(['餐饮', '交通', '居家', '其他', '收入']));
    });

    test('应用模板「上班族」覆盖 + 引用保护 → 餐饮保留 + 新增',
        () async {
      // seed 已有「餐饮」分类,先给它建一笔交易 → 有引用
      final food = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final acc = (await db.accountDao.getDefault())!;
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 2500,
          type: TransactionType.expense,
          categoryId: food.id,
          accountId: acc.id,
        ),
      );

      // 应用「上班族」覆盖
      final result = await db.categoryTemplateDao
          .applyTemplate('office_worker', TemplateApplyMode.overwrite);

      // 引用保护:餐饮保留 → preservedCount = 1(原 seed 10 - 删 9 - 保留 1)
      expect(result.deletedCount, 9);
      expect(result.preservedCount, 1);
      // 上班族有 12 个,去重后:与现有「餐饮」重复 1 个 → 新增 11
      expect(result.insertedCount, 11);

      // 餐饮分类仍然存在(保留,不是删除)
      final after = await db.categoryDao.getAll();
      final kept = after.where((c) => c.name == '餐饮');
      expect(kept, hasLength(1));
      // 新增的「咖啡」分类存在(上班族独有,seed 没有)
      expect(after.any((c) => c.name == '咖啡'), isTrue);
    });

    test('应用模板「极简」追加模式 → 已有不删 + 新增 2 个新分类',
        () async {
      // seed 默认 10 个,「极简」5 个去重分析:
      // - 餐饮(🍔)/ 交通(🚗)/ 其他(📦) 与 seed 完全同名同 emoji → 跳过 3
      // - 居家(🏠) vs seed「居住」(🏠)name 不同 → 新增
      // - 收入(💰) vs seed「工资」(💰)name 不同 → 新增
      // → insertedCount = 2,skippedDuplicateCount = 3
      final initialCount = (await db.categoryDao.getAll()).length;

      final result = await db.categoryTemplateDao
          .applyTemplate('minimal', TemplateApplyMode.append);

      expect(result.deletedCount, 0);
      expect(result.preservedCount, 0);
      expect(result.insertedCount, 2);
      expect(result.skippedDuplicateCount, 3);

      final cats = await db.categoryDao.getAll();
      // 10 + 2 新增 = 12
      expect(cats, hasLength(initialCount + 2));
      expect(cats.any((c) => c.name == '居家'), isTrue);
      expect(cats.any((c) => c.name == '收入'), isTrue);
    });
  });

  group('Widget 全链路', () {
    testWidgets('完整 S02 journey:主页 → 应用模板覆盖 → toast 显示',
        (tester) async {
      final container = await bootContainer(tester);

      // 渲染主页(实际验证 bootContainer 在 HomePage 也能正常工作)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 主页可见「分类模板」入口(Stage 2 主页 AppBar 按钮)
      expect(find.byKey(const Key('home-template-button')), findsOneWidget);
      expect(find.text('审计官'), findsOneWidget);

      // 跳转模板页
      await tester.tap(find.byKey(const Key('home-template-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 模板页可见 5 张卡片
      expect(find.text('上班族'), findsOneWidget);
      expect(find.text('极简'), findsOneWidget);
      expect(find.byKey(const Key('template-card-minimal')), findsOneWidget);

      // 点「极简」→ 弹策略选择层
      await tester.tap(find.byKey(const Key('template-card-minimal')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('应用方式'), findsOneWidget);

      // 选「覆盖」→ toast 显示
      await tester.tap(find.byKey(const Key('template-mode-overwrite')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('模板应用完成'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // DB 验证:模板应用后分类表更新(默认 10 seed - 删 0 + 新增 1 = 11,因为极简 5 个去重)
      // 等 SnackBar 显示完成 → drift stream 通知 → 重新查 DB
      final cats = await db.categoryDao.getAll();
      // 「收入」是极简独有,seed 没有
      expect(cats.any((c) => c.name == '收入'), isTrue,
          reason: '极简模板应用后,「收入」分类应存在');
    });
  });
}