// CategoryTemplate provider 测试(Day 15)。
//
// 覆盖:
// - templateListProvider 监听 watchAllTemplates
// - templateCategoryCountProvider 返模板内分类数
// - ApplyTemplateService.apply 调用 DAO

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/daos/category_template_dao.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/category/application/category_template_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('templateListProvider', () {
    test('emit 5 个预设模板', () async {
      final templates = await container.read(templateListProvider.future);
      expect(templates, hasLength(5));
      final codes = templates.map((t) => t.code).toSet();
      expect(codes, containsAll(['office_worker', 'family', 'student', 'minimal', 'empty']));
    });
  });

  group('templateCategoryCountProvider', () {
    test('上班族 = 12 个分类', () {
      final count = container.read(templateCategoryCountProvider('office_worker'));
      expect(count, 12);
    });

    test('家庭 = 10 个分类', () {
      expect(container.read(templateCategoryCountProvider('family')), 10);
    });

    test('学生 = 8 个分类', () {
      expect(container.read(templateCategoryCountProvider('student')), 8);
    });

    test('极简 = 5 个分类', () {
      expect(container.read(templateCategoryCountProvider('minimal')), 5);
    });

    test('自定义空 = 0 个分类', () {
      expect(container.read(templateCategoryCountProvider('empty')), 0);
    });

    test('不存在的 code = 0', () {
      expect(container.read(templateCategoryCountProvider('xxx')), 0);
    });
  });

  group('ApplyTemplateService', () {
    test('apply 调用 DAO 返回 ApplyResult', () async {
      final service = container.read(applyTemplateServiceProvider);
      final result =
          await service.apply('minimal', TemplateApplyMode.overwrite);
      expect(result.mode, TemplateApplyMode.overwrite);
      // 极简 5 个,seed 重合 3 个(餐饮/交通/其他)+ 新增 2 个(居家/收入)
      expect(result.insertedCount + result.skippedDuplicateCount, 5);
    });

    test('apply 不存在的模板抛 ArgumentError', () async {
      final service = container.read(applyTemplateServiceProvider);
      expect(
        () => service.apply('xxx', TemplateApplyMode.append),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}