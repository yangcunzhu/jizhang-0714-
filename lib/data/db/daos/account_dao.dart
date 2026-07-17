import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts.dart';

part 'account_dao.g.dart';

/// 账户数据访问对象。
///
/// Stage 1: getAll / watchAll / getDefault / insertAccount
/// Stage 2 (ADR-0017): + update / delete / watchByType / 余额查询
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

  /// 按 ID 取账户。
  Future<AccountEntry?> getById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// 按 ID 监听单个账户变化(用于余额 / 字段实时更新)。
  Stream<AccountEntry?> watchById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).watchSingle();
  }

  /// 按 type 监听(主页账户分组、设置页筛选)。
  Stream<List<AccountEntry>> watchByType(AccountType type) {
    return (select(accounts)..where((a) => a.type.equalsValue(type)))
        .watch();
  }

  /// 取所有账户类型集合(去重,UI 切换器分类用)。
  Future<List<AccountType>> getDistinctTypes() async {
    final all = await getAll();
    return all.map((a) => a.type).toSet().toList();
  }

  /// 新增账户。
  Future<int> insertAccount(AccountsCompanion entry) {
    return into(accounts).insert(entry);
  }

  /// 按 ID 更新账户字段(返回受影响行数,0 表示 ID 不存在)。
  ///
  /// 入参 [entry.id] 必须已设置才能定位行,其他字段为 null/absent 时跳过。
  /// WHY: 用 companion 的"部分更新"语义 — 只改传入字段,不动其他列。
  /// 这样前端按字段表单独立提交时(如只改名称)无需先读再写全字段。
  Future<int> updateAccountById(AccountsCompanion entry) {
    final id = entry.id.value;
    return (update(accounts)..where((a) => a.id.equals(id))).write(entry);
  }

  /// 按 ID 删账户。
  ///
  /// 注意:有交易引用的账户删除会失败(外键约束,FK 由 beforeOpen 打开)。
  /// 调用方应先检查或提示用户。
  Future<int> deleteAccount(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  /// 按 ID 列表批量删除(账户合并 / 重置用)。
  Future<int> deleteAccountsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(accounts)..where((a) => a.id.isIn(ids))).go();
  }
}
