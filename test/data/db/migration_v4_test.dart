// Schema migration v3 → v4 测试(Stage 3 Day 18 — ADR-0021)。
//
// WHY: Stage 3 (S03) 在 Stage 2 (S02) 用户真机数据基础上,扩展 TransactionType
// enum 加 `repayment` 值,用于信用卡还款流(transaction)。必须保证:
// 1. schemaVersion 升级到 4
// 2. 旧 transaction.type='expense' / 'income' 完全保留,仍可读写
// 3. 新 transaction.type='repayment' 可正常写入 + 读出
// 4. v3 → v4 升级路径稳定(模拟用户从 S02 build 升级到 S03 build)
//
// 测试策略:用 file-based NativeDatabase,创 v4 schema + DROP 表 + 用 raw SQL
// 重建 v3 schema + seed 数据 + 改 user_version=3 + 重开 → Drift 触发 onUpgrade。
//
// 决策依据:ADR-0021 §「不可逆性」+ §「风险缓解」。

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Schema migration v3 → v4 (Stage 3 Day 18 — ADR-0021)', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('drift_migration_v4_');
      dbPath = p.join(tmpDir.path, 'test.sqlite');
    });

    tearDown(() async {
      if (await Directory(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await tmpDir.delete(recursive: true);
    });

    /// Step 1: 创 v4 schema(完整 onCreate 触发默认 seed)
    /// Step 2: DROP 表 + 用 raw SQL 重建 v3 schema + 灌入 S02 终态数据
    /// Step 3: 改 user_version=3,重开 → Drift 检测到旧版本 → 走 onUpgrade v3→v4
    Future<AppDatabase> bootstrapV3AndReopen() async {
      // Step 1: 用 AppDatabase 创 v4 schema(触发默认 seed)
      final db1 = AppDatabase.forTesting(NativeDatabase(File(dbPath)));

      // Step 2: 删 v4 表,按 S02 终态(D17 收尾)的 v3 schema 重建
      await db1.customStatement('DROP TABLE IF EXISTS transactions');
      await db1.customStatement('DROP TABLE IF EXISTS category_templates');
      await db1.customStatement('DROP TABLE IF EXISTS accounts');
      await db1.customStatement('DROP TABLE IF EXISTS categories');

      // accounts:与 v4 一致(v2 起就有全部字段,无迁移需求)
      await db1.customStatement('''
        CREATE TABLE accounts (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'cash',
          include_in_net_worth INTEGER NOT NULL DEFAULT 1,
          credit_limit INTEGER,
          billing_day INTEGER,
          due_day INTEGER,
          balance_cents INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');
      // categories:与 v4 一致
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
      // transactions:与 v4 一致(textEnum 存 TEXT 列,v3 / v4 完全相同)
      await db1.customStatement('''
        CREATE TABLE transactions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          account_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount_cents INTEGER NOT NULL,
          note TEXT,
          occurred_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');
      // category_templates:v3 schema 已有此表(D15 加的)
      await db1.customStatement('''
        CREATE TABLE category_templates (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');

      // seed S02 终态数据(刻意制造「用户已有数据」场景)
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents) VALUES ('现金', 50000)");
      await db1.customStatement(
          "INSERT INTO accounts (name, type, credit_limit, billing_day, due_day) VALUES ('招行信用卡', 'creditCard', 5000000, 5, 25)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('餐饮', '🍔', 4294932035, 'expense', 0)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('工资', '💰', 4253396954, 'income', 9)");
      // 写一笔历史支出交易(模拟 S02 已有流水)
      await db1.customStatement(
          "INSERT INTO transactions (account_id, category_id, type, amount_cents, note) VALUES (1, 1, 'expense', 2999, '午饭')");
      // 写一笔历史收入交易
      await db1.customStatement(
          "INSERT INTO transactions (account_id, category_id, type, amount_cents, note) VALUES (1, 2, 'income', 500000, '月薪')");

      // 把 user_version 写为 3(Drift 通过这个判断版本)
      await db1.customStatement('PRAGMA user_version = 3');
      await db1.close();

      // 重开同一 SQLite 文件 → Drift 检测 user_version=3 < schemaVersion=4 → 走 onUpgrade
      return AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    }

    test('schemaVersion = 9(累计升级:v4 repayment → v5 期数 → v6 账户模型 → v7 借贷双账户 → v8 D25 整合 5 ADR → v9 D27 24 分类完整版)', () {
      // WHY: v3→v4 ADR-0021(repayment),v4→v5 ADR-0024(installment_period),
      // v5→v6 ADR-0026(accounts 5 大类 × 23 子类模型),
      // v6→v7 D22 借贷 transactions 加 4 列,
      // v7→v8 D25 schema v8 整合 5 ADR(accounts +4 + transactions +6),
      // v8→v9 D27 ADR-0031+0032 24 分类完整版 seed(bump schemaVersion = 9)。
      // 验证当前 schemaVersion = 9。
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 9,
          reason: 'D27:schema v9 seed 24 分类(ADR-0031+0032),版本升至 9');
      db.close();
    });

    test('升级后旧 expense / income 交易完整保留', () async {
      final db = await bootstrapV3AndReopen();
      try {
        final txList = await db.select(db.transactions).get();
        expect(txList, hasLength(2),
            reason: 'S02 写的 2 笔交易(expense + income)全部保留');

        final expense =
            txList.firstWhere((t) => t.type == TransactionType.expense);
        expect(expense.amountCents, 2999);
        expect(expense.note, '午饭');

        final income =
            txList.firstWhere((t) => t.type == TransactionType.income);
        expect(income.amountCents, 500000);
        expect(income.note, '月薪');
      } finally {
        await db.close();
      }
    });

    test('升级后可写入新 repayment 类型交易', () async {
      final db = await bootstrapV3AndReopen();
      try {
        // 新增「还款」分类(决策 ADR-0021 §不可逆性 — 保持 categoryId NOT NULL 约束)
        await db.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('还款', '💳', 4286470082, 'expense', 10)",
        );

        // 写一笔还款交易(repayment 类型,categoryId=3)
        await db.customStatement(
          "INSERT INTO transactions (account_id, category_id, type, amount_cents, note) VALUES (1, 3, 'repayment', 100000, '还招行信用卡')",
        );

        // 读出验证
        final allTx = await db.select(db.transactions).get();
        expect(allTx, hasLength(3),
            reason: '旧 2 笔 + 新 1 笔还款 = 3 笔');

        final repaymentTx =
            allTx.firstWhere((t) => t.type == TransactionType.repayment);
        expect(repaymentTx.amountCents, 100000);
        expect(repaymentTx.note, '还招行信用卡');

        // 旧 expense / income 交易仍可读(不被新类型污染)
        expect(allTx.where((t) => t.type == TransactionType.expense),
            hasLength(1));
        expect(allTx.where((t) => t.type == TransactionType.income),
            hasLength(1));
        expect(allTx.where((t) => t.type == TransactionType.repayment),
            hasLength(1));
      } finally {
        await db.close();
      }
    });

    test('升级后旧账户 + 信用卡字段全部保留', () async {
      final db = await bootstrapV3AndReopen();
      try {
        final accounts = await db.accountDao.getAll();
        expect(accounts, hasLength(2));

        // IQA-fix2 (2026-08-12):D27 BUG-4 rename 老 S03 seed「现金」→「现金(储蓄)」,
        // v3 → v9 升级触发 if<6 subType 回填 + if<9 rename。
        final cash = accounts.firstWhere((a) => a.name == '现金(储蓄)');
        expect(cash.type, AccountType.cash);
        expect(cash.balanceCents, 50000);

        final creditCard = accounts.firstWhere((a) => a.name == '招行信用卡');
        expect(creditCard.type, AccountType.creditCard);
        expect(creditCard.creditLimit, 5000000);
        expect(creditCard.billingDay, 5);
        expect(creditCard.dueDay, 25);
      } finally {
        await db.close();
      }
    });

    test('Stage 3 全新安装(不走 onUpgrade)— 默认 seed 完整', () async {
      // 此路径不触发 onUpgrade,直接走 onCreate(v4)
      final freshPath = p.join(tmpDir.path, 'fresh.sqlite');
      final fresh = NativeDatabase(File(freshPath));
      try {
        final db = AppDatabase.forTesting(fresh);
        final accounts = await db.accountDao.getAll();
        expect(accounts, hasLength(1),
            reason: '全新安装只 seed 1 条「现金」账户');
        expect(accounts.single.name, '现金');

        // 模板元数据(S02 沿用)
        final templates = await db.categoryTemplateDao.getAllTemplates();
        expect(templates, hasLength(5));

        // 10 个默认分类(S01 沿用,v4 不影响 seed 列表)
        final categories = await db.categoryDao.getAll();
        expect(categories, hasLength(24));

        await db.close();
      } finally {
        if (await File(freshPath).exists()) {
          await File(freshPath).delete();
        }
      }
    });
  });
}