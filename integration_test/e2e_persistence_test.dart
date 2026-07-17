import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/selectors.dart';
import '_helpers/test_harness.dart';

/// E2E 3:生命周期持久化(ADR-0014 — 真 SQLite 文件而非内存)。
///
/// 验证路径:
/// 1. 启动 app,记一笔 → 主页显示
/// 2. 模拟 app 进入后台 + 回前台(对应真机锁屏回来)
/// 3. 主页数据仍在 + 不重新 seed
///
/// 限制:本测试不验证"杀进程 + 重启",那是真机 Day 10 手动验收场景。
/// 只验证"暂停 → 恢复"生命周期不丢数据(SQLite 文件 + ProviderScope 状态)。
///
/// WHY: widget test 不会触发 AppLifecycleState,这是真机专属场景。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('记账 → app 暂停 → app 恢复 → 数据仍在', (tester) async {
    final h = TestHarness(tester);
    await h.bootApp();

    // 1. 记一笔
    await h.openRecordSheet();
    await h.selectCategory('交通');
    await h.enterAmount('8888');
    await h.tapNext();
    await h.tapSave();

    // 2. 主页显示新交易
    expect(find.text('交通'), findsOneWidget);
    expect(Selectors.homeEmpty(), findsNothing);

    // 3. 模拟 app 暂停 → 真机锁屏
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.text('交通'), findsOneWidget,
        reason: '暂停后 widget tree 仍可见 SQLite 数据');

    // 4. 模拟 app 恢复 → 真机解锁
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('交通'), findsOneWidget,
        reason: '恢复后主页交易仍在(真持久化)');
    expect(Selectors.homeEmpty(), findsNothing,
        reason: '不会因为恢复而重置为空态(seed 已写一次)');
  });

  testWidgets('连续记 3 笔 → 暂停 → 恢复 → 3 笔全在', (tester) async {
    final h = TestHarness(tester);
    await h.bootApp();

    Future<void> recordOne(String cat, String amount) async {
      await h.openRecordSheet();
      await h.selectCategory(cat);
      await h.enterAmount(amount);
      await h.tapNext();
      await h.tapSave();
    }

    await recordOne('餐饮', '30');  // 30 cents → ¥0.30
    await recordOne('交通', '500');  // 500 cents → ¥5.00
    await recordOne('娱乐', '99');   // 99 cents → ¥0.99

    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
    expect(find.text('娱乐'), findsOneWidget);

    // 暂停 → 恢复
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
    expect(find.text('娱乐'), findsOneWidget,
        reason: '3 笔交易在 pause + resume 后都仍在');
  });
}
