// TransferSheet widget 测试(ADR-0026 §5)。
//
// 覆盖:
// - 标题「转账」
// - 账户 < 2 时显示提示,不显示下拉
// - 有 ≥2 账户时显示扣款/入款下拉
// - 选账户 + 输金额 → 保存成功落库 + pop(true)
// - 取消 → pop(false)

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/transfer/presentation/transfer_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> seedTwo() async {
    await db.accountDao.getDefault();
    await db.accountDao.insertAccount(AccountsCompanion.insert(
      name: '储蓄卡',
      subType: const Value(AccountSubType.savingsCard),
      balanceCents: const Value(100000),
    ));
    await db.accountDao.insertAccount(AccountsCompanion.insert(
      name: '微信',
      subType: const Value(AccountSubType.wechat),
      balanceCents: const Value(5000),
    ));
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: TransferSheet())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('标题「转账」', (tester) async {
    await seedTwo();
    await pump(tester);
    expect(find.text('转账'), findsWidgets);
  });

  testWidgets('账户不足 2 个 → 显示提示', (tester) async {
    // 只有默认现金 1 个可转账账户
    await db.accountDao.getDefault();
    await pump(tester);
    expect(find.byKey(const Key('transfer-not-enough-accounts')), findsOneWidget);
    expect(find.byKey(const Key('transfer-from-account')), findsNothing);
  });

  testWidgets('≥2 账户 → 显示扣款/入款下拉 + 金额', (tester) async {
    await seedTwo();
    await pump(tester);
    expect(find.byKey(const Key('transfer-from-account')), findsOneWidget);
    expect(find.byKey(const Key('transfer-to-account')), findsOneWidget);
    expect(find.byKey(const Key('transfer-amount')), findsOneWidget);
  });

  testWidgets('选账户 + 输金额 → 保存成功落库', (tester) async {
    await seedTwo();
    bool? popResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    popResult = await showTransferSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final accounts = await db.accountDao.getAll();
    final from = accounts.firstWhere((a) => a.name == '储蓄卡');
    final to = accounts.firstWhere((a) => a.name == '微信');

    await tester.tap(find.byKey(const Key('transfer-from-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('💳 储蓄卡（¥1000.00）').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transfer-to-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('💬 微信（¥50.00）').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('transfer-amount')), '300');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('transfer-save')));
    await tester.tap(find.byKey(const Key('transfer-save')));
    await tester.pumpAndSettle();

    expect(popResult, isTrue);
    final fromAfter = await db.accountDao.getById(from.id);
    final toAfter = await db.accountDao.getById(to.id);
    expect(fromAfter!.balanceCents, 70000);
    expect(toAfter!.balanceCents, 35000);
  });

  testWidgets('取消 → pop(false)', (tester) async {
    await seedTwo();
    bool? popResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    popResult = await showTransferSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transfer-cancel')));
    await tester.pumpAndSettle();
    expect(popResult, isFalse);
  });
}
