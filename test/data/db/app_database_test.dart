import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('默认数据 seed', () {
    test('首次建库植入单一"现金"账户', () async {
      final accounts = await db.accountDao.getAll();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, '现金');
      expect(accounts.single.balanceCents, 0);

      final def = await db.accountDao.getDefault();
      expect(def, isNotNull);
      expect(def!.name, '现金');
    });

    test('首次建库植入 10 个默认分类(8 支出 + 2 收入),按 sortOrder 升序', () async {
      final cats = await db.categoryDao.getAll();
      expect(cats, hasLength(10));

      final expense =
          cats.where((c) => c.type == TransactionType.expense).length;
      final income =
          cats.where((c) => c.type == TransactionType.income).length;
      expect(expense, 8);
      expect(income, 2);

      final orders = cats.map((c) => c.sortOrder).toList();
      final sorted = [...orders]..sort();
      expect(orders, sorted);
      expect(cats.first.name, '餐饮');
    });
  });

  group('交易 CRUD', () {
    Future<int> firstCategoryId() async =>
        (await db.categoryDao.getAll()).first.id;
    Future<int> defaultAccountId() async =>
        (await db.accountDao.getDefault())!.id;

    test('插入一笔交易后可查询到,金额以整数分存储', () async {
      final catId = await firstCategoryId();
      final accId = await defaultAccountId();

      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 1299,
          type: TransactionType.expense,
          categoryId: catId,
          accountId: accId,
          note: const Value('午饭'),
        ),
      );
      expect(id, greaterThan(0));

      final all = await db.transactionDao.getAll();
      expect(all, hasLength(1));
      expect(all.single.amountCents, 1299);
      expect(all.single.type, TransactionType.expense);
      expect(all.single.note, '午饭');
    });

    test('多笔交易按 occurredAt 倒序返回(最新在前)', () async {
      final catId = await firstCategoryId();
      final accId = await defaultAccountId();

      final older = DateTime(2026, 7, 1, 8);
      final newer = DateTime(2026, 7, 17, 12);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 100,
          type: TransactionType.expense,
          categoryId: catId,
          accountId: accId,
          occurredAt: Value(older),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 200,
          type: TransactionType.expense,
          categoryId: catId,
          accountId: accId,
          occurredAt: Value(newer),
        ),
      );

      final all = await db.transactionDao.getAll();
      expect(all.map((t) => t.amountCents).toList(), [200, 100]);
    });

    test('更新交易金额生效', () async {
      final catId = await firstCategoryId();
      final accId = await defaultAccountId();

      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 500,
          type: TransactionType.expense,
          categoryId: catId,
          accountId: accId,
        ),
      );

      final entry = (await db.transactionDao.getAll()).single;
      final ok = await db.transactionDao.updateTransaction(
        entry.copyWith(amountCents: 888),
      );
      expect(ok, isTrue);

      final updated = (await db.transactionDao.getAll()).single;
      expect(updated.id, id);
      expect(updated.amountCents, 888);
    });

    test('删除交易后列表为空', () async {
      final catId = await firstCategoryId();
      final accId = await defaultAccountId();

      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 999,
          type: TransactionType.income,
          categoryId: catId,
          accountId: accId,
        ),
      );

      final removed = await db.transactionDao.deleteById(id);
      expect(removed, 1);
      expect(await db.transactionDao.getAll(), isEmpty);
    });

    test('watchAll 发出交易变更', () async {
      final catId = await firstCategoryId();
      final accId = await defaultAccountId();

      final stream = db.transactionDao.watchAll();
      expect(
        stream,
        emitsThrough(
          predicate<List<TransactionEntry>>(
            (list) => list.length == 1 && list.single.amountCents == 3300,
          ),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 3300,
          type: TransactionType.expense,
          categoryId: catId,
          accountId: accId,
        ),
      );
    });
  });
}
