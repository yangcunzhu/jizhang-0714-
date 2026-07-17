import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';

part 'account_dao.g.dart';

/// 账户数据访问对象。
@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<AccountEntry>> getAll() => select(accounts).get();

  Stream<List<AccountEntry>> watchAll() => select(accounts).watch();

  /// 取默认账户(Stage 1 单一账户,即第一条)。
  Future<AccountEntry?> getDefault() {
    return (select(accounts)..limit(1)).getSingleOrNull();
  }

  Future<int> insertAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }
}
