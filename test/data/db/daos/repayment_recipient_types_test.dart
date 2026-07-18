// transferRepayment 4 种收款类型 + 3 类场景测试(ADR-0024 §1 + §3)。
//
// 覆盖矩阵(4 收款类型 × 3 场景 = 12 用例):
// 1. 信用卡(creditCard) × 正常 / 异常(余额不足) / 边界(amount=0)
// 2. 花呗(huabei) × 3 场景
// 3. 网贷(onlineLoan) × 3 场景(含 installmentPeriod 校验)
// 4. 储蓄(savings) 作为收款方 → 应失败(必须是欠款类)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';

void main() {
  late AppDatabase db;
  late int cashId; // 扣款方
  late int creditCardId;
  late int huabeiId;
  late int onlineLoanId;
  late int savingsId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountDao.getDefault();
    // 删除 seed 默认现金账户,重新建
    await db.customStatement('DELETE FROM accounts WHERE name = ?', ['现金']);

    cashId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '我的现金',
        type: const Value(AccountType.cash),
        balanceCents: const Value(1000000), // 10000 元
      ),
    );
    creditCardId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '招行信用卡',
        type: const Value(AccountType.creditCard),
        creditLimit: const Value(5000000),
        billingDay: const Value(5),
        dueDay: const Value(25),
      ),
    );
    huabeiId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '花呗',
        type: const Value(AccountType.huabei),
        creditLimit: const Value(300000),
        dueDay: const Value(10),
      ),
    );
    onlineLoanId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '借呗',
        type: const Value(AccountType.onlineLoan),
        creditLimit: const Value(500000),
        dueDay: const Value(20),
      ),
    );
    savingsId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '活期',
        type: const Value(AccountType.savings),
        balanceCents: const Value(500000),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('1. 信用卡收款 × 3 场景', () {
    test('正常:储蓄 -500 + 信用卡已用 -500', () async {
      final result = await db.transactionDao.transferRepayment(
        fromAccountId: cashId,
        toAccountId: creditCardId,
        amountCents: 50000,
      );
      expect(result, isPositive);
      expect((await db.accountDao.getById(cashId))!.balanceCents, 950000);
      expect((await db.accountDao.getById(creditCardId))!.balanceCents, -50000);
    });

    test('异常:储蓄余额不足 → StateError + 事务回滚', () async {
      await expectLater(
        db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: creditCardId,
          amountCents: 99999999,
        ),
        throwsA(isA<StateError>()),
      );
      // 余额 + transaction 不变
      expect((await db.accountDao.getById(cashId))!.balanceCents, 1000000);
      expect((await db.transactionDao.getAll()), isEmpty);
    });

    test('边界:amount = 0 → ArgumentError', () async {
      expect(
        () => db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: creditCardId,
          amountCents: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('2. 花呗收款 × 3 场景', () {
    test('正常:储蓄 -300 + 花呗已用 -300', () async {
      final result = await db.transactionDao.transferRepayment(
        fromAccountId: cashId,
        toAccountId: huabeiId,
        amountCents: 30000,
      );
      expect(result, isPositive);
      expect((await db.accountDao.getById(cashId))!.balanceCents, 970000);
      expect((await db.accountDao.getById(huabeiId))!.balanceCents, -30000);
    });

    test('异常:储蓄余额不足 → 失败 + 回滚', () async {
      await expectLater(
        db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: huabeiId,
          amountCents: 99999999,
        ),
        throwsA(isA<StateError>()),
      );
      expect((await db.accountDao.getById(cashId))!.balanceCents, 1000000);
    });

    test('花呗不要求 installment_period(普通一次性还款)', () async {
      final result = await db.transactionDao.transferRepayment(
        fromAccountId: cashId,
        toAccountId: huabeiId,
        amountCents: 5000,
        // installmentPeriod: null(花呗没分期概念)
      );
      expect(result, isPositive);
      // 写入的 transaction.installment_period = null
      final txList = await db.transactionDao.getAll();
      expect(txList.single.installmentPeriod, isNull);
    });
  });

  group('3. 网贷收款 × 3 场景', () {
    test('正常:储蓄 -500 + 借呗已用 -500 + 12 期', () async {
      final result = await db.transactionDao.transferRepayment(
        fromAccountId: cashId,
        toAccountId: onlineLoanId,
        amountCents: 50000,
        installmentPeriod: 12,
      );
      expect(result, isPositive);
      expect((await db.accountDao.getById(cashId))!.balanceCents, 950000);
      expect((await db.accountDao.getById(onlineLoanId))!.balanceCents,
          -50000);
      // 写入的 transaction.installment_period = 12
      final txList = await db.transactionDao.getAll();
      expect(txList.single.installmentPeriod, 12);
    });

    test('异常:网贷还款必须传 installment_period → ArgumentError', () async {
      expect(
        () => db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: onlineLoanId,
          amountCents: 5000,
          // installmentPeriod: null → 应失败
        ),
        throwsArgumentError,
        reason: '网贷还款必须传期数(>=1)',
      );
    });

    test('异常:网贷还款 + installment_period=0 → ArgumentError', () async {
      expect(
        () => db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: onlineLoanId,
          amountCents: 5000,
          installmentPeriod: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('4. 储蓄作为收款方(应失败 — 储蓄不是欠款类)', () {
    test('正常路径:不允许储蓄当收款方', () async {
      expect(
        () => db.transactionDao.transferRepayment(
          fromAccountId: cashId,
          toAccountId: savingsId, // 储蓄,不是欠款类
          amountCents: 1000,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}