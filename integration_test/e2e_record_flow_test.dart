import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/selectors.dart';
import '_helpers/test_harness.dart';

/// E2E 1:完整记账主流程(ADR-0014 — Stage 1 必须覆盖)。
///
/// 启动 → 主页 → FAB → 弹层 3 步 → 选分类 → 输入金额 → 保存 → 主页列表显示
/// 全部在真 Flutter engine + 真 SQLite 文件下跑通。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整记账流程:主页 → 弹层 → 选分类 → 输入金额 → 保存 → 列表显示',
      (tester) async {
    final h = TestHarness(tester);
    await h.bootApp();

    // 1. 主页空态
    expect(Selectors.homeAppBar(), findsOneWidget);
    expect(Selectors.homeEmpty(), findsOneWidget);

    // 2. 点 FAB 打开弹层
    await h.openRecordSheet();
    expect(Selectors.recordSheetTitle(), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);

    // 3. 选分类"餐饮"
    await h.selectCategory('餐饮');
    expect(Selectors.amountDisplay(), findsOneWidget);

    // 4. 输入金额 12.34(整数分累计: 1+2+3+4 = 1234 cents → "12.34")
    await h.enterAmount('1234');
    expect(find.text('12.34'), findsOneWidget,
        reason: '输入 1234 cents → 金额显示 "12.34"');

    // 5. 点"下一步"
    await h.tapNext();

    // 6. Step 3:账户 + 保存
    expect(find.text('现金'), findsOneWidget);
    expect(find.text('添加账户'), findsOneWidget);
    await h.tapSave();

    // 7. 弹层关闭 + 主页显示新交易
    expect(Selectors.recordSheetTitle(), findsNothing);
    expect(Selectors.homeEmpty(), findsNothing);
    expect(find.text('餐饮'), findsOneWidget,
        reason: '主页交易列表显示刚记的"餐饮"');
  });
}
