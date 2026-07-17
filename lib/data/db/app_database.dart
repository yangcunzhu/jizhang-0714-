import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

/// 应用主数据库。
///
/// Stage 1 用 Drift + 原生 SQLite(未加密)。SQLCipher 加密延后到 Stage 6,
/// 届时替换 [_openConnection] 的底层 executor 即可,schema 不变。
@DriftDatabase(
  tables: [Categories, Accounts, Transactions],
  daos: [CategoryDao, AccountDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试专用:注入内存 executor(NativeDatabase.memory())。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaults();
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
}

/// 10 个默认分类(8 支出 + 2 收入),iconName 由 UI 层映射为 IconData。
const List<CategoriesCompanion> _defaultCategories = [
  CategoriesCompanion(
      name: Value('餐饮'),
      iconName: Value('restaurant'),
      colorValue: Value(0xFFFF7043),
      type: Value(TransactionType.expense),
      sortOrder: Value(0)),
  CategoriesCompanion(
      name: Value('交通'),
      iconName: Value('directions_car'),
      colorValue: Value(0xFF42A5F5),
      type: Value(TransactionType.expense),
      sortOrder: Value(1)),
  CategoriesCompanion(
      name: Value('购物'),
      iconName: Value('shopping_bag'),
      colorValue: Value(0xFFAB47BC),
      type: Value(TransactionType.expense),
      sortOrder: Value(2)),
  CategoriesCompanion(
      name: Value('娱乐'),
      iconName: Value('sports_esports'),
      colorValue: Value(0xFFEC407A),
      type: Value(TransactionType.expense),
      sortOrder: Value(3)),
  CategoriesCompanion(
      name: Value('居住'),
      iconName: Value('home'),
      colorValue: Value(0xFF26A69A),
      type: Value(TransactionType.expense),
      sortOrder: Value(4)),
  CategoriesCompanion(
      name: Value('医疗'),
      iconName: Value('local_hospital'),
      colorValue: Value(0xFFEF5350),
      type: Value(TransactionType.expense),
      sortOrder: Value(5)),
  CategoriesCompanion(
      name: Value('通讯'),
      iconName: Value('smartphone'),
      colorValue: Value(0xFF5C6BC0),
      type: Value(TransactionType.expense),
      sortOrder: Value(6)),
  CategoriesCompanion(
      name: Value('学习'),
      iconName: Value('menu_book'),
      colorValue: Value(0xFF66BB6A),
      type: Value(TransactionType.expense),
      sortOrder: Value(7)),
  CategoriesCompanion(
      name: Value('其他'),
      iconName: Value('category'),
      colorValue: Value(0xFF78909C),
      type: Value(TransactionType.expense),
      sortOrder: Value(8)),
  CategoriesCompanion(
      name: Value('工资'),
      iconName: Value('payments'),
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
