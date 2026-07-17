import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// 数据库单例 provider。
///
/// 应用启动时由 ProviderScope 自动创建，整个生命周期共享一个 AppDatabase 实例。
/// 测试时可通过 `overrides: [databaseProvider.overrideWith(...)]` 注入内存库，
/// 详见 `test/features/home/`。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});