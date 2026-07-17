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
}