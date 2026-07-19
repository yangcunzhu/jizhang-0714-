import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';

/// 账户表单状态(Day 12 起 + ADR-0026 重做 — 账户编辑弹层用)。
///
/// v6(ADR-0026):从「扁平 6 种 type」升级为「5 大类 × 23 子类 subType」主模型。
/// - [subType] 是主字段(决定大类 / 品牌 / 字段表单 / 资产负债)。
/// - [type] 保留为向下兼容字段(旧查询/统计仍读),提交时由 subType 派生兜底。
class AccountFormState {
  const AccountFormState({
    required this.type,
    required this.name,
    this.subType,
    this.brandName,
    this.balanceCents,
    this.creditLimitCents,
    this.initialDebtCents,
    this.billingDay,
    this.dueDay,
    this.startDate,
    this.dueDate,
    this.counterpartyName,
    this.includeInNetWorth = true,
    this.isPinned = false,
    this.isDefaultIncomeAccount = false,
    this.isDefaultExpenseAccount = false,
  });

  /// 默认初始值(新建现金账户,余额 0)。
  static const AccountFormState initial = AccountFormState(
    type: AccountType.cash,
    name: '',
    subType: AccountSubType.cash,
  );

  /// 向下兼容旧类型(v6 起由 subType 派生兜底)。
  final AccountType type;

  /// 账户子类型(v6 主模型)。null 仅出现在极老数据回填前。
  final AccountSubType? subType;

  /// 账户名称(必填,1-20 字)。
  final String name;

  /// 品牌/机构名(自定义子类用户填)。
  final String? brandName;

  /// 初始/当前余额(分)。资金/充值/理财类 + 借贷本金用。
  final int? balanceCents;

  /// 信用额度(分)。仅信用类。
  final int? creditLimitCents;

  /// 起始欠款(分)。仅信用类(ADR-0026 §11)。
  final int? initialDebtCents;

  /// 出账日/账单日(1-31)。仅信用类。
  final int? billingDay;

  /// 还款日(1-31)。仅信用类。
  final int? dueDay;

  /// 起始时间(信用账户起始 / 借贷借出借入日期)。
  final DateTime? startDate;

  /// 到期还款日期(借贷账户)。
  final DateTime? dueDate;

  /// 借款人姓名(借贷账户)。占位符规则见 CLAUDE §5。
  final String? counterpartyName;

  final bool includeInNetWorth;
  final bool isPinned;
  final bool isDefaultIncomeAccount;
  final bool isDefaultExpenseAccount;

  /// 大类(由 subType 派生;subType 为空时按旧 type 推断)。
  AccountCategory get category =>
      subType?.category ?? _categoryFromLegacy(type);

  /// 是否信用类(额度/起始欠款/出账日/还款日 字段)。
  bool get isCreditLike =>
      subType?.isCreditLike ?? (type == AccountType.creditCard);

  /// 是否借贷类(借款人/日期/本金 字段)。
  bool get isLoan => category == AccountCategory.loan;

  /// 是否自定义子类(需要用户填品牌名)。
  bool get isCustom =>
      subType == AccountSubType.fundCustom ||
      subType == AccountSubType.creditCustom ||
      subType == AccountSubType.rechargeCustom ||
      subType == AccountSubType.investCustom;

  /// 可用额度(自动算:额度 - 起始欠款),仅信用类且额度已填时有值。
  int? get availableCreditCents {
    if (!isCreditLike || creditLimitCents == null) return null;
    return creditLimitCents! - (initialDebtCents ?? 0);
  }

  /// 表单校验:名称非空 + 信用/借贷字段若填则合法。
  String? validate() {
    if (name.trim().isEmpty) return '账户名称不能为空';
    if (name.trim().length > 20) return '账户名称不能超过 20 字';
    if (balanceCents != null && balanceCents! < 0 && !isCreditLike) {
      return '余额不能为负数';
    }
    if (isCreditLike) {
      if (creditLimitCents != null && creditLimitCents! <= 0) {
        return '信用卡额度必须大于 0';
      }
      if (initialDebtCents != null && initialDebtCents! < 0) {
        return '起始欠款不能为负数';
      }
      if (billingDay != null && (billingDay! < 1 || billingDay! > 31)) {
        return '账单日必须在 1-31 之间';
      }
      if (dueDay != null && (dueDay! < 1 || dueDay! > 31)) {
        return '还款日必须在 1-31 之间';
      }
    }
    if (isCustom && (brandName == null || brandName!.trim().isEmpty)) {
      return '自定义账户请填写品牌/机构名';
    }
    return null;
  }

  AccountFormState copyWith({
    AccountType? type,
    AccountSubType? subType,
    String? name,
    String? brandName,
    int? balanceCents,
    int? creditLimitCents,
    int? initialDebtCents,
    int? billingDay,
    int? dueDay,
    DateTime? startDate,
    DateTime? dueDate,
    String? counterpartyName,
    bool? includeInNetWorth,
    bool? isPinned,
    bool? isDefaultIncomeAccount,
    bool? isDefaultExpenseAccount,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      subType: subType ?? this.subType,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      balanceCents: balanceCents ?? this.balanceCents,
      creditLimitCents: creditLimitCents ?? this.creditLimitCents,
      initialDebtCents: initialDebtCents ?? this.initialDebtCents,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      isPinned: isPinned ?? this.isPinned,
      isDefaultIncomeAccount:
          isDefaultIncomeAccount ?? this.isDefaultIncomeAccount,
      isDefaultExpenseAccount:
          isDefaultExpenseAccount ?? this.isDefaultExpenseAccount,
    );
  }

  /// 从已有账户构造 state。
  factory AccountFormState.from(AccountEntry acc) => AccountFormState(
        type: acc.type,
        subType: acc.subType ?? _subTypeFromLegacy(acc.type),
        name: acc.name,
        brandName: acc.brandName,
        balanceCents: acc.balanceCents,
        creditLimitCents: acc.creditLimit,
        initialDebtCents: acc.initialDebtCents,
        billingDay: acc.billingDay,
        dueDay: acc.dueDay,
        startDate: acc.startDate,
        dueDate: acc.dueDate,
        counterpartyName: acc.counterpartyName,
        includeInNetWorth: acc.includeInNetWorth,
        isPinned: acc.isPinned,
        isDefaultIncomeAccount: acc.isDefaultIncomeAccount,
        isDefaultExpenseAccount: acc.isDefaultExpenseAccount,
      );
}

/// 旧 [AccountType] → 大类(subType 缺失时兜底)。
AccountCategory _categoryFromLegacy(AccountType t) => switch (t) {
      AccountType.cash || AccountType.savings => AccountCategory.fund,
      AccountType.creditCard ||
      AccountType.huabei ||
      AccountType.onlineLoan =>
        AccountCategory.credit,
      AccountType.investment => AccountCategory.investment,
    };

/// 旧 [AccountType] → 代表性 subType(回填/兜底)。
AccountSubType _subTypeFromLegacy(AccountType t) => switch (t) {
      AccountType.cash => AccountSubType.cash,
      AccountType.savings => AccountSubType.savingsCard,
      AccountType.creditCard => AccountSubType.creditCard,
      AccountType.huabei => AccountSubType.huabei,
      AccountType.onlineLoan => AccountSubType.jiebei,
      AccountType.investment => AccountSubType.mutualFund,
    };

/// 账户表单 controller(弹层用)。
class AccountFormController extends StateNotifier<AccountFormState> {
  AccountFormController(this._ref, {this.existingId})
      : super(AccountFormState.initial) {
    if (existingId != null) {
      _loadExisting(existingId!);
    }
  }

  final Ref _ref;
  final int? existingId;

  Future<void> _loadExisting(int id) async {
    final db = _ref.read(databaseProvider);
    final acc = await db.accountDao.getById(id);
    if (acc != null && mounted) {
      state = AccountFormState.from(acc);
    }
  }

  /// 切换子类型(v6 主路径)—— 同步派生 type,并清空跨大类不相关字段。
  ///
  /// WHY 显式构造:切换大类时必须清空上一个大类的专属字段(如从信用切到资金要清
  /// creditLimit/initialDebt/billingDay/dueDay),copyWith 的 `x ?? this.x` 无法表达清空。
  void changeSubType(AccountSubType sub) {
    final keepCredit = sub.isCreditLike;
    final keepLoan = sub.category == AccountCategory.loan;
    state = AccountFormState(
      type: sub.legacyType,
      subType: sub,
      name: state.name,
      // 自定义子类保留已填品牌名,否则清空
      brandName: state.isCustom &&
              (sub == AccountSubType.fundCustom ||
                  sub == AccountSubType.creditCustom ||
                  sub == AccountSubType.rechargeCustom ||
                  sub == AccountSubType.investCustom)
          ? state.brandName
          : null,
      balanceCents: state.balanceCents,
      creditLimitCents: keepCredit ? state.creditLimitCents : null,
      initialDebtCents: keepCredit ? state.initialDebtCents : null,
      billingDay: keepCredit ? state.billingDay : null,
      dueDay: keepCredit ? state.dueDay : null,
      startDate: (keepCredit || keepLoan) ? state.startDate : null,
      dueDate: keepLoan ? state.dueDate : null,
      counterpartyName: keepLoan ? state.counterpartyName : null,
      includeInNetWorth: state.includeInNetWorth,
      isPinned: state.isPinned,
      isDefaultIncomeAccount: state.isDefaultIncomeAccount,
      isDefaultExpenseAccount: state.isDefaultExpenseAccount,
    );
  }

  /// 向下兼容:旧 type 切换(保留给既有调用/测试)。
  void changeType(AccountType type) {
    if (type == AccountType.creditCard) {
      state = state.copyWith(type: type);
    } else {
      state = AccountFormState(
        type: type,
        subType: state.subType,
        name: state.name,
        balanceCents: state.balanceCents,
        includeInNetWorth: state.includeInNetWorth,
        isPinned: state.isPinned,
        isDefaultIncomeAccount: state.isDefaultIncomeAccount,
        isDefaultExpenseAccount: state.isDefaultExpenseAccount,
        // creditLimit/billingDay/dueDay 不传 → 清空
      );
    }
  }

  void changeName(String name) => state = state.copyWith(name: name);
  void changeBrandName(String v) => state = state.copyWith(brandName: v);
  void changeIncludeInNetWorth(bool v) =>
      state = state.copyWith(includeInNetWorth: v);
  void changeIsPinned(bool v) => state = state.copyWith(isPinned: v);
  void changeIsDefaultIncome(bool v) =>
      state = state.copyWith(isDefaultIncomeAccount: v);
  void changeIsDefaultExpense(bool v) =>
      state = state.copyWith(isDefaultExpenseAccount: v);

  /// 以下 nullable 数值 setter 用显式构造(支持传 null 清空)。
  void changeBalanceCents(int? cents) =>
      state = _rebuild(balanceCents: cents, clearBalance: cents == null);
  void changeCreditLimitCents(int? cents) =>
      state = _rebuild(creditLimitCents: cents, clearCredit: cents == null);
  void changeInitialDebtCents(int? cents) =>
      state = _rebuild(initialDebtCents: cents, clearDebt: cents == null);
  void changeBillingDay(int? day) =>
      state = _rebuild(billingDay: day, clearBilling: day == null);
  void changeDueDay(int? day) =>
      state = _rebuild(dueDay: day, clearDue: day == null);
  void changeStartDate(DateTime? d) =>
      state = _rebuild(startDate: d, clearStart: d == null);
  void changeDueDate(DateTime? d) =>
      state = _rebuild(dueDate: d, clearDueDate: d == null);
  void changeCounterparty(String v) => state = state.copyWith(counterpartyName: v);

  /// 统一显式重建(nullable 字段清空语义)。
  AccountFormState _rebuild({
    int? balanceCents,
    int? creditLimitCents,
    int? initialDebtCents,
    int? billingDay,
    int? dueDay,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearBalance = false,
    bool clearCredit = false,
    bool clearDebt = false,
    bool clearBilling = false,
    bool clearDue = false,
    bool clearStart = false,
    bool clearDueDate = false,
  }) {
    return AccountFormState(
      type: state.type,
      subType: state.subType,
      name: state.name,
      brandName: state.brandName,
      balanceCents: clearBalance ? null : (balanceCents ?? state.balanceCents),
      creditLimitCents:
          clearCredit ? null : (creditLimitCents ?? state.creditLimitCents),
      initialDebtCents:
          clearDebt ? null : (initialDebtCents ?? state.initialDebtCents),
      billingDay: clearBilling ? null : (billingDay ?? state.billingDay),
      dueDay: clearDue ? null : (dueDay ?? state.dueDay),
      startDate: clearStart ? null : (startDate ?? state.startDate),
      dueDate: clearDueDate ? null : (dueDate ?? state.dueDate),
      counterpartyName: state.counterpartyName,
      includeInNetWorth: state.includeInNetWorth,
      isPinned: state.isPinned,
      isDefaultIncomeAccount: state.isDefaultIncomeAccount,
      isDefaultExpenseAccount: state.isDefaultExpenseAccount,
    );
  }

  /// 提交:返回 true 表示写入成功,false 表示校验失败或写失败。
  Future<bool> submit() async {
    final err = state.validate();
    if (err != null) return false;

    final sub = state.subType ?? _subTypeFromLegacy(state.type);
    final db = _ref.read(databaseProvider);
    try {
      if (existingId == null) {
        await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: state.name.trim(),
            type: Value(state.type),
            subType: Value(sub),
            brandName: Value(state.brandName?.trim()),
            includeInNetWorth: Value(state.includeInNetWorth),
            isPinned: Value(state.isPinned),
            isDefaultIncomeAccount: Value(state.isDefaultIncomeAccount),
            isDefaultExpenseAccount: Value(state.isDefaultExpenseAccount),
            balanceCents: Value(state.balanceCents ?? 0),
            creditLimit: Value(state.creditLimitCents),
            initialDebtCents: Value(state.initialDebtCents),
            billingDay: Value(state.billingDay),
            dueDay: Value(state.dueDay),
            startDate: Value(state.startDate),
            dueDate: Value(state.dueDate),
            counterpartyName: Value(state.counterpartyName?.trim()),
          ),
        );
        _ref.invalidate(accountListProvider);
      } else {
        await db.accountDao.updateAccountById(
          AccountsCompanion(
            id: Value(existingId!),
            name: Value(state.name.trim()),
            type: Value(state.type),
            subType: Value(sub),
            brandName: Value(state.brandName?.trim()),
            includeInNetWorth: Value(state.includeInNetWorth),
            isPinned: Value(state.isPinned),
            isDefaultIncomeAccount: Value(state.isDefaultIncomeAccount),
            isDefaultExpenseAccount: Value(state.isDefaultExpenseAccount),
            balanceCents: Value(state.balanceCents ?? 0),
            creditLimit: Value(state.creditLimitCents),
            initialDebtCents: Value(state.initialDebtCents),
            billingDay: Value(state.billingDay),
            dueDay: Value(state.dueDay),
            startDate: Value(state.startDate),
            dueDate: Value(state.dueDate),
            counterpartyName: Value(state.counterpartyName?.trim()),
          ),
        );
        _ref.invalidate(accountListProvider);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 账户表单 provider(弹层用,family key = int? existingId)。
final accountFormProvider = StateNotifierProvider
    .family<AccountFormController, AccountFormState, int?>(
  (ref, existingId) => AccountFormController(ref, existingId: existingId),
);

/// 账户列表 provider(监听所有账户,主页 + 管理页共用)。
final accountListProvider = StreamProvider<List<AccountEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.accountDao.watchAll();
});
