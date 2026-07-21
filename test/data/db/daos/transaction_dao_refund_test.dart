// TransactionDao.refundMoney 测试(D26 ADR-0030 + 用户拍板 Q2=B + Q3=B + Q4=α2)
//
// 覆盖范围(8 用例):
// 1. 正常 expense 退款 + 余额联动
// 2. 嵌套退款拒绝(refund 对 refund)
// 3. 单笔超限拒绝(amount > original)
// 4. 累计超限拒绝(sum + amount > original,多次拆分退款保护)
// 5. income 拒绝退款
// 6. repayment 允许退款(2026-08-09 Q2=B 拍板,从 v4 §P0-05 "只 expense"扩展)
// 7. lend 允许退款(同上)
// 8. refundTime 落库(occurredAt == refundTime,C6 fix)
// 9. 拆分退款 → DAO getRefundedAmount 返回累加总额(SUM 查)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('TransactionDao.refundMoney — D26 (ADR-0030 §决策 3 修订版)', () {
    late AppDatabase db;
    late int cashAccountId;
    late int creditCardAccountId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      cashAccountId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '现金',
          type: const Value(AccountType.cash),
          balanceCents: const Value(100000), // 1000 元
        ),
      );
      creditCardAccountId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: const Value(AccountType.creditCard),
          balanceCents: const Value(0),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    // ────────────────────────────────────────────────────────────────
    // 1. 正常 expense 退款
    // ────────────────────────────────────────────────────────────────

    test('正常 expense -¥8.96 退款 → 现金账户 +¥8.96 + 写 refund transaction',
        () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 896,
        ),
      );
      // 退款前余额:1000 - 8.96 = 991.04
      final beforeCash = await db.accountDao.getById(cashAccountId);
      expect(beforeCash!.balanceCents, 100000 - 896);

      final refundTime = DateTime(2026, 8, 9, 22, 22);
      final refundId = await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 896,
        refundTime: refundTime,
        refundNote: '占位-退款原因',
      );

      // 1) 现金账户余额 +896 = 991.04 + 8.96 = 1000.00(净值归零)
      final afterCash = await db.accountDao.getById(cashAccountId);
      expect(afterCash!.balanceCents, 100000,
          reason: '退款回滚原 -amount,净值归零');

      // 2) refund transaction 落库
      final refund = await db.transactionDao.getById(refundId);
      expect(refund, isNotNull);
      expect(refund!.type, TransactionType.refund);
      expect(refund.amountCents, 896);
      expect(refund.occurredAt, refundTime,
          reason: 'C6 fix:occurredAt 用 refundTime 非 now');
      expect(refund.originalTransactionId, originalId,
          reason: '关联交易引用落库');
      expect(refund.refundNote, '占位-退款原因');
    });

    // ────────────────────────────────────────────────────────────────
    // 2. 嵌套退款拒绝(refund 对 refund)
    // ────────────────────────────────────────────────────────────────

    test('嵌套退款拒绝(refund 对 refund → StateError)', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 1000,
        ),
      );
      // 先做一次完整退款
      final firstRefundId = await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 1000,
        refundTime: DateTime(2026, 8, 1),
      );
      // 再对 refund 行退款 — 应抛 StateError
      await expectLater(
        db.transactionDao.refundMoney(
          originalTransactionId: firstRefundId,
          refundAccountId: cashAccountId,
          amountCents: 1000,
          refundTime: DateTime(2026, 8, 2),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('不能对退款记录再退款'),
        )),
      );
    });

    // ────────────────────────────────────────────────────────────────
    // 3. 单笔超限拒绝
    // ────────────────────────────────────────────────────────────────

    test('单笔超限拒绝(amount > original → StateError)', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 1000, // 原 ¥10
        ),
      );
      await expectLater(
        db.transactionDao.refundMoney(
          originalTransactionId: originalId,
          refundAccountId: cashAccountId,
          amountCents: 2000, // 退 ¥20,超限
          refundTime: DateTime(2026, 8, 1),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('单笔退款金额不能超过'),
        )),
      );
      // 余额不变(事务回滚)
      final cash = await db.accountDao.getById(cashAccountId);
      expect(cash!.balanceCents, 100000 - 1000);
      final refunded = await db.transactionDao.getRefundedAmount(originalId);
      expect(refunded, 0,
          reason: '事务回滚,无 refund 写入');
    });

    // ────────────────────────────────────────────────────────────────
    // 4. 累计超限拒绝(多次拆分退款保护)
    // ────────────────────────────────────────────────────────────────

    test('累计超限拒绝(已退 ¥8 + 退 ¥5 > ¥10 → StateError)', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 1000, // 原 ¥10
        ),
      );
      // 第一次退 ¥8 → 成功
      await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 800,
        refundTime: DateTime(2026, 8, 1),
      );
      // 第二次退 ¥5 → 累计 1300 > 1000,抛 StateError
      await expectLater(
        db.transactionDao.refundMoney(
          originalTransactionId: originalId,
          refundAccountId: cashAccountId,
          amountCents: 500,
          refundTime: DateTime(2026, 8, 2),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('累计退款金额超限'),
        )),
      );
      // 但 getRefundedAmount 应返回 800(第一次成功的不被回滚)
      final refunded = await db.transactionDao.getRefundedAmount(originalId);
      expect(refunded, 800,
          reason: '第一次退款已落库,第二次抛 StateError 但第一次还在');
    });

    // ────────────────────────────────────────────────────────────────
    // 5. income 拒绝退款
    // ────────────────────────────────────────────────────────────────

    test('income 类型拒绝退款(→ StateError)', () async {
      final salaryCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '工资');
      final incomeId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: salaryCategory.id,
          type: TransactionType.income,
          amountCents: 50000, // ¥500 工资
        ),
      );
      await expectLater(
        db.transactionDao.refundMoney(
          originalTransactionId: incomeId,
          refundAccountId: cashAccountId,
          amountCents: 50000,
          refundTime: DateTime(2026, 8, 1),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('只能对支出/还款/借贷'),
        )),
      );
    });

    // ────────────────────────────────────────────────────────────────
    // 6. repayment 允许退款(2026-08-09 Q2=B 拍板扩展)
    // ────────────────────────────────────────────────────────────────

    test('repayment 类型允许退款(Q2=B 拍板扩展)', () async {
      // 先 seed 一个 type=repayment '还款' 分类(fresh install 没自动 seed)
      final repaymentCategoryId = await db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: '还款',
          iconName: '💳',
          colorValue: 4286470082,
          type: TransactionType.repayment,
        ),
      );
      // 写还款原 transaction
      final repaymentOriginalId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: repaymentCategoryId,
          type: TransactionType.repayment,
          amountCents: 50000, // ¥500
        ),
      );
      // 对 repayment 退款
      final refundId = await db.transactionDao.refundMoney(
        originalTransactionId: repaymentOriginalId,
        refundAccountId: cashAccountId,
        amountCents: 50000,
        refundTime: DateTime(2026, 8, 1),
      );
      final refund = await db.transactionDao.getById(refundId);
      expect(refund!.type, TransactionType.refund);
      expect(refund.originalTransactionId, repaymentOriginalId);
    });

    // ────────────────────────────────────────────────────────────────
    // 7. lend 允许退款(同上)
    // ────────────────────────────────────────────────────────────────

    test('lend 类型允许退款(Q2=B 拍板扩展)', () async {
      // 先 seed type=lend '借出' 分类
      final lendCategoryId = await db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: '借出',
          iconName: '📤',
          colorValue: 4294739011,
          type: TransactionType.lend,
        ),
      );
      // 建借贷借出账户
      final lendAccountId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出-张三',
          subType: const Value(AccountSubType.lendOut),
          balanceCents: const Value(10000), // ¥100 借出应收
        ),
      );
      // 建借出 transaction(简化:不走 lendMoney,直接 insert)
      final lendOriginalId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: lendAccountId,
          categoryId: lendCategoryId,
          type: TransactionType.lend,
          amountCents: 10000, // ¥100
        ),
      );
      // 对 lend 退款
      final refundId = await db.transactionDao.refundMoney(
        originalTransactionId: lendOriginalId,
        refundAccountId: cashAccountId,
        amountCents: 10000,
        refundTime: DateTime(2026, 8, 1),
      );
      final refund = await db.transactionDao.getById(refundId);
      expect(refund!.type, TransactionType.refund);
      expect(refund.originalTransactionId, lendOriginalId);
    });

    // ────────────────────────────────────────────────────────────────
    // 8. refundTime 落库(C6 fix)
    // ────────────────────────────────────────────────────────────────

    test('refundTime 落库(occurredAt == refundTime,非 now)', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 500,
        ),
      );
      final customRefundTime = DateTime(2025, 12, 25, 14, 30);
      final refundId = await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 500,
        refundTime: customRefundTime,
      );
      final refund = await db.transactionDao.getById(refundId);
      expect(refund!.occurredAt, customRefundTime,
          reason: 'C6 fix:occurredAt 必须用用户选的时间(refundTime)');
    });

    // ────────────────────────────────────────────────────────────────
    // 9. 拆分退款 + getRefundedAmount 累加(SUM 查)
    // ────────────────────────────────────────────────────────────────

    test('拆分退款 + getRefundedAmount SUM 累加', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final originalId = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: cashAccountId,
          categoryId: mealCategory.id,
          type: TransactionType.expense,
          amountCents: 1000, // ¥10
        ),
      );
      // 第一次退 ¥3
      await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 300,
        refundTime: DateTime(2026, 8, 1),
      );
      expect(await db.transactionDao.getRefundedAmount(originalId), 300);
      // 第二次退 ¥4
      await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 400,
        refundTime: DateTime(2026, 8, 2),
      );
      expect(await db.transactionDao.getRefundedAmount(originalId), 700,
          reason: '300 + 400 = 700');
      // 第三次退 ¥2(再累计 900 ≤ 1000 OK)
      await db.transactionDao.refundMoney(
        originalTransactionId: originalId,
        refundAccountId: cashAccountId,
        amountCents: 200,
        refundTime: DateTime(2026, 8, 3),
      );
      expect(await db.transactionDao.getRefundedAmount(originalId), 900);

      // 验证数据库真有 3 条 refund rows
      final allRefunds = await (db.select(db.transactions)
            ..where((t) => t.originalTransactionId.equals(originalId)))
          .get();
      expect(allRefunds, hasLength(3),
          reason: '3 笔独立 refund transaction,各自 originalTransactionId=原 ID');
    });
  });
}
