// Schema migration v2 → v3 测试(Day 15)。
//
// 验证:
// - schemaVersion = 3
// - 全新安装走 onCreate + _seedDefaults + _seedTemplates
// - 模板元数据字段正确填充
// - 老分类数据不受影响(新表不影响旧表)
//
// 注:真实 onUpgrade v2→v3 路径需 drift schemaHistory mock,Day 15 暂略。
// onUpgrade 路径的 createTable + _seedTemplates 是显式逻辑,与 onCreate 同步。

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';

void main() {
  group('Schema v3(Stage 2 Day 15 — ADR-0020)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion >= 3(S03 升至 4,基线断言兼容)', () {
      // WHY: S03 (Day 18, ADR-0021) schemaVersion 3 → 4,加 TransactionType enum `repayment`。
      // 原 v3 schema 行为(5 模板 + 10 默认分类 + 老分类不丢)在 v4 仍成立,改为基线断言。
      expect(db.schemaVersion, greaterThanOrEqualTo(3));
    });

    test('新装数据库含 5 个预设模板', () async {
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

    test('模板元数据字段正确填充', () async {
      final officeWorker =
          await db.categoryTemplateDao.getTemplateByCode('office_worker');
      expect(officeWorker, isNotNull);
      expect(officeWorker!.name, '上班族');
      expect(officeWorker.emoji, '👔');
      expect(officeWorker.description, contains('12'));
    });

    test('老分类数据完整保留(不影响现有分类)', () async {
      final categories = await db.categoryDao.getAll();
      expect(categories, hasLength(10));
      expect(categories.any((c) => c.name == '餐饮'), isTrue);
      expect(categories.any((c) => c.name == '工资'), isTrue);
    });

    test('同时存在 5 模板 + 10 默认分类(seed 互不干扰)', () async {
      final templates = await db.categoryTemplateDao.getAllTemplates();
      final categories = await db.categoryDao.getAll();
      expect(templates, hasLength(5));
      expect(categories, hasLength(10));
    });
  });
}