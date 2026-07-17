import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

/// 交易流水表:一笔记账 = 一行。
///
/// 核心表,承载"5 秒 3 步记账"的落库结果。
@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 金额,单位:分(整数,恒 > 0)。支出 / 收入由 [type] 区分,不用负数。
  IntColumn get amountCents => integer()();

  /// 支出 / 收入。
  IntColumn get type => intEnum<TransactionType>()();

  /// 所属分类。
  IntColumn get categoryId =>
      integer().references(Categories, #id)();

  /// 所属账户。
  IntColumn get accountId =>
      integer().references(Accounts, #id)();

  /// 备注,可空(默认空串)。
  TextColumn get note => text().withDefault(const Constant(''))();

  /// 交易发生时间(用户可改),默认当前。列表按此倒序。
  DateTimeColumn get occurredAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
