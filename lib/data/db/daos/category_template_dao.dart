import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';
import '../tables/category_templates.dart';
import '../tables/transactions.dart';

part 'category_template_dao.g.dart';

/// 模板应用策略(决策 ADR-0020 — 混合弹层让用户每次选)。
enum TemplateApplyMode {
  /// 覆盖:删除无引用的旧分类 + 插入新分类(有引用的保留)
  overwrite,

  /// 追加:不删任何分类,只插入新分类(去重 name + iconName)
  append,
}

/// 模板应用结果(供 UI toast / 详情反馈)。
class ApplyResult {
  const ApplyResult({
    required this.deletedCount,
    required this.preservedCount,
    required this.insertedCount,
    required this.skippedDuplicateCount,
    required this.mode,
  });

  /// 删除的旧分类数(仅 overwrite 模式)。
  final int deletedCount;

  /// 保留的有引用旧分类数(仅 overwrite 模式,append 永远为 0)。
  final int preservedCount;

  /// 成功插入的新分类数。
  final int insertedCount;

  /// 跳过的重复分类数(name + iconName 已存在)。
  final int skippedDuplicateCount;

  /// 应用的模式。
  final TemplateApplyMode mode;

  /// 一句话摘要,UI toast 用。
  String summary() {
    final parts = <String>[];
    if (mode == TemplateApplyMode.overwrite) {
      if (deletedCount > 0) parts.add('删除 $deletedCount 个');
      if (preservedCount > 0) parts.add('保留 $preservedCount 个有引用分类');
    }
    if (insertedCount > 0) parts.add('新增 $insertedCount 个');
    if (skippedDuplicateCount > 0) parts.add('跳过 $skippedDuplicateCount 个重复');
    return parts.isEmpty ? '应用完成' : parts.join(',');
  }
}

/// 分类模板数据访问对象(Day 15 — Stage 2 分类模板)。
///
/// 决策:ADR-0020 — 混合策略(overwrite / append)+ 引用保护(保留跳过)
/// + 差异化模板(5 模板,5~12 个分类)。
@DriftAccessor(tables: [CategoryTemplates, Categories, Transactions])
class CategoryTemplateDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryTemplateDaoMixin {
  CategoryTemplateDao(super.db);

  /// 列出所有模板元数据(按 id 升序 = 写入顺序)。
  Future<List<CategoryTemplateEntry>> getAllTemplates() {
    return (select(categoryTemplates)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  /// 监听所有模板元数据(模板页面响应式)。
  Stream<List<CategoryTemplateEntry>> watchAllTemplates() {
    return (select(categoryTemplates)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  /// 按 code 取单个模板元数据。
  Future<CategoryTemplateEntry?> getTemplateByCode(String code) {
    return (select(categoryTemplates)..where((t) => t.code.equals(code)))
        .getSingleOrNull();
  }

  /// 取指定模板的分类定义(Dart const,不在 DB)。
  ///
  /// WHY: 模板内分类用 Dart `defaultTemplateDefinitions` 存储,不入 categories,
  /// 应用时通过此方法读 → 去重 → 插入 categories。
  /// 找不到对应 code 返回 null。
  TemplateDefinition? getTemplateDefinition(String code) {
    for (final def in defaultTemplateDefinitions) {
      if (def.code == code) return def;
    }
    return null;
  }

  /// 应用模板(决策 ADR-0020)。
  ///
  /// 入参:
  /// - [code]: 模板代号(如 'office_worker')
  /// - [mode]: 应用策略(overwrite / append)
  ///
  /// 返回 [ApplyResult] 含计数 + 摘要。
  ///
  /// 关键逻辑:
  /// - 整个应用过程在事务里,中间失败自动回滚
  /// - 覆盖模式:删除无引用分类(逐个 delete),保留有引用分类
  /// - 追加模式:不删除任何分类
  /// - 模板分类插入前去重:同 name + iconName 跳过
  /// - sortOrder:用 max(existing sortOrder) + 1 + index 保证新增分类排在最后
  Future<ApplyResult> applyTemplate(
    String code,
    TemplateApplyMode mode,
  ) async {
    final def = getTemplateDefinition(code);
    if (def == null) {
      throw ArgumentError('Template not found: $code');
    }

    return transaction(() async {
      final existing = await db.categoryDao.getAll();
      final existingKeys = <String>{
        for (final c in existing) '${c.name}|${c.iconName}',
      };
      // sortOrder 基线:用 max+1,保证新增分类排在已有之后
      var nextSort = existing.fold<int>(-1, (acc, c) => c.sortOrder > acc ? c.sortOrder : acc) + 1;

      var deletedCount = 0;
      var preservedCount = 0;

      // 「覆盖」模式:删除无引用分类 + 保留有引用分类
      // (空模板也走这条 — 让用户能从零起步)
      if (mode == TemplateApplyMode.overwrite) {
        for (final c in existing) {
          final refCount = await db.categoryDao.countTransactionsByCategory(c.id);
          if (refCount == 0) {
            await (db.delete(db.categories)
                  ..where((tbl) => tbl.id.equals(c.id)))
                .go();
            deletedCount++;
            // 同步从 existingKeys 移除,避免模板里有同 name+iconName 时仍被跳过
            existingKeys.remove('${c.name}|${c.iconName}');
          } else {
            preservedCount++;
          }
        }
      }

      // 插入模板分类(去重 name + iconName)
      // 空模板 → for 循环 0 次,自动跳过
      var insertedCount = 0;
      var skippedDuplicateCount = 0;
      for (final tc in def.categories) {
        final key = '${tc.name}|${tc.iconName}';
        if (existingKeys.contains(key)) {
          skippedDuplicateCount++;
          continue;
        }
        await db.into(db.categories).insert(
              CategoriesCompanion.insert(
                name: tc.name,
                iconName: tc.iconName,
                colorValue: tc.colorValue,
                type: tc.type,
                sortOrder: Value(nextSort),
              ),
            );
        existingKeys.add(key);
        insertedCount++;
        nextSort++;
      }

      return ApplyResult(
        deletedCount: deletedCount,
        preservedCount: preservedCount,
        insertedCount: insertedCount,
        skippedDuplicateCount: skippedDuplicateCount,
        mode: mode,
      );
    });
  }
}