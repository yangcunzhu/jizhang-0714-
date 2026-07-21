// StatisticsDao — D28 ADR-0033 实施
//
// 收支/预算统计过滤 toggle(ADR-0033 §决策 3)。
// 账户余额 = 真实状态(不过滤,accountDao.getById 已实现)— toggle 只影响"展示"。
//
// 5 方法:
// 1. getMonthlyIncome — 过滤 type=income + excludeFromIncomeExpense=false
// 2. getMonthlyExpense — 过滤 type=expense + excludeFromIncomeExpense=false
// 3. getMonthlyBalance — income - expense(本月净额)
// 4. getCategoryBudgetUsed — 过滤 type=expense + categoryId + excludeFromBudget=false(S04 预算前置)
// 5. getMonthlyStats — 聚合 record(MonthlyStatsSnapshot)— 主页卡片用
//
// ⚠️ M 互斥:D26 refund 自动 excludeFromIncomeExpense=true(此 DAO 自动过滤)。

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'statistics_dao.g.dart';

/// 月度统计快照(主页卡片 S05 占位 v0 + D28 接入)。
class MonthlyStatsSnapshot {
  const MonthlyStatsSnapshot({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
    required this.transactionCount,
    required this.excludedCount,
  });

  final DateTime month;
  final int incomeCents;
  final int expenseCents;
  final int transactionCount;
  final int excludedCount;

  int get balanceCents => incomeCents - expenseCents;

  /// 格式:¥1,234
  String get incomeYuan =>
      '¥${(incomeCents ~/ 100).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}.${(incomeCents.abs() % 100).toString().padLeft(2, '0')}';

  String get expenseYuan =>
      '¥${(expenseCents ~/ 100).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}.${(expenseCents.abs() % 100).toString().padLeft(2, '0')}';

  String get balanceYuan =>
      '¥${(balanceCents ~/ 100).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}.${(balanceCents.abs() % 100).toString().padLeft(2, '0')}';

  @override
  String toString() =>
      'MonthlyStats($month: income=$incomeCents expense=$expenseCents balance=$balanceCents '
      'count=$transactionCount excluded=$excludedCount)';
}

@DriftAccessor(tables: [Transactions])
class StatisticsDao extends DatabaseAccessor<AppDatabase>
    with _$StatisticsDaoMixin {
  StatisticsDao(super.db);

  /// 本月起止时间戳(`[start, end)`)。
  (DateTime, DateTime) _monthRange(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (start, end);
  }

  /// 月度收入(分)— 过滤 type=income + excludeFromIncomeExpense=false。
  Future<int> getMonthlyIncome(DateTime month) async {
    final (start, end) = _monthRange(month);
    final rows = await (select(transactions)
          ..where((t) =>
              t.type.equals(TransactionType.income.name) &
              t.occurredAt.isBiggerOrEqualValue(start) &
              t.occurredAt.isSmallerThanValue(end) &
              t.excludeFromIncomeExpense.equals(false)))
        .get();
    return rows.fold<int>(0, (sum, t) => sum + t.amountCents);
  }

  /// 月度支出(分)— 过滤 type=expense + excludeFromIncomeExpense=false。
  Future<int> getMonthlyExpense(DateTime month) async {
    final (start, end) = _monthRange(month);
    final rows = await (select(transactions)
          ..where((t) =>
              t.type.equals(TransactionType.expense.name) &
              t.occurredAt.isBiggerOrEqualValue(start) &
              t.occurredAt.isSmallerThanValue(end) &
              t.excludeFromIncomeExpense.equals(false)))
        .get();
    return rows.fold<int>(0, (sum, t) => sum + t.amountCents);
  }

  /// 月度净额 = income - expense。
  Future<int> getMonthlyBalance(DateTime month) async {
    final income = await getMonthlyIncome(month);
    final expense = await getMonthlyExpense(month);
    return income - expense;
  }

  /// 分类预算已用(分)— 过滤 type=expense + categoryId + excludeFromBudget=false。
  ///
  /// WHY 单独:excludeFromBudget 仅影响预算计算,不影响 monthly income/expense。
  /// (语义"这笔花了钱,影响账户余额 + 收支统计,但不是分类预算"= 大件消费)
  Future<int> getCategoryBudgetUsed(int categoryId, DateTime month) async {
    final (start, end) = _monthRange(month);
    final rows = await (select(transactions)
          ..where((t) =>
              t.type.equals(TransactionType.expense.name) &
              t.categoryId.equals(categoryId) &
              t.occurredAt.isBiggerOrEqualValue(start) &
              t.occurredAt.isSmallerThanValue(end) &
              t.excludeFromBudget.equals(false)))
        .get();
    return rows.fold<int>(0, (sum, t) => sum + t.amountCents);
  }

  /// 月度统计快照 — 主页卡片 + D29 整合验证用。
  ///
  /// 一次性查 4 query(income/expense/excluded count/transaction count)→ 主页
  /// 用 1 次 FutureBuilder 比 4 个独立 query 快(Riverpod autoDispose)。
  Future<MonthlyStatsSnapshot> getMonthlyStats(DateTime month) async {
    final (start, end) = _monthRange(month);

    // 4 个并行 query — drift 默认串行执行,但 SQLite 内 io 很快(本地 DB)
    final allRows = await (select(transactions)
          ..where((t) =>
              t.occurredAt.isBiggerOrEqualValue(start) &
              t.occurredAt.isSmallerThanValue(end)))
        .get();

    var income = 0;
    var expense = 0;
    var excluded = 0;
    var total = 0;
    for (final t in allRows) {
      total++;
      final isIncome = t.type == TransactionType.income;
      final isExpense = t.type == TransactionType.expense;
      final excludedIncome = isIncome && t.excludeFromIncomeExpense;
      final excludedExpense = isExpense && t.excludeFromIncomeExpense;
      final excludedBudget = isExpense && t.excludeFromBudget;
      if (excludedIncome || excludedExpense) excluded++;
      // 收支统计:income + income;expense + expense
      if (isIncome && !t.excludeFromIncomeExpense) {
        income += t.amountCents;
      } else if (isExpense && !t.excludeFromIncomeExpense) {
        expense += t.amountCents;
      }
      // 注意:excludeFromBudget 单独语义(不影响 income/expense)— 见 getCategoryBudgetUsed
      // 这里不再 exclude(excludedBudget 已单独加到 excluded count for UI 展示)
      if (excludedBudget && !excludedIncome && !excludedExpense) excluded++;
    }

    return MonthlyStatsSnapshot(
      month: month,
      incomeCents: income,
      expenseCents: expense,
      transactionCount: total,
      excludedCount: excluded,
    );
  }
}
