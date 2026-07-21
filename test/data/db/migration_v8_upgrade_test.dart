// Schema migration v7 → v8 真升级路径测试(IQA M4 修复)。
//
// WHY: migration_v8_test.dart 只验证 fresh install 字段读写,不验证 onUpgrade
// 触发路径。本测试复制 migration_v4_test.dart 模式,用 file-based DB:
// 1. 创 v8 schema(完整 onCreate 触发默认 seed)
// 2. DROP + 用 raw SQL 重建 v7 schema(23 字段 accounts + 12 字段 transactions)
// 3. seed v7 终态数据(含 lend/borrow transactions)
// 4. user_version=7,close + 重开 → Drift 走 onUpgrade from<8 块加 10 列
// 5. 验证旧数据完整保留 + 新列存在 + 默认值正确

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Schema migration v7 → v8 真升级路径(D25 IQA M4 修复)', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('drift_migration_v8_');
      dbPath = p.join(tmpDir.path, 'test.sqlite');
    });

    tearDown(() async {
      if (await Directory(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await tmpDir.delete(recursive: true);
    });

    /// Bootstrap v7 schema + seed + 改 user_version=7,重开触发 v7→v8 onUpgrade。
    Future<AppDatabase> bootstrapV7AndReopen() async {
      // Step 1: 用 AppDatabase 创 v8 schema(触发默认 seed)
      final db1 = AppDatabase.forTesting(NativeDatabase(File(dbPath)));

      // Step 2: 删 v8 表,按 D22 收尾的 v7 schema 重建
      await db1.customStatement('DROP TABLE IF EXISTS transactions');
      await db1.customStatement('DROP TABLE IF EXISTS category_templates');
      await db1.customStatement('DROP TABLE IF EXISTS accounts');
      await db1.customStatement('DROP TABLE IF EXISTS categories');

      // categories:v7 与 v8 一致(种子数据有 10 个 + D20 v5+ 加的)
      await db1.customStatement('''
        CREATE TABLE categories (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          type TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');

      // accounts:v7 schema(D22 收尾)— 无 v8 新加 4 字段
      await db1.customStatement('''
        CREATE TABLE accounts (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          balance_cents INTEGER NOT NULL DEFAULT 0,
          type TEXT NOT NULL DEFAULT 'cash',
          sub_type TEXT,
          brand_name TEXT,
          include_in_net_worth INTEGER NOT NULL DEFAULT 1,
          is_pinned INTEGER NOT NULL DEFAULT 0,
          is_default_income_account INTEGER NOT NULL DEFAULT 0,
          is_default_expense_account INTEGER NOT NULL DEFAULT 0,
          credit_limit INTEGER,
          initial_debt_cents INTEGER,
          billing_day INTEGER,
          due_day INTEGER,
          start_date INTEGER,
          due_date INTEGER,
          counterparty_name TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');

      // transactions:v7 schema(D22)— 无 v8 新加 6 字段
      await db1.customStatement('''
        CREATE TABLE transactions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          amount_cents INTEGER NOT NULL,
          type TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          account_id INTEGER NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          occurred_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          installment_period INTEGER,
          from_account_id INTEGER,
          to_account_id INTEGER,
          counterparty_name TEXT,
          start_date INTEGER,
          CHECK (amount_cents > 0)
        )
      ''');

      // category_templates:v7 schema
      await db1.customStatement('''
        CREATE TABLE category_templates (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');

      // seed v7 终态数据:现金 + 借出/借入账户 + lend transaction(模拟 D22 后用户数据)
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents, type, sub_type) VALUES ('现金', 50000, 'cash', 'cash')");
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents, type, sub_type) VALUES ('储蓄卡', 100000, 'savings', 'savingsCard')");
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents, type, sub_type, counterparty_name, due_date) VALUES ('借出账户', 0, 'savings', 'lendOut', '占位-借款人', 1798761600)"); // 2027-01-01
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('餐饮', '🍔', 4294932035, 'expense', 0)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('借出', '📤', 4294932035, 'lend', 0)");
      // 写一笔 v7 历史 lend transaction(双账户 + counterpartyName + startDate)
      await db1.customStatement('''
        INSERT INTO transactions
          (amount_cents, type, category_id, account_id, note,
           from_account_id, to_account_id, counterparty_name, start_date)
        VALUES (30000, 'lend', 2, 1, '借出给占位-借款人', 1, 3, '占位-借款人', 1736899200)
      '''); // start_date=2025-01-15

      // user_version=7,close + 重开 → Drift 走 onUpgrade from<8 块
      await db1.customStatement('PRAGMA user_version = 7');
      await db1.close();

      return AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    }

    test('v7 → v8 onUpgrade 触发后 schemaVersion = 8', () async {
      final db = await bootstrapV7AndReopen();
      expect(db.schemaVersion, 8);
      await db.close();
    });

    test('v7 旧 accounts 数据完整保留 + 4 新字段默认 null', () async {
      final db = await bootstrapV7AndReopen();
      final all = await db.accountDao.getAll();
      expect(all, hasLength(3), reason: 'v7 seed 3 个账户全部保留');

      // 验证 lendOut 账户的 v7 字段保留 + v8 新加字段为 null
      final lendOut = all.firstWhere((a) => a.name == '借出账户');
      expect(lendOut.subType, AccountSubType.lendOut);
      expect(lendOut.counterpartyName, '占位-借款人');
      expect(lendOut.dueDate, isNotNull);
      // v8 新加字段(迁移后默认 null)
      expect(lendOut.initialLendBalanceCents, isNull);
      expect(lendOut.initialTime, isNull);
      expect(lendOut.lendCounterpartyName, isNull);
      expect(lendOut.lendDueDate, isNull);
      await db.close();
    });

    test('v7 旧 lend transaction 完整保留 + 6 新字段默认 null/false',
        () async {
      final db = await bootstrapV7AndReopen();
      final all = await db.transactionDao.getAll();
      expect(all, hasLength(1), reason: 'v7 seed 1 笔 lend transaction 保留');

      final tx = all.first;
      // v7 字段保留
      expect(tx.amountCents, 30000);
      expect(tx.type, TransactionType.lend);
      expect(tx.fromAccountId, 1);
      expect(tx.toAccountId, 3);
      expect(tx.counterpartyName, '占位-借款人');
      expect(tx.startDate, isNotNull);
      // v8 新加字段(迁移后默认 null/false)
      expect(tx.lendStartDate, isNull);
      expect(tx.lendEndDate, isNull);
      expect(tx.originalTransactionId, isNull);
      expect(tx.refundNote, isNull);
      expect(tx.excludeFromIncomeExpense, isFalse);
      expect(tx.excludeFromBudget, isFalse);
      await db.close();
    });

    test('v7 → v8 升级后可写新字段(往返验证)', () async {
      final db = await bootstrapV7AndReopen();
      // 拿到 v7 seed 的 lendOut 账户 + lend transaction
      final lendOut = (await db.accountDao.getAll())
          .firstWhere((a) => a.subType == AccountSubType.lendOut);

      // 用 dao 写新字段(虽然账户已存在,这里验证 v8 schema 支持写新字段)
      await db.accountDao.updateAccountById(
        AccountsCompanion(
          id: Value(lendOut.id),
          initialLendBalanceCents: const Value(50000),
          initialTime: Value(DateTime(2025, 1, 1)),
        ),
      );

      // 直接 insert 一笔带 v8 新字段的 transaction
      final cats = await db.categoryDao.getAll();
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amountCents: 10000,
              type: TransactionType.lend,
              categoryId: cats.first.id,
              accountId: 1,
              lendStartDate: Value(DateTime(2025, 1, 1)),
              lendEndDate: Value(DateTime(2026, 1, 1)),
              excludeFromIncomeExpense: const Value(true),
            ),
          );

      // 验证写成功
      final updated = await db.accountDao.getById(lendOut.id);
      expect(updated!.initialLendBalanceCents, 50000);
      expect(updated.initialTime, DateTime(2025, 1, 1));

      final allTx = await db.transactionDao.getAll();
      expect(allTx, hasLength(2), reason: 'v7 1 笔 + v8 新写 1 笔');
      final newTx = allTx.firstWhere((t) => t.amountCents == 10000);
      expect(newTx.lendStartDate, DateTime(2025, 1, 1));
      expect(newTx.lendEndDate, DateTime(2026, 1, 1));
      expect(newTx.excludeFromIncomeExpense, isTrue);
      await db.close();
    });
  });
}
