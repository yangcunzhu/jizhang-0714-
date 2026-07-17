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

void main() {
  late AppDatabase db;

  /// 构造一个外部 ProviderContainer,预先 .future 同步拿到 stream 首个 event,
  /// 避免 widget tree 在 fake_async 中等待 Drift 真 timer 卡死。
  Future<ProviderContainer> bootContainer(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);
    return container;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('空态主页显示净资产占位 + 提示文案 + 记一笔按钮', (tester) async {
    final container = await bootContainer(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('审计官'), findsOneWidget);
    expect(find.text('净资产'), findsOneWidget);
    expect(find.text('暂未计算'), findsOneWidget);
    expect(find.text('还没有记账'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
  });

  testWidgets('有数据主页：交易列表渲染分类名 + 金额 + 备注', (tester) async {
    final cats = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 1299,
        type: TransactionType.expense,
        categoryId: cats.first.id,
        accountId: acc!.id,
        note: const Value('午饭'),
      ),
    );

    final container = await bootContainer(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('餐饮'), findsOneWidget);
    expect(find.textContaining('午饭'), findsOneWidget);
    expect(find.text('-¥12.99'), findsOneWidget);
    expect(find.text('还没有记账'), findsNothing);
  });
}