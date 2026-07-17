// AccountPicker widget 测试（Day 13 — 多账户选择器）。
//
// 覆盖：多账户列表渲染、类型 emoji、余额、选中高亮、点选回调、
// 切换选中、"添加账户"跳转、空态、信用卡专项字段、净资产标记、备注。
//
// StreamProvider 测试范式：pumpWidget → runAsync(delay 50ms 让 Drift 走真 timer)
// → pump()，与 account_management_page_test 一致（见 Day 12 收尾卡）。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/record/presentation/widgets/account_picker.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 等 onCreate + seed（单一"现金"账户 id=1）完成。
    await db.accountDao.getDefault();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// 把 AccountPicker 嵌进最小 host，模拟记账弹层 Step 3 的容器。
  Widget host({
    int? selectedAccountId,
    ValueChanged<int>? onAccountSelected,
    String initialNote = '',
    ValueChanged<String>? onNoteChanged,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountPicker(
              selectedAccountId: selectedAccountId,
              onAccountSelected: onAccountSelected ?? (_) {},
              initialNote: initialNote,
              onNoteChanged: onNoteChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  /// pump + 让 Drift stream 完成首次 emit。
  Future<void> pumpPicker(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }

  Future<void> addSavings(String name, {int balanceCents = 0}) {
    return db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: name,
        type: const Value(AccountType.savings),
        balanceCents: Value(balanceCents),
      ),
    );
  }

  testWidgets('列出全部账户：现金 seed + 储蓄 + 信用卡 → 3 张卡片', (tester) async {
    await addSavings('招行储蓄');
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '招行信用卡',
        type: const Value(AccountType.creditCard),
      ),
    );

    await pumpPicker(tester, host());

    expect(find.byKey(const Key('account-option-1')), findsOneWidget);
    expect(find.byKey(const Key('account-option-2')), findsOneWidget);
    expect(find.byKey(const Key('account-option-3')), findsOneWidget);
    expect(find.text('现金'), findsWidgets);
    expect(find.text('招行储蓄'), findsOneWidget);
    expect(find.text('招行信用卡'), findsOneWidget);
  });

  testWidgets('账户头像按类型显示对应 emoji（💵 / 🏦 / 💳）', (tester) async {
    await addSavings('储蓄卡');
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '信用卡',
        type: const Value(AccountType.creditCard),
      ),
    );

    await pumpPicker(tester, host());

    expect(find.text('💵'), findsOneWidget);
    expect(find.text('🏦'), findsOneWidget);
    expect(find.text('💳'), findsOneWidget);
  });

  testWidgets('账户余额格式化显示（¥123.45）', (tester) async {
    await addSavings('储蓄卡', balanceCents: 12345);

    await pumpPicker(tester, host());

    expect(find.textContaining('123.45'), findsOneWidget);
  });

  testWidgets('selectedAccountId 指向账户 → 显示选中 check', (tester) async {
    await pumpPicker(tester, host(selectedAccountId: 1));

    expect(find.byKey(const Key('account-selected-1')), findsOneWidget);
  });

  testWidgets('未选中的账户不显示 check', (tester) async {
    await addSavings('储蓄卡');

    await pumpPicker(tester, host(selectedAccountId: 1));

    expect(find.byKey(const Key('account-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('account-selected-2')), findsNothing);
  });

  testWidgets('selectedAccountId=null → 无任何 check', (tester) async {
    await addSavings('储蓄卡');

    await pumpPicker(tester, host(selectedAccountId: null));

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('selectedAccountId 指向不存在的账户 → 无 check（边界值）', (tester) async {
    await addSavings('储蓄卡');

    await pumpPicker(tester, host(selectedAccountId: 999));

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('点击账户 → onAccountSelected 携带该 id', (tester) async {
    await addSavings('储蓄卡');
    int? picked;

    await pumpPicker(tester, host(onAccountSelected: (id) => picked = id));
    await tester.tap(find.byKey(const Key('account-card-2')));
    await tester.pump();

    expect(picked, 2);
  });

  testWidgets('点已选中账户 → 回调仍触发（幂等）', (tester) async {
    int? picked;

    await pumpPicker(
      tester,
      host(selectedAccountId: 1, onAccountSelected: (id) => picked = id),
    );
    await tester.tap(find.byKey(const Key('account-card-1')));
    await tester.pump();

    expect(picked, 1);
  });

  testWidgets('两次点击不同账户 → 回调各自携带正确 id', (tester) async {
    await addSavings('储蓄卡');
    final picked = <int>[];

    await pumpPicker(tester, host(onAccountSelected: picked.add));
    await tester.tap(find.byKey(const Key('account-card-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account-card-2')));
    await tester.pump();

    expect(picked, [1, 2]);
  });

  testWidgets('切换选中：点账户 2 → 高亮从 1 移到 2', (tester) async {
    await addSavings('储蓄卡');

    await tester.pumpWidget(_SelectionHost(container: container, initial: 1));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byKey(const Key('account-selected-1')), findsOneWidget);
    expect(find.byKey(const Key('account-selected-2')), findsNothing);

    await tester.tap(find.byKey(const Key('account-card-2')));
    await tester.pump();

    expect(find.byKey(const Key('account-selected-1')), findsNothing);
    expect(find.byKey(const Key('account-selected-2')), findsOneWidget);
  });

  testWidgets('"添加账户"按钮存在', (tester) async {
    await pumpPicker(tester, host());

    expect(find.byKey(const Key('btn-add-account')), findsOneWidget);
  });

  testWidgets('账户列表非空时"添加账户"按钮仍在列表下方', (tester) async {
    await addSavings('储蓄卡');

    await pumpPicker(tester, host());

    expect(find.byKey(const Key('account-option-1')), findsOneWidget);
    expect(find.byKey(const Key('btn-add-account')), findsOneWidget);
  });

  testWidgets('点"添加账户" → 跳转账户管理页', (tester) async {
    await pumpPicker(tester, host());

    await tester.tap(find.byKey(const Key('btn-add-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('账户管理'), findsOneWidget);
  });

  testWidgets('账户列表为空 → 空态文案 + 仍有添加按钮', (tester) async {
    await db.accountDao.deleteAccount(1); // 删掉 seed

    await pumpPicker(tester, host());

    expect(find.text('还没有账户，先添加一个吧'), findsOneWidget);
    expect(find.byKey(const Key('btn-add-account')), findsOneWidget);
  });

  testWidgets('信用卡账户显示信用卡专项字段（复用 AccountCard）', (tester) async {
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '招行信用卡',
        type: const Value(AccountType.creditCard),
        creditLimit: const Value(5000000), // ¥50000
        billingDay: const Value(5),
        dueDay: const Value(25),
      ),
    );

    await pumpPicker(tester, host());

    expect(find.textContaining('额度'), findsOneWidget);
    expect(find.textContaining('5 号账 / 25 号还'), findsOneWidget);
  });

  testWidgets('不计入净资产账户显示标记', (tester) async {
    await db.accountDao.insertAccount(
      AccountsCompanion.insert(
        name: '基金账户',
        type: const Value(AccountType.investment),
        includeInNetWorth: const Value(false),
      ),
    );

    await pumpPicker(tester, host());

    expect(find.text('不计入净资产'), findsOneWidget);
  });

  testWidgets('备注初始值回填到输入框', (tester) async {
    await pumpPicker(tester, host(initialNote: '午饭'));

    expect(find.text('午饭'), findsOneWidget);
  });

  testWidgets('备注输入 → onNoteChanged 回调', (tester) async {
    String? note;

    await pumpPicker(tester, host(onNoteChanged: (v) => note = v));
    await tester.enterText(find.byKey(const Key('record-note')), '咖啡');

    expect(note, '咖啡');
  });
}

/// 有状态 host：把 onAccountSelected 回写 selectedAccountId，
/// 用于测试"点选后高亮真实切换"。
class _SelectionHost extends StatefulWidget {
  const _SelectionHost({required this.container, this.initial});

  final ProviderContainer container;
  final int? initial;

  @override
  State<_SelectionHost> createState() => _SelectionHostState();
}

class _SelectionHostState extends State<_SelectionHost> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: widget.container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountPicker(
              selectedAccountId: _selected,
              onAccountSelected: (id) => setState(() => _selected = id),
              initialNote: '',
              onNoteChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }
}
