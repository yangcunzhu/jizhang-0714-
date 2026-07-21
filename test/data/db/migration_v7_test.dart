// Schema migration v6 → v7 测试(D22 ADR-0026 借出/借入落地)。
//
// 验证:
// - schemaVersion = 7
// - transactions 表新增 4 列(fromAccountId / toAccountId / counterpartyName / startDate)
// - 新 lend / borrow transaction 可写双账户字段

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('Schema migration v6 → v7 (D22 — 借出/借入双账户)', () {
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

    test('schemaVersion = 7', () {
      expect(db.schemaVersion, 8);
    });

    test('transactions 表有 fromAccountId / toAccountId / startDate / counterpartyName 列(默认 null)',
        () async {
      final cats = await db.categoryDao.getAll();
      final id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 1000,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: cashId,
        ),
      );
      final tx = await db.transactionDao.getById(id);
      expect(tx, isNotNull);
      expect(tx!.fromAccountId, isNull);
      expect(tx.toAccountId, isNull);
      expect(tx.startDate, isNull);
      expect(tx.counterpartyName, isNull);
    });

    test('lend transaction 可写双账户字段 + 起始时间', () async {
      final fundId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '储蓄卡',
          subType: const Value(AccountSubType.savingsCard),
          balanceCents: const Value(50000),
        ),
      );
      final lendId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出账户',
          subType: const Value(AccountSubType.lendOut),
        ),
      );
      final txId = await db.transactionDao.lendMoney(
        fromAccountId: fundId,
        toAccountId: lendId,
        amountCents: 10000,
        counterparty: '占位-某人',
        startDate: DateTime(2026, 1, 15),
      );
      final tx = await db.transactionDao.getById(txId);
      expect(tx!.fromAccountId, fundId);
      expect(tx.toAccountId, lendId);
      expect(tx.counterpartyName, '占位-某人');
      expect(tx.startDate, DateTime(2026, 1, 15));
      expect(tx.type, TransactionType.lend);
    });
  });
}