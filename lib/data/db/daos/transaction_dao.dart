import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

/// 交易流水数据访问对象。
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// 监听全部交易(按发生时间倒序,最新在前)。
  Stream<List<TransactionEntry>> watchAll() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<TransactionEntry>> getAll() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  /// 按 id 查询单笔交易(编辑/退款流程需要先 load 再反向填充表单)。
  ///
  /// 返回 null 表示 id 不存在(不应在 UI 主流程发生,但留给退款流程防御)。
  Future<TransactionEntry?> getById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 全量更新一笔交易,内部自动刷新 updatedAt。
  ///
  /// WHY: .replace() 不会触碰 updatedAt 默认值(默认仅在 INSERT 生效),
  /// 若交由调用方手动刷新极易遗漏 → 在 DAO 内统一 stamp,杜绝幽灵旧时间戳。
  Future<bool> updateTransaction(TransactionEntry entry) {
    final stamped = entry.copyWith(updatedAt: DateTime.now());
    return update(transactions).replace(stamped);
  }

  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
