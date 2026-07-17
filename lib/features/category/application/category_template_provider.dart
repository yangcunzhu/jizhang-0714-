import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/daos/category_template_dao.dart';

/// 分类模板列表 provider(Day 15 — Stage 2 分类模板)。
///
/// 监听 `categoryTemplateDao.watchAllTemplates()`(按 id 升序 = seed 顺序)。
/// UI 层用 `ref.watch(templateListProvider)` 拿模板元数据列表。
final templateListProvider = StreamProvider<List<CategoryTemplateEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoryTemplateDao.watchAllTemplates();
});

/// 模板分类数查询(轻量 provider,UI 卡片显示「N 个分类」用)。
///
/// WHY: 模板内分类是 Dart const,不在 DB,无法 SQL 查;每次都通过
/// `defaultTemplateDefinitions` 现算。零 IO 开销,可同步返回。
final templateCategoryCountProvider =
    Provider.family<int, String>((ref, code) {
  final dao = ref.watch(databaseProvider).categoryTemplateDao;
  final def = dao.getTemplateDefinition(code);
  return def?.categories.length ?? 0;
});

/// 应用模板的服务(由 page 调用,不放在 page 内避免重复构造)。
///
/// WHY: 把 dao 调用包成统一 service,page 只关心"应用并返回结果"。
/// 失败抛异常由 page 用 SnackBar 显示。
class ApplyTemplateService {
  ApplyTemplateService(this._ref);
  final Ref _ref;

  Future<ApplyResult> apply(String code, TemplateApplyMode mode) async {
    final db = _ref.read(databaseProvider);
    return db.categoryTemplateDao.applyTemplate(code, mode);
  }
}

final applyTemplateServiceProvider =
    Provider<ApplyTemplateService>((ref) => ApplyTemplateService(ref));