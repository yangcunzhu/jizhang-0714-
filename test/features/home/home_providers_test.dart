import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('transactionListProvider 初始为空列表', () async {
    final list = await container.read(transactionListProvider.future);
    expect(list, isEmpty);
  });

  test('categoryListProvider 包含 10 个 seed 分类(9 支出 + 1 收入),按 sortOrder 升序',
      () async {
    final cats = await container.read(categoryListProvider.future);
    expect(cats, hasLength(10));
    expect(cats.first.name, '餐饮');
    expect(cats.last.name, '工资');
    expect(cats.first.type, TransactionType.expense);
    expect(cats.last.type, TransactionType.income);
  });

  test('defaultAccountProvider 返回 seed 的"现金"账户', () async {
    final acc = await container.read(defaultAccountProvider.future);
    expect(acc, isNotNull);
    expect(acc!.name, '现金');
    expect(acc.balanceCents, 0);
  });

  test('插入交易后 transactionListProvider 实时刷新', () async {
    final cats = await container.read(categoryListProvider.future);
    final acc = await container.read(defaultAccountProvider.future);

    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 500,
        type: TransactionType.expense,
        categoryId: cats.first.id,
        accountId: acc!.id,
        note: const Value('咖啡'),
      ),
    );

    final list = await container.read(transactionListProvider.future);
    expect(list, hasLength(1));
    expect(list.first.amountCents, 500);
    expect(list.first.note, '咖啡');
  });
}