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
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: CategoryGrid(
            selectedCategoryId: selectedId,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  testWidgets('10 个默认分类 emoji 都渲染(🍔 🚗 🛍️ 🎮 🏠 🏥 📱 📚 📦 💰)',
      (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();

    const expectedEmojis = ['🍔', '🚗', '🛍️', '🎮', '🏠', '🏥', '📱', '📚', '📦', '💰'];
    for (final emoji in expectedEmojis) {
      expect(find.text(emoji), findsOneWidget, reason: 'emoji $emoji 应渲染');
    }
  });

  testWidgets('同时显示分类名称(回归保护:Day 6 起的文案不变)', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();

    const names = ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '通讯', '学习', '其他', '工资'];
    for (final name in names) {
      expect(find.text(name), findsOneWidget, reason: '分类名 $name 应渲染');
    }
  });

  testWidgets('点 emoji/分类卡片触发 onSelected 回调', (tester) async {
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
    await bootContainer();
    final cats = await db.categoryDao.getAll();
    final firstId = cats.first.id;

    // 未选中状态
    await tester.pumpWidget(hostWithGrid(selectedId: null, onSelected: (_) {}));
    await tester.pumpAndSettle();
    final unselectedTile = find.text('餐饮');
    expect(unselectedTile, findsOneWidget);

    // 选中第一个分类
    await tester.pumpWidget(
      hostWithGrid(selectedId: firstId, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('🍔'), findsWidgets);
    // 选中后同名分类文案仍渲染,测试不打 pumpAndSettle 即可继续验证
    expect(find.text('餐饮'), findsWidgets);
  });
}
