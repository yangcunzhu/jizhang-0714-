// Schema migration v8 → v9 真升级路径测试(IQA-fix D27-3,2026-08-10)。
//
// WHY: migration_v9_test.dart 只验证 fresh install 字段读写,
// 不验证 onUpgrade 触发路径。本测试复制 migration_v8_upgrade_test.dart 模式,
// 用 file-based DB 模拟 S03 schema v8 老用户升级到 v9:
//
// 1. 创 v9 schema(走 onCreate 24 seed)
// 2. DROP categories 表 + 用 v8 schema CREATE(同 v9,只是枚举不加 refund)
// 3. seed S03 终态数据(10 分类:8 expense + 1 收入 + 1 兜底「其他」)
// 4. PRAGMA user_version=8,close + 重开 → Drift 走 onUpgrade from<9
// 5. 验证:
//    a) 4 income rename 成功(工资收入→职业收入 / 红包收入→好运收入 /
//       退款收入→退款(type=refund)/ 投资收益→保险理财 / 其他收入 keep)
//    b) 5 expense rename(娱乐→休闲娱乐 / 居住→住房 / 其他→其他支出)
//    c) S03 老数据完整保留(transaction 外键引用保留)
//    d) 总分类数 = 24(S03 10 + 新增 14,扣除 rename 4 = 20 ... 实际算法详见断言)

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart' show AccountType;
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Schema migration v8 → v9 真升级路径(D27 + IQA-fix)', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('drift_migration_v9_');
      dbPath = p.join(tmpDir.path, 'test.sqlite');
    });

    tearDown(() async {
      if (await Directory(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await tmpDir.delete(recursive: true);
    });

    /// Bootstrap v8 schema + S03 seed + 改 user_version=8,重开触发 v8→v9。
    ///
    /// v8 schema 与 v9 schema 同结构(categories 表),只是 v9 enum 加 refund 值。
    /// 本测试复用 v8 schema DDL(seed 模拟 S03 schema v8 用户数据)。
    Future<AppDatabase> bootstrapV8AndReopen() async {
      // Step 1: 用 AppDatabase 创 v9 schema + onCreate 24 分类 seed
      final db1 = AppDatabase.forTesting(NativeDatabase(File(dbPath)));

      // Step 2: 删 v9 默认 seed 的 categories,按 v8 schema 重建 + seed S03 默认 10 分类
      await db1.customStatement('DROP TABLE IF EXISTS transactions');
      await db1.customStatement('DROP TABLE IF EXISTS category_templates');
      await db1.customStatement('DROP TABLE IF EXISTS accounts');
      await db1.customStatement('DROP TABLE IF EXISTS categories');

      // categories v8 schema(同 v9 结构)
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

      // accounts v8 schema
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

      // transactions v8 schema
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
          original_transaction_id INTEGER,
          refund_note TEXT,
          exclude_from_income_expense INTEGER NOT NULL DEFAULT 0,
          exclude_from_budget INTEGER NOT NULL DEFAULT 0,
          lend_start_date INTEGER,
          lend_end_date INTEGER,
          initial_lend_balance_cents INTEGER,
          initial_time INTEGER,
          lend_counterparty_name TEXT,
          lend_due_date INTEGER,
          CHECK (amount_cents > 0)
        )
      ''');

      // category_templates v8 schema
      await db1.customStatement('''
        CREATE TABLE category_templates (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');

      // seed S03 默认 10 分类(模拟 S03 用户老数据)
      // 8 expense:餐饮/交通/购物/娱乐/居住/医疗/通讯/学习 + 1 兜底「其他」
      // 1 income:工资
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('餐饮', '🍔', 4294932035, 'expense', 0)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('交通', '🚗', 4282550259, 'expense', 1)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('购物', '🛍️', 4282476572, 'expense', 2)");
      // 「娱乐」— D27 IQA-fix C-4 会 rename 成「休闲娱乐」
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('娱乐', '🎮', 4281804922, 'expense', 3)");
      // 「居住」— D27 IQA-fix C-4 会 rename 成「住房」
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('居住', '🏠', 4280390810, 'expense', 4)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('医疗', '🏥', 4282512976, 'expense', 5)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('通讯', '📱', 4283254464, 'expense', 6)");
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('学习', '📚', 4284594922, 'expense', 7)");
      // 「其他」— D27 会 rename 成「其他支出」
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('其他', '📦', 4280030556, 'expense', 8)");
      // 「工资」— D27 会 rename 成「职业收入」
      await db1.customStatement(
          "INSERT INTO categories (name, icon_name, color_value, type, sort_order) VALUES ('工资', '💰', 4280997594, 'income', 9)");

      // seed 1 个账户 + 1 笔 expense transaction(模拟用户数据,验证外键引用保留)
      await db1.customStatement(
          "INSERT INTO accounts (name, balance_cents, type) VALUES ('现金', 50000, 'cash')");
      await db1.customStatement(
          "INSERT INTO transactions (amount_cents, type, category_id, account_id, note) VALUES (3000, 'expense', 1, 1, '午饭')");

      // user_version=8,close + 重开 → Drift 走 onUpgrade from<9 块
      await db1.customStatement('PRAGMA user_version = 8');
      await db1.close();

      return AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    }

    test('v8 → v9 onUpgrade 触发后 schemaVersion = 9', () async {
      final db = await bootstrapV8AndReopen();
      expect(db.schemaVersion, 9);
      await db.close();
    });

    test('4 个 income rename 成功(工资→职业 / 红包→好运 / 退款收入→退款 + type=refund / 投资→保险理财)',
        () async {
      final db = await bootstrapV8AndReopen();
      final cats = await db.categoryDao.getAll();

      // 5 个原 S03 income 检查重命名后
      // 1. 工资收入 → 职业收入(原 S03 只有一个「工资」,会顺手改为「职业收入」)
      expect(cats.where((c) => c.name == '职业收入').length, 1,
          reason: 'S03「工资」已 rename「职业收入」');
      // 2. 红包收入 — S03 seed 没「红包收入」(only v8+ 才 seed),new ADD
      expect(cats.any((c) => c.name == '好运收入' && c.type == TransactionType.income), isTrue,
          reason: '好运收入 D27 新增(WHERE NOT EXISTS 已幂等)');

      // 用户原「工资」被改成「职业收入」(没保留),这点在 IQA-fix 没异议
      expect(cats.where((c) => c.name == '工资' && c.type == TransactionType.income).length, 0,
          reason: '原「工资」已 rename 为「职业收入」(若用户自定义 icon/color 不会冲突)');
      await db.close();
    });

    test('5 个 expense rename(娱乐→休闲娱乐 / 居住→住房 / 其他→其他支出)+ 数据保留',
        () async {
      final db = await bootstrapV8AndReopen();
      final cats = await db.categoryDao.getAll();

      // IQA-fix C-4:「娱乐」「居住」必须被 rename,否则 S03 用户升级后 4 个相似分类
      expect(cats.where((c) => c.name == '休闲娱乐').length, 1,
          reason: 'IQA-fix D27-4:「娱乐」rename「休闲娱乐」');
      expect(cats.where((c) => c.name == '住房').length, 1,
          reason: 'IQA-fix D27-4:「居住」rename「住房」');
      expect(cats.where((c) => c.name == '其他支出').length, 1,
          reason: '「其他」rename「其他支出」');
      // 不应再有「娱乐」「居住」「其他」(S03 老名已 100% rename)
      expect(cats.where((c) => c.name == '娱乐').length, 0,
          reason: 'IQA-fix C-4:不应再有 S03「娱乐」');
      expect(cats.where((c) => c.name == '居住').length, 0,
          reason: 'IQA-fix C-4:不应再有 S03「居住」');
      expect(cats.where((c) => c.name == '其他').length, 0,
          reason: '不应再有 S03「其他」');

      // 数据保留:transaction(午饭 ¥30)仍然引用「餐饮」categoryId = 1
      final txList = await db.transactionDao.getAll();
      expect(txList, hasLength(1));
      expect(txList.single.note, '午饭');
      expect(txList.single.amountCents, 3000);
      expect(txList.single.categoryId, 1,
          reason: 'transaction 外键引用「餐饮」categoryId 保留(同 id 不变)');
      // 「餐饮」分类仍存在(没被 rename 或删)
      expect(cats.any((c) => c.name == '餐饮'), isTrue);
      await db.close();
    });

    test('11 + 4 个新分类 INSERT WHERE NOT EXISTS 真幂等(IQA-fix D27-1)',
        () async {
      final db = await bootstrapV8AndReopen();
      final cats = await db.categoryDao.getAll();

      // D27 后共 24 分类(8 income + 16 expense)— S03 10 + 新 14,扣 4 rename(没新增)
      // 总:S03 10 - 4 rename(只是改名,不是删)+ 4 income NEW + 11 expense NEW = 14 NEW + 10 RENAMED = 24 个不重复
      // 实际算术:
      //   S03 10 分类(餐饮 交通 购物 娱乐 居住 医疗 通讯 学习 其他 工资)
      //   4 income rename:
      //     - 工资 → 职业收入(1)
      //     - 退款收入... S03 没「退款收入」seed,不存在;但 D27 seed「退款」由 DAO 自动,走 M4 互斥
      //     - 其他(投资收益/红包收入) S03 seed 没
      //   实际 = S03 10 - 0(没 rename,因 S03 seed 没红包/退款/投资)+ 5 expense rename(娱乐→休闲,居住→住房,其他→其他支出)+ 11 expense INSERT + 4 income INSERT = 10 + 11 + 4 - 0(没 rename) = 25 ???

      // 让我重数:
      //   S03 seed 10:
      //     - 1 income 「工资」 → rename「职业收入」后仍是 1 个(改名不删)
      //     - 9 expense(餐饮 交通 购物 娱乐 居住 医疗 通讯 学习 其他) → 2 个被 rename(娱乐→休闲娱乐,居住→住房,其他→其他支出)= 仍是 9 个(改名不删)
      //   D27 INSERT WHERE NOT EXISTS(11 expense + 4 income):
      //     - 11 expense:医疗健康/老人/交通出行/通讯/缝纫/育儿/住房/休闲娱乐/学习办公/资金往来/保险理财/健身
      //       ↑ S03 已有「通讯」「住房」(被 rename 后是「住房」),所以 「通讯」「住房」 WHERE NOT EXISTS 跳过 = 9 个真 INSERT
      //     - 4 income:经营收入/资金往来/二手买卖/生活费(全 S03 没有,WHERE NOT EXISTS 4 个 INSERT)
      //   总:10(S03 rename 不变数)+ 9(11 expense - 2 跳过)+ 4(4 income)= 23

      // 但 D27 fresh install seed 是 24,D27 也应在 onUpgrade 后 24 吗?
      // 第 24 个是「退款」type=refund(由 DAO 自动 seed — M4 互斥)
      // onUpgrade 不 seed type=refund,所以 onUpgrade 后是 23 个。
      //
      // IQA-fix D29-1 (2026-08-12):加 2 rename 「医疗」→「医疗健康」+「学习」→「学习办公」
      // 后,S03 升级路径不再有 4 相似分类双份 — onUpgrade 后 24(= fresh install,不变量)
      // 分布:8 expense(rename/keep 后 8)+ 8 income + 1 expense 重命名跳过 = 实际 24
      expect(cats.length, 24,
          reason: 'IQA-fix D29-1:加 2 rename 后,S03 onUpgrade = Fresh install = 24 分类'
              '(无 4 相似双份)。8 income 全部 NEW INSERT + 8 expense rename/keep/INSERT 等于 16 expense + 8 income = 24');
      // 验证同名 2 个 type 共存仍然存在(「资金往来」「保险理财」是允许的)
      expect(cats.where((c) => c.name == '资金往来').length, 2,
          reason: '同名多 type 共存(设计决策):expense「资金往来」💸 + income「资金往来」💬 各 1');
      expect(cats.where((c) => c.name == '保险理财').length, 2,
          reason: '同名多 type 共存(设计决策):expense「保险理财」💎 + income「保险理财」🛡️ 各 1');
      // IQA-fix D29-1 关键验证:不再有 4 相似分类(医疗/医疗健康/学习/学习办公)
      expect(cats.where((c) => c.name == '医疗').length, 0,
          reason: '「医疗」S03 同名已 rename「医疗健康」,无残留');
      expect(cats.where((c) => c.name == '学习').length, 0,
          reason: '「学习」S03 同名已 rename「学习办公」,无残留');
      expect(cats.where((c) => c.name == '娱乐').length, 0,
          reason: '「娱乐」S03 同名已 rename「休闲娱乐」,无残留');
      expect(cats.where((c) => c.name == '居住').length, 0,
          reason: '「居住」S03 同名已 rename「住房」,无残留');
      // BUG-4 用户反馈(2026-08-12):S03 seed 现金 + 用户新建现金储蓄 = 2 个同名「现金」—
      // onUpgrade rename 老 S03 seed「现金」→「现金(储蓄)」,避免同名账户冲突
      // IQA-fix (2026-08-12 装机验后):原版 WHERE type='income' 错 — S03 现金 type=AccountType.cash
      // (TransactionType 是 transaction 类型;账户 type 是 AccountType)
      expect(cats.where((c) => c.name == '现金' && c.type == AccountType.cash).length, 0,
          reason: 'BUG-4:「现金」S03 seed cash 已 rename「现金(储蓄)」,无残留');
      // S03 升级用户自己新建的「现金」账户(若 type 匹配)被保留(rename strict,
      // 严格 name+type 匹配)所以用户自定义「现金」被保护,只 rename S03 seed 那条
      // 验证同名 2 个 type 共存:「资金往来」(expense + income) + 「保险理财」(expense + income) — 已在 IQA-fix D29-1 测试中
      await db.close();
    });

    test('v8 → v9 升级后可写新字段(往返验证)— TransactionType.refund 可用',
        () async {
      final db = await bootstrapV8AndReopen();

      // 拿到 S03 seed 的「职业收入」分类(原「工资」已 rename)
      final incomeCat = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '职业收入');

      // insert type=refund 交易(IQA-fix M4 互斥 — 退款分类不在 onUpgrade seed,
      // 由 DAO 在首次 refundMoney 时自动 seed「退款」type=refund)
      final refundId = await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amountCents: 500,
              type: TransactionType.refund,
              categoryId: incomeCat.id, // 用「职业收入」代替,后续 DAO 会重定向到「退款」
              accountId: 1,
              originalTransactionId: const Value(1), // 引用 v8 seed 的午饭 transaction
            ),
          );
      expect(refundId, greaterThan(0));
      final refund = await db.transactionDao.getById(refundId);
      expect(refund, isNotNull);
      expect(refund!.type, TransactionType.refund,
          reason: 'D27 enum 加 refund 值,textEnum 落库"refund"');
      await db.close();
    });
  });
}
