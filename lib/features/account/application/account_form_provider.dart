import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';

/// 账户表单状态(Day 12 — 账户编辑弹层用)。
///
/// WHY: 编辑/新建账户需要保存弹层内多个字段(type / name / creditLimit / ...),
/// 弹层关闭时一次性提交。
class AccountFormState {
  const AccountFormState({
    required this.type,
    required this.name,
    this.creditLimitCents,
    this.billingDay,
    this.dueDay,
    this.includeInNetWorth = true,
  });

  /// 默认初始值(新建现金账户)。
  static const AccountFormState initial =
      AccountFormState(type: AccountType.cash, name: '');

  /// 当前选中的账户类型(决定哪些字段显示)。
  final AccountType type;

  /// 账户名称(必填,1-20 字)。
  final String name;

  /// 信用卡额度(分)。仅 [type] == [AccountType.creditCard] 有意义。
  final int? creditLimitCents;

  /// 信用卡账单日(1-31)。仅 [AccountType.creditCard]。
  final int? billingDay;

  /// 信用卡还款日(1-31)。仅 [AccountType.creditCard]。
  final int? dueDay;

  /// 是否计入净资产(理财类账户通常 false)。
  final bool includeInNetWorth;

  bool get isCreditCard => type == AccountType.creditCard;

  /// 表单校验:名称非空 + 信用卡字段若填了必须合法。
  String? validate() {
    if (name.trim().isEmpty) return '账户名称不能为空';
    if (name.trim().length > 20) return '账户名称不能超过 20 字';
    if (isCreditCard) {
      if (creditLimitCents != null && creditLimitCents! <= 0) {
        return '信用卡额度必须大于 0';
      }
      if (billingDay != null && (billingDay! < 1 || billingDay! > 31)) {
        return '账单日必须在 1-31 之间';
      }
      if (dueDay != null && (dueDay! < 1 || dueDay! > 31)) {
        return '还款日必须在 1-31 之间';
      }
    }
    return null;
  }

  /// 复制 — 不支持清空 nullable 字段(语义模糊)。
  /// 需要"修改 + 清空信用卡字段"用 controller 的 setter 显式构造。
  AccountFormState copyWith({
    AccountType? type,
    String? name,
    bool? includeInNetWorth,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      creditLimitCents: creditLimitCents,
      billingDay: billingDay,
      dueDay: dueDay,
    );
  }

  /// 从已有账户构造 state。
  factory AccountFormState.from(AccountEntry acc) => AccountFormState(
        type: acc.type,
        name: acc.name,
        creditLimitCents: acc.creditLimit,
        billingDay: acc.billingDay,
        dueDay: acc.dueDay,
        includeInNetWorth: acc.includeInNetWorth,
      );
}

/// 账户表单 controller(弹层用)。
///
/// - [existingId] == null 表示新建;非 null 表示编辑已有账户
/// - [submit] 写入数据库,返回是否成功(校验失败或抛错都返回 false)
class AccountFormController extends StateNotifier<AccountFormState> {
  AccountFormController(this._ref, {this.existingId}) : super(AccountFormState.initial) {
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

  /// 切换账户类型。
  ///
  /// WHY 显式构造:切到非信用卡时必须清空信用卡字段(`creditLimitCents = null`),
  /// 而 `copyWith` 的 `param ?? this.x` 语义无法区分"未传"和"传 null",
  /// 故这里直接用构造器一次性重置信用卡字段。
  void changeType(AccountType type) {
    if (type == AccountType.creditCard) {
      state = state.copyWith(type: type);
    } else {
      state = AccountFormState(
        type: type,
        name: state.name,
        includeInNetWorth: state.includeInNetWorth,
        // creditLimitCents / billingDay / dueDay 都不传 → 默认 null → 清空
      );
    }
  }

  void changeName(String name) => state = state.copyWith(name: name);
  void changeIncludeInNetWorth(bool include) =>
      state = state.copyWith(includeInNetWorth: include);

  /// 信用卡字段单独 setter(可能传 null 视为清空)。
  void changeCreditLimitCents(int? cents) {
    state = AccountFormState(
      type: state.type,
      name: state.name,
      includeInNetWorth: state.includeInNetWorth,
      creditLimitCents: cents,
      billingDay: state.billingDay,
      dueDay: state.dueDay,
    );
  }

  void changeBillingDay(int? day) {
    state = AccountFormState(
      type: state.type,
      name: state.name,
      includeInNetWorth: state.includeInNetWorth,
      creditLimitCents: state.creditLimitCents,
      billingDay: day,
      dueDay: state.dueDay,
    );
  }

  void changeDueDay(int? day) {
    state = AccountFormState(
      type: state.type,
      name: state.name,
      includeInNetWorth: state.includeInNetWorth,
      creditLimitCents: state.creditLimitCents,
      billingDay: state.billingDay,
      dueDay: day,
    );
  }

  /// 提交:返回 true 表示写入成功,false 表示校验失败或写失败。
  Future<bool> submit() async {
    final err = state.validate();
    if (err != null) return false;

    final db = _ref.read(databaseProvider);
    try {
      if (existingId == null) {
        // 新建
        await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: state.name.trim(),
            type: Value(state.type),
            includeInNetWorth: Value(state.includeInNetWorth),
            creditLimit: Value(state.creditLimitCents),
            billingDay: Value(state.billingDay),
            dueDay: Value(state.dueDay),
          ),
        );
        // D19 修复:主动 invalidate accountListProvider,刷新账户卡片列表
        _ref.invalidate(accountListProvider);
      } else {
        // 更新
        await db.accountDao.updateAccountById(
          AccountsCompanion(
            id: Value(existingId!),
            name: Value(state.name.trim()),
            type: Value(state.type),
            includeInNetWorth: Value(state.includeInNetWorth),
            creditLimit: Value(state.creditLimitCents),
            billingDay: Value(state.billingDay),
            dueDay: Value(state.dueDay),
          ),
        );
        // D19 修复:主动 invalidate accountListProvider,刷新账户卡片余额显示
        _ref.invalidate(accountListProvider);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 账户表单 provider(弹层用)。
///
/// WHY: family 模式 — Key 是 int?(null = 新建,非 null = 编辑该 ID 的账户),
/// 弹层打开创建新 controller 实例。不用 autoDispose 是因为:
/// - 弹层关闭时 family key 仍可能被外部 listener 引用,立即 dispose 会导致
///   测试和真实场景 race condition
/// - 实例数量 = 用户同时打开的弹层数(实际 ≤ 1),GC 自然清理
final accountFormProvider = StateNotifierProvider
    .family<AccountFormController, AccountFormState, int?>(
  (ref, existingId) => AccountFormController(ref, existingId: existingId),
);

/// 账户列表 provider(监听所有账户,主页 + 管理页共用)。
final accountListProvider = StreamProvider<List<AccountEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.accountDao.watchAll();
});