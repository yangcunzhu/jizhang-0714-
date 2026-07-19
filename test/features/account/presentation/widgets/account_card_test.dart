// AccountCard widget 测试。
//
// 决策依据:ADR-0018 — 列表 + emoji 透明背景。
// 覆盖:6 类型 emoji 显示 + 信用卡专项字段 + 不计入净资产标记 + 点击回调。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/features/account/presentation/widgets/account_card.dart';

AccountEntry _entry({
  String name = '现金',
  AccountType type = AccountType.cash,
  int? balanceCents = 0,
  bool includeInNetWorth = true,
  int? creditLimit,
  int? billingDay,
  int? dueDay,
}) {
  return AccountEntry(
    id: 1,
    name: name,
    balanceCents: balanceCents ?? 0,
    type: type,
    includeInNetWorth: includeInNetWorth,
    isPinned: false,
    isDefaultIncomeAccount: false,
    isDefaultExpenseAccount: false,
    creditLimit: creditLimit,
    billingDay: billingDay,
    dueDay: dueDay,
    createdAt: DateTime(2026, 7, 18),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('现金账户:显示 💵 emoji + 名称 + 余额', (tester) async {
    await tester.pumpWidget(_wrap(AccountCard(account: _entry())));
    expect(find.text('💵'), findsOneWidget);
    expect(find.text('现金'), findsWidgets); // name + type.displayName 都显示
    expect(find.textContaining('余额'), findsOneWidget);
  });

  testWidgets('信用卡专项字段(creditCard + 额度/账单日/还款日)显示完整',
      (tester) async {
    await tester.pumpWidget(_wrap(AccountCard(
      account: _entry(
        name: '招行信用卡',
        type: AccountType.creditCard,
        creditLimit: 5000000,
        billingDay: 5,
        dueDay: 25,
      ),
    )));
    expect(find.text('💳'), findsOneWidget);
    expect(find.text('招行信用卡'), findsOneWidget);
    expect(find.text('信用卡'), findsOneWidget);
    expect(find.textContaining('额度'), findsOneWidget);
    expect(find.textContaining('5 号账'), findsOneWidget);
    expect(find.textContaining('25 号还'), findsOneWidget);
  });

  testWidgets('不计入净资产 → 显示「不计入净资产」标记', (tester) async {
    await tester.pumpWidget(_wrap(AccountCard(
      account: _entry(
        name: '货币基金',
        type: AccountType.investment,
        balanceCents: 100000,
        includeInNetWorth: false,
      ),
    )));
    expect(find.text('📈'), findsOneWidget);
    expect(find.text('货币基金'), findsOneWidget);
    expect(find.text('不计入净资产'), findsOneWidget);
  });

  testWidgets('showBalance=false → 不显示余额文本', (tester) async {
    await tester.pumpWidget(_wrap(AccountCard(
      account: _entry(balanceCents: 999),
      showBalance: false,
    )));
    expect(find.text('现金'), findsWidgets);
    expect(find.textContaining('余额'), findsNothing);
    expect(find.textContaining('9.99'), findsNothing);
  });

  testWidgets('onTap 回调触发', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(AccountCard(
      account: _entry(),
      onTap: () => tapped = true,
    )));
    await tester.tap(find.byKey(const Key('account-card-1')));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('信用卡部分字段(只账单日)→ 简化版', (tester) async {
    await tester.pumpWidget(_wrap(AccountCard(
      account: _entry(
        name: '建行卡',
        type: AccountType.creditCard,
        billingDay: 10,
      ),
    )));
    expect(find.textContaining('额度'), findsNothing);
    expect(find.textContaining('10 号账'), findsOneWidget);
  });
}