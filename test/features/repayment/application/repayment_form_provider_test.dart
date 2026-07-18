// RepaymentFormController 单元测试(D20 — 信用卡还款流)。
//
// 覆盖:
// - canSubmit 校验逻辑(储蓄 + 信用卡 + 金额 > 0 + 未提交中)
// - submit 成功路径:调 transferRepayment + reset state + invalidate
// - submit 失败路径:StateError 透传错误信息
// - submit 边界:同一账户 = 储蓄 + 信用卡

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/repayment/application/repayment_form_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int cashAccountId;
  late int creditCardId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountDao.getDefault(); // 等 seed 完成

    // 创建 1 个现金账户(余额 10000)和 1 个信用卡账户(余额 0)
    cashAccountId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '现金',
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

    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('RepaymentFormState.canSubmit', () {
    test('空状态 → canSubmit = false', () {
      const state = RepaymentFormState.initial;
      expect(state.canSubmit, isFalse);
    });

    test('只有金额 > 0 → canSubmit = false(还差储蓄/信用卡)', () {
      const state = RepaymentFormState(amountCents: 50000);
      expect(state.canSubmit, isFalse);
    });

    test('储蓄 + 信用卡 + 金额 → canSubmit = true', () {
      const state = RepaymentFormState(
        fromSavingsAccountId: 1,
        toCreditCardAccountId: 2,
        amountCents: 50000,
      );
      expect(state.canSubmit, isTrue);
    });

    test('金额 = 0 → canSubmit = false', () {
      const state = RepaymentFormState(
        fromSavingsAccountId: 1,
        toCreditCardAccountId: 2,
        amountCents: 0,
      );
      expect(state.canSubmit, isFalse);
    });

    test('提交中 → canSubmit = false', () {
      const state = RepaymentFormState(
        fromSavingsAccountId: 1,
        toCreditCardAccountId: 2,
        amountCents: 50000,
        isSubmitting: true,
      );
      expect(state.canSubmit, isFalse);
    });
  });

  group('RepaymentFormController', () {
    test('setAmount / setFromSavingsAccount / setToCreditCardAccount setter 有效',
        () {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setAmount(50000);
      controller.setToCreditCardAccount(creditCardId);
      controller.setNote('还 8 月账单');

      expect(controller.state.fromSavingsAccountId, cashAccountId);
      expect(controller.state.amountCents, 50000);
      expect(controller.state.toCreditCardAccountId, creditCardId);
      expect(controller.state.note, '还 8 月账单');
      expect(controller.state.canSubmit, isTrue);
    });

    test('submit 成功路径:扣储蓄 + 减信用卡已用 + 写 repayment transaction',
        () async {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setToCreditCardAccount(creditCardId);
      controller.setAmount(50000); // 500 元

      final ok = await controller.submit();
      expect(ok, isTrue);

      // 储蓄 -500
      final cash = await db.accountDao.getById(cashAccountId);
      expect(cash!.balanceCents, 1000000 - 50000);

      // 信用卡已用 -500(从 0 变 -500,极端情况允许)
      final card = await db.accountDao.getById(creditCardId);
      expect(card!.balanceCents, -50000);

      // 写了一条 repayment
      final txList = await db.transactionDao.getAll();
      expect(txList, hasLength(1));
      expect(txList.first.type, TransactionType.repayment);
    });

    test('submit 后 state 重置,避免下次打开弹层残留上次输入', () async {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setToCreditCardAccount(creditCardId);
      controller.setAmount(50000);

      await controller.submit();

      expect(controller.state.fromSavingsAccountId, isNull);
      expect(controller.state.toCreditCardAccountId, isNull);
      expect(controller.state.amountCents, 0);
    });

    test('submit 边界:储蓄账户余额不足 → 失败 + 状态保留', () async {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setToCreditCardAccount(creditCardId);
      controller.setAmount(99999999); // 远超储蓄余额

      final ok = await controller.submit();
      expect(ok, isFalse);
      expect(controller.state.errorMessage, contains('余额不足'));
      expect(controller.state.isSubmitting, isFalse,
          reason: '失败后 isSubmitting 应该复位');
    });

    test('submit 边界:同一账户 = 储蓄 + 信用卡 → 失败', () async {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setToCreditCardAccount(cashAccountId); // 同一个!
      controller.setAmount(1000);

      final ok = await controller.submit();
      expect(ok, isFalse);
      expect(controller.state.errorMessage, contains('不能是同一个'));
    });

    test('submit 边界:amount = 0 → canSubmit = false, 不调 transferRepayment',
        () async {
      final controller = container.read(repaymentFormProvider.notifier);
      controller.setFromSavingsAccount(cashAccountId);
      controller.setToCreditCardAccount(creditCardId);
      controller.setAmount(0);

      final ok = await controller.submit();
      expect(ok, isFalse);
      expect(controller.state.errorMessage, isNull,
          reason: 'canSubmit 已经是 false,submit 早返回,无错误信息');
    });
  });

  group('储蓄/信用卡候选 provider', () {
    test('savingsAccountListProvider 包含现金 + 储蓄 + 网贷(不含信用卡/花呗/理财)',
        () async {
      // 添加一个储蓄账户
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '活期',
          type: const Value(AccountType.savings),
        ),
      );
      final list = await container.read(savingsAccountListProvider.future);
      // 应该包含:seed 现金 + 我创建的 现金 + 储蓄
      expect(list.length, greaterThanOrEqualTo(2));
      expect(list.any((a) => a.type == AccountType.cash), isTrue);
      expect(list.any((a) => a.type == AccountType.savings), isTrue);
      // 不应包含信用卡
      expect(list.any((a) => a.type == AccountType.creditCard), isFalse);
    });

    test('creditCardAccountListProvider 只含信用卡', () async {
      final list = await container.read(creditCardAccountListProvider.future);
      expect(list, hasLength(1));
      expect(list.single.type, AccountType.creditCard);
      expect(list.single.name, '招行信用卡');
    });
  });
}