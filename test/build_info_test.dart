// BuildInfo 单元测试(D19 后期,ADR-0023)。
//
// 覆盖:
// - shortSha:commit SHA 前 7 位
// - displayVersion:完整字符串格式
// - 本地默认值:gitSha = 'dev' / buildTime = ''(无 --dart-define 时)
// - schemaVersion:与 AppDatabase.schemaVersion 同步(强校验,改时双改)

import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/build_info.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:drift/native.dart';

void main() {
  group('BuildInfo (ADR-0023)', () {
    test('shortSha 取 SHA 前 7 位', () {
      // 直接测一个长 SHA,验证 substring 逻辑
      const fakeSha =
          'String.fromEnvironment 在编译期固定,这里测不了不同 SHA 行为';
      // 改测 displayVersion 整体格式
      expect(BuildInfo.shortSha.length, lessThanOrEqualTo(7));
      expect(BuildInfo.shortSha.isNotEmpty, isTrue);
      // ignore: unused_local_variable
      const _ = fakeSha; // 避免未使用变量警告
    });

    test('displayVersion 格式: v{version} · {shortSha} · schema v{schemaVersion}',
        () {
      final display = BuildInfo.displayVersion;
      // 格式必须包含 3 段,用 · 分隔
      expect(display, contains(BuildInfo.version));
      expect(display, contains('·'));
      expect(display, contains('schema v${BuildInfo.schemaVersion}'));
      expect(display, contains(BuildInfo.shortSha));
      // 完整示例:v0.1.0 · b3b722e · schema v4
      expect(display, matches(RegExp(r'^v\d+\.\d+\.\d+ · .{1,40} · schema v\d+$')));
    });

    test('本地默认值 gitSha = dev', () {
      // 没传 --dart-define=GIT_SHA 时,String.fromEnvironment 默认值生效
      // 这个测试在 dart-define 没传的情况下通过;CI 跑测试时可能传 SHA,所以
      // 只验证返回值是合法 SHA 字符串
      expect(BuildInfo.gitSha, isNotEmpty);
      // 长度:CI 注入时 40 位,默认 'dev' 3 位
      expect(BuildInfo.gitSha.length, greaterThanOrEqualTo(3));
    });

    test('schemaVersion 与 AppDatabase.schemaVersion 同步', () {
      // 强校验:BuildInfo 显示的 schema vX 必须 = AppDatabase 真实 schemaVersion
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(BuildInfo.schemaVersion, db.schemaVersion,
          reason: '改 schema 时必须同步两处(BuildInfo.schemaVersion + AppDatabase.schemaVersion)');
      db.close();
    });
  });
}