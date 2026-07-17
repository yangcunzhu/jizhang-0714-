import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/features/home/presentation/widgets/confetti_burst.dart';

/// ConfettiBurst 测试(Day 9):
/// - 静态 fire 入口不抛错
/// - 无效 originKey(Widget 未挂载)静默返回,无 crash
/// - 动画完成后 OverlayEntry 自动 remove
/// - Widget 渲染无 crash,CustomPainter 不抛
void main() {
  testWidgets('ConfettiBurst.fire 无效 originKey(空 context)静默返回', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    // 一个无效的 GlobalKey,从未 attach 到任何 widget
    final orphanKey = GlobalKey();
    final buildContext = tester.element(find.byType(Scaffold));

    // 不应抛错
    ConfettiBurst.fire(buildContext, originKey: orphanKey);
    await tester.pump();
    expect(find.byType(ConfettiBurst), findsNothing,
        reason: '无效 originKey 时不应插入 Overlay');
  });

  testWidgets('ConfettiBurst.fire 有效 originKey 触发动画,500ms 后自移除',
      (tester) async {
    final fabKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingActionButton(
              key: fabKey,
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // fire 动画
    ConfettiBurst.fire(tester.element(find.byType(Scaffold)), originKey: fabKey);
    await tester.pump();

    // 动画初期 ConfettiBurst widget 存在(OverlayEntry 内)
    expect(find.byType(ConfettiBurst), findsOneWidget,
        reason: 'fire 后应立即有 ConfettiBurst 在 Overlay');

    // 推进到动画结束(500ms)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // 动画结束 → OverlayEntry remove → ConfettiBurst 消失
    expect(find.byType(ConfettiBurst), findsNothing,
        reason: '动画完成后 OverlayEntry 应自移除');
  });

  testWidgets('ConfettiBurst.fire 自定义颜色', (tester) async {
    final anchorKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: anchorKey,
            width: 100,
            height: 100,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
      ),
    );

    ConfettiBurst.fire(
      tester.element(find.byType(Scaffold)),
      originKey: anchorKey,
      color: Colors.red,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 不抛错 + ConfettiBurst 在
    expect(find.byType(ConfettiBurst), findsOneWidget);

    // 清理
    await tester.pumpAndSettle();
  });
}