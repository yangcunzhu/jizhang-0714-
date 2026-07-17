import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/home/presentation/home_page.dart';
import 'package:jizhang_app/features/home/presentation/widgets/transaction_actions_sheet.dart';
import 'package:jizhang_app/features/record/application/record_form_provider.dart';

/// ActionSheet 测试套件(Day 8):
/// - 长按触发
/// - 3 个 action(编辑/退款/删除)正确渲染 + Key 标注存在
/// - 删除 action:DAO deleteById + SnackBar
/// - 退款 action:反向 insert + SnackBar
/// - 编辑 action:loadForEdit + 复用 recordSheet
/// - 主页 ListTile 长按入口
///
/// 所有测试都用内存 SQLite(Drift NativeDatabase.memory())+ ProviderScope override。
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CategoryEntry expenseCat;
  late AccountEntry acc;

  Future<void> bootContainer() async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);
    final cats = await db.categoryDao.getAll();
    expenseCat = cats.first; // 餐饮(支出)
    acc = (await db.accountDao.getDefault())!;
  }

  Future<int> insertSampleExpense({
    int amountCents = 1299,
    String note = '咖啡',
  }) {
    return db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: amountCents,
        type: TransactionType.expense,
        categoryId: expenseCat.id,
        accountId: acc.id,
        note: Value(note),
      ),
    );
  }

  /// 用 HomePage 套一个最小 host,模拟真实长按入口。
  Widget hostWithHome() {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomePage()),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ----- TransactionActionsSheet 直接渲染 -----

  group('TransactionActionsSheet 直接渲染', () {
    testWidgets('显示 3 个 action + Key 标注 + 标题', (tester) async {
      await bootContainer();
      final id = await insertSampleExpense();
      final tx = (await db.transactionDao.getById(id))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: tx),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('交易操作'), findsOneWidget);
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('退款'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      // Key 标注存在(ADR-0014)
      expect(find.byKey(const Key('txn-action-edit')), findsOneWidget);
      expect(find.byKey(const Key('txn-action-refund')), findsOneWidget);
      expect(find.byKey(const Key('txn-action-delete')), findsOneWidget);
    });

    testWidgets('点外部 / 把手区域不会误触 action', (tester) async {
      await bootContainer();
      final id = await insertSampleExpense();
      final tx = (await db.transactionDao.getById(id))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: tx),
            ),
          ),
        ),
      );
      await tester.pump();

      // 点标题不会触发任何 action(只是装饰)
      await tester.tap(find.text('交易操作'));
      await tester.pump();

      // 数据库仍 1 条(没有 insert/delete)
      final all = await db.transactionDao.getAll();
      expect(all, hasLength(1));
    });
  });

  // ----- 删除 action -----

  group('删除 action', () {
    testWidgets('点"删除"→ DAO 删除 + SnackBar "已删除"', (tester) async {
      await bootContainer();
      final id = await insertSampleExpense();
      expect((await db.transactionDao.getAll()), hasLength(1));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(
                key: const Key('test-sheet'),
                transaction: (await db.transactionDao.getById(id))!,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('txn-action-delete')));
      await tester.pump(); // SnackBar 入场
      await tester.pump(const Duration(milliseconds: 100));

      expect((await db.transactionDao.getAll()), isEmpty);
      expect(find.text('已删除'), findsOneWidget);
    });
  });

  // ----- 退款 action -----

  group('退款 action(方案 A)', () {
    testWidgets('点"退款"→ 反向 insert 一笔 + SnackBar "已退款"',
        (tester) async {
      await bootContainer();
      final id = await insertSampleExpense(amountCents: 1299, note: '咖啡');
      final original = (await db.transactionDao.getById(id))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: original),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('txn-action-refund')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 数据库:原 1 笔 + 退款 1 笔 = 2 笔
      final all = await db.transactionDao.getAll();
      expect(all, hasLength(2));
      // 原交易不变
      expect(all.where((t) => t.id == original.id), hasLength(1));
      // 退款那笔:同金额、反向类型、反向分类、note 加 "退款" 前缀
      final refund = all.firstWhere((t) => t.id != original.id);
      expect(refund.amountCents, original.amountCents);
      expect(refund.type, TransactionType.income);
      expect(refund.accountId, original.accountId);
      expect(refund.note, '退款 · 咖啡');
      expect(find.text('已退款'), findsOneWidget);
    });

    testWidgets('收入交易退款 → 类型变支出 + note "退款"', (tester) async {
      await bootContainer();
      final cats = await db.categoryDao.getAll();
      final incomeCat = cats.firstWhere((c) => c.type == TransactionType.income);
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 5000,
          type: TransactionType.income,
          categoryId: incomeCat.id,
          accountId: acc.id,
          note: const Value('工资'),
        ),
      );
      final original = (await db.transactionDao.getById(id))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: original),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('txn-action-refund')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final all = await db.transactionDao.getAll();
      final refund = all.firstWhere((t) => t.id != original.id);
      expect(refund.type, TransactionType.expense);
      expect(refund.amountCents, 5000);
      expect(refund.note, '退款 · 工资');
    });

    testWidgets('原交易 note 为空 → 退款 note 仅 "退款"', (tester) async {
      await bootContainer();
      final id = await insertSampleExpense(note: '');
      final original = (await db.transactionDao.getById(id))!;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: original),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('txn-action-refund')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final refund = (await db.transactionDao.getAll())
          .firstWhere((t) => t.id != original.id);
      expect(refund.note, '退款');
    });
  });

  // ----- 编辑 action -----

  group('编辑 action', () {
    testWidgets('点"编辑"→ loadForEdit 把状态切到编辑模式(form 状态正确)',
        (tester) async {
      await bootContainer();
      final id = await insertSampleExpense(amountCents: 1234, note: '咖啡');
      final original = (await db.transactionDao.getById(id))!;

      // 宿主仅含 ActionSheet,避免主页 TransactionTile 干扰"咖啡"出现次数判断
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TransactionActionsSheet(transaction: original),
            ),
          ),
        ),
      );
      await tester.pump();

      // ActionSheet 弹出
      expect(find.text('交易操作'), findsOneWidget);

      // 点编辑 → loadForEdit 触发
      await tester.tap(find.byKey(const Key('txn-action-edit')));
      await tester.pump(); // Navigator.pop + showRecordSheet
      await tester.pumpAndSettle();

      // form state 已切到编辑模式
      final form = container.read(recordFormProvider);
      expect(form.isEditing, true);
      expect(form.editingTransactionId, original.id);
      expect(form.amountCents, 1234);
      expect(form.categoryId, original.categoryId);
      expect(form.accountId, original.accountId);
      expect(form.note, '咖啡');
    });
  });

  // ----- 主页长按入口 -----

  group('主页长按入口', () {
    testWidgets('长按交易 → 主页弹出 ActionSheet', (tester) async {
      await bootContainer();
      final id = await insertSampleExpense();

      await tester.pumpWidget(hostWithHome());
      await tester.pump();

      expect(find.byKey(Key('txn-$id')), findsOneWidget);
      await tester.longPress(find.byKey(Key('txn-$id')));
      await tester.pumpAndSettle();

      expect(find.text('交易操作'), findsOneWidget);
    });
  });
}