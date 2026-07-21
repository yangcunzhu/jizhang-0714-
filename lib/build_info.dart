/// 构建元信息(版本号 + commit SHA + schema 版本)。
///
/// WHY: 装机后用户/开发者能在 App 内看到自己装的是哪个 commit,
/// 避免「装错版本」浪费时间(参见 ADR-0023)。
///
/// 来源:
/// - GIT_SHA: CI `--dart-define=GIT_SHA=${{ github.sha }}` 注入
/// - BUILD_TIME: CI `--dart-define=BUILD_TIME=$(date -u +...)` 注入
/// - version: 硬编码(每次 release 大改动 +1,见下方说明)
/// - schemaVersion: 硬编码(随 migration 升级,**必须**与 AppDatabase.schemaVersion 同步)
class BuildInfo {
  BuildInfo._();

  /// Git commit SHA(完整 40 位),CI 注入。本地 flutter run 不注入时 = 'dev'。
  static const String gitSha = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: 'dev',
  );

  /// Build 时间(ISO8601),CI 注入。本地不注入时 = ''。
  static const String buildTime = String.fromEnvironment(
    'BUILD_TIME',
    defaultValue: '',
  );

  /// 主版本号。
  /// - 0.1.0:Stage 3 期间(S03,2026-08)
  /// - 每次 release 大改动 +1 位
  static const String version = '0.1.0';

  /// 数据库 schema 版本(随 migration 升级)。
  /// **必须** 与 `AppDatabase.schemaVersion` getter 保持一致!
  /// 同步检查点:每次升级 schema 时同时改两处(本常量 + AppDatabase.schemaVersion)。
  static const int schemaVersion = 8; // S03 D25 schema v8 整合(5 ADR 协同):accounts +4 + transactions +6;v7 D22 借贷;v6 accounts 5 大类;v5 期数;v4 repayment

  /// commit SHA 前 7 位(GitHub commit 列表用 7 位)。
  /// 本地 'dev' 返回 'dev'。
  static String get shortSha =>
      gitSha.length >= 7 ? gitSha.substring(0, 7) : gitSha;

  /// 主页底部 + 错误日志用的完整版本字符串。
  /// 例: `v0.1.0 · b3b722e · schema v4`
  static String get displayVersion =>
      'v$version · $shortSha · schema v$schemaVersion';
}