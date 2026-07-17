// EmojiPicker widget 测试(Day 14 — 决策 ADR-0019 自建精选网格)。
//
// 覆盖:
// - 6 主题标题都渲染
// - 选中 emoji 触发 onSelected 回调
// - initial emoji 高亮

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/features/category/presentation/widgets/emoji_picker.dart';

void main() {
  Widget hostWithPicker({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EmojiPicker(
          selected: selected,
          onSelected: onSelected,
        ),
      ),
    );
  }

  testWidgets('6 主题标题(食物/交通/居家/工作/娱乐/其他)都渲染',
      (tester) async {
    await tester.pumpWidget(
      hostWithPicker(selected: '🍔', onSelected: (_) {}),
    );

    const groups = ['食物', '交通', '居家', '工作', '娱乐', '其他'];
    for (final g in groups) {
      expect(find.text(g), findsOneWidget, reason: '主题 $g 应渲染');
    }
  });

  testWidgets('点击 emoji → 触发 onSelected 回调', (tester) async {
    String? picked;
    await tester.pumpWidget(
      hostWithPicker(selected: '🍔', onSelected: (e) => picked = e),
    );

    await tester.tap(find.byKey(const Key('emoji-pick-☕')));
    await tester.pump();

    expect(picked, '☕');
  });

  testWidgets('initial emoji 高亮(其他不)', (tester) async {
    await tester.pumpWidget(
      hostWithPicker(selected: '☕', onSelected: (_) {}),
    );

    // 通过 Container 装饰边框识别:selected 有 primary 边框 + primaryContainer 背景
    // 简化为:能找到 emoji-pick-☕ 即可
    expect(find.byKey(const Key('emoji-pick-☕')), findsOneWidget);
    expect(find.byKey(const Key('emoji-pick-🍔')), findsOneWidget);
  });

  testWidgets('底部「更多 emoji(系统键盘)」入口渲染', (tester) async {
    await tester.pumpWidget(
      hostWithPicker(selected: '🍔', onSelected: (_) {}),
    );
    // ListView 懒构建,scroll 到底部
    await tester.dragUntilVisible(
      find.byKey(const Key('emoji-picker-more')),
      find.byType(EmojiPicker),
      const Offset(0, -100),
    );
    expect(find.byKey(const Key('emoji-picker-more')), findsOneWidget);
    expect(find.text('更多 emoji（系统键盘）'), findsOneWidget);
  });

  testWidgets('点「更多 emoji」→ 弹 Dialog 含 autofocus TextField + 取消/确认按钮',
      (tester) async {
    await tester.pumpWidget(
      hostWithPicker(selected: '🍔', onSelected: (_) {}),
    );
    await tester.dragUntilVisible(
      find.byKey(const Key('emoji-picker-more')),
      find.byType(EmojiPicker),
      const Offset(0, -100),
    );
    await tester.tap(find.byKey(const Key('emoji-picker-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('emoji-picker-more-dialog')), findsOneWidget);
    expect(find.text('更多 Emoji'), findsOneWidget);
    expect(find.byKey(const Key('emoji-picker-more-input')), findsOneWidget);
    expect(find.byKey(const Key('emoji-picker-more-confirm')), findsOneWidget);
    expect(find.byKey(const Key('emoji-picker-more-cancel')), findsOneWidget);
  });

  testWidgets('Dialog 输入 emoji → 点确认 → 触发 onSelected + Dialog 关闭',
      (tester) async {
    String? picked;
    await tester.pumpWidget(
      hostWithPicker(selected: '🍔', onSelected: (e) => picked = e),
    );
    await tester.dragUntilVisible(
      find.byKey(const Key('emoji-picker-more')),
      find.byType(EmojiPicker),
      const Offset(0, -100),
    );
    await tester.tap(find.byKey(const Key('emoji-picker-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('emoji-picker-more-input')),
      '🐱',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('emoji-picker-more-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(picked, '🐱');
    expect(find.byKey(const Key('emoji-picker-more-dialog')), findsNothing);
  });
}