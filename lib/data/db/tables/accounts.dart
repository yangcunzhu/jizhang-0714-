import 'package:drift/drift.dart';

/// 账户类型 — Stage 2 扩展 6 种。
///
/// 决策(ADR-0017):
/// - 值 = 英文(数据库 i18n 安全)
/// - 显示 = 中文(displayName)+ 类型 emoji 头像(emoji)
/// - 模仿项目已有的 TransactionType,用 Drift `textEnum<>()` 存 name 字符串
enum AccountType {
  cash,
  savings,
  creditCard,
  huabei,
  onlineLoan,
  investment;

  /// 中文显示名(UI 用)。
  String get displayName => switch (this) {
        AccountType.cash => '现金',
        AccountType.savings => '储蓄',
        AccountType.creditCard => '信用卡',
        AccountType.huabei => '花呗',
        AccountType.onlineLoan => '网贷',
        AccountType.investment => '理财',
      };

  /// 类型 emoji(账户卡片头像用,沿用 ADR-0013)。
  String get emoji => switch (this) {
        AccountType.cash => '💵',
        AccountType.savings => '🏦',
        AccountType.creditCard => '💳',
        AccountType.huabei => '🅰️',
        AccountType.onlineLoan => '🆘',
        AccountType.investment => '📈',
      };
}

/// 账户表。
///
/// Stage 1 (id / name / balanceCents / createdAt) + Stage 2 扩展 5 字段:
/// - type:6 种账户类型(见 [AccountType])
/// - includeInNetWorth:是否计入净资产(理财类账户通常 false)
/// - creditLimit / billingDay / dueDay:仅信用卡账户有意义,nullable
@DataClassName('AccountEntry')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 账户名称,1-20 字。
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// 账户余额,单位:分(整数)。
  ///
  /// WHY: 金额一律用整数分存储,杜绝 double 浮点误差(0.1+0.2 问题)。
  IntColumn get balanceCents =>
      integer().withDefault(const Constant(0))();

  /// 账户类型 — 6 种之一。
  ///
  /// Stage 1 已有 row 自动归类 'cash'(withDefault)。
  TextColumn get type =>
      textEnum<AccountType>().withDefault(const Constant('cash'))();

  /// 是否计入净资产。
  ///
  /// WHY: 理财类账户(已投入本金,未来收益未实现)通常不计入净资产,
  /// 与现金流账户区分。Stage 5 净资产计算据此过滤。
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();

  /// 信用卡额度(分)。Nullable:仅 creditCard 类型有意义。
  IntColumn get creditLimit => integer().nullable()();

  /// 信用卡账单日(1-31)。Nullable:仅 creditCard 类型有意义。
  IntColumn get billingDay => integer().nullable()();

  /// 信用卡还款日(1-31)。Nullable:仅 creditCard 类型有意义。
  IntColumn get dueDay => integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
