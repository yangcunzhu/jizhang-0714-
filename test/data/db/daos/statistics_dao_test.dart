// StatisticsDao 测试(D28 ADR-0033)
//
// 6 用例覆盖:
// 1. 月度收入默认 toggle=false 全计入
// 2. excludeFromIncomeExpense=true 收入不计入
// 3. 月度支出同理
// 4. 月度边界(上月/本月/下月)— 不混入跨月数据
// 5. excludeFromBudget=true 单笔预算不计入 + 但仍计入收支
// 6. 退款 transaction 自动 excludeFromIncomeExpense=true(ADR-0033 §衔接下游)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/daos/statistics_dao.dart' show MonthlyStatsSnapshot;
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('StatisticsDao — D28 ADR-0033', () {
    late AppDatabase db;
    late int cashId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      cashId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '现金',
          type: const Value(AccountType.cash),
          balanceCents: const Value(1000000),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// seed 一笔 expense transaction(可指定 amount + toggle)
    Future<int> insertExpense({
      int amountCents = 10000, // ¥100
      required DateTime when,
      bool excludeFromIncomeExpense = false,
      bool excludeFromBudget = false,
    }) async {
      final cat = (await db.categoryDao.getAll())
          .firstWhere((c) => c.type == TransactionType.expense);
      return db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashId,
          categoryId: cat.id,
          type: TransactionType.expense,
          amountCents: amountCents,
          occurredAt: Value(when),
          excludeFromIncomeExpense: Value(excludeFromIncomeExpense),
          excludeFromBudget: Value(excludeFromBudget),
        ),
      );
    }

    /// seed 一笔 income transaction
    Future<int> insertIncome({
      int amountCents = 50000, // ¥500
      required DateTime when,
      bool excludeFromIncomeExpense = false,
    }) async {
      final cat = (await db.categoryDao.getAll())
          .firstWhere((c) => c.type == TransactionType.income);
      return db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashId,
          categoryId: cat.id,
          type: TransactionType.income,
          amountCents: amountCents,
          occurredAt: Value(when),
          excludeFromIncomeExpense: Value(excludeFromIncomeExpense),
        ),
      );
    }

    test('1. 月度收入:toggle=false 全计入', () async {
      final now = DateTime(2026, 8, 15);
      await insertIncome(amountCents: 50000, when: now);
      await insertIncome(amountCents: 30000, when: now);
      // 第三笔本月:¥500 + ¥300 = ¥800 = 80000 cents
      expect(
        await db.statisticsDao.getMonthlyIncome(DateTime(2026, 8, 1)),
        80000,
        reason: '2 笔 income 各 ¥500 + ¥300,全计入',
      );
    });

    test('2. excludeFromIncomeExpense=true 收入不计入月度收入', () async {
      final now = DateTime(2026, 8, 15);
      await insertIncome(amountCents: 50000, when: now);
      // 第二笔 toggle=true(报销场景)— 不计入
      await insertIncome(
          amountCents: 50000, when: now, excludeFromIncomeExpense: true);
      expect(
        await db.statisticsDao.getMonthlyIncome(DateTime(2026, 8, 1)),
        50000,
        reason: '50000 + 0(被过滤)= 50000',
      );
    });

    test('3. 月度支出:excludeFromIncomeExpense=true 同样过滤', () async {
      final now = DateTime(2026, 8, 15);
      await insertExpense(amountCents: 10000, when: now);
      // 第二笔 expense toggle=true(代付场景)
      await insertExpense(
          amountCents: 8000,
          when: now,
          excludeFromIncomeExpense: true);
      expect(
        await db.statisticsDao.getMonthlyExpense(DateTime(2026, 8, 1)),
        10000,
        reason: 'expense 10000 + 0(被过滤)= 10000',
      );
    });

    test('4. 月度边界:跨月数据不混入(7月/8月/9月隔离)', () async {
      // 7月1笔 + 8月1笔 + 9月1笔
      await insertIncome(
          amountCents: 10000, when: DateTime(2026, 7, 15));
      await insertIncome(
          amountCents: 20000, when: DateTime(2026, 8, 15));
      await insertIncome(
          amountCents: 30000, when: DateTime(2026, 9, 15));
      // 8月只取 8月
      expect(
        await db.statisticsDao.getMonthlyIncome(DateTime(2026, 8, 1)),
        20000,
        reason: '7月 + 9月不混入 8月',
      );
    });

    test('5. excludeFromBudget=true 单笔预算过滤(但仍计入收支)',
        () async {
      final now = DateTime(2026, 8, 15);
      // 2 笔支出:
      await insertExpense(
          amountCents: 50000,
          when: now,
          excludeFromBudget: true); // 大件消费,不计预算
      await insertExpense(amountCents: 30000, when: now);
      // 收支统计:2 笔都计入(toggle 只影响预算)
      expect(await db.statisticsDao.getMonthlyExpense(DateTime(2026, 8, 1)),
          80000,
          reason: '预算 toggle 不影响收支统计,2 笔全计入');
      // 预算过滤:只算 1 笔
      final cats = await db.categoryDao.getAll();
      final expCat = cats.firstWhere(
          (c) => c.type == TransactionType.expense);
      expect(
        await db.statisticsDao
            .getCategoryBudgetUsed(expCat.id, DateTime(2026, 8, 1)),
        30000,
        reason: '¥500 toggle 不计预算 + ¥300 计入 = ¥300',
      );
    });

    test('6. 退款 transaction 自动 excludeFromIncomeExpense=true', () async {
      final now = DateTime(2026, 8, 15);
      final cat = (await db.categoryDao.getAll())
          .firstWhere((c) => c.type == TransactionType.expense);
      // 写一笔 expense ¥100 (8月15)
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashId,
          categoryId: cat.id,
          type: TransactionType.expense,
          amountCents: 10000,
          occurredAt: Value(now),
        ),
      );
      // 退 ¥40(8月20)— D28 联动:refund 自动 2 个 toggle = true
      await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashId,
        amountCents: 4000,
        refundTime: DateTime(2026, 8, 20),
      );
      final refund = (await db.transactionDao.getById(
          await db.select(db.transactions)
              .get()
              .then((rows) => rows.firstWhere((t) => t.type == TransactionType.refund)
                  .id)))!;
      expect(refund.excludeFromIncomeExpense, isTrue,
          reason: 'D28 联动:refund 自动 excludeFromIncomeExpense=true');
      expect(refund.excludeFromBudget, isTrue,
          reason: 'D28 联动:refund 自动 excludeFromBudget=true');
      // 收支统计:1 笔 expense 计入 + 1 笔 refund 被过滤
      expect(
        await db.statisticsDao.getMonthlyExpense(DateTime(2026, 8, 1)),
        10000,
        reason: 'expense ¥100 计入 + refund 0(被过滤) = ¥100',
      );
    });

    // D28 IQA-fix M-IQA-D28-3 + 4 (2026-08-11):formatter getter + empty 月份
    test('7. MonthlyStatsSnapshot incomeYuan 大数额千位分隔',
        () async {
      final snap = MonthlyStatsSnapshot(
        month: DateTime(2026, 8, 1),
        incomeCents: 12345678, // 123,456.78
        expenseCents: 0,
        transactionCount: 1,
        excludedCount: 0,
      );
      expect(snap.incomeYuan, '¥123,456.78',
          reason: '¥12,345,678 cents → ¥123,456.78');
    });

    test('8. MonthlyStatsSnapshot balanceYuan 负数 + 零处理', () async {
      final negSnap = MonthlyStatsSnapshot(
        month: DateTime(2026, 8, 1),
        incomeCents: 5000,
        expenseCents: 10000, // balance = -5000
        transactionCount: 2,
        excludedCount: 0,
      );
      expect(negSnap.balanceCents, -5000);
      expect(negSnap.balanceYuan, '¥-50.00',
          reason: '负数处理正确(整数除法 -50.00)');
      final zeroSnap = MonthlyStatsSnapshot(
        month: DateTime(2026, 8, 1),
        incomeCents: 0,
        expenseCents: 0,
        transactionCount: 0,
        excludedCount: 0,
      );
      expect(zeroSnap.balanceYuan, '¥0.00');
    });

    test('9. 空月份边界(无任何交易)— 全 0 cents', () async {
      final now = DateTime(2026, 8, 1);
      final snap = await db.statisticsDao.getMonthlyStats(now);
      // fresh install db 没任何 transaction → 空月份
      expect(snap.transactionCount, 0);
      expect(snap.incomeCents, 0);
      expect(snap.expenseCents, 0);
      expect(snap.balanceCents, 0);
      expect(snap.excludedCount, 0);
      expect(snap.balanceYuan, '¥0.00',
          reason: '空月份主页显示 ¥0.00');
    });
  });
}
