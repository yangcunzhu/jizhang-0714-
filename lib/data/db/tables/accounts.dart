import 'package:drift/drift.dart';

/// 账户大类 — 咔皮对标(v4 §3.1 / ADR-0026 §10):5 大类。
///
/// 决策(ADR-0026 §12):账户从「扁平 6 种」升级为「5 大类 × 子类」。
/// - 资产/负债在大类层面有默认倾向,借贷例外(借出=资产 / 借入=负债),故
///   资产负债最终以 [AccountSubType.isLiability] 为准。
enum AccountCategory {
  fund,
  credit,
  recharge,
  investment,
  loan;

  /// 中文显示名(UI 分组标题)。
  String get displayName => switch (this) {
        AccountCategory.fund => '资金账户',
        AccountCategory.credit => '信用账户',
        AccountCategory.recharge => '充值账户',
        AccountCategory.investment => '理财账户',
        AccountCategory.loan => '借贷账户',
      };

  /// 大类图标(分组标题 emoji)。
  String get emoji => switch (this) {
        AccountCategory.fund => '💰',
        AccountCategory.credit => '💳',
        AccountCategory.recharge => '🚌',
        AccountCategory.investment => '📈',
        AccountCategory.loan => '🤝',
      };

  /// 该大类下的子类型(UI 二级选择用,顺序即展示顺序)。
  List<AccountSubType> get subTypes =>
      AccountSubType.values.where((s) => s.category == this).toList();
}

/// 账户子类型 — 真实品牌清单(v4 §3.1 / ADR-0026 §10):23 子类。
///
/// 存储:Drift `textEnum<>()` 存 name 字符串(与 [AccountType] 同策略,ADR-0017)。
/// 每个子类携带:所属大类 [category] / 中文名 [displayName] / 品牌 emoji [emoji] /
/// 是否负债 [isLiability] / 向下兼容旧枚举 [legacyType]。
enum AccountSubType {
  // 资金账户(资产,5)
  savingsCard,
  wechat,
  alipay,
  cash,
  fundCustom,
  // 信用账户(负债,7)
  creditCard,
  huabei,
  jdBaitiao,
  jiebei,
  douyinLoan,
  douyinMonthly,
  creditCustom,
  // 充值账户(资产,3)
  transitCard,
  mealCard,
  rechargeCustom,
  // 理财账户(资产,6)
  stock,
  mutualFund,
  yuebao,
  lingqiantong,
  timeDeposit,
  investCustom,
  // 借贷账户(2:借出=资产 / 借入=负债)
  lendOut,
  borrowIn;

  /// 所属大类。
  AccountCategory get category => switch (this) {
        savingsCard || wechat || alipay || cash || fundCustom =>
          AccountCategory.fund,
        creditCard ||
        huabei ||
        jdBaitiao ||
        jiebei ||
        douyinLoan ||
        douyinMonthly ||
        creditCustom =>
          AccountCategory.credit,
        transitCard || mealCard || rechargeCustom => AccountCategory.recharge,
        stock || mutualFund || yuebao || lingqiantong || timeDeposit ||
              investCustom =>
          AccountCategory.investment,
        lendOut || borrowIn => AccountCategory.loan,
      };

  /// 中文显示名。
  String get displayName => switch (this) {
        savingsCard => '储蓄卡',
        wechat => '微信',
        alipay => '支付宝',
        cash => '现金',
        fundCustom => '自定义',
        creditCard => '信用卡',
        huabei => '花呗',
        jdBaitiao => '京东白条',
        jiebei => '借呗',
        douyinLoan => '抖音放心贷',
        douyinMonthly => '抖音月付',
        creditCustom => '自定义',
        transitCard => '公交卡',
        mealCard => '饭卡',
        rechargeCustom => '自定义',
        stock => '股票',
        mutualFund => '基金',
        yuebao => '余额宝',
        lingqiantong => '零钱通',
        timeDeposit => '定期存款',
        investCustom => '自定义',
        lendOut => '借出',
        borrowIn => '借入',
      };

  /// 品牌 emoji(子类头像)。
  String get emoji => switch (this) {
        savingsCard => '💳',
        wechat => '💬',
        alipay => '🅰️',
        cash => '💵',
        fundCustom => '❓',
        creditCard => '💳',
        huabei => '🅰️',
        jdBaitiao => '🟠',
        jiebei => '🦊',
        douyinLoan => '🎵',
        douyinMonthly => '🎶',
        creditCustom => '❓',
        transitCard => '🚎',
        mealCard => '🍱',
        rechargeCustom => '❓',
        stock => '📈',
        mutualFund => '🏦',
        yuebao => '🟠',
        lingqiantong => '🟡',
        timeDeposit => '⏰',
        investCustom => '❓',
        lendOut => '📤',
        borrowIn => '📥',
      };

  /// 是否负债 — 净资产计算用(信用账户 + 借入)。
  ///
  /// WHY: 净资产 = 资产 - 负债(ADR-0026 §6)。信用账户全部为负债;借贷中
  /// 「借入」是应付债务(负债)、「借出」是应收债权(资产)。
  bool get isLiability =>
      category == AccountCategory.credit || this == AccountSubType.borrowIn;

  /// 是否信用类字段(额度 / 起始欠款 / 出账日 / 还款日)。
  bool get isCreditLike => category == AccountCategory.credit;

  /// 向下兼容旧 [AccountType](保留 type 列,不破坏既有查询/测试)。
  AccountType get legacyType => switch (category) {
        AccountCategory.fund =>
          this == AccountSubType.cash ? AccountType.cash : AccountType.savings,
        AccountCategory.credit => switch (this) {
            AccountSubType.creditCard => AccountType.creditCard,
            AccountSubType.huabei => AccountType.huabei,
            _ => AccountType.onlineLoan,
          },
        AccountCategory.recharge => AccountType.savings,
        AccountCategory.investment => AccountType.investment,
        AccountCategory.loan => this == AccountSubType.lendOut
            ? AccountType.savings
            : AccountType.onlineLoan,
      };
}

/// 账户类型 — Stage 2 扩展 6 种(向下兼容保留)。
///
/// ⚠️ 自 ADR-0026(schema v6)起,[AccountSubType] 是主模型;本枚举保留仅为
/// 向下兼容既有数据 + 既有查询/测试。新代码优先用 [AccountSubType]。
///
/// 决策(ADR-0017):
/// - 值 = 英文(数据库 i18n 安全)
/// - 显示 = 中文(displayName)+ 类型 emoji 头像(emoji)
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
/// - v1 (Stage 1):id / name / balanceCents / createdAt
/// - v2 (Stage 2):type / includeInNetWorth / creditLimit / billingDay / dueDay
/// - v6 (Stage 3 ADR-0026):subType(主模型)/ brandName / 4 toggle 补 3 个 /
///   initialDebtCents / startDate / counterpartyName / dueDate
/// - v8 (Stage 3 D25 ADR-0029):借贷账户 subType 补 4 字段 — initialLendBalanceCents /
///   initialTime / lendCounterpartyName / lendDueDate(咔皮图 8/13/14/280/281 完整借贷字段)
@DataClassName('AccountEntry')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 账户名称,1-20 字。
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// 账户余额,单位:分(整数)。
  ///
  /// WHY: 金额一律用整数分存储,杜绝 double 浮点误差(0.1+0.2 问题)。
  IntColumn get balanceCents => integer().withDefault(const Constant(0))();

  /// 账户类型 — 向下兼容旧 6 种(v6 起由 subType 派生,见 [AccountSubType.legacyType])。
  TextColumn get type =>
      textEnum<AccountType>().withDefault(const Constant('cash'))();

  /// 账户子类型(v6 主模型,23 子类)。Nullable:v5 老数据 migration 回填。
  TextColumn get subType => textEnum<AccountSubType>().nullable()();

  /// 品牌/机构名(自定义子类用户填,如自定义银行名)。Nullable。
  TextColumn get brandName => text().nullable()();

  /// 是否计入净资产。
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();

  /// 特别关注账户 — 资产列表置顶(ADR-0026 §9)。
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// 默认收账账户 — 收入未指定账户时自动关联(ADR-0026 §9)。
  BoolColumn get isDefaultIncomeAccount =>
      boolean().withDefault(const Constant(false))();

  /// 默认支出账户 — 支出未指定账户时自动关联(ADR-0026 §9)。
  BoolColumn get isDefaultExpenseAccount =>
      boolean().withDefault(const Constant(false))();

  /// 信用额度(分)。仅信用类账户有意义。
  IntColumn get creditLimit => integer().nullable()();

  /// 起始欠款(分)。信用类账户初始欠多少(ADR-0026 §11)。Nullable。
  IntColumn get initialDebtCents => integer().nullable()();

  /// 出账日/账单日(1-31)。仅信用类账户有意义。
  IntColumn get billingDay => integer().nullable()();

  /// 还款日(1-31)。仅信用类账户有意义。
  IntColumn get dueDay => integer().nullable()();

  /// 起始时间 — 信用账户开始用卡时间 / 借贷借出借入日期(ADR-0026 §11/§12)。Nullable。
  DateTimeColumn get startDate => dateTime().nullable()();

  /// 到期还款日期 — 借贷账户专用(具体日期,非月度 dueDay)。Nullable。
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// 借款人姓名 — 借贷账户专用(借给谁/从谁借)。Nullable。占位符规则见 CLAUDE §5。
  TextColumn get counterpartyName => text().nullable()();

  // --- v8 (Stage 3 D25 ADR-0029 借贷账户字段修补) ---

  /// 起始余额/起始欠款(借贷账户专用,v8 D25 ADR-0029 加)。
  ///
  /// 借出 = 起始余额;借入 = 起始欠款。不在 includeInNetWorth 公式里
  /// (沿用 ADR-0026 §6/§8 D22 修订)。整数分存储,与项目其他 cents 字段一致
  /// (修正 ADR-0029 §决策 2 字面写的 RealColumn)。
  IntColumn get initialLendBalanceCents => integer().nullable()();

  /// 借贷账户起始时间(UI 必填,DB nullable,v8 D25 ADR-0029 加)。
  ///
  /// UI 层(LendRecordPage/BorrowRecordPage)校验必填 + 语义「该时间之前的记录不
  /// 计入余额统计」。DB 层 nullable 让 v7 老数据零影响迁移。
  DateTimeColumn get initialTime => dateTime().nullable()();

  /// 借贷账户对手方姓名(v8 D25 ADR-0029 加)。
  ///
  /// 与现有 [counterpartyName] 语义重叠,保留为借贷专用字段,UI 不暴露
  /// (LendRecordPage/BorrowRecordPage 直接用 transaction.counterpartyName)。
  /// TODO(D26+):评估与 [counterpartyName] 合并。
  TextColumn get lendCounterpartyName => text().nullable()();

  /// 借贷账户到期还款/收款日期(v8 D25 ADR-0029 加)。
  ///
  /// 与现有 [dueDate] 语义重叠(都是借贷账户到期日),保留为借贷专用。
  /// TODO(D26+):评估与 [dueDate] 合并。
  DateTimeColumn get lendDueDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
