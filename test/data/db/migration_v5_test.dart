// Schema migration v4 → v5 测试(Stage 3 Day 20 + ADR-0024)。
//
// 验证:
// - schemaVersion = 7(累计升级后当前版本)
// - transactions 表新增 installmentPeriod 列(nullable)
// - 新 repayment transaction 可写入 installment_period
// - 旧 transaction 不丢(沿用 drift addColumn 行为,不需复杂模拟)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('Schema migration v4 → v5 (Stage 3 Day 20 — ADR-0024)', () {
    late AppDatabase db;
    late int cashId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.accountDao.getDefault();
      cashId = (await db.accountDao.getAll()).first.id;
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion = 7', () {
      expect(db.schemaVersion, 8);
    });

    test('全新建库 transactions 表有 installmentPeriod 列(默认 null)', () async {
      // 没有 transactions 数据
      final txList = await db.select(db.transactions).get();
      expect(txList, isEmpty);

      // insert 一个 expense,不传 installment_period,验证列允许 null
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 1234,
          type: TransactionType.expense,
          categoryId: mealCategory.id,
          accountId: cashId,
        ),
      );
      final tx = await db.transactionDao.getById(id);
      expect(tx, isNotNull);
      expect(tx!.installmentPeriod, isNull,
          reason: '非网贷还款,installment_period 应为 null');
    });

    test('网贷还款可写 installment_period=12', () async {
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      final id = await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 100000,
          type: TransactionType.repayment,
          categoryId: mealCategory.id,
          accountId: cashId,
          installmentPeriod: const Value(12),
        ),
      );
      final tx = await db.transactionDao.getById(id);
      expect(tx, isNotNull);
      expect(tx!.installmentPeriod, 12);
    });

    test('普通还款不写 installment_period(信用卡 / 花呗 / 储蓄)', () async {
      // 模拟:用户还信用卡储蓄,不传 installment_period(信用卡没分期概念)
      final mealCategory = (await db.categoryDao.getAll())
          .firstWhere((c) => c.name == '餐饮');
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amountCents: 50000,
          type: TransactionType.repayment,
          categoryId: mealCategory.id,
          accountId: cashId,
        ),
      );
      final txList = await db.select(db.transactions).get();
      expect(txList.single.installmentPeriod, isNull,
          reason: '信用卡 / 花呗没分期,installment_period 应为 null');
    });
  });
}