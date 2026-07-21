import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/category_template_dao.dart';
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
  daos: [CategoryDao, AccountDao, TransactionDao, CategoryTemplateDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试专用：注入内存 executor(NativeDatabase.memory())。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

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

/// 10 个默认分类(8 支出 + 2 收入),iconName 直接存 emoji 字符串。
///
/// WHY: 选 emoji 而非 Material Icons,见 ADR-0013 — 跨平台一致 + 用户直观
/// + 零依赖。Stage 2 自定义分类天然兼容 emoji 输入。
const List<CategoriesCompanion> _defaultCategories = [
  CategoriesCompanion(
      name: Value('餐饮'),
      iconName: Value('🍔'),
      colorValue: Value(0xFFFF7043),
      type: Value(TransactionType.expense),
      sortOrder: Value(0)),
  CategoriesCompanion(
      name: Value('交通'),
      iconName: Value('🚗'),
      colorValue: Value(0xFF42A5F5),
      type: Value(TransactionType.expense),
      sortOrder: Value(1)),
  CategoriesCompanion(
      name: Value('购物'),
      iconName: Value('🛍️'),
      colorValue: Value(0xFFAB47BC),
      type: Value(TransactionType.expense),
      sortOrder: Value(2)),
  CategoriesCompanion(
      name: Value('娱乐'),
      iconName: Value('🎮'),
      colorValue: Value(0xFFEC407A),
      type: Value(TransactionType.expense),
      sortOrder: Value(3)),
  CategoriesCompanion(
      name: Value('居住'),
      iconName: Value('🏠'),
      colorValue: Value(0xFF26A69A),
      type: Value(TransactionType.expense),
      sortOrder: Value(4)),
  CategoriesCompanion(
      name: Value('医疗'),
      iconName: Value('🏥'),
      colorValue: Value(0xFFEF5350),
      type: Value(TransactionType.expense),
      sortOrder: Value(5)),
  CategoriesCompanion(
      name: Value('通讯'),
      iconName: Value('📱'),
      colorValue: Value(0xFF5C6BC0),
      type: Value(TransactionType.expense),
      sortOrder: Value(6)),
  CategoriesCompanion(
      name: Value('学习'),
      iconName: Value('📚'),
      colorValue: Value(0xFF66BB6A),
      type: Value(TransactionType.expense),
      sortOrder: Value(7)),
  CategoriesCompanion(
      name: Value('其他'),
      iconName: Value('📦'),
      colorValue: Value(0xFF78909C),
      type: Value(TransactionType.expense),
      sortOrder: Value(8)),
  CategoriesCompanion(
      name: Value('工资'),
      iconName: Value('💰'),
      colorValue: Value(0xFF26C6DA),
      type: Value(TransactionType.income),
      sortOrder: Value(9)),
];

/// 打开物理数据库连接(应用运行时)。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'jizhang.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}