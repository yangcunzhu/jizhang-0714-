import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jizhang_app/main.dart' as app;

/// 共享 E2E 测试工具(ADR-0014)。
///
/// 真 Flutter engine + 真 SQLite 文件 + 真 Plugin Channel 启动整个 app。
/// 仅在 iOS/Android 真机或模拟器上跑(`flutter test integration_test/`)。
///
/// WHY: widget test 的 fake_async + 内存 SQLite 覆盖不到真机场景(字体、文件、
/// Plugin、impeller 渲染),E2E 是 0 成本路线下覆盖真机问题的最便宜路径。
class TestHarness {
  TestHarness(this.tester);

  final WidgetTester tester;

  /// 启动整个 app 并等待首屏稳定。
  ///
  /// WHY: ProviderScope 创建 + 主页 AsyncValue 第一次 resolve 需要时间。
  /// 2 秒窗口足够;若仍 loading 可在外层 await pumpAndSettle 重试。
  Future<void> bootApp() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await tester.binding.setSurfaceSize(const Size(414, 896)); // iPhone 11 Pro
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// 点 FAB 打开记账弹层。
  Future<void> openRecordSheet() async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  /// 通过分类中文名点击(emoji cat grid)。
  ///
  /// WHY: 分类名是 emoji grid 唯一稳定文本(emoji 在不同字号渲染有差异)。
  Future<void> selectCategory(String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  /// 输入金额(append 数字 + dot)。
  ///
  /// WHY: AmountKeypad 的 button 文本就是 '1'..'9' '.',不依赖 Key。
  Future<void> enterAmount(String digits) async {
    for (final ch in digits.split('')) {
      await tester.tap(find.text(ch));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// 点底部"下一步"按钮。
  Future<void> tapNext() async {
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();
  }

  /// 点底部"保存"按钮。
  Future<void> tapSave() async {
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
  }

  /// 关闭弹层(顶栏 X)。
  Future<void> closeSheet() async {
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  }
}
