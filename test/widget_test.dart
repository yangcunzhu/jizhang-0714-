import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/main.dart';

void main() {
  testWidgets('App 显示 Hello 审计官', (WidgetTester tester) async {
    await tester.pumpWidget(const AuditorApp());

    expect(find.text('Hello 审计官'), findsOneWidget);
    expect(find.text('审计官'), findsOneWidget);
  });
}
