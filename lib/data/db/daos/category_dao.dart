import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

/// 分类数据访问对象。
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 一次性读取全部分类(按 sortOrder 升序)。
  Future<List<CategoryEntry>> getAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  /// 监听全部分类(响应式,供 Riverpod/StreamBuilder 使用)。
  Stream<List<CategoryEntry>> watchAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }
}
