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

  /// 全量更新一笔交易(同步刷新 updatedAt 由调用方在 companion 里带上)。
  Future<bool> updateTransaction(TransactionEntry entry) {
    return update(transactions).replace(entry);
  }

  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
