// Schema migration v5 → v6 测试(Stage 3 — ADR-0026)。
//
// 验证:
// - schemaVersion = 6
// - accounts 表新增 9 列(subType / brandName / isPinned /
//   isDefaultIncomeAccount / isDefaultExpenseAccount / initialDebtCents /
//   startDate / dueDate / counterpartyName)
// - fresh install 默认现金账户 subType = cash(seed 已写)
// - subType textEnum 往返(存 name 字符串,读回枚举)
// - 回填 SQL CASE 映射正确(旧 type → 新 subType)
//
// WHY 不做真 v5→v6 升级模拟:NativeDatabase.memory() 不能 close 后重开
// (migration_v5_test 已记录此限制),故用「全新库 + 直接跑回填 SQL」验证。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';

void main() {
  group('Schema migration v5 → v6 (ADR-0026 — 5 大类 × 23 子类)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.accountDao.getDefault();
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion = 6', () {
      expect(db.schemaVersion, 6);
    });

    test('fresh install 默认现金账户 subType = cash', () async {
      final cash = (await db.accountDao.getAll()).single;
      expect(cash.subType, AccountSubType.cash,
          reason: 'seed 已给默认现金账户写 subType');
      expect(cash.type, AccountType.cash);
    });

    test('新增 9 列均可写入并读回(信用账户全字段)', () async {
      final start = DateTime(2026, 1, 1);
      final due = DateTime(2026, 8, 20);
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: const Value(AccountType.creditCard),
          subType: const Value(AccountSubType.creditCard),
          brandName: const Value('招商银行'),
          isPinned: const Value(true),
          isDefaultIncomeAccount: const Value(false),
          isDefaultExpenseAccount: const Value(true),
          creditLimit: const Value(5000000),
          initialDebtCents: const Value(120000),
          billingDay: const Value(5),
          dueDay: const Value(25),
          startDate: Value(start),
          dueDate: Value(due),
          counterpartyName: const Value('占位-借款人'),
        ),
      );
      final acc = await db.accountDao.getById(id);
      expect(acc, isNotNull);
      expect(acc!.subType, AccountSubType.creditCard);
      expect(acc.brandName, '招商银行');
      expect(acc.isPinned, isTrue);
      expect(acc.isDefaultExpenseAccount, isTrue);
      expect(acc.isDefaultIncomeAccount, isFalse);
      expect(acc.initialDebtCents, 120000);
      expect(acc.startDate, start);
      expect(acc.dueDate, due);
      expect(acc.counterpartyName, '占位-借款人');
    });

    test('新列有合理默认(3 toggle 默认 false,nullable 列默认 null)', () async {
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '微信',
          subType: const Value(AccountSubType.wechat),
        ),
      );
      final acc = (await db.accountDao.getById(id))!;
      expect(acc.isPinned, isFalse);
      expect(acc.isDefaultIncomeAccount, isFalse);
      expect(acc.isDefaultExpenseAccount, isFalse);
      expect(acc.brandName, isNull);
      expect(acc.initialDebtCents, isNull);
      expect(acc.startDate, isNull);
      expect(acc.dueDate, isNull);
      expect(acc.counterpartyName, isNull);
    });

    test('回填 SQL:旧 type → 新 subType CASE 映射正确', () async {
      // 模拟 6 个旧账户(subType 为 NULL,只有 type),跑 migration 的回填 SQL。
      const legacy = {
        'cash': AccountSubType.cash,
        'savings': AccountSubType.savingsCard,
        'creditCard': AccountSubType.creditCard,
        'huabei': AccountSubType.huabei,
        'onlineLoan': AccountSubType.jiebei,
        'investment': AccountSubType.mutualFund,
      };
      for (final t in legacy.keys) {
        await db.customStatement(
          "INSERT INTO accounts (name, type, balance_cents, "
          "include_in_net_worth, is_pinned, is_default_income_account, "
          "is_default_expense_account) VALUES ('老-$t', '$t', 0, 1, 0, 0, 0)",
        );
      }
      // 回填(与 app_database.dart onUpgrade from<6 同一 SQL)。
      await db.customStatement(
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
      final all = await db.accountDao.getAll();
      for (final entry in legacy.entries) {
        final acc = all.firstWhere((a) => a.name == '老-${entry.key}');
        expect(acc.subType, entry.value,
            reason: '${entry.key} 应回填为 ${entry.value.name}');
      }
    });
  });
}
