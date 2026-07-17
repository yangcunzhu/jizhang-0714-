import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';

/// 交易列表(provider)。
///
/// 监听 `transactionDao.watchAll()`（按 occurredAt 倒序），数据库写入即刷新。
/// UI 层用 `ref.watch(transactionListProvider)` 拿 `AsyncValue<List<TransactionEntry>>`。
final transactionListProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.transactionDao.watchAll();
});

/// 分类列表(provider)。
///
/// 监听 `categoryDao.watchAll()`（按 sortOrder 升序）。
/// UI 层用于把 `categoryId` 解析为分类实体（颜色 / 图标 / 名称）。
final categoryListProvider = StreamProvider<List<CategoryEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoryDao.watchAll();
});

/// 默认账户(provider)。
///
/// Stage 1 简化为单一"现金"账户（取 `accountDao.getDefault()` 第一条）。
/// Stage 2 扩展为多账户时改为 `watchDefault()` + UI 选择器。
final defaultAccountProvider = FutureProvider<AccountEntry?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.accountDao.getDefault();
});