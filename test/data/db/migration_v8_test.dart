// Schema migration v7 → v8 测试(Stage 3 D25 — 5 ADR 协同)。
//
// 验证 schema v8 整合覆盖:
// - accounts +4 字段(ADR-0029 借贷):initialLendBalanceCents / initialTime /
//   lendCounterpartyName / lendDueDate — 全部 nullable
// - transactions +2 借贷(ADR-0029):lendStartDate / lendEndDate — 全部 nullable
// - transactions +2 退款(ADR-0030):originalTransactionId / refundNote — 全部 nullable
// - transactions +2 toggle(ADR-0033):excludeFromIncomeExpense / excludeFromBudget —
//   默认 false
//
// WHY 不做真 v7→v8 升级模拟:NativeDatabase.memory() 不能 close 后重开
// (migration_v5_test 已记录此限制),沿用 v6/v7 测试的「fresh install + 直接验证
// schema/字段」模式。v7 旧数据零影响靠字段 nullable/default 保证。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('Schema migration v7 → v8 (D25 — 5 ADR 协同)', () {
    late AppDatabase db;
    late int cashId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.accountDao.getDefault();
      cashId = (await db.accountDao.getAll()).first.id;
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion = 8', () {
      expect(db.schemaVersion, 8);
    });

    test('accounts 加 4 借贷字段(ADR-0029)— nullable 默认 null', () async {
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出账户',
          subType: const Value(AccountSubType.lendOut),
        ),
      );
      final acc = await db.accountDao.getById(id);
      expect(acc, isNotNull);
      expect(acc!.initialLendBalanceCents, isNull,
          reason: '起始余额字段 nullable,v7 旧数据 NULL 兜底');
      expect(acc.initialTime, isNull,
          reason: '起始时间字段 nullable,v7 旧数据 NULL 兜底');
      expect(acc.lendCounterpartyName, isNull,
          reason: '借贷对手方字段 nullable,与现有 counterpartyName 语义重叠');
      expect(acc.lendDueDate, isNull,
          reason: '借贷到期日字段 nullable,与现有 dueDate 语义重叠');
    });

    test('transactions 加 6 字段(ADR-0029 借贷 + 0030 退款 + 0033 toggle)— '
        '4 nullable 默认 null + 2 toggle 默认 false', () async {
      final cats = await db.categoryDao.getAll();
      final txId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 1000,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: cashId,
        ),
      );
      final tx = await db.transactionDao.getById(txId);
      expect(tx, isNotNull);

      // ADR-0029 借贷
      expect(tx!.lendStartDate, isNull);
      expect(tx.lendEndDate, isNull);

      // ADR-0030 退款
      expect(tx.originalTransactionId, isNull);
      expect(tx.refundNote, isNull);

      // ADR-0033 toggle(默认 false)
      expect(tx.excludeFromIncomeExpense, isFalse);
      expect(tx.excludeFromBudget, isFalse);
    });

    test('accounts 借贷 4 字段可写可读(整合)', () async {
      final start = DateTime(2026, 1, 15);
      final due = DateTime(2026, 7, 15);
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出-张三',
          subType: const Value(AccountSubType.lendOut),
          initialLendBalanceCents: const Value(50000),
          initialTime: Value(start),
          lendCounterpartyName: const Value('占位-借款人'),
          lendDueDate: Value(due),
        ),
      );
      final acc = await db.accountDao.getById(id);
      expect(acc!.initialLendBalanceCents, 50000,
          reason: '整数分存储(修正 ADR §决策 2 字面 RealColumn)');
      expect(acc.initialTime, start);
      expect(acc.lendCounterpartyName, '占位-借款人');
      expect(acc.lendDueDate, due);
    });

    test('transactions 借贷/退款/toggle 6 字段可写可读(整合)', () async {
      final cats = await db.categoryDao.getAll();
      final lendStart = DateTime(2026, 1, 15);
      final lendEnd = DateTime(2026, 7, 15);
      // 先写一个原 transaction(给退款引用)
      final originalId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 5000,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: cashId,
        ),
      );
      // 再写一个带全部 6 新字段的 transaction
      final txId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 3000,
          type: TransactionType.lend,
          categoryId: cats.first.id,
          accountId: cashId,
          lendStartDate: Value(lendStart),
          lendEndDate: Value(lendEnd),
          originalTransactionId: Value(originalId),
          refundNote: const Value('占位-退款原因'),
          excludeFromIncomeExpense: const Value(true),
          excludeFromBudget: const Value(true),
        ),
      );
      final tx = await db.transactionDao.getById(txId);
      expect(tx!.lendStartDate, lendStart);
      expect(tx.lendEndDate, lendEnd);
      expect(tx.originalTransactionId, originalId);
      expect(tx.refundNote, '占位-退款原因');
      expect(tx.excludeFromIncomeExpense, isTrue);
      expect(tx.excludeFromBudget, isTrue);
    });

    // D26 P1-11 (ADR-0030 + IQA C8):type=refund 真路径测试 — textEnum 落库
    test('type=refund 真路径落库(D26 ADR-0030 + IQA C8 修复)', () async {
      final cats = await db.categoryDao.getAll();
      // 原 transaction(给退款引用)
      final originalId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 896,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: cashId,
        ),
      );
      // refund transaction(type=refund + originalTransactionId + refundNote)
      final refundId = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 896,
          type: TransactionType.refund,
          categoryId: cats.first.id,
          accountId: cashId,
          originalTransactionId: Value(originalId),
          refundNote: const Value('占位-退款'),
        ),
      );
      final refund = await db.transactionDao.getById(refundId);
      expect(refund, isNotNull);
      expect(refund!.type, TransactionType.refund,
          reason: 'textEnum 存 enum.name = "refund"(D26 加值)');
      expect(refund.originalTransactionId, originalId,
          reason: '关联交易引用落库');
      expect(refund.refundNote, '占位-退款');
    });
  });
}
