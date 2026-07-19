// transferMoney DAO 测试(ADR-0026 §5 — 资金账户间转账)。
//
// 覆盖 3 类场景(铁律 8 — 边界必测):
// - 正常:余额够 → 双方余额联动 + 写 transfer 流水
// - 异常:余额不足 → StateError,事务回滚(余额不变)
// - 边界:amount<=0 / 同账户 → ArgumentError
// - 「转账」分类自动 seed

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  late AppDatabase db;
  late int fromId;
  late int toId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.accountDao.getDefault();
    fromId = await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '储蓄卡',
        subType: const Value(AccountSubType.savingsCard),
        balanceCents: const Value(100000), // ¥1000
      ),
    );
    toId = await db.accountDao.insertAccount(
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

  test('正常:转 ¥300 → 双方余额联动 + 写 transfer 流水', () async {
    final id = await db.transactionDao.transferMoney(
      fromAccountId: fromId,
      toAccountId: toId,
      amountCents: 30000,
    );
    expect(id, greaterThan(0));

    final from = await db.accountDao.getById(fromId);
    final to = await db.accountDao.getById(toId);
    expect(from!.balanceCents, 70000, reason: '1000 - 300 = 700');
    expect(to!.balanceCents, 35000, reason: '50 + 300 = 350');

    final tx = await db.transactionDao.getById(id);
    expect(tx!.type, TransactionType.transfer);
    expect(tx.accountId, fromId);
    expect(tx.amountCents, 30000);
  });

  test('自动 seed「转账」分类', () async {
    await db.transactionDao.transferMoney(
      fromAccountId: fromId,
      toAccountId: toId,
      amountCents: 10000,
    );
    final cats = await db.categoryDao.getAll();
    expect(cats.any((c) => c.name == '转账'), isTrue);
  });

  test('异常:余额不足 → StateError,余额回滚', () async {
    expect(
      () => db.transactionDao.transferMoney(
        fromAccountId: fromId,
        toAccountId: toId,
        amountCents: 200000, // > 1000
      ),
      throwsA(isA<StateError>()),
    );
    final from = await db.accountDao.getById(fromId);
    expect(from!.balanceCents, 100000, reason: '失败事务回滚,余额不变');
  });

  test('边界:金额 0 → ArgumentError', () async {
    expect(
      () => db.transactionDao.transferMoney(
        fromAccountId: fromId,
        toAccountId: toId,
        amountCents: 0,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('边界:同账户 → ArgumentError', () async {
    expect(
      () => db.transactionDao.transferMoney(
        fromAccountId: fromId,
        toAccountId: fromId,
        amountCents: 10000,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
