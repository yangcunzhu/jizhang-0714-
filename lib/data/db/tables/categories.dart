import 'package:drift/drift.dart';

/// 交易类型:支出 / 收入 / 还款。
///
/// WHY: 用 textEnum(按枚举 name 字符串存储),而非 intEnum(按 index)。
/// 这样未来在枚举中间插入新值(如 repayment)不会错位映射历史数据。
/// 决策见 ADR-0017(S02 首次落地)+ ADR-0021(S03 扩展还款类型)。
///
/// 不可逆性:`repayment` 名称必须永不变更,下游月度还款总额统计依赖字符串匹配
/// (见 ADR-0021 §「不可逆性」)。
enum TransactionType { expense, income, repayment, transfer }

/// 分类表:记账的一级分类(餐饮/交通/工资...)。
///
/// Stage 1 内置 10 个默认分类,自定义分类管理延后到 Stage 2。
@DataClassName('CategoryEntry')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 分类名称,1-20 字。
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// 图标 = emoji 字符(UTF-16 字符串,如 '🍔' / '🚗'),UI 层用 Text 直接渲染。
  ///
  /// 决策:ADR-0019 — 不存 Material Icons codepoint。maxLength=40 足以放下 emoji 序列
  /// (带 ZWJ 组合如 👨‍👩‍👧‍👦 占 11 个 UTF-16 code unit)。
  TextColumn get iconName => text().withLength(min: 1, max: 40)();

  /// 主题色,存 ARGB int(Color.value)。
  IntColumn get colorValue => integer()();

  /// 支出 / 收入。
  ///
  /// WHY: 用 textEnum(按枚举 name 字符串存储),而非 intEnum(按 index)。
  /// 这样未来在枚举中间插入新值(如 transfer)不会错位映射历史数据。
  TextColumn get type => textEnum<TransactionType>()();

  /// 列表排序,越小越靠前。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
