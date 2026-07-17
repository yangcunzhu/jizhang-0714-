// AccountFormController + accountListProvider 单元测试。
//
// 决策依据:ADR-0017 (enum) + ADR-0018 (UI 决策)。
//
// 覆盖:
// - validate() 各种非法场景
// - changeType 切到非信用卡时清空信用卡字段
// - submit() 新建 + 编辑 + 校验失败
// - accountListProvider 实时刷新

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/account/application/account_form_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 等待 onCreate + seed 完成
    await db.accountDao.getDefault();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('AccountFormState.validate()', () {
    test('空名称 → "账户名称不能为空"', () {
      const state = AccountFormState(type: AccountType.cash, name: '');
      expect(state.validate(), '账户名称不能为空');
    });

    test('仅空白的名称 → 校验失败', () {
      const state = AccountFormState(type: AccountType.cash, name: '   ');
      expect(state.validate(), isNotNull);
    });

    test('名称超 20 字 → "账户名称不能超过 20 字"', () {
      final state = AccountFormState(type: AccountType.cash, name: 'a' * 21);
      expect(state.validate(), '账户名称不能超过 20 字');
    });

    test('非信用卡类型 + 任意字段 → 通过校验', () {
      const state = AccountFormState(type: AccountType.savings, name: '活期');
      expect(state.validate(), isNull);
    });

    test('信用卡 + 额度 0 → "信用卡额度必须大于 0"', () {
      const state = AccountFormState(
        type: AccountType.creditCard,
        name: '招行卡',
        creditLimitCents: 0,
      );
      expect(state.validate(), '信用卡额度必须大于 0');
    });

    test('信用卡 + 账单日 0 → "账单日必须在 1-31 之间"', () {
      const state = AccountFormState(
        type: AccountType.creditCard,
        name: '招行卡',
        billingDay: 0,
      );
      expect(state.validate(), '账单日必须在 1-31 之间');
    });

    test('信用卡 + 还款日 32 → "还款日必须在 1-31 之间"', () {
      const state = AccountFormState(
        type: AccountType.creditCard,
        name: '招行卡',
        dueDay: 32,
      );
      expect(state.validate(), '还款日必须在 1-31 之间');
    });

    test('信用卡 + 所有字段合法 → 通过校验', () {
      const state = AccountFormState(
        type: AccountType.creditCard,
        name: '招行卡',
        creditLimitCents: 5000000,
        billingDay: 5,
        dueDay: 25,
      );
      expect(state.validate(), isNull);
    });
  });

  group('AccountFormController', () {
    test('新建场景 — 初始 state 默认 cash + 空名', () {
      final controller =
          container.read(accountFormProvider(null).notifier);
      expect(controller.state.type, AccountType.cash);
      expect(controller.state.name, '');
    });

    test('changeType 切到非信用卡 → 清空 creditLimit/billingDay/dueDay', () {
      final controller =
          container.read(accountFormProvider(null).notifier);
      // 先填信用卡字段
      controller.changeType(AccountType.creditCard);
      controller.changeCreditLimitCents(5000000);
      controller.changeBillingDay(5);
      controller.changeDueDay(25);

      // 切到储蓄
      controller.changeType(AccountType.savings);

      expect(controller.state.type, AccountType.savings);
      expect(controller.state.creditLimitCents, isNull);
      expect(controller.state.billingDay, isNull);
      expect(controller.state.dueDay, isNull);
    });

    test('changeType 切到信用卡 → 保留信用卡字段(不强制清空)', () {
      final controller =
          container.read(accountFormProvider(null).notifier);
      controller.changeType(AccountType.creditCard);
      controller.changeCreditLimitCents(100);
      controller.changeBillingDay(1);
      // 切到 cash 再切回 creditCard
      controller.changeType(AccountType.cash);
      controller.changeType(AccountType.creditCard);
      // 重新切换后字段保持空(因为 cash 切走时已清空)
      expect(controller.state.creditLimitCents, isNull);
      expect(controller.state.billingDay, isNull);
    });

    test('submit() 新建 → 数据库新增一行,返回 true', () async {
      final controller =
          container.read(accountFormProvider(null).notifier);
      controller.changeType(AccountType.creditCard);
      controller.changeName('招行卡');
      controller.changeCreditLimitCents(5000000);
      controller.changeBillingDay(5);
      controller.changeDueDay(25);

      final ok = await controller.submit();
      expect(ok, isTrue);

      final accounts = await db.accountDao.getAll();
      expect(accounts, hasLength(2)); // seed 现金 + 新增招行卡
      final cmb = accounts.firstWhere((a) => a.name == '招行卡');
      expect(cmb.type, AccountType.creditCard);
      expect(cmb.creditLimit, 5000000);
      expect(cmb.billingDay, 5);
      expect(cmb.dueDay, 25);
    });

    test('submit() 校验失败(空名) → 返回 false,数据库不变', () async {
      final controller =
          container.read(accountFormProvider(null).notifier);
      // 名字留空
      controller.changeType(AccountType.savings);

      final before = await db.accountDao.getAll();
      final ok = await controller.submit();
      expect(ok, isFalse);
      final after = await db.accountDao.getAll();
      expect(after.length, before.length, reason: '校验失败不应写库');
    });

    test('submit() 编辑已有账户(existingId 非空) → 更新该行', () async {
      // 先创建
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(name: '临时账户'),
      );
      // 用编辑 controller
      final controller =
          container.read(accountFormProvider(id).notifier);
      // 等异步加载完成后改名字
      await Future.delayed(const Duration(milliseconds: 10));
      controller.changeName('修改后');

      final ok = await controller.submit();
      expect(ok, isTrue);

      final updated = await db.accountDao.getById(id);
      expect(updated!.name, '修改后');
    });

    test('changeIncludeInNetWorth 切换有效', () {
      final controller =
          container.read(accountFormProvider(null).notifier);
      expect(controller.state.includeInNetWorth, isTrue);
      controller.changeIncludeInNetWorth(false);
      expect(controller.state.includeInNetWorth, isFalse);
      controller.changeIncludeInNetWorth(true);
      expect(controller.state.includeInNetWorth, isTrue);
    });
  });

  group('accountListProvider', () {
    test('初次订阅返回当前 accounts(1 条 seed)', () async {
      final accounts = await container.read(accountListProvider.future);
      expect(accounts, hasLength(1));
      expect(accounts.single.name, '现金');
    });

    test('accountListProvider 反映数据库写入', () async {
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(name: '新账户'),
      );
      // 给 Drift stream 一点时间 emit
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final accounts = await container.read(accountListProvider.future);
      expect(accounts.length, 2);
      expect(accounts.any((a) => a.name == '新账户'), isTrue);
    });
  });
}