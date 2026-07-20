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
  ///
  /// 非负由表级 CHECK 约束强制(见 [customConstraints]),拦截 UI/迁移 bug。
  IntColumn get amountCents => integer()();

  /// 支出 / 收入 / 还款。textEnum 按 name 存储(见 Categories.type 说明)。
  ///
  /// WHY: textEnum 加新枚举值(如 S03 加 `repayment`)无需 ALTER TABLE,SQLite 列定义不变,
  /// 仅 Dart 层 enum 多一个常量,迁移成本零。决策见 ADR-0017 + ADR-0021。
  TextColumn get type => textEnum<TransactionType>()();

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

  /// 还款期数(S03 D20 + ADR-0024 增)。
  ///
  /// 仅网贷还款(type=repayment + toAccountId=网贷账户)有意义。
  /// 普通还款(信用卡 / 花呗)为 null。Nullable 让现有数据无需 backfill。
  ///
  /// WHY: 网贷有「12 期 / 24 期 / 36 期」概念,记账流水需要记录,下游 S05 净资产
  /// / S07 AI 攒攒会基于此判断还款提醒是否值得。
  IntColumn get installmentPeriod => integer().nullable()();

  /// 扣款方账户 ID(v7 D22 + ADR-0026 借贷/转账增)。
  ///
  /// 用于 `transfer` / `lend`(资金方) / `repayment`(扣款方)。普通 expense/income 用
  /// 主 [accountId] 即可,本字段 nullable 让现有数据无需 backfill。
  ///
  /// 外键策略:**不显式 references(Accounts, ...)** —— 避免 drift codegen 在 nullable
  /// + FK 上出现「NOT NULL constraint failed」的迁移陷阱。FK 完整性由调用方保证
  /// (DAO 的事务里先 insert 再 update)。
  IntColumn get fromAccountId => integer().nullable()();

  /// 入款方账户 ID(v7 D22 + ADR-0026 借贷/转账/还款增)。
  ///
  /// 用于 `transfer`(入款)/ `borrow`(借入方)/ `repayment`(欠款方)/ `lend`(借出人)。
  /// Nullable 让现有数据无需 backfill。
  IntColumn get toAccountId => integer().nullable()();

  /// 借款对手方姓名(v7 D22 + ADR-0026 借贷增)。
  ///
  /// 借出 = 借款人(借给谁);借入 = 出借人(从谁借)。Nullable。
  /// 存为冗余字段(账户表也有 counterpartyName,这里冗余便于 transaction 直接渲染)。
  TextColumn get counterpartyName => text().nullable()();

  /// 起始时间(借贷记账用,v7 D22 增)。
  ///
  /// 用户填借贷账户时输入的「起始时间」会作为该借贷 transaction 的 occurredAt,
  /// 实现咔皮「该时间之前的记录不计入余额统计」语义。
  DateTimeColumn get startDate => dateTime().nullable()();

  /// 表级约束:金额恒正。用表级 CHECK 而非列级 .check(),避免列 getter 自引用。
  @override
  List<String> get customConstraints => const ['CHECK (amount_cents > 0)'];
}
