// Schema migration v1 → v2 测试。
//
// WHY: Stage 1 (S01) 用户真机数据(v1 schema)升级到 Stage 2 (S02) build 时,
// Drift 会发现 schemaVersion=1 → 2,触发 onUpgrade。必须保证:
// 1. Stage 1 已有账户 / 分类 / 交易数据全部保留
// 2. accounts 新字段自动获得合理默认值(type=cash, includeInNetWorth=true,
//    creditLimit/billingDay/dueDay=NULL — 现金账户不是信用卡)
// 3. transactions 外键完整(transactions.accountId 引用 accounts.id 不被破坏)
//
// 测试策略:用 file-based NativeDatabase,创 v2 schema 后改 user_version=1 +
// DROP/CREATE accounts 表模拟 v1 状态,重开同一 SQLite 文件 → Drift 触发 onUpgrade。
// 这是真实环境(用户真机升级)的迁移行为,因为 Drift 仅以 user_version 决定
// 走 onCreate 或 onUpgrade。
//
// 决策依据:ADR-0017 + S02 计划第 1 项 "Schema migration v2"

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Schema migration v1 → v2 (Stage 2 升级路径)', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() async {
      tmpDir =
          await Directory.systemTemp.createTemp('drift_migration_v2_');
      dbPath = p.join(tmpDir.path, 'test.sqlite');
    });

    tearDown(() async {
      if (await Directory(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await tmpDir.delete(recursive: true);
    });

    /// Step 1: 创 v2 schema + seed
    /// Step 2: 改 user_version=1 + DROP accounts + 重建 v1 + seed
    /// Step 3: 重开 → 触发 onUpgrade
    Future<AppDatabase> bootstrapV1AndReopen() async {
      // Step 1: 创 v2 schema(完整 onCreate)
      final db1 = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      await db1.customStatement('DROP TABLE IF EXISTS transactions');
      await db1.customStatement('DROP TABLE IF EXISTS accounts');
      await db1.customStatement('DROP TABLE IF EXISTS categories');

      // 严格按 Stage 1 (commit bfbfa13 之前)的 v1 schema 重建
      // accounts: id / name / balance_cents / created_at (无 type/includeInNetWorth/creditLimit 等)
      await db1.customStatement('''
        CREATE TABLE accounts (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          balance_cents INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
        )
      ''');
      // categories 与 v2 一致(v1 已有 type/sort_order/icon_name/color_value,不迁移)
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
      // transactions 与 v2 一致(v1 已有 account_id / category_id / type / amount 等)
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

      // seed Stage 1 默认数据(刻意制造"用户已有数据"场景)
      await db1.customStatement(
          "INSERT INTO accounts (name) VALUES ('现金')");
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents) VALUES ('备用钱包', 12345)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('餐饮', '🍔', 4294932035, 'expense', 0)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('工资', '💰', 4253396954, 'income', 9)");
      // 写一笔历史交易(account_id=1 现金,category_id=1 餐饮)
      await db1.customStatement(
          "INSERT INTO transactions (account_id, category_id, type, amount_cents, note) VALUES (1, 1, 'expense', 2999, '午饭')");

      // 把 user_version 写为 1(Drift 通过这个判断版本)
      await db1.customStatement('PRAGMA user_version = 1');
      await db1.close();

      // 重开同一 SQLite 文件 → Drift 检测 user_version=1 < schemaVersion=2 → 走 onUpgrade
      return AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    }

    test('现有账户自动归类 type=cash,信用卡字段全 NULL', () async {
      final db = await bootstrapV1AndReopen();
      try {
        final accounts = await db.accountDao.getAll();
        // seed 现金 + 备用钱包 = 2 行
        expect(accounts, hasLength(2));

        // 现金账户:Stage 1 seed,默认归类 cash
        final cash = accounts.firstWhere((a) => a.name == '现金');
        expect(cash.type, AccountType.cash,
            reason: 'ADR-0017:已有账户 type 默认 cash');
        expect(cash.includeInNetWorth, isTrue,
            reason: 'ADR-0017:默认值 true,理财类账户后续手动改');
        expect(cash.creditLimit, isNull);
        expect(cash.billingDay, isNull);
        expect(cash.dueDay, isNull);

        // 备用钱包账户同样自动归类,余额保留
        final backup = accounts.firstWhere((a) => a.name == '备用钱包');
        expect(backup.type, AccountType.cash);
        expect(backup.balanceCents, 12345,
            reason: 'balance_cents 原值保留,不被默认值覆盖');
        expect(backup.includeInNetWorth, isTrue);
        expect(backup.creditLimit, isNull);
      } finally {
        await db.close();
      }
    });

    test('upgrade 后分类 + 交易数据完全保留', () async {
      final db = await bootstrapV1AndReopen();
      try {
        // 分类保留
        final cats = await db.categoryDao.getAll();
        expect(cats.length, greaterThanOrEqualTo(2));
        final meal = cats.firstWhere((c) => c.name == '餐饮');
        expect(meal.type, TransactionType.expense);
        expect(meal.iconName, '🍔');

        // 交易保留
        final txList = await db.select(db.transactions).get();
        expect(txList, hasLength(1));
        expect(txList.single.amountCents, 2999);
        expect(txList.single.note, '午饭');
        expect(txList.single.accountId, 1,
            reason: '外键 accountId 保留指向原账户(不被 NULL 取代)');
        expect(txList.single.categoryId, 1);

        // 可以查到账户(确认没把历史账户清掉)
        final accounts = await db.accountDao.getAll();
        expect(accounts.map((a) => a.name), contains('现金'));
      } finally {
        await db.close();
      }
    });

    test('upgrade 后可正常新增信用卡账户(新字段支持)', () async {
      final db = await bootstrapV1AndReopen();
      try {
        final beforeCount = (await db.accountDao.getAll()).length;

        // 新增信用卡,带完整信用卡字段
        final newId = await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: '招行信用卡',
            type: Value(AccountType.creditCard),
            creditLimit: const Value(5000000),
            billingDay: const Value(5),
            dueDay: const Value(25),
          ),
        );

        final newAcc = await db.accountDao.getById(newId);
        expect(newAcc!.type, AccountType.creditCard);
        expect(newAcc.creditLimit, 5000000);
        expect(newAcc.billingDay, 5);
        expect(newAcc.dueDay, 25);

        // 旧账户仍可读,新账户并存
        final all = await db.accountDao.getAll();
        expect(all, hasLength(beforeCount + 1));
      } finally {
        await db.close();
      }
    });

    test('upgrade 后按 type 查询工作(watchByType)', () async {
      final db = await bootstrapV1AndReopen();
      try {
        // 已升级,默认都是 cash
        final cashList =
            await db.accountDao.watchByType(AccountType.cash).first;
        expect(cashList, hasLength(2)); // 现金 + 备用钱包

        // 信用卡账户原本不存在
        final cards =
            await db.accountDao.watchByType(AccountType.creditCard).first;
        expect(cards, isEmpty);

        // 新增一张信用卡后再查
        await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: '测试卡',
            type: Value(AccountType.creditCard),
            creditLimit: const Value(100),
          ),
        );
        final cardsAfter =
            await db.accountDao.watchByType(AccountType.creditCard).first;
        expect(cardsAfter, hasLength(1));
      } finally {
        await db.close();
      }
    });

    test('Stage 2 全新安装(不走 onUpgrade) — 默认 seed 1 条,字段均默认值', () async {
      // 此路径不触发 onUpgrade,直接走 onCreate(v2)
      final freshPath = p.join(tmpDir.path, 'fresh.sqlite');
      final fresh = NativeDatabase(File(freshPath));
      try {
        final db = AppDatabase.forTesting(fresh);
        final accounts = await db.accountDao.getAll();
        expect(accounts, hasLength(1),
            reason: '全新安装只 seed 1 条"现金"账户');
        expect(accounts.single.name, '现金');
        expect(accounts.single.type, AccountType.cash);
        expect(accounts.single.includeInNetWorth, isTrue);
        expect(accounts.single.creditLimit, isNull);
        await db.close();
      } finally {
        if (await File(freshPath).exists()) {
          await File(freshPath).delete();
        }
      }
    });
  });
}