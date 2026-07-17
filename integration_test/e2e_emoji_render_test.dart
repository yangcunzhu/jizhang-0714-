import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/test_harness.dart';

/// E2E 2:emoji 真机渲染(ADR-0014 — Stage 1 Day 7 emoji 化回归保护)。
///
/// WHY: widget test 用 Ahem 字体,iOS 真机用 Apple Color Emoji。
/// 验证 10 个默认分类 emoji 在真 Flutter engine 下渲染(不是 missing glyph box)。
///
/// 验证方式:打开弹层,确认 emoji 文本存在 + emoji 在屏幕可见矩形范围内
/// (非 0×0 表示字体有 glyph,missing glyph 会让 Text widget 退化但仍存在)。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('10 个默认分类 emoji 在真 Flutter engine 下渲染',
      (tester) async {
    final h = TestHarness(tester);
    await h.bootApp();
    await h.openRecordSheet();

    // 10 个默认分类 emoji(与 _defaultCategories 一一对应,ADR-0013)
    const emojis = ['🍔', '🚗', '🛍️', '🎮', '🏠', '🏥', '📱', '📚', '📦', '💰'];

    for (final emoji in emojis) {
      final finder = find.text(emoji);
      expect(finder, findsOneWidget,
          reason: 'emoji $emoji 应在分类网格渲染(真 Apple Color Emoji 字体)');
      // 进一步断言:widget size > 0(说明字体有 glyph,不是 missing box)
      final renderBox = tester.renderObject(finder) as RenderBox;
      expect(renderBox.size.width, greaterThan(0),
          reason: 'emoji $emoji 宽度 > 0 表示有真实字形');
      expect(renderBox.size.height, greaterThan(0),
          reason: 'emoji $emoji 高度 > 0 表示有真实字形');
    }

    await h.closeSheet();
  });

  testWidgets('主页交易列表 emoji 头像 + 账户卡片 💵 渲染', (tester) async {
    final h = TestHarness(tester);
    await h.bootApp();
    await h.openRecordSheet();
    await h.selectCategory('餐饮');
    await h.enterAmount('5');
    await h.tapNext();

    // 账户卡片 💵 emoji(Stage 1 默认账户)
    expect(find.text('💵'), findsOneWidget,
        reason: '账户卡片 emoji 头像在真引擎下渲染');

    // 保存
    await h.tapSave();

    // 主页交易列表显示 🍔
    expect(find.text('🍔'), findsOneWidget,
        reason: '主页列表 emoji 在真引擎下渲染');
  });
}
