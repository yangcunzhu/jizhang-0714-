import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/record/presentation/widgets/category_grid.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  /// 构造外部 ProviderContainer + 预读 stream 首事件,避免 fake_async 卡死。
  Future<void> bootContainer() async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(categoryListProvider.future);
  }

  /// D27 24 分类后 GridView 默认 lazy build,屏幕装不下。
  /// 测试环境扩展视口高度让所有 tile 一次性渲染,不再需要 scrollUntilVisible。
  /// 全局设置(在 testWidgets 内每次自动生效,addTearDown 复位)。
  void useBigSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// 把 CategoryGrid 嵌进最小 host,模拟记账弹层 Step 1 的容器。
  Widget hostWithGrid({
    required int? selectedId,
    required ValueChanged<CategoryEntry> onSelected,
    VoidCallback? onManageCategory,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: CategoryGrid(
            selectedCategoryId: selectedId,
            onSelected: onSelected,
            onManageCategory: onManageCategory,
          ),
        ),
      ),
    );
  }

  testWidgets('24 个默认分类 emoji 都渲染(D27 ADR-0031+0032)',
      (tester) async {
    useBigSurface(tester);
    await bootContainer();
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();

    // D27 24 个分类 emoji(8 收入 + 16 支出)
    const expectedEmojis = [
      // expense(16)— 唯一 emoji(findsOneWidget)
      '💊', '👴', '🍔', '🚗', '🚙', '📞', '🧵',
      '🍼', '🏠', '🎬', '📚', '💸', '💎', '💪',
      // income(8)— 唯一 emoji
      '💳', '💰', '🛡️', '💬', '🎁', '🎉',
    ];
    for (final emoji in expectedEmojis) {
      expect(find.text(emoji), findsOneWidget, reason: 'emoji $emoji 应渲染');
    }
    // 同名 emoji 2 个:🛍️(购物 + 生活)+ 📦(其他支出 + 其他收入)
    expect(find.text('🛍️'), findsNWidgets(2),
        reason: '🛍️ expense「购物」+ income「生活费」');
    expect(find.text('📦'), findsNWidgets(2),
        reason: '📦 expense「其他支出」+ income「其他收入」');
  });

  testWidgets('同时显示 24 个分类名称(回归保护)', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();

    const names = [
      // expense(16)— 不含同名冲突(「资金往来」「保险理财」)
      '医疗健康', '老人', '餐饮', '购物', '交通', '交通出行', '通讯',
      '缝纫', '育儿', '住房', '休闲娱乐', '学习办公',
      '健身', '其他支出',
      // income(8)— 不含同名冲突
      '职业收入', '经营收入', '二手买卖', '好运收入', '生活费', '其他收入',
    ];
    for (final name in names) {
      expect(find.text(name), findsOneWidget, reason: '分类名 $name 应渲染');
    }
    // 同名冲突 2 个:expense + income 各 1(共 2 widgets)
    expect(find.text('资金往来'), findsNWidgets(2),
        reason: '「资金往来」expense + income 各 1');
    expect(find.text('保险理财'), findsNWidgets(2),
        reason: '「保险理财」expense + income 各 1');
  });

  testWidgets('点 emoji/分类卡片触发 onSelected 回调', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    CategoryEntry? captured;

    await tester.pumpWidget(
      hostWithGrid(
        selectedId: null,
        onSelected: (c) => captured = c,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('🚗'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull, reason: 'onSelected 应被调用');
    expect(captured!.name, '交通');
    expect(captured!.iconName, '🚗');
  });

  testWidgets('选中分类卡片有高亮态(unselected 时无 Border)', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    final cats = await db.categoryDao.getAll();
    final firstId = cats.first.id;

    // 未选中状态
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();
    final unselectedTile = find.text('医疗健康');
    expect(unselectedTile, findsOneWidget,
        reason: 'D27 sortOrder=1 第 1 个「医疗健康」');

    // 选中第一个分类
    await tester.pumpWidget(
      hostWithGrid(selectedId: firstId, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('💊'), findsWidgets);
    expect(find.text('医疗健康'), findsWidgets);
  });

  // Day 14 (ADR-0019):「+新增」入口 + 长按回调

  testWidgets('有 onManageCategory 时,末尾显示「+新增」tile', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    await tester.pumpWidget(
      hostWithGrid(
        selectedId: null,
        onSelected: (_) {},
        onManageCategory: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category-grid-add')), findsOneWidget);
    expect(find.text('新增'), findsOneWidget);
  });

  testWidgets('无 onManageCategory 时,不显示「+新增」tile', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category-grid-add')), findsNothing);
  });

  testWidgets('长按分类 → 触发 onManageCategory 回调', (tester) async {
    useBigSurface(tester);
    await bootContainer();
    var manageCalled = 0;

    await tester.pumpWidget(
      hostWithGrid(
        selectedId: null,
        onSelected: (_) {},
        onManageCategory: () => manageCalled++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('🍔'));
    await tester.pump();

    expect(manageCalled, 1);
  });
}
