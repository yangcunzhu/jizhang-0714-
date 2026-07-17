import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/features/home/application/home_providers.dart';
import 'package:jizhang_app/main.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('应用启动显示主页骨架(AppBar + 净资产占位 + FAB)', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(transactionListProvider.future);
    await container.read(categoryListProvider.future);
    await container.read(defaultAccountProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AuditorApp(),
      ),
    );
    await tester.pump();

    expect(find.text('审计官'), findsOneWidget);
    expect(find.text('净资产'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
  });
}