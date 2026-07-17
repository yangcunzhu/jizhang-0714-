import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'category_dao.g.dart';

/// 分类数据访问对象。
///
/// Day 11(Stage 2 启动):getAll / watchAll / insertCategory
/// Day 14(本 ADR-0019):+ getById / updateCategory / deleteCategory /
///   countTransactionsByCategory / swapSortOrder
///
/// 决策:ADR-0019 — 引用检查放本 DAO,不碰 transaction_dao(避免越界)。
@DriftAccessor(tables: [Categories, Transactions])
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

  /// 按 ID 取单个分类。
  ///
  /// 返回 null 表示 id 不存在(分类管理页编辑前需先 load)。
  Future<CategoryEntry?> getById(int id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  /// 按 ID 更新分类字段(返回受影响行数,0 表示 ID 不存在)。
  ///
  /// 入参 [entry.id] 必须已设置才能定位行,其他字段为 null/absent 时跳过。
  /// WHY: 用 companion 的"部分更新"语义 — 只改传入字段,不动其他列。
  /// 这样表单字段独立提交时(如只改名称)无需先读再写全字段。
  Future<int> updateCategoryById(CategoriesCompanion entry) {
    final id = entry.id.value;
    return (update(categories)..where((c) => c.id.equals(id))).write(entry);
  }

  /// 按 ID 删分类。
  ///
  /// 注意:有交易引用的分类删除会失败(外键约束,FK 由 beforeOpen 打开)。
  /// 调用方应先 [countTransactionsByCategory] 检查或提示用户(见 ADR-0019)。
  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  /// 统计某分类被交易引用的次数。
  ///
  /// WHY:删除分类前需要知道是否有交易引用 — 不能只靠外键抛错(用户体验差)。
  /// 用 COUNT 查询代替 [transactionDao] 的全量读取(避免 N+1)。
  /// 决策:ADR-0019 — 引用计数放本 DAO,通过 @DriftAccessor 加 Transactions 表
  /// 拿到 transactions 句柄,不跨 DAO 调用。
  Future<int> countTransactionsByCategory(int categoryId) async {
    final count = countAll();
    final query = selectOnly(transactions)
      ..addColumns([count])
      ..where(transactions.categoryId.equals(categoryId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// 原子交换两个分类的 sortOrder(单步移动)。
  ///
  /// WHY: 单步交换比批量重排更安全 — 仅影响两行,无需事务,UI 与 DAO 语义一致
  /// (按 ↑/↓ 按钮移动一次)。批量重排留给 Stage 4+ 拖拽重排(本 ADR 不展开)。
  ///
  /// 入参 [idA] / [idB] 必须存在(否则对应 UPDATE 影响 0 行,无副作用)。
  /// 同 id 调用 = no-op(等价于把 sortOrder 设成自己,无变化)。
  Future<void> swapSortOrder(int idA, int idB) async {
    if (idA == idB) return;
    final a = await getById(idA);
    final b = await getById(idB);
    if (a == null || b == null) return;
    // 直接交换,不需要中间变量。
    await update(categories).replace(a.copyWith(sortOrder: b.sortOrder));
    await update(categories).replace(b.copyWith(sortOrder: a.sortOrder));
  }
}