import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2E 测试语义化查找器(ADR-0014)。
///
/// WHY: 集中所有 find.* 写在这,Day 8 加 Key 后只用 byKey 找元素 — 改文案不改测试。
/// 混用:文字查找保留给"测试该文案本身"的场景(如期望出现"已记账"SnackBar)。
class Selectors {
  Selectors._();

  // ---- 主页 ----
  static Finder homeAppBar() => find.text('审计官');
  static Finder homeAssetCard() => find.text('净资产');
  static Finder homeEmpty() => find.byKey(const Key('home-empty'));
  /// FAB:全 app 唯一,用类型找比 GlobalKey 字符串匹配更稳。
  static Finder recordFab() => find.byType(FloatingActionButton);

  /// 交易列表项:Key('txn-{id}')
  static Finder transactionTile(int id) => find.byKey(Key('txn-$id'));

  // ---- 弹层 ----
  static Finder recordSheetTitle() => find.text('记一笔');
  static Finder recordSheetClose() =>
      find.byKey(const Key('record-sheet-close'));
  static Finder recordSheetBack() =>
      find.byKey(const Key('record-sheet-back'));
  static Finder recordSheetPrimary() =>
      find.byKey(const Key('record-sheet-primary'));

  // ---- 弹层 step 导航(旧 text-based,避免改 record_sheet)----
  static Finder nextButton() => find.widgetWithText(FilledButton, '下一步');
  static Finder saveButton() => find.widgetWithText(FilledButton, '保存');

  // ---- 分类网格 ----
  static Finder categoryTile(String name) => find.byKey(Key('emoji-$name'));

  // ---- 金额键盘 ----
  static Finder digit(String d) => find.byKey(Key('digit-$d'));
  static Finder digitDot() => find.byKey(const Key('digit-dot'));
  static Finder digitBackspace() => find.byKey(const Key('digit-backspace'));
  static Finder amountDisplay() => find.textContaining('¥');

  // ---- Step 3 账户 + 备注 ----
  static Finder accountCard() => find.byKey(const Key('account-card'));
  static Finder addAccountButton() => find.byKey(const Key('btn-add-account'));
  static Finder noteField() => find.byKey(const Key('record-note'));

  // ---- 长按 ActionSheet(Day 8 引入)----
  static Finder actionSheetEdit() =>
      find.byKey(const Key('txn-action-edit'));
  static Finder actionSheetRefund() =>
      find.byKey(const Key('txn-action-refund'));
  static Finder actionSheetDelete() =>
      find.byKey(const Key('txn-action-delete'));

  // ---- SnackBar ----
  static Finder snackBar(String content) => find.text(content);
}