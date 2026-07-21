// lendMoney / borrowMoney DAO 测试(ADR-0026 §12 + D22 落地)。
//
// 覆盖 3 类场景(铁律 8):
// - 正常:借出/借入 → 双方余额联动 + 写 lend/borrow 流水 + 借贷分类自动 seed
// - 异常(余额不足):借出 → StateError,事务回滚
// - 边界:amount<=0 / 同账户 / 收款账户不是借贷子类型 → ArgumentError

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  late AppDatabase db;
  late int fundId;
  late int cash2Id;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountDao.getDefault();
    fundId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '储蓄卡',
        subType: const Value(AccountSubType.savingsCard),
        balanceCents: const Value(100000), // ¥1000
      ),
    );
    cash2Id = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '微信',
        subType: const Value(AccountSubType.wechat),
        balanceCents: const Value(5000), // ¥50
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('lendMoney', () {
    test('正常:资金账户 → 借出账户,扣款/应收债权联动', () async {
      final lendAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借给张三',
          subType: const Value(AccountSubType.lendOut),
          balanceCents: const Value(0),
        ),
      );
      final txId = await db.transactionDao.lendMoney(
        fromAccountId: fundId,
        toAccountId: lendAccId,
        amountCents: 30000,
        counterparty: '张三',
        startDate: DateTime(2026, 1, 1),
      );
      expect(txId, greaterThan(0));

      final fund = await db.accountDao.getById(fundId);
      final lendAcc = await db.accountDao.getById(lendAccId);
      expect(fund!.balanceCents, 70000, reason: '1000 - 300 = 700');
      expect(lendAcc!.balanceCents, 30000, reason: '借出账户应收 +300');

      final tx = await db.transactionDao.getById(txId);
      expect(tx!.type, TransactionType.lend);
      expect(tx.counterpartyName, '张三');
      expect(tx.fromAccountId, fundId);
      expect(tx.toAccountId, lendAccId);
      expect(tx.startDate, DateTime(2026, 1, 1));
    });

    test('自动 seed「借出」分类', () async {
      final lendAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出账户',
          subType: const Value(AccountSubType.lendOut),
        ),
      );
      await db.transactionDao.lendMoney(
        fromAccountId: fundId,
        toAccountId: lendAccId,
        amountCents: 10000,
      );
      final cats = await db.categoryDao.getAll();
      expect(cats.any((c) => c.name == '借出'), isTrue);
    });

    test('异常:余额不足 → StateError,余额回滚', () async {
      final lendAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出账户',
          subType: const Value(AccountSubType.lendOut),
        ),
      );
      expect(
        () => db.transactionDao.lendMoney(
          fromAccountId: fundId,
          toAccountId: lendAccId,
          amountCents: 500000, // > 1000
        ),
        throwsA(isA<StateError>()),
      );
      expect((await db.accountDao.getById(fundId))!.balanceCents, 100000);
    });

    test('边界:收款账户不是借出子类型 → ArgumentError', () async {
      // cash2Id 是微信(资金类),不是 lendOut
      expect(
        () => db.transactionDao.lendMoney(
          fromAccountId: fundId,
          toAccountId: cash2Id,
          amountCents: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('边界:同账户 → ArgumentError', () async {
      expect(
        () => db.transactionDao.lendMoney(
          fromAccountId: fundId,
          toAccountId: fundId,
          amountCents: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('borrowMoney', () {
    test('正常:借入账户 + 入款账户,双方余额 +amount', () async {
      final borrowAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '从李四借',
          subType: const Value(AccountSubType.borrowIn),
          balanceCents: const Value(0),
        ),
      );
      final txId = await db.transactionDao.borrowMoney(
        fromAccountId: borrowAccId,
        toAccountId: fundId,
        amountCents: 50000,
        counterparty: '李四',
        startDate: DateTime(2026, 2, 1),
      );
      expect(txId, greaterThan(0));

      final borrowAcc = await db.accountDao.getById(borrowAccId);
      final fund = await db.accountDao.getById(fundId);
      expect(borrowAcc!.balanceCents, 50000, reason: '借入账户负债 +500');
      expect(fund!.balanceCents, 150000, reason: '1000 + 500 = 1500');

      final tx = await db.transactionDao.getById(txId);
      expect(tx!.type, TransactionType.borrow);
      expect(tx.counterpartyName, '李四');
      expect(tx.startDate, DateTime(2026, 2, 1));
    });

    test('自动 seed「借入」分类', () async {
      final borrowAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借入账户',
          subType: const Value(AccountSubType.borrowIn),
        ),
      );
      await db.transactionDao.borrowMoney(
        fromAccountId: borrowAccId,
        toAccountId: fundId,
        amountCents: 10000,
      );
      final cats = await db.categoryDao.getAll();
      expect(cats.any((c) => c.name == '借入'), isTrue);
    });

    test('边界:来源账户不是借入子类型 → ArgumentError', () async {
      expect(
        () => db.transactionDao.borrowMoney(
          fromAccountId: cash2Id, // 微信,不是 borrowIn
          toAccountId: fundId,
          amountCents: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // D25 IQA 修复 M1+M2:DAO 不再写 accounts.initialLendBalanceCents/initialTime
  // (避免已存在账户二次记账被 Value(null) 覆盖 + initialTime 被错误覆盖)。
  // accounts 字段由 UI 在 insertAccount 路径写一次,DAO 仅写 transaction 表。
  group('D25 IQA:DAO 不写 accounts(避免二次记账覆盖)', () {
    test('lendMoney 不写 accounts.initialTime(已有账户二次记账不被覆盖)',
        () async {
      // seed 已存在 lend 账户,initialTime = 2025-01-15(用户已填)
      final initialTime = DateTime(2025, 1, 15);
      final lendAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借出账户',
          subType: const Value(AccountSubType.lendOut),
          initialTime: Value(initialTime),
          initialLendBalanceCents: const Value(50000),
        ),
      );
      // UI _save 路径调用 lendMoney(无 initialTime 参数 — D25 修复后)
      await db.transactionDao.lendMoney(
        fromAccountId: fundId,
        toAccountId: lendAccId,
        amountCents: 10000,
        counterparty: '占位-李四',
        lendStartDate: DateTime(2026, 1, 15),
        lendEndDate: DateTime(2026, 7, 15),
      );
      // 断言:accounts.initialTime 仍是 2025-01-15(未被 DAO 覆盖)
      final acc = await db.accountDao.getById(lendAccId);
      expect(acc!.initialTime, initialTime,
          reason: 'M2 修复:DAO 不应覆盖已存在账户的 initialTime');
      expect(acc.initialLendBalanceCents, 50000,
          reason: 'M1 修复:DAO 不应覆盖已存在账户的 initialLendBalanceCents');
      // 断言:transaction 4 字段正确落库
      final txs = await db.transactionDao.getAll();
      expect(txs, hasLength(1));
      final tx = txs.first;
      expect(tx.lendStartDate, DateTime(2026, 1, 15));
      expect(tx.lendEndDate, DateTime(2026, 7, 15));
      expect(tx.counterpartyName, '占位-李四');
    });

    test('borrowMoney 不写 accounts.initialTime', () async {
      final initialTime = DateTime(2025, 3, 1);
      final borrowAccId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '借入账户',
          subType: const Value(AccountSubType.borrowIn),
          initialTime: Value(initialTime),
          initialLendBalanceCents: const Value(80000),
        ),
      );
      await db.transactionDao.borrowMoney(
        fromAccountId: borrowAccId,
        toAccountId: fundId,
        amountCents: 20000,
        counterparty: '占位-王五',
        lendStartDate: DateTime(2026, 3, 1),
        lendEndDate: DateTime(2027, 3, 1),
      );
      final acc = await db.accountDao.getById(borrowAccId);
      expect(acc!.initialTime, initialTime);
      expect(acc.initialLendBalanceCents, 80000);
      final txs = await db.transactionDao.getAll();
      expect(txs.first.lendStartDate, DateTime(2026, 3, 1));
      expect(txs.first.lendEndDate, DateTime(2027, 3, 1));
    });
  });
}