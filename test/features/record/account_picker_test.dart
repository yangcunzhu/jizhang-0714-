import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/features/home/presentation/widgets/transaction_tile.dart';
import 'package:jizhang_app/features/record/presentation/widgets/account_picker.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  /// 构造外部 ProviderContainer + 预读 stream 首事件,避免 fake_async 卡死。
  Future<void> bootContainer() async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(defaultAccountProvider.future);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// 把 AccountPicker 嵌进最小 host,模拟记账弹层 Step 3 的容器。
  Widget hostWithPicker({
    String initialNote = '',
    ValueChanged<String>? onNoteChanged,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountPicker(
              initialNote: initialNote,
              onNoteChanged: onNoteChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('显示默认账户"现金"和余额 ¥0.00', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithPicker());
    await tester.pumpAndSettle();

    expect(find.text('现金'), findsOneWidget);
    expect(find.textContaining('¥0.00'), findsOneWidget);
  });

  testWidgets('显示"添加账户"按钮 + 余额 emoji 头像 💵', (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithPicker());
    await tester.pumpAndSettle();

    expect(find.text('添加账户'), findsOneWidget);
    expect(find.text('💵'), findsOneWidget);
  });

  testWidgets('点"添加账户"按钮 → SnackBar 提示"多账户管理将在 Stage 2 实装"',
      (tester) async {
    await bootContainer();
    await tester.pumpWidget(hostWithPicker());
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加账户'));
    await tester.pump(); // SnackBar 入场动画
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('多账户管理将在 Stage 2 实装'), findsOneWidget);
  });

  testWidgets('cents → 元 格式化(单元回归保护:复用 TransactionTile.formatYuan)',
      (tester) async {
    expect(TransactionTile.formatYuan(0), '0.00');
    expect(TransactionTile.formatYuan(99), '0.99');
    expect(TransactionTile.formatYuan(100), '1.00');
    expect(TransactionTile.formatYuan(1234), '12.34');
    expect(TransactionTile.formatYuan(100000), '1000.00');
  });
}
