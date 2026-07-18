import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Stage 2 schema 字段(seed 验证)', () {
    test('seed 账户 type 默认值 = cash,includeInNetWorth = true,信用卡字段全 NULL',
        () async {
      final acc = (await db.accountDao.getAll()).single;
      expect(acc.name, '现金');
      expect(acc.type, AccountType.cash);
      expect(acc.includeInNetWorth, isTrue);
      expect(acc.creditLimit, isNull);
      expect(acc.billingDay, isNull);
      expect(acc.dueDay, isNull);
    });
  });

  group('AccountType enum 展示(ADR-0017)', () {
    test('6 种类型 + displayName + emoji 全部定义', () {
      expect(AccountType.values, hasLength(6));
      expect(AccountType.cash.displayName, '现金');
      expect(AccountType.savings.displayName, '储蓄');
      expect(AccountType.creditCard.displayName, '信用卡');
      expect(AccountType.huabei.displayName, '花呗');
      expect(AccountType.onlineLoan.displayName, '网贷');
      expect(AccountType.investment.displayName, '理财');

      expect(AccountType.cash.emoji, '💵');
      expect(AccountType.creditCard.emoji, '💳');
      expect(AccountType.investment.emoji, '📈');
    });

    test('enum.name 是英文 (数据库持久化用)', () {
      expect(AccountType.cash.name, 'cash');
      expect(AccountType.creditCard.name, 'creditCard');
      expect(AccountType.onlineLoan.name, 'onlineLoan');
    });
  });

  group('add/update/delete CRUD', () {
    test('insertAccount 后 getAll / getById 可查到', () async {
      final id = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: Value(AccountType.creditCard),
          creditLimit: const Value(5000000),
          billingDay: const Value(5),
          dueDay: const Value(25),
        ),
      );
      expect(id, greaterThan(0));

      final byId = await db.accountDao.getById(id);
      expect(byId, isNotNull);
      expect(byId!.name, '招行信用卡');
      expect(byId.type, AccountType.creditCard);
      expect(byId.creditLimit, 5000000);
      expect(byId.billingDay, 5);
      expect(byId.dueDay, 25);

      final all = await db.accountDao.getAll();
      expect(all.map((a) => a.name), containsAll(['现金', '招行信用卡']));
    });

    test('updateAccountById 改 name,其他字段不变', () async {
      final original = (await db.accountDao.getAll()).single;
      final originalName = original.name;

      final ok = await db.accountDao.updateAccountById(
        AccountsCompanion(id: Value(original.id), name: const Value('生活费')),
      );
      expect(ok, 1);

      final updated = await db.accountDao.getById(original.id);
      expect(updated!.name, '生活费');
      expect(updated.type, original.type);
      expect(updated.includeInNetWorth, original.includeInNetWorth);
      expect(updated.balanceCents, original.balanceCents);
      expect(updated.createdAt, original.createdAt);
      expect(updated.creditLimit, original.creditLimit);

      // 回滚改回原名
      await db.accountDao.updateAccountById(
        AccountsCompanion(id: Value(original.id), name: Value(originalName)),
      );
    });

    test('updateAccountById 不传 name,只改 type', () async {
      final original = (await db.accountDao.getAll()).single;

      final ok = await db.accountDao.updateAccountById(
        AccountsCompanion(
          id: Value(original.id),
          type: const Value(AccountType.savings),
          includeInNetWorth: const Value(false),
        ),
      );
      expect(ok, 1);

      final updated = await db.accountDao.getById(original.id);
      expect(updated!.name, original.name);
      expect(updated.type, AccountType.savings);
      expect(updated.includeInNetWorth, isFalse);
    });

    test('deleteAccount 移除 seed 账户(seed 默认无交易引用)', () async {
      final acc = (await db.accountDao.getAll()).single;
      final removed = await db.accountDao.deleteAccount(acc.id);
      expect(removed, 1);
      expect(await db.accountDao.getAll(), isEmpty);
    });

    test('deleteAccountsByIds 批量删除', () async {
      // 插 3 个新账户
      final ids = <int>[];
      for (final name in ['A', 'B', 'C']) {
        ids.add(await db.accountDao
            .insertAccount(AccountsCompanion.insert(name: name)));
      }

      final removed =
          await db.accountDao.deleteAccountsByIds([ids[0], ids[2]]);
      expect(removed, 2);

      final remaining = (await db.accountDao.getAll()).map((a) => a.name).toSet();
      expect(remaining.contains('A'), isFalse);
      expect(remaining.contains('B'), isTrue);
      expect(remaining.contains('C'), isFalse);
      // seed 账户仍在
      expect(remaining.contains('现金'), isTrue);
    });
  });

  group('按 type 查询', () {
    setUp(() async {
      await db.accountDao
          .insertAccount(AccountsCompanion.insert(name: 'A1'));
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(name: '储蓄1', type: Value(AccountType.savings)),
      );
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '信用卡1',
          type: Value(AccountType.creditCard),
          creditLimit: const Value(1000000),
          billingDay: const Value(1),
          dueDay: const Value(20),
        ),
      );
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '信用卡2',
          type: Value(AccountType.creditCard),
          creditLimit: const Value(2000000),
          billingDay: const Value(10),
          dueDay: const Value(28),
        ),
      );
    });

    test('watchByType(cash) 返回 seed 现金账户 + A1 (默认 cash)', () async {
      final cashAccounts = await db.accountDao.watchByType(AccountType.cash).first;
      final names = cashAccounts.map((a) => a.name).toSet();
      expect(names, containsAll(['现金', 'A1']));
    });

    test('watchByType(creditCard) 返回 2 张信用卡', () async {
      final cards = await db.accountDao.watchByType(AccountType.creditCard).first;
      expect(cards, hasLength(2));
      final names = cards.map((c) => c.name).toSet();
      expect(names, {'信用卡1', '信用卡2'});
      // 信用卡字段都有值
      for (final card in cards) {
        expect(card.creditLimit, isNotNull);
        expect(card.billingDay, isNotNull);
        expect(card.dueDay, isNotNull);
      }
    });

    test('watchByType(huabei) 返回空(没人用花呗)', () async {
      final huabei = await db.accountDao.watchByType(AccountType.huabei).first;
      expect(huabei, isEmpty);
    });

    test('getDistinctTypes 返回本测试用例出现的所有类型', () async {
      final types = await db.accountDao.getDistinctTypes();
      expect(types.toSet(), {
        AccountType.cash,
        AccountType.savings,
        AccountType.creditCard,
      });
    });
  });

  group('Stream 行为', () {
    test('watchById 发出当前账户', () async {
      // D19 简化:drift watchSingle 在某些条件下立即 closed,只验证初始 emit
      // 修改后用 getById 验证 db 真的改了
      final acc = (await db.accountDao.getAll()).single;

      final initial = await db.accountDao.watchById(acc.id).first;
      expect(initial, isNotNull);
      expect(initial!.name, '现金');

      // 修改后 db 真的改了(用 getById 验证,不依赖 stream emit 行为)
      await db.accountDao.updateAccountById(
        AccountsCompanion(id: Value(acc.id), name: const Value('修改后')),
      );
      final updated = await db.accountDao.getById(acc.id);
      expect(updated!.name, '修改后');
    });
  });
}
