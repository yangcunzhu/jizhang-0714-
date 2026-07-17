import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2E 测试语义化查找器(ADR-0014)。
///
/// WHY: 集中所有 find.* 写在这,Day 8 加 Key 后只需改这里不用改测试本体。
class Selectors {
  Selectors._();

  // ---- 主页 ----
  static Finder homeEmpty() => find.text('还没有记账');
  static Finder homeAssetCard() => find.text('净资产');
  static Finder homeAppBar() => find.text('审计官');

  // ---- 弹层 ----
  static Finder recordSheetTitle() => find.text('记一笔');
  static Finder recordSheetClose() => find.byIcon(Icons.close);
  static Finder recordSheetBack() => find.byIcon(Icons.arrow_back);

  // ---- 底部按钮 ----
  static Finder fab() => find.byType(FloatingActionButton);
  static Finder nextButton() => find.widgetWithText(FilledButton, '下一步');
  static Finder saveButton() => find.widgetWithText(FilledButton, '保存');

  // ---- 金额键盘 ----
  static Finder digit(String d) => find.text(d);
  static Finder amountDisplay() => find.textContaining('¥');

  // ---- 账户卡片 ----
  static Finder accountCard(String name) => find.text(name);
  static Finder addAccountButton() => find.text('添加账户');

  // ---- SnackBar ----
  static Finder snackBar(String content) => find.text(content);
}
