import 'package:drift/drift.dart';

/// 账户表。
///
/// Stage 1 简化为单一"现金"账户(初始化时 seed),多账户 / 6 种账户类型延后到 Stage 2。
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

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
