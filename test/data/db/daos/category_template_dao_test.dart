// CategoryTemplateDao 测试(Day 15 — 决策 ADR-0020)。
//
// 覆盖:
// - getAllTemplates / getTemplateByCode / getTemplateDefinition
// - applyTemplate(overwrite / append) + 引用保护 + 重复跳过 + 事务回滚

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/daos/category_template_dao.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('模板元数据(seed)', () {
    test('getAllTemplates 返回 5 个预设模板', () async {
      final templates = await db.categoryTemplateDao.getAllTemplates();
      expect(templates, hasLength(5));
      final codes = templates.map((t) => t.code).toList();
      expect(codes, containsAll([
        'office_worker',
        'family',
        'student',
        'minimal',
        'empty',
      ]));
    });

    test('getTemplateByCode 返回 null 当 code 不存在', () async {
      final result = await db.categoryTemplateDao.getTemplateByCode('nonexistent');
      expect(result, isNull);
    });

    test('getTemplateByCode 正确返回指定模板', () async {
      final result = await db.categoryTemplateDao.getTemplateByCode('minimal');
      expect(result, isNotNull);
      expect(result!.name, '极简');
      expect(result.emoji, '✨');
    });

    test('getTemplateDefinition 返回模板内分类(空模板返回空列表)', () async {
      final def = db.categoryTemplateDao.getTemplateDefinition('minimal');
      expect(def, isNotNull);
      expect(def!.categories, hasLength(5));

      final empty = db.categoryTemplateDao.getTemplateDefinition('empty');
      expect(empty, isNotNull);
      expect(empty!.categories, isEmpty);
    });

    test('getTemplateDefinition 返回 null 当 code 不存在', () async {
      final def = db.categoryTemplateDao.getTemplateDefinition('xxx');
      expect(def, isNull);
    });
  });

  group('applyTemplate — append 模式', () {
    test('追加时不删除任何现有分类', () async {
      final before = await db.categoryDao.getAll();
      expect(before, hasLength(10));

      final result =
          await db.categoryTemplateDao.applyTemplate('minimal', TemplateApplyMode.append);

      expect(result.mode, TemplateApplyMode.append);
      expect(result.deletedCount, 0);
      expect(result.preservedCount, 0);
      // 极简模板 5 个分类:
      // - 餐饮/交通/其他 = name+emoji 与 seed 重复 → 跳过 (3)
      // - 居家(模板) ≠ 居住(seed,name 不同) → 插入 (1)
      // - 收入(模板) ≠ 工资(seed,name 不同) → 插入 (1)
      expect(result.insertedCount, 2);
      expect(result.skippedDuplicateCount, 3);

      final after = await db.categoryDao.getAll();
      expect(after, hasLength(12)); // 10 seed + 2 新增
    });

    test('追加空模板 = 无操作', () async {
      final result =
          await db.categoryTemplateDao.applyTemplate('empty', TemplateApplyMode.append);
      expect(result.insertedCount, 0);
      expect(result.deletedCount, 0);
      expect(result.summary(), '应用完成');
    });

    test('应用不存在模板抛 ArgumentError', () async {
      expect(
        () => db.categoryTemplateDao.applyTemplate('xxx', TemplateApplyMode.append),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('applyTemplate — overwrite 模式 + 引用保护', () {
    test('覆盖模式:删除无引用 + 插入新模板分类', () async {
      final before = await db.categoryDao.getAll();
      expect(before, hasLength(10));

      final result = await db.categoryTemplateDao
          .applyTemplate('student', TemplateApplyMode.overwrite);

      expect(result.mode, TemplateApplyMode.overwrite);
      // seed 10 个分类都无引用 → 全部删除
      expect(result.deletedCount, 10);
      expect(result.preservedCount, 0);
      // 学生模板 8 个,全部是新插入
      expect(result.insertedCount, 8);
      expect(result.skippedDuplicateCount, 0);

      final after = await db.categoryDao.getAll();
      expect(after, hasLength(8));
    });

    test('引用保护:有交易的分类保留 + 无引用分类删除', () async {
      // 给「餐饮」加 2 笔交易(模拟真实引用)
      final food = (await db.categoryDao.getAll()).firstWhere((c) => c.name == '餐饮');
      final acc = (await db.accountDao.getAll()).first;
      for (var i = 0; i < 2; i++) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            amountCents: 1000 + i,
            type: TransactionType.expense,
            categoryId: food.id,
            accountId: acc.id,
          ),
        );
      }

      final result = await db.categoryTemplateDao
          .applyTemplate('student', TemplateApplyMode.overwrite);

      expect(result.deletedCount, 9);
      expect(result.preservedCount, 1);
      // 学生模板里有「餐饮」(同名同 emoji),保留分类已存在 → 跳过
      expect(result.insertedCount, 7);
      expect(result.skippedDuplicateCount, 1);

      final after = await db.categoryDao.getAll();
      expect(after, hasLength(8)); // 1 保留 + 7 新插入
      expect(after.any((c) => c.name == '餐饮'), isTrue);
    });

    test('应用空模板(overwrite)只删不增', () async {
      final result = await db.categoryTemplateDao
          .applyTemplate('empty', TemplateApplyMode.overwrite);
      // 全部 seed 删除
      expect(result.deletedCount, 10);
      expect(result.insertedCount, 0);

      final after = await db.categoryDao.getAll();
      expect(after, isEmpty);
    });

    test('事务原子性:模板应用后分类 sortOrder 连续递增', () async {
      // 用户已有 3 个自定义分类
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        name: 'A',
        iconName: '🅰️',
        colorValue: 0xFFE57373,
        type: TransactionType.expense,
      ));
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        name: 'B',
        iconName: '🅱️',
        colorValue: 0xFF42A5F5,
        type: TransactionType.expense,
      ));
      await db.categoryDao.insertCategory(CategoriesCompanion.insert(
        name: 'C',
        iconName: '©️',
        colorValue: 0xFF66BB6A,
        type: TransactionType.expense,
      ));
      // 调整 sortOrder 让最后一个是 12
      await db.categoryDao.updateCategoryById(
        CategoriesCompanion(
          id: const Value(0),
          sortOrder: const Value(10),
        ),
      );

      final result = await db.categoryTemplateDao
          .applyTemplate('minimal', TemplateApplyMode.overwrite);
      expect(result.insertedCount, 5);
      expect(result.deletedCount, 13); // 10 seed + 3 用户

      // 新插入的 5 个分类的 sortOrder 应该连续(从 max+1 开始)
      final after = await db.categoryDao.getAll();
      expect(after, hasLength(5));
      final orders = after.map((c) => c.sortOrder).toList();
      // 排序后应连续
      orders.sort();
      for (var i = 1; i < orders.length; i++) {
        expect(orders[i], greaterThan(orders[i - 1]));
      }
    });
  });

  group('ApplyResult.summary()', () {
    test('overwrite + 删除 + 保留 + 插入', () {
      const r = ApplyResult(
        deletedCount: 3,
        preservedCount: 2,
        insertedCount: 5,
        skippedDuplicateCount: 1,
        mode: TemplateApplyMode.overwrite,
      );
      expect(r.summary(), '删除 3 个,保留 2 个有引用分类,新增 5 个,跳过 1 个重复');
    });

    test('append + 插入', () {
      const r = ApplyResult(
        deletedCount: 0,
        preservedCount: 0,
        insertedCount: 5,
        skippedDuplicateCount: 0,
        mode: TemplateApplyMode.append,
      );
      expect(r.summary(), '新增 5 个');
    });

    test('全空 = 应用完成', () {
      const r = ApplyResult(
        deletedCount: 0,
        preservedCount: 0,
        insertedCount: 0,
        skippedDuplicateCount: 0,
        mode: TemplateApplyMode.append,
      );
      expect(r.summary(), '应用完成');
    });
  });
}