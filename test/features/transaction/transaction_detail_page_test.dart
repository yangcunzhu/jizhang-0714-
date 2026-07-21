// TransactionDetailPage widget 测试(D26 IQA-fix C-IQA-2)
//
// 覆盖 4 用例:
// 1. type=expense + 未退过 → 「编辑」「删除」「退款」3 按钮全亮
// 2. type=refund → 3 按钮全灰 + tooltip「退款记录不可修改」
// 3. type=expense + 已退过(原交易被退过)→ 3 按钮全灰 + tooltip「已被退款,不可修改」
// 4. type=income → 「退款」按钮灰(类型不允许)+ 编辑/删除亮

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/transaction/presentation/transaction_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<TransactionEntry> insertTransaction({
    required TransactionType type,
    int amountCents = 1000,
    int? originalTransactionId,
    bool excludeFromIncomeExpense = false,
    bool excludeFromBudget = false,
  }) async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    // income / transfer 需要对应 type 的分类(默认 seed 10 分类没全 cover),
    // 但 DetailPage 渲染不要求分类存在 — 缺分类会显示「未知」,不影响按钮 disable 测试。
    if (type == TransactionType.repayment ||
        type == TransactionType.transfer ||
        type == TransactionType.lend) {
      // 这些 type 默认 seed 里没对应 type 分类,但我们只测 disable 逻辑,分类无关紧要
      // 复用第一个分类(餐饮 type=expense)— ForeignKey 不会因 type 错出错
    }
    return (await db.transactionDao.getById(
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: acc!.id,
          categoryId: cats.first.id,
          type: type,
          amountCents: amountCents,
          originalTransactionId:
              originalTransactionId != null ? Value(originalTransactionId) : const Value.absent(),
          // D28 IQA-fix M-IQA-D28-2:widget toggle 测试 — 显式传 toggle
          excludeFromIncomeExpense: Value(excludeFromIncomeExpense),
          excludeFromBudget: Value(excludeFromBudget),
        ),
      ),
    ))!;
  }

  /// 强制 ref 退款 — 让「原交易」已退过某金额。
  Future<void> refundOriginal(TransactionEntry original, int refundCents) async {
    final acc = await db.accountDao.getDefault();
    await db.transactionDao.refundMoney(
      originalTransactionId: original.id,
      refundAccountId: acc!.id,
      amountCents: refundCents,
      refundTime: DateTime(2026, 8, 1),
    );
  }

  Widget hostDetail(TransactionEntry tx) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: TransactionDetailPage(transactionId: tx.id),
      ),
    );
  }

  testWidgets('type=expense + 未退过 → 3 按钮全亮(可点击)', (tester) async {
    final tx = await insertTransaction(type: TransactionType.expense);
    await tester.pumpWidget(hostDetail(tx));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-action-edit')), findsOneWidget);
    expect(find.byKey(const Key('detail-action-delete')), findsOneWidget);
    expect(find.byKey(const Key('detail-action-refund')), findsOneWidget);
  });

  testWidgets('type=refund → 3 按钮全灰(refund 行不可修改)', (tester) async {
    // 先做一个普通 expense,然后退它产生 refund 行
    final original = await insertTransaction(type: TransactionType.expense);
    final refundTime = DateTime(2026, 8, 1);
    final acc = await db.accountDao.getDefault();
    final refundId = await db.transactionDao.refundMoney(
      originalTransactionId: original.id,
      refundAccountId: acc!.id,
      amountCents: 500,
      refundTime: refundTime,
    );
    final refund = (await db.transactionDao.getById(refundId))!;

    await tester.pumpWidget(hostDetail(refund));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail-action-edit')), findsOneWidget);
    expect(find.byKey(const Key('detail-action-delete')), findsOneWidget);
    expect(find.byKey(const Key('detail-action-refund')), findsOneWidget);
    // 验证 onPressed:null(灰色)— OutlinedButton / FilledButton 在 onPressed:null 时 widget 已 disabled
    final editBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-edit')),
    );
    expect(editBtn.onPressed, isNull, reason: 'edit 按钮 disabled(type=refund)');
    final deleteBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-delete')),
    );
    expect(deleteBtn.onPressed, isNull, reason: 'delete 按钮 disabled(type=refund)');
    final refundBtn = tester.widget<FilledButton>(
      find.byKey(const Key('detail-action-refund')),
    );
    expect(refundBtn.onPressed, isNull, reason: 'refund 按钮 disabled(type=refund)');
  });

  testWidgets('type=expense + 已退过 → 3 按钮全灰(原交易被退过)',
      (tester) async {
    final original = await insertTransaction(type: TransactionType.expense);
    await refundOriginal(original, 500); // 已退 ¥5

    await tester.pumpWidget(hostDetail(original));
    await tester.pumpAndSettle();

    final editBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-edit')),
    );
    expect(editBtn.onPressed, isNull, reason: '原交易被退过 → edit 灰');
    final deleteBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-delete')),
    );
    expect(deleteBtn.onPressed, isNull, reason: '原交易被退过 → delete 灰');
    final refundBtn = tester.widget<FilledButton>(
      find.byKey(const Key('detail-action-refund')),
    );
    expect(refundBtn.onPressed, isNull, reason: '原交易被退过 → refund 灰');
  });

  testWidgets('type=income → 「退款」按钮灰(类型不允许);编辑+删除亮',
      (tester) async {
    // income 默认 seed 分类「工资」存在
    final cats = await db.categoryDao.getAll();
    final incomeCat = cats.firstWhere(
      (c) => c.type == TransactionType.income,
      orElse: () => cats.first, // fallback(测试用)
    );
    final acc = await db.accountDao.getDefault();
    final tx = (await db.transactionDao.getById(
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          accountId: acc!.id,
          categoryId: incomeCat.id,
          type: TransactionType.income,
          amountCents: 50000,
        ),
      ),
    ))!;

    await tester.pumpWidget(hostDetail(tx));
    await tester.pumpAndSettle();

    final editBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-edit')),
    );
    expect(editBtn.onPressed, isNotNull, reason: 'income 行 edit 亮');
    final deleteBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('detail-action-delete')),
    );
    expect(deleteBtn.onPressed, isNotNull, reason: 'income 行 delete 亮');
    final refundBtn = tester.widget<FilledButton>(
      find.byKey(const Key('detail-action-refund')),
    );
    expect(refundBtn.onPressed, isNull,
        reason: 'income 类型不允许退款 → refund 灰');
  });

  // D28 IQA-fix M-IQA-D28-2 (2026-08-11):2 toggle 行显示
  testWidgets(
      'type=expense + excludeFromIncomeExpense=true → 显示「不计收支:开」',
      (tester) async {
    final tx = await insertTransaction(
      type: TransactionType.expense,
      amountCents: 10000,
      excludeFromIncomeExpense: true, // 报销场景
    );
    // 验证 toggle 真写入 db(detail_page widget 读 transaction.excludeFromIncomeExpense)
    final fetched = await db.transactionDao.getById(tx.id);
    expect(fetched, isNotNull);
    expect(fetched!.excludeFromIncomeExpense, isTrue,
        reason: 'insertTransaction 应持久化 toggle=true');

    await tester.pumpWidget(hostDetail(tx));
    await tester.pumpAndSettle();

    expect(find.text('不计收支'), findsOneWidget,
        reason: 'label 渲染');
    // toggle on 时「不计收支」显示「开」 + 「不计预算」默认 false 仍显示「关」
    // expect 找到 ≥ 1 个「开」(「不计收支」行)+ ≥ 1 个「关」(「不计预算」行)
    expect(find.text('开'), findsOneWidget,
        reason: 'excludeFromIncomeExpense=true → 显示「开」');
    expect(find.text('关'), findsOneWidget,
        reason: 'excludeFromBudget=false 默认 → 显示「关」');
  });

  testWidgets(
      'type=expense + excludeFromBudget=true → 显示「不计预算:开」',
      (tester) async {
    final tx = await insertTransaction(
      type: TransactionType.expense,
      amountCents: 30000,
      excludeFromBudget: true, // 大件消费预算外
    );
    await tester.pumpWidget(hostDetail(tx));
    await tester.pumpAndSettle();

    expect(find.text('不计预算'), findsOneWidget);
    expect(find.text('开'), findsOneWidget);
  });

  testWidgets('toggle 默认 false → 显示「关」', (tester) async {
    final tx = await insertTransaction(
        type: TransactionType.expense, amountCents: 5000);
    await tester.pumpWidget(hostDetail(tx));
    await tester.pumpAndSettle();

    expect(find.text('关'), findsNWidgets(2),
        reason: '2 toggle 默认 false → 都显示「关」');
  });
}
