// CategoryFormProvider 测试(Day 14 — 决策 ADR-0019 校验 + 提交 + 排序初始化)。
//
// 覆盖:
// - CategoryFormState.validate: 空名称 / 超长名称 / 无 emoji
// - CategoryFormController.submit: 新建 / 编辑
// - 新建场景 sortOrder 取 max+1

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/category/application/category_form_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('CategoryFormState.validate', () {
    test('空名称 → 返回错误', () {
      final state = CategoryFormState.initialFor(TransactionType.expense);
      expect(state.validate(), '分类名称不能为空');
    });

    test('名称超 20 字 → 返回错误', () {
      final state = CategoryFormState.initialFor(TransactionType.expense)
          .copyWith(name: 'a' * 21);
      expect(state.validate(), '分类名称不能超过 20 字');
    });

    test('空 emoji → 返回错误', () {
      final state = CategoryFormState.initialFor(TransactionType.expense)
          .copyWith(name: '奶茶', iconName: '');
      expect(state.validate(), '请选择 emoji');
    });

    test('合法字段 → 返回 null', () {
      final state = CategoryFormState.initialFor(TransactionType.expense)
          .copyWith(name: '奶茶', iconName: '🧋');
      expect(state.validate(), isNull);
    });
  });

  group('CategoryFormController.submit', () {
    test('新建场景:提交成功且 sortOrder = max+1', () async {
      final key = (existingId: null, type: TransactionType.expense);
      final controller =
          container.read(categoryFormProvider(key).notifier);
      controller.changeName('奶茶');
      controller.changeIcon('🧋');

      // 等异步 _initSortOrderForNew 完成
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final ok = await controller.submit();
      expect(ok, isTrue);

      final all = await db.categoryDao.getAll();
      final milk = all.firstWhere((c) => c.name == '奶茶');
      expect(milk.iconName, '🧋');
      // seed 中 sortOrder 最大 = 9(工资),新建 = 10
      expect(milk.sortOrder, 10);
    });

    test('编辑场景:改 name + iconName,sortOrder 不变', () async {
      final food = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalOrder = food.sortOrder;

      final key = (
        existingId: food.id,
        type: TransactionType.expense,
      );
      final controller =
          container.read(categoryFormProvider(key).notifier);
      // 等异步 _loadExisting 完成
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.changeName('吃喝');
      controller.changeIcon('🍽️');

      final ok = await controller.submit();
      expect(ok, isTrue);

      final after = await db.categoryDao.getById(food.id);
      expect(after, isNotNull);
      expect(after!.name, '吃喝');
      expect(after.iconName, '🍽️');
      expect(after.sortOrder, originalOrder);
    });

    test('校验失败 → submit 返回 false,数据库不变', () async {
      final key = (existingId: null, type: TransactionType.expense);
      final controller =
          container.read(categoryFormProvider(key).notifier);
      // 不改 name(空)

      final before = await db.categoryDao.getAll();
      final ok = await controller.submit();
      expect(ok, isFalse);

      final after = await db.categoryDao.getAll();
      expect(after.length, before.length);
    });
  });
}