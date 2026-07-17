// CategoryTemplatePage widget 测试(Day 16 — Stage 2 收尾)。
//
// 决策:ADR-0020 — 5 个预设模板卡片 + 弹层选「覆盖 / 追加」+ 应用后 toast。
//
// 覆盖:
// - 5 个模板卡片渲染(emoji + 名称 + 简介 + 分类数)
// - 点空模板 → 弹「空模板」提示对话框
// - 点非空模板 → 弹策略选择层(覆盖 / 追加)
// - 选「追加」 → toast 显示「模板应用完成:...」
// - ListView 渲染 + Key 检查
//
// 根因(D15 留空):StreamProvider + Drift stream 在 fake_async 下等待真 timer 卡死。
// 解决(本卡):bootContainer 模式预先 `.future` 同步拿 stream 首个 event,
//   避开 widget tree 在 fake_async 中等待 Drift timer。沿用 home_page_test.dart 模式。

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/category/application/category_template_provider.dart';
import 'package:jizhang_app/features/category/presentation/category_template_page.dart';

void main() {
  late AppDatabase db;

  /// 预先 `.future` 同步拿 stream 首个 event,避免 widget tree 在 fake_async 中
  /// 等待 Drift 真 timer 卡死(D15 留空根因)。沿用 home_page_test.dart 模式。
  Future<ProviderContainer> bootContainer(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(templateListProvider.future);
    return container;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final container = await bootContainer(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CategoryTemplatePage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('AppBar 标题「分类模板」', (tester) async {
    await pumpPage(tester);
    expect(find.text('分类模板'), findsOneWidget);
  });

  testWidgets('5 个模板卡片都渲染(emoji + 名称 + 分类数)',
      (tester) async {
    await pumpPage(tester);

    // 5 个模板 code → name + emoji
    final expected = [
      ('上班族', '👔', '12 个分类'),
      ('家庭', '👨‍👩‍👧', '10 个分类'),
      ('学生', '🎓', '8 个分类'),
      ('极简', '✨', '5 个分类'),
      ('自定义空', '📝', '空模板'),
    ];

    for (final (name, emoji, countLabel) in expected) {
      expect(find.text(name, skipOffstage: false), findsOneWidget,
          reason: '模板名 $name 应渲染');
      expect(find.text(emoji, skipOffstage: false), findsOneWidget,
          reason: '模板 emoji $emoji 应渲染');
      expect(find.text(countLabel, skipOffstage: false), findsOneWidget,
          reason: '模板 $name 分类数标签应渲染');
    }
  });

  testWidgets('5 个模板卡片都用 template-card-{code} Key 渲染',
      (tester) async {
    await pumpPage(tester);

    final codes = ['office_worker', 'family', 'student', 'minimal', 'empty'];
    for (final code in codes) {
      expect(
        find.byKey(Key('template-card-$code'), skipOffstage: false),
        findsOneWidget,
        reason: 'Key template-card-$code 应渲染',
      );
    }
  });

  testWidgets('点空模板「自定义空」→ 弹「空模板」提示对话框',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('template-card-empty')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 对话框独有文本(卡片上「空模板」标签也会出现,所以用对话框特征文案断言)
    expect(
      find.textContaining('这是一个空模板'),
      findsOneWidget,
      reason: '对话框内容文案应出现',
    );
    expect(find.text('知道了'), findsOneWidget,
        reason: '对话框确认按钮应出现');
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('点非空模板「极简」→ 弹策略选择层(覆盖 + 追加)',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('template-card-minimal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('应用方式'), findsOneWidget);
    expect(find.text('覆盖现有分类'), findsOneWidget);
    expect(find.text('追加到现有分类'), findsOneWidget);
    expect(find.byKey(const Key('template-mode-overwrite')), findsOneWidget);
    expect(find.byKey(const Key('template-mode-append')), findsOneWidget);
  });

  testWidgets('选「追加」→ toast 显示「模板应用完成:...」',
      (tester) async {
    await pumpPage(tester);

    // 触发应用弹层
    await tester.tap(find.byKey(const Key('template-card-minimal')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 选追加
    await tester.tap(find.byKey(const Key('template-mode-append')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('模板应用完成'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('ListView 用 template-list Key 渲染', (tester) async {
    await pumpPage(tester);
    expect(find.byKey(const Key('template-list')), findsOneWidget);
    // ListView.separated 渲染 5 个卡片 + 4 个 separator
    expect(find.byKey(const Key('template-list')), findsOneWidget);
  });
}