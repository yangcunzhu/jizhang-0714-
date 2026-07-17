// CategoryDao 测试(Day 14 — 决策 ADR-0019 CRUD + 引用检查 + swapSortOrder)。
//
// 覆盖:
// - getById / updateCategoryById / deleteCategory
// - countTransactionsByCategory(引用计数)
// - swapSortOrder(原子交换两个分类的 sortOrder)

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('getById / update / delete', () {
    test('getById 返回 null 当 id 不存在', () async {
      final result = await db.categoryDao.getById(9999);
      expect(result, isNull);
    });

    test('updateCategoryById 部分更新(只改 name,其他字段不变)',
        () async {
      final original = (await db.categoryDao.getAll()).first;
      final before = await db.categoryDao.getById(original.id);
      expect(before, isNotNull);

      await db.categoryDao.updateCategoryById(
        CategoriesCompanion(
          id: Value(original.id),
          name: const Value('新餐饮'),
        ),
      );

      final after = await db.categoryDao.getById(original.id);
      expect(after, isNotNull);
      expect(after!.name, '新餐饮');
      // iconName / colorValue 不变
      expect(after.iconName, before!.iconName);
      expect(after.colorValue, before.colorValue);
    });

    test('deleteCategory 删除无引用的分类', () async {
      // 自建一个分类(seed 中没有这个)
      final id = await db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: '奶茶',
          iconName: '🧋',
          colorValue: 0xFFE57373,
          type: TransactionType.expense,
        ),
      );
      final before = await db.categoryDao.getAll();
      expect(before.any((c) => c.id == id), isTrue);

      await db.categoryDao.deleteCategory(id);

      final after = await db.categoryDao.getAll();
      expect(after.any((c) => c.id == id), isFalse);
    });
  });

  group('引用检查(ADR-0019)', () {
    test('countTransactionsByCategory 返回 0 当无引用', () async {
      // 取 seed 中的「餐饮」分类
      final food = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final count = await db.categoryDao.countTransactionsByCategory(food.id);
      expect(count, 0);
    });

    test('countTransactionsByCategory 正确计数引用', () async {
      final food = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final acc = (await db.accountDao.getAll()).first;

      // 插 3 笔交易引用「餐饮」
      for (var i = 0; i < 3; i++) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            amountCents: 1000 + i,
            type: TransactionType.expense,
            categoryId: food.id,
            accountId: acc.id,
          ),
        );
      }

      final count = await db.categoryDao.countTransactionsByCategory(food.id);
      expect(count, 3);
    });

    test('删除有引用的分类会抛外键异常', () async {
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

      // FK 约束开启(由 beforeOpen),删除应抛异常
      expect(
        () => db.categoryDao.deleteCategory(food.id),
        throwsA(anything),
      );
    });
  });

  group('swapSortOrder(ADR-0019)', () {
    test('交换两个分类的 sortOrder', () async {
      final all = await db.categoryDao.getAll();
      final first = all[0];
      final second = all[1];

      await db.categoryDao.swapSortOrder(first.id, second.id);

      final after = await db.categoryDao.getAll();
      expect(after[0].id, second.id);
      expect(after[1].id, first.id);
    });

    test('swapSortOrder 同 id = no-op', () async {
      final all = await db.categoryDao.getAll();
      final first = all[0];
      final originalOrder = first.sortOrder;

      await db.categoryDao.swapSortOrder(first.id, first.id);

      final after = await db.categoryDao.getById(first.id);
      expect(after!.sortOrder, originalOrder);
    });

    test('swapSortOrder id 不存在 = no-op 不抛错', () async {
      // 不应抛错,直接返回
      await db.categoryDao.swapSortOrder(9999, 9998);
      // 原数据未动
      final all = await db.categoryDao.getAll();
      expect(all, hasLength(10));
    });
  });

  // suppress unused import warnings
  test('AccountType 仅 placeholder', () {
    expect(AccountType.cash.name, 'cash');
  });
}