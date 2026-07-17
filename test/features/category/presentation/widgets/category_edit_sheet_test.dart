// CategoryEditSheet widget 测试(Day 14 — 决策 ADR-0019 弹层 + 12 色板)。
//
// 覆盖:
// - 新建 vs 编辑标题
// - 12 色板渲染
// - 实时预览显示
// - 校验失败阻止保存
// - 输入名称后保存 → Navigator.pop(true)

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/category/presentation/widgets/category_edit_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    int? existingId,
    TransactionType type = TransactionType.expense,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: CategoryEditSheet(existingId: existingId, type: type),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('新建场景:标题显示「新建分类」', (tester) async {
    await pumpSheet(tester);
    expect(find.text('新建分类'), findsOneWidget);
  });

  testWidgets('编辑场景:标题显示「编辑分类」', (tester) async {
    final food = (await db.categoryDao.getAll()).first;
    await pumpSheet(tester, existingId: food.id);
    expect(find.text('编辑分类'), findsOneWidget);
  });

  testWidgets('12 色板 chip 都渲染', (tester) async {
    await pumpSheet(tester);
    // 12 色板的 hex 字符串 key(0xFFE57373.toRadixString(16) = 'ffe57373')
    // Wrap 内的 off-screen chip 用 skipOffstage: false 仍可断言
    final expectedHexes = [
      'ffe57373', 'ffffb74d', 'ffffd54f', 'ff81c784',
      'ff4dd0e1', 'ff64b5f6', 'ff9575cd', 'fff06292',
      'ffa1887f', 'ff90a4ae', 'ff455a64', 'ff26a69a',
    ];
    for (final hex in expectedHexes) {
      expect(
        find.byKey(Key('category-color-$hex'), skipOffstage: false),
        findsOneWidget,
        reason: '色板 $hex 应渲染',
      );
    }
  });

  testWidgets('emoji 选择按钮 + 选择 emoji 弹层入口存在', (tester) async {
    await pumpSheet(tester);
    expect(
      find.byKey(const Key('category-edit-emoji-button')),
      findsOneWidget,
    );
    expect(find.text('选择 Emoji'), findsOneWidget);
  });

  testWidgets('点保存但名称为空 → 数据库不变', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('category-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));

    final cats = await db.categoryDao.getAll();
    expect(cats, hasLength(10)); // seed 默认 10 个,无新增
  });

  testWidgets('输入名称后保存 → Navigator.pop(true) + DB 新增',
      (tester) async {
    bool? popResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) => const CategoryEditSheet(
                        existingId: null,
                        type: TransactionType.expense,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
        find.byKey(const Key('category-edit-name')), '奶茶');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-edit-save')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(popResult, isTrue);

    final cats = await db.categoryDao.getAll();
    expect(cats.any((c) => c.name == '奶茶'), isTrue);
  });
}