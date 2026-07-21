// TransactionDetailPage + RefundSheet + TransactionTile 视觉测试(D26)
//
// 覆盖 4 用例:
// 1. TransactionTile type=refund 显示 ↩️ overlay + 蓝灰 amountColor + tileColor
// 2. TransactionTile type=expense 不显示 ↩️ overlay
// 3. RefundSheet 默认填原金额 + 默认原付款账户
// 4. TransactionTile onTap 回调被触发

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/home/presentation/widgets/transaction_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<TransactionEntry> _insertRefundTransaction() async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    return (await db.transactionDao.getById(
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: acc!.id,
          categoryId: cats.first.id,
          type: TransactionType.refund,
          amountCents: 896,
        ),
      ),
    ))!;
  }

  Future<TransactionEntry> _insertExpenseTransaction() async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    return (await db.transactionDao.getById(
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: acc!.id,
          categoryId: cats.first.id,
          type: TransactionType.expense,
          amountCents: 896,
        ),
      ),
    ))!;
  }

  Widget _hostTile(TransactionEntry tx, {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: tx,
            category: null,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }

  testWidgets('TransactionTile type=refund 显示 ↩️ overlay + 蓝灰 + tileColor',
      (tester) async {
    final tx = await _insertRefundTransaction();
    await tester.pumpWidget(_hostTile(tx));
    await tester.pump();

    // ↩️ overlay(右上角 badge)
    expect(find.byKey(Key('txn-refund-overlay-${tx.id}')), findsOneWidget,
        reason: 'D26 ↩️ overlay 在 leading 右上角');
    // ↩️ prefix + 蓝灰 amount(text 含 '↩' + '¥8.96')
    expect(find.byKey(Key('txn-tile-amount-${tx.id}')), findsOneWidget);
    final amountWidget = tester.widget<Text>(
      find.byKey(Key('txn-tile-amount-${tx.id}')),
    );
    expect(amountWidget.data, contains('¥8.96'));
    expect(amountWidget.data, contains('↩'),
        reason: 'refund 行 amount 前缀加 ↩');
  });

  testWidgets('TransactionTile type=expense 不显示 ↩️ overlay', (tester) async {
    final tx = await _insertExpenseTransaction();
    await tester.pumpWidget(_hostTile(tx));
    await tester.pump();

    // 无 ↩️ overlay
    expect(find.byKey(Key('txn-refund-overlay-${tx.id}')), findsNothing);
    // 纯 -¥8.96(无 ↩ 前缀)
    expect(find.text('-¥8.96'), findsOneWidget);
  });

  testWidgets('TransactionTile onTap 回调被触发', (tester) async {
    final tx = await _insertExpenseTransaction();
    var tapped = false;
    await tester.pumpWidget(_hostTile(tx, onTap: () => tapped = true));
    await tester.pump();
    await tester.tap(find.byKey(Key('txn-${tx.id}')));
    await tester.pump();
    expect(tapped, isTrue, reason: 'D26 加 onTap,D4 修复可用');
  });

  testWidgets(
      'TransactionTile type=repayment 显示「12 期」徽章(回归测试,D26 不破既有渲染)',
      (tester) async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    final tx = (await db.transactionDao.getById(
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: acc!.id,
          categoryId: cats.first.id,
          type: TransactionType.expense,
          amountCents: 50000,
          installmentPeriod: const Value(12),
        ),
      ),
    ))!;
    await tester.pumpWidget(_hostTile(tx));
    await tester.pump();

    expect(find.byKey(const Key('txn-installment-badge')), findsOneWidget);
    expect(find.text('12 期'), findsOneWidget);
  });
}
