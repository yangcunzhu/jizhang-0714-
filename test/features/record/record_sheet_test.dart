import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/account/application/account_form_provider.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/record/presentation/record_sheet.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  /// 构造外部 ProviderContainer + 预读 stream 首事件,避免 fake_async 卡死。
  Future<void> bootContainer() async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);
    // Day 13：AccountPicker 改用 accountListProvider(多账户),预读首事件避免 fake_async 卡死。
    await container.read(accountListProvider.future);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  /// D27 后 24 分类 GridView 超出默认 test 视口(800x600),不扩展会让 tap 算的
  /// offset 超出 hit test range → "could not find any matching widgets"。
  /// 测试用 `tester.view.physicalSize = ...` 全局扩展到 1000x3000,让弹层
  /// (主页 24 grid + sheet 数字键盘)都能 render + tap。
  void useBigSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// 把弹层嵌进一个最小 host page,提供 MaterialApp + Scaffold + 触发按钮。
  Widget hostWithFab() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showRecordSheet(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('点 open 打开弹层,显示标题"记一笔"和分类列表', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('职业收入'), findsOneWidget,
        reason: 'D27 ADR-0031 「工资收入」→「职业收入」');
    expect(find.text('交通'), findsOneWidget);
  });

  testWidgets('选分类后切到金额步骤,显示 0.00 + 数字键盘', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
  });

  testWidgets('输入 12.34 → 金额显示 12.34', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('.'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();

    expect(find.text('12.34'), findsOneWidget);
  });

  testWidgets('backspace 删掉最后一位 → 12.30', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.text('12.34'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    // 删掉分位最后一位 4：1234 → 1203 = 12.03 元
    expect(find.text('12.03'), findsOneWidget);
  });

  testWidgets('点关闭按钮 → 弹层消失', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('记一笔'), findsNothing);
  });

  testWidgets('金额未填时"下一步"按钮 disabled', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    final nextBtn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '下一步'));
    expect(nextBtn.onPressed, isNull);
  });

  testWidgets('完整流程：选分类 + 输入 12.34 + 下一步 + 保存 → 数据库新增一行 + 弹层关闭',
      (tester) async {
    await bootContainer();
    // D27 24 分类 + 弹层数字键盘超出默认 test 视口,扩展
    useBigSurface(tester);
    await tester.pumpWidget(hostWithFab());

    final initialCount = (await db.transactionDao.getAll()).length;
    expect(initialCount, 0);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Step 1: 选分类"交通"
    await tester.tap(find.text('交通'));
    await tester.pumpAndSettle();

    // Step 2: 输入 12.34
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.text('12.34'), findsOneWidget);

    // Step 2 → Step 3：点"下一步"
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    // Step 3: 显示默认账户 + 保存按钮
    // Day 13：AccountPicker 复用 AccountCard,现金账户同时显示名称"现金"与类型标签"现金"。
    expect(find.text('现金'), findsWidgets);
    expect(find.text('保存'), findsOneWidget);

    // 保存
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    // 弹层关闭
    expect(find.text('记一笔'), findsNothing);

    // 数据库新增一行
    final list = await db.transactionDao.getAll();
    expect(list, hasLength(1));
    expect(list.first.amountCents, 1234);
    expect(list.first.categoryId, isNotNull);
    expect(list.first.accountId, isNotNull);
  });

  testWidgets('备注输入会持久化到交易', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3'));
    await tester.tap(find.text('0'));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    // 在备注输入框里输入"咖啡"
    await tester.enterText(find.byType(TextField), '咖啡');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final list = await db.transactionDao.getAll();
    expect(list, hasLength(1));
    expect(list.first.note, '咖啡');
    expect(list.first.amountCents, 30);
  });

  // D28 IQA-fix M-IQA-D28-2 (2026-08-11):record_sheet step 3 toggle widget 测试
  testWidgets('toggle 默认 false 写入 transactions.excludeFromIncomeExpense=false',
      (tester) async {
    // 完整流程走到 step 3,验证默认 toggle off 写入 db
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    // step 3:验证 2 SwitchListTile 默认 false
    expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('record-toggle-no-income-expense')),
            )
            .value,
        isFalse,
        reason: 'toggle 默认 off');
    expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('record-toggle-no-budget')),
            )
            .value,
        isFalse);

    // 保存
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final list = await db.transactionDao.getAll();
    expect(list.first.excludeFromIncomeExpense, isFalse,
        reason: 'toggle 默认 false 持久化');
    expect(list.first.excludeFromBudget, isFalse);
  });

  testWidgets('打开 toggle 后写入 transactions.excludeFromIncomeExpense=true',
      (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithFab());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    // 打开「不计收支」toggle
    await tester.tap(find.byKey(const Key('record-toggle-no-income-expense')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('record-toggle-no-income-expense')),
            )
            .value,
        isTrue,
        reason: 'toggle 已打开');

    // 保存
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final list = await db.transactionDao.getAll();
    expect(list.first.excludeFromIncomeExpense, isTrue,
        reason: 'toggle 打开后 true 持久化到 db');
    expect(list.first.excludeFromBudget, isFalse,
        reason: '另一个 toggle 默认 false 不变');
  });
}