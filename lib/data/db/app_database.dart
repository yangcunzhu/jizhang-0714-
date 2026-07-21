import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/category_template_dao.dart';
import 'daos/statistics_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/category_templates.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

/// 应用主数据库。
///
/// Stage 1 用 Drift + 原生 SQLite(未加密)。SQLCipher 加密延后到 Stage 6,
/// 届时替换 [_openConnection] 的底层 executor 即可,schema 不变。
///
/// Schema 版本:
/// - v1 (Stage 1):3 表,accounts 4 字段,单一"现金"账户 + 10 默认分类
/// - v2 (Stage 2):accounts 加 5 字段 — ADR-0017
/// - v3 (Stage 2 Day 15):新增 category_templates 表 — ADR-0020
/// - v4 (Stage 3 Day 18):TransactionType enum 加 repayment 值 — ADR-0021
/// - v5 (Stage 3 Day 20 + ADR-0024):transactions 表加 installmentPeriod 列(网贷期数)
/// - v6 (Stage 3 ADR-0026):accounts 加 9 列(subType 主模型 + brandName + isPinned +
///   isDefaultIncome/ExpenseAccount + initialDebtCents + startDate + dueDate +
///   counterpartyName)+ 回填 subType from type — 5 大类 × 23 子类账户模型
/// - v7 (Stage 3 D22 ADR-0026 借贷落地):transactions 加 5 列(fromAccountId /
///   toAccountId / counterpartyName / startDate)+ TransactionType 加 lend / borrow — 双账户借出/借入全屏 UI 数据基础
/// - v8 (Stage 3 D25 schema v8 整合:D25 commit 实施 3 ADR + 2 ADR 字段占位):
///   - accounts 加 4 列(initialLendBalanceCents / initialTime /
///     lendCounterpartyName / lendDueDate)— ADR-0029(D25 实施)
///   - transactions 加 6 列(lendStartDate / lendEndDate — ADR-0029 字段占位 +
///     originalTransactionId / refundNote — ADR-0030 字段占位 +
///     excludeFromIncomeExpense / excludeFromBudget — ADR-0033 字段占位)
///   - categories + DefaultTemplate 24 分类(ADR-0031 + 0032)— D27 实施
///   - TransactionType enum 加 refund 值(ADR-0030)— D26 实施
@DriftDatabase(
  tables: [Categories, Accounts, Transactions, CategoryTemplates],
  daos: [
    CategoryDao,
    AccountDao,
    TransactionDao,
    CategoryTemplateDao,
    StatisticsDao, // D28 ADR-0033
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试专用：注入内存 executor(NativeDatabase.memory())。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaults();
        await _seedTemplates();
      },
      onUpgrade: (m, from, to) async {
        // Stage 1 → Stage 2:accounts 加 5 字段(type / includeInNetWorth /
        // creditLimit / billingDay / dueDay)。决策见 ADR-0017。
        //
        // WHY: 已有 row 自动用 DEFAULT 兜底
        // - type:'cash' — 已有现金账户自动归类
        // - includeInNetWorth:true — 理财类账户用户后续手动改
        // - creditLimit / billingDay / dueDay:NULL(非信用卡)
        if (from < 2) {
          await m.addColumn(accounts, accounts.type);
          await m.addColumn(accounts, accounts.includeInNetWorth);
          await m.addColumn(accounts, accounts.creditLimit);
          await m.addColumn(accounts, accounts.billingDay);
          await m.addColumn(accounts, accounts.dueDay);
        }
        // Stage 2 → Stage 2 (Day 15):新增 category_templates 表 — ADR-0020。
        //
        // WHY: 表里只放模板元数据(id / code / name / description / emoji),
        // 模板内分类用 Dart const,不入 categories(避免污染用户分类)。
        // 老用户的 categories / transactions 不受影响,只多了 5 条模板元数据。
        if (from < 3) {
          await m.createTable(categoryTemplates);
          await _seedTemplates();
        }
        // Stage 2 → Stage 3 (Day 18):TransactionType enum 加 repayment 值 — ADR-0021。
        //
        // WHY: textEnum 按枚举 name 字符串存储,SQLite 列定义仍是 TEXT,枚举值新增不需
        // ALTER TABLE。仅 Dart 层 enum 多一个常量,旧 transaction.type='expense'/'income'
        // 仍可读(向下兼容)。`repayment` 名称不可变更(下游统计依赖字符串匹配)。
        if (from < 4) {
          // 占位:无需 SQL,仅作版本标记 + 注释意图。下游 migration_v4_test 断言此路径通过。
        }
        // Stage 3 → Stage 3 (Day 20, ADR-0024):transactions 表加 installmentPeriod 列。
        //
        // WHY: 网贷还款需要记录期数(12/24/36 期),下游 S05 净资产 / S07 AI 攒攒
        // 会基于此判断还款提醒。Nullable 列,现有数据自动为 null。
        if (from < 5) {
          await m.addColumn(transactions, transactions.installmentPeriod);
        }
        // Stage 3 → Stage 3 (ADR-0026):accounts 升级为 5 大类 × 23 子类模型。
        //
        // WHY: 咔皮对标(v4 §3.1)暴露扁平 6 种类型不够,补 subType 主模型 + 品牌 +
        // 4 toggle(补 isPinned / isDefaultIncome / isDefaultExpense)+ 信用/借贷字段
        // (initialDebtCents / startDate / dueDate / counterpartyName)。
        //
        // 向下兼容:保留 type 列不动,新增列全部 nullable 或有 default。老账户 subType
        // 为 NULL → 用 UPDATE 按旧 type 回填(cash→cash / savings→savingsCard /
        // creditCard→creditCard / huabei→huabei / onlineLoan→jiebei / investment→mutualFund),
        // 保证升级后 subType 主模型对老数据也可用。
        if (from < 6) {
          await m.addColumn(accounts, accounts.subType);
          await m.addColumn(accounts, accounts.brandName);
          await m.addColumn(accounts, accounts.isPinned);
          await m.addColumn(accounts, accounts.isDefaultIncomeAccount);
          await m.addColumn(accounts, accounts.isDefaultExpenseAccount);
          await m.addColumn(accounts, accounts.initialDebtCents);
          await m.addColumn(accounts, accounts.startDate);
          await m.addColumn(accounts, accounts.dueDate);
          await m.addColumn(accounts, accounts.counterpartyName);
          // 回填 subType(textEnum 存 enum.name 字符串)。
          await customStatement(
            "UPDATE accounts SET sub_type = CASE type "
            "WHEN 'cash' THEN 'cash' "
            "WHEN 'savings' THEN 'savingsCard' "
            "WHEN 'creditCard' THEN 'creditCard' "
            "WHEN 'huabei' THEN 'huabei' "
            "WHEN 'onlineLoan' THEN 'jiebei' "
            "WHEN 'investment' THEN 'mutualFund' "
            "ELSE 'cash' END "
            "WHERE sub_type IS NULL",
          );
        }
        // Stage 3 → Stage 3 (D22):transactions 升级为支持借出/借入双账户转账
        // (ADR-0026 §12 落地 — 借出/借入独立 UI + 双账户联动)。
        //
        // WHY: 之前 transactions 只有 accountId(主账户),借出/借入需要扣款方+入款方
        // 双账户联动。Nullable 列让现有数据无需 backfill,老 expense/income/repayment/
        // transfer 流水保留。from/to 在已有 transfer 流水里当时未存 → 不回填(已知
        // 数据迁移缺口,S05 净资产报表需手动对账,记录在 daily)。
        if (from < 7) {
          await m.addColumn(transactions, transactions.fromAccountId);
          await m.addColumn(transactions, transactions.toAccountId);
          await m.addColumn(transactions, transactions.counterpartyName);
          await m.addColumn(transactions, transactions.startDate);
        }
        // Stage 3 → Stage 3 (D25 schema v8 整合:D25 commit 实施 1 ADR + 2 ADR 字段占位)。
        // - D25 实施:ADR-0029(accounts +4 + transactions 借贷 2 字段)
        // - D25 占位(待 D26/D27/D28 实施):ADR-0030(transactions 退款 2 字段)+
        //   ADR-0033(transactions toggle 2 字段)
        //
        // WHY 一次整合到 v8:避免 5 个 ADR 连续 schema bump;v7 旧数据零影响靠字段
        // nullable / default false 兜底。categories 24 分类 + 1 退款 seed(D27 实施)
        // + TransactionType.refund enum 值(D26 实施)留 onUpgrade 子块处理。
        //
        // WHY: 5 个新 ADR(0029/0030/0031/0032/0033)集中迁移到 v8,避免 5 次连续
        // schema bump。accounts +4 + transactions +6 = 10 列全部 nullable 或带
        // default,v7 旧数据零影响。categories seed 改动(8 收入 + 16 支出 + 1 退款)
        // 在 D27 实施时另开 onUpgrade 子块,本迁移只做表结构。
        //
        // ADR-0029 借贷字段修补(accounts +4):
        //   - initialLendBalanceCents:起始余额/欠款(整数分,与项目其他 cents 一致;
        //     修正 ADR §决策 2 字面 RealColumn)
        //   - initialTime:借贷账户起始时间(语义「该时间之前的记录不计入余额统计」)
        //   - lendCounterpartyName:借贷账户对手方姓名(与现有 counterpartyName
        //     语义重叠,留 D26+ 评估合并)
        //   - lendDueDate:借贷账户到期还款/收款日期(与现有 dueDate 语义重叠)
        //
        // ADR-0029 借贷字段修补(transactions +2):
        //   - lendStartDate:借出/借入 transaction 起始日期(与 v7 startDate
        //     语义重叠,留 D26+ 评估合并)
        //   - lendEndDate:借出收款/借入还款 transaction 日期(S07 异常检测用)
        //
        // ADR-0030 退款 transaction 化(transactions +2,D26 实施):
        //   - originalTransactionId:退款原 transaction.id 引用(nullable + FK 弱约束)
        //   - refundNote:退款备注
        //
        // ADR-0033 交易级 2 toggle(transactions +2,D28 实施):
        //   - excludeFromIncomeExpense:不计入收支统计(默认 false)
        //   - excludeFromBudget:不计入预算(默认 false)
        if (from < 8) {
          // accounts +4(ADR-0029)
          await m.addColumn(accounts, accounts.initialLendBalanceCents);
          await m.addColumn(accounts, accounts.initialTime);
          await m.addColumn(accounts, accounts.lendCounterpartyName);
          await m.addColumn(accounts, accounts.lendDueDate);
          // transactions +2(ADR-0029)
          await m.addColumn(transactions, transactions.lendStartDate);
          await m.addColumn(transactions, transactions.lendEndDate);
          // transactions +2(ADR-0030 占位,D26 写 DAO)
          await m.addColumn(transactions, transactions.originalTransactionId);
          await m.addColumn(transactions, transactions.refundNote);
          // transactions +2(ADR-0033 占位,D28 写 StatisticsDao)
          await m.addColumn(transactions, transactions.excludeFromIncomeExpense);
          await m.addColumn(transactions, transactions.excludeFromBudget);
        }
        // Stage 3 → Stage 3 (D27 schema v9 整合:ADR-0031 + 0032 24 分类完整版)
        //
        // WHY 升级到 v9:D25 已 bump 到 v8(ADR-0029 借贷字段),继续 bump v9 是
        // 标准 schema 升级惯例。本迁移**不动 schema 结构**,仅做数据迁移
        // (rename + INSERT OR IGNORE),但 bump schemaVersion 触发 onUpgrade 路径。
        //
        // **M4 互斥显式声明(2026-08-09 IQA D26 M4)**:
        // type=refund 分类由 DAO `_getOrCreateRefundCategoryId`(ADR-0030 §决策 4)
        // 在首次 refundMoney 时**自动 seed**(按 name + type 双字段查找)。
        // 本 migration **故意不 seed**「退款」type=refund 分类(避免与 DAO 懒加载
        // seed 重复创建)。**种子路径互斥 = DAO 唯一来源**(防御性 design)。
        if (from < 9) {
          // ═══ ADR-0031 + 0032 + IQA-fix C-IQA-D27-1/4(v8 → v9 数据迁移)═══
          //
          // IQA-fix D27-1 (2026-08-10):
          // 原版用 `INSERT OR IGNORE` 因 categories 表**没有 UNIQUE 约束**,
          // rowid 自增不会冲突 → INSERT OR IGNORE 实际等同 INSERT,
          // **重复跑 onUpgrade 会创建重复分类**。修法:用 `WHERE NOT EXISTS`
          // 子查询做真幂等保证。
          //
          // IQA-fix D27-4 (2026-08-10):
          // S03 默认 seed 有「娱乐」「居住」,D27 默认 seed 没有这 2 个(改名
          // 「休闲娱乐」「住房」)。如果**只 INSERT 不 rename**,S03 用户升级后
          // 会同时有「娱乐」+「休闲娱乐」+「居住」+「住房」(4 个相似分类 UX 偷懒点)。
          // 修法:加 rename 「娱乐」→「休闲娱乐」+「居住」→「住房」(严格按
          // name + type 匹配,用户自定义保留),S03 升级后只剩 rename 后的 1 个。

          // ─── 旧 S02/S03 默认 4 income rename(严格 name+type 匹配,用户自定义保留)───
          //
          // 实际 S03 _defaultCategories 用的 name 是「工资」「红包收入」没有,
          // 但 ADR-0031 §背景字面写的是「工资收入」「红包收入」「退款收入」「投资收益」。
          // 实际 S03 seed 调查(2026-08-10):
          //   - 「工资」:存在
          //   - 「红包收入」:不存在(S03 seed 没)
          //   - 「退款收入」:不存在(S03 seed 没,只在 ADR 字面描述)
          //   - 「投资收益」:不存在(S03 seed 没)
          // 修法:SQL WHERE 兼容 S03 真实 seed 名「工资」+ ADR 字面名(两条都试)

          // 1. 工资收入 / 工资 → 职业收入(S03 用「工资」,ADR 字面是「工资收入」)
          await customStatement(
            "UPDATE categories SET name = '职业收入' "
            "WHERE (name = '工资' OR name = '工资收入') AND type = 'income'",
          );
          // 2. 红包收入 → 好运收入(S03 seed 没有这条,但保留 ADR 字面对齐)
          await customStatement(
            "UPDATE categories SET name = '好运收入' "
            "WHERE name = '红包收入' AND type = 'income'",
          );
          // 3. 退款收入 → 退款 + type=refund(跟随 ADR-0030 §决策 4 互斥)
          await customStatement(
            "UPDATE categories SET name = '退款', type = 'refund' "
            "WHERE (name = '退款收入' OR name = '退款') AND type = 'income'",
          );
          // 4. 投资收益 → 保险理财
          await customStatement(
            "UPDATE categories SET name = '保险理财' "
            "WHERE (name = '投资收益' OR name = '保险理财') "
            "AND type = 'income' AND id NOT IN (SELECT id FROM categories WHERE name = '保险理财' AND type = 'income')",
          );

          // ─── IQA-fix D27-4 (2026-08-10):S03 默认 expense rename───
          // 「娱乐」→「休闲娱乐」(D27 16 支出 sortOrder=11)
          await customStatement(
            "UPDATE categories SET name = '休闲娱乐' "
            "WHERE name = '娱乐' AND type = 'expense'",
          );
          // 「居住」→「住房」(D27 16 支出 sortOrder=10)
          await customStatement(
            "UPDATE categories SET name = '住房' "
            "WHERE name = '居住' AND type = 'expense'",
          );
          // 「其他」→「其他支出」(D27 16 支出 sortOrder=99)— 已在原版做,保留
          // (不再重复 — 这里是单行 UPDATE,不需要改)

          // ─── 新增 11 个 expense:INSERT ... SELECT WHERE NOT EXISTS(真幂等)───
          // IQA-fix D27-1:用 WHERE NOT EXISTS 替 INSERT OR IGNORE,
          // 保证重复跑 onUpgrade 不会创建重复分类。
          //
          // 颜色常量(ARGB int hex 整数):
          //   💊 医疗健康 0xFFE91E63 = 4287010675
          //   👴 老人 0xFF795548 = 4284510557
          //   🚗 交通 0xFF2196F3 = 4282550259(S02 seed 已有)
          //   🚙 交通出行 0xFF1976D2 = 4283460609
          //   📞 通讯 0xFF00BCD4 = 4288982228(S02 seed 已有,WHERE NOT EXISTS 跳过)
          //   🧵 缝纫 0xFF8D6E63 = 4287127651
          //   🍼 育儿 0xFFFFEB3B = 4293716539
          //   🏠 住房 0xFF4CAF50 = 4281428581(S03「居住」已 rename)
          //   🎬 休闲娱乐 0xFFFFC107 = 4294940615(S03「娱乐」已 rename)
          //   📚 学习办公 0xFF3F51B5 = 4283268373(S02「学习」keep,sortOrder 12)
          //   💸 资金往来 0xFF607D8B = 4290956491
          //   💎 保险理财 0xFF009688 = 4283161448
          //   💪 健身 0xFFCDDC39 = 4295343161
          await customStatement(
            "INSERT INTO categories (name, icon_name, color_value, type, sort_order, created_at) "
            "SELECT '医疗健康', '💊', 4287010675, 'expense', 1, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '医疗健康' AND type = 'expense') "
            "UNION ALL "
            "SELECT '老人', '👴', 4284510557, 'expense', 2, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '老人' AND type = 'expense') "
            "UNION ALL "
            "SELECT '交通出行', '🚙', 4283460609, 'expense', 6, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '交通出行' AND type = 'expense') "
            "UNION ALL "
            "SELECT '通讯', '📞', 4288982228, 'expense', 7, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '通讯' AND type = 'expense') "
            "UNION ALL "
            "SELECT '缝纫', '🧵', 4287127651, 'expense', 8, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '缝纫' AND type = 'expense') "
            "UNION ALL "
            "SELECT '育儿', '🍼', 4293716539, 'expense', 9, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '育儿' AND type = 'expense') "
            "UNION ALL "
            "SELECT '住房', '🏠', 4281428581, 'expense', 10, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '住房' AND type = 'expense') "
            "UNION ALL "
            "SELECT '休闲娱乐', '🎬', 4294940615, 'expense', 11, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '休闲娱乐' AND type = 'expense') "
            "UNION ALL "
            "SELECT '学习办公', '📚', 4283268373, 'expense', 12, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '学习办公' AND type = 'expense') "
            "UNION ALL "
            "SELECT '资金往来', '💸', 4290956491, 'expense', 13, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '资金往来' AND type = 'expense') "
            "UNION ALL "
            "SELECT '保险理财', '💎', 4283161448, 'expense', 14, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '保险理财' AND type = 'expense') "
            "UNION ALL "
            "SELECT '健身', '💪', 4295343161, 'expense', 15, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '健身' AND type = 'expense')",
          );

          // ─── 新增 7 个 income WHERE NOT EXISTS(真幂等,完整 D27 8 income)───
          // 修正:原版只 INSERT 6 个漏了「其他收入」 — 但 S03 seed 没「其他收入」 income
          // (S03 _defaultCategories 只有 1 income「工资」+ 9 expense),如果不补 INSERT,
          // S03 升级路径会少 1 个 income「其他收入」,D27 fresh install = 24 / onUpgrade = 25 不一致。
          // 修法:补 INSERT「其他收入」,让两条路径都 25(FRESH 25 / UPGRADE 25 不变量)。
          // 颜色常量:
          //   💰 经营收入 0xFF4CAF50 = 4283215696
          //   🛡️ 保险理财 0xFFFF9800 = 4294934528(D27 ADR-0031 §决策 1 income #3)
          //   💬 资金往来 0xFF9C27B0 = 4282479696
          //   🎁 二手买卖 0xFF00BCD4 = 4290703316
          //   🎉 好运收入 0xFFE91E63 = 4288028259
          //   🛍️ 生活费 0xFF8BC34A = 4282326090
          //
          // 实际 8 income 分布:
          //   - 老「S03 工资」rename「职业收入」 (S03 有这条,改名生效)
          //   - 老「红包收入」/「退款收入」/「投资收益」/「其他收入」S03 seed 没 — fall through 到 INSERT
          //   - 退款分类由 DAO 自动 seed(M4 互斥,不在 onUpgrade)
          // 实际 7 个 NEW INSERT(其他 1 个老有 seed):
          //   经营收入 / 保险理财 / 资金往来 / 二手买卖 / 好运收入 / 生活费 / 其他收入
          await customStatement(
            "INSERT INTO categories (name, icon_name, color_value, type, sort_order, created_at) "
            "SELECT '经营收入', '💰', 4283215696, 'income', 2, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '经营收入' AND type = 'income') "
            "UNION ALL "
            "SELECT '保险理财', '🛡️', 4294934528, 'income', 3, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '保险理财' AND type = 'income') "
            "UNION ALL "
            "SELECT '资金往来', '💬', 4282479696, 'income', 4, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '资金往来' AND type = 'income') "
            "UNION ALL "
            "SELECT '二手买卖', '🎁', 4290703316, 'income', 5, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '二手买卖' AND type = 'income') "
            "UNION ALL "
            "SELECT '好运收入', '🎉', 4288028259, 'income', 6, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '好运收入' AND type = 'income') "
            "UNION ALL "
            "SELECT '生活费', '🛍️', 4282326090, 'income', 7, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '生活费' AND type = 'income') "
            "UNION ALL "
            "SELECT '其他收入', '📦', 4288585374, 'income', 99, CAST(strftime('%s', 'now') AS INTEGER) "
            "WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '其他收入' AND type = 'income')",
          );

          // ─── 「其他」→「其他支出」改名(已在原版 — 保留单行 UPDATE)───
          await customStatement(
            "UPDATE categories SET name = '其他支出' "
            "WHERE name = '其他' AND type = 'expense'",
          );

          // ═══ M4 互斥显式声明(2026-08-09 IQA D26):type=refund 不 seed ═══
          // type=refund「退款」分类由 DAO `_getOrCreateRefundCategoryId`
          // (ADR-0030 §决策 4)在首次 refundMoney 时自动 seed。
          // 本 migration **故意不 seed**(避免与 DAO 懒加载重复创建)。
        }
      },
      beforeOpen: (details) async {
        // WHY: SQLite 默认每个连接 foreign_keys=OFF,不开则 references() 形同虚设。
        // 记账数据完整性依赖外键(禁止悬挂 categoryId/accountId)。
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// 首次建库时植入默认数据:单一"现金"账户 + 10 个默认分类。
  Future<void> _seedDefaults() async {
    // v6:默认现金账户同时写 subType(fresh install 不走 onUpgrade 回填)。
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: '现金',
        subType: const Value(AccountSubType.cash),
      ),
    );
    await batch((b) => b.insertAll(categories, _defaultCategories));
  }

  /// 植入 5 个预设分类模板元数据(决策 ADR-0020)。
  ///
  /// WHY: 模板分类内容用 Dart const 存储(见 `defaultTemplateDefinitions`),
  /// 此处只入元数据到 DB(code / name / description / emoji)。
  Future<void> _seedTemplates() async {
    await batch((b) {
      for (final def in defaultTemplateDefinitions) {
        b.insert(
          categoryTemplates,
          CategoryTemplatesCompanion.insert(
            code: def.code,
            name: def.name,
            description: def.description,
            emoji: def.emoji,
          ),
        );
      }
    });
  }
}

/// 24 个默认分类(8 收入 + 16 支出),iconName 直接存 emoji 字符串。
///
/// D27 (ADR-0031 + ADR-0032) 升级:从 10 个(8 支出 + 2 收入)扩到 24 个完整版,
/// 覆盖咔皮对标所有真实场景(餐饮/医疗/购物/老人/交通 等 16 支出 + 8 收入)。
///
/// WHY: 选 emoji 而非 Material Icons,见 ADR-0013 — 跨平台一致 + 用户直观
/// + 零依赖。Stage 2 自定义分类天然兼容 emoji 输入。
///
/// **M4 互斥(2026-08-09 IQA D26)**:本 seed **不包含** type=refund 「退款」分类。
/// 「退款」分类由 DAO `_getOrCreateRefundCategoryId`(ADR-0030 §决策 4)在首次
/// refundMoney 时自动 seed。本 seed 与 DAO seed 路径互斥,fresh install + 老数据
/// 升级均如此(seed 互斥 = DAO 唯一来源)。
const List<CategoriesCompanion> _defaultCategories = [
  // ═══ 16 支出(ADR-0032 §决策 1)═══
  CategoriesCompanion(
      name: Value('医疗健康'),
      iconName: Value('💊'),
      colorValue: Value(0xFFE91E63),
      type: Value(TransactionType.expense),
      sortOrder: Value(1)),
  CategoriesCompanion(
      name: Value('老人'),
      iconName: Value('👴'),
      colorValue: Value(0xFF795548),
      type: Value(TransactionType.expense),
      sortOrder: Value(2)),
  CategoriesCompanion(
      name: Value('餐饮'),
      iconName: Value('🍔'),
      colorValue: Value(0xFFFF7043),
      type: Value(TransactionType.expense),
      sortOrder: Value(3)),
  CategoriesCompanion(
      name: Value('购物'),
      iconName: Value('🛍️'),
      colorValue: Value(0xFFAB47BC),
      type: Value(TransactionType.expense),
      sortOrder: Value(4)),
  CategoriesCompanion(
      name: Value('交通'),
      iconName: Value('🚗'),
      colorValue: Value(0xFF42A5F5),
      type: Value(TransactionType.expense),
      sortOrder: Value(5)),
  CategoriesCompanion(
      name: Value('交通出行'),
      iconName: Value('🚙'),
      colorValue: Value(0xFF1976D2),
      type: Value(TransactionType.expense),
      sortOrder: Value(6)),
  CategoriesCompanion(
      name: Value('通讯'),
      iconName: Value('📞'),
      colorValue: Value(0xFF00BCD4),
      type: Value(TransactionType.expense),
      sortOrder: Value(7)),
  CategoriesCompanion(
      name: Value('缝纫'),
      iconName: Value('🧵'),
      colorValue: Value(0xFF8D6E63),
      type: Value(TransactionType.expense),
      sortOrder: Value(8)),
  CategoriesCompanion(
      name: Value('育儿'),
      iconName: Value('🍼'),
      colorValue: Value(0xFFFFEB3B),
      type: Value(TransactionType.expense),
      sortOrder: Value(9)),
  CategoriesCompanion(
      name: Value('住房'),
      iconName: Value('🏠'),
      colorValue: Value(0xFF4CAF50),
      type: Value(TransactionType.expense),
      sortOrder: Value(10)),
  CategoriesCompanion(
      name: Value('休闲娱乐'),
      iconName: Value('🎬'),
      colorValue: Value(0xFFFFC107),
      type: Value(TransactionType.expense),
      sortOrder: Value(11)),
  CategoriesCompanion(
      name: Value('学习办公'),
      iconName: Value('📚'),
      colorValue: Value(0xFF3F51B5),
      type: Value(TransactionType.expense),
      sortOrder: Value(12)),
  CategoriesCompanion(
      name: Value('资金往来'),
      iconName: Value('💸'),
      colorValue: Value(0xFF607D8B),
      type: Value(TransactionType.expense),
      sortOrder: Value(13)),
  CategoriesCompanion(
      name: Value('保险理财'),
      iconName: Value('💎'),
      colorValue: Value(0xFF009688),
      type: Value(TransactionType.expense),
      sortOrder: Value(14)),
  CategoriesCompanion(
      name: Value('健身'),
      iconName: Value('💪'),
      colorValue: Value(0xFFCDDC39),
      type: Value(TransactionType.expense),
      sortOrder: Value(15)),
  CategoriesCompanion(
      name: Value('其他支出'),
      iconName: Value('📦'),
      colorValue: Value(0xFF9E9E9E),
      type: Value(TransactionType.expense),
      sortOrder: Value(99)),
  // ═══ 8 收入(ADR-0031 §决策 1)═══
  CategoriesCompanion(
      name: Value('职业收入'),
      iconName: Value('💳'),
      colorValue: Value(0xFF2196F3),
      type: Value(TransactionType.income),
      sortOrder: Value(1)),
  CategoriesCompanion(
      name: Value('经营收入'),
      iconName: Value('💰'),
      colorValue: Value(0xFF4CAF50),
      type: Value(TransactionType.income),
      sortOrder: Value(2)),
  CategoriesCompanion(
      name: Value('保险理财'),
      iconName: Value('🛡️'),
      colorValue: Value(0xFFFF9800),
      type: Value(TransactionType.income),
      sortOrder: Value(3)),
  CategoriesCompanion(
      name: Value('资金往来'),
      iconName: Value('💬'),
      colorValue: Value(0xFF9C27B0),
      type: Value(TransactionType.income),
      sortOrder: Value(4)),
  CategoriesCompanion(
      name: Value('二手买卖'),
      iconName: Value('🎁'),
      colorValue: Value(0xFF00BCD4),
      type: Value(TransactionType.income),
      sortOrder: Value(5)),
  CategoriesCompanion(
      name: Value('好运收入'),
      iconName: Value('🎉'),
      colorValue: Value(0xFFE91E63),
      type: Value(TransactionType.income),
      sortOrder: Value(6)),
  CategoriesCompanion(
      name: Value('生活费'),
      iconName: Value('🛍️'),
      colorValue: Value(0xFF8BC34A),
      type: Value(TransactionType.income),
      sortOrder: Value(7)),
  CategoriesCompanion(
      name: Value('其他收入'),
      iconName: Value('📦'),
      colorValue: Value(0xFF9E9E9E),
      type: Value(TransactionType.income),
      sortOrder: Value(99)),
  // 注意:type=refund「退款」分类**故意不 seed**(M4 互斥),
  // 由 transactionDao._getOrCreateRefundCategoryId 在首次 refund 时增量 seed。
];

/// 打开物理数据库连接(应用运行时)。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'jizhang.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}