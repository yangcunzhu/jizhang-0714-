import 'package:drift/drift.dart';

/// 交易类型:支出 / 收入。
///
/// WHY: 用 int 枚举存库(intEnum),避免字符串比较开销,且 Stage 2 扩展类型时不破坏历史数据。
enum TransactionType { expense, income }

/// 分类表:记账的一级分类(餐饮/交通/工资...)。
///
/// Stage 1 内置 10 个默认分类,自定义分类管理延后到 Stage 2。
@DataClassName('CategoryEntry')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 分类名称,1-20 字。
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// 图标标识(Material/Cupertino 图标名或 codepoint 别名),UI 层映射为 IconData。
  TextColumn get iconName => text().withLength(min: 1, max: 40)();

  /// 主题色,存 ARGB int(Color.value)。
  IntColumn get colorValue => integer()();

  /// 支出 / 收入。
  IntColumn get type => intEnum<TransactionType>()();

  /// 列表排序,越小越靠前。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
