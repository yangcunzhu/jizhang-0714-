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
@DriftDatabase(
  tables: [Categories, Accounts, Transactions, CategoryTemplates],
  daos: [CategoryDao, AccountDao, TransactionDao, CategoryTemplateDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试专用：注入内存 executor(NativeDatabase.memory())。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

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
    await into(accounts).insert(const AccountsCompanion(name: Value('现金')));
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