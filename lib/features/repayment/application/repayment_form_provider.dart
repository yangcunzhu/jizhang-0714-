import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';

/// 还款表单状态(D20 — 信用卡还款流 + ADR-0024)。
///
/// 与 recordFormProvider 类似,但语义不同:不是记账支出,而是从扣款账户
/// 转账到收款账户(语义:还款),生成 1 条 type=repayment 的 transaction。
///
/// ADR-0024 改名:
/// - fromSavingsAccountId → fromAccountId(扣款方,任意现金类:现金/储蓄)
/// - toCreditCardAccountId → toAccountId(收款方,任意欠款类:信用卡/花呗/网贷)
/// - 新增 installmentPeriod(网贷专属,其他类型忽略)
class RepaymentFormState {
  const RepaymentFormState({
    this.fromAccountId,
    this.toAccountId,
    this.amountCents = 0,
    this.installmentPeriod,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// 默认初始值。
  static const RepaymentFormState initial = RepaymentFormState();

  /// 扣款账户 ID(现金/储蓄)。
  final int? fromAccountId;

  /// 收款账户 ID(信用卡/花呗/网贷)。
  final int? toAccountId;

  /// 还款金额(分)。
  final int amountCents;

  /// 网贷期数(可选,仅网贷还款需要)。
  final int? installmentPeriod;

  /// 备注(可选)。
  final String note;

  /// 是否正在提交。
  final bool isSubmitting;

  /// 错误信息(提交失败时)。
  final String? errorMessage;

  bool get canSubmit =>
      fromAccountId != null &&
      toAccountId != null &&
      amountCents > 0 &&
      !isSubmitting;

  RepaymentFormState copyWith({
    int? fromAccountId,
    int? toAccountId,
    int? amountCents,
    int? installmentPeriod,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearFromAccount = false,
    bool clearToAccount = false,
    bool clearError = false,
  }) {
    return RepaymentFormState(
      fromAccountId:
          clearFromAccount ? null : (fromAccountId ?? this.fromAccountId),
      toAccountId:
          clearToAccount ? null : (toAccountId ?? this.toAccountId),
      amountCents: amountCents ?? this.amountCents,
      installmentPeriod: installmentPeriod ?? this.installmentPeriod,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 还款表单 controller(D20 + ADR-0024)。
///
/// 调用 [accountListProvider] 读账户,提交时调 [TransactionDao.transferRepayment]。
class RepaymentFormController extends AutoDisposeNotifier<RepaymentFormState> {
  @override
  RepaymentFormState build() => RepaymentFormState.initial;

  void setFromAccount(int? accountId) {
    state = state.copyWith(
      fromAccountId: accountId,
      clearFromAccount: accountId == null,
      clearError: true,
    );
  }

  void setToAccount(int? accountId) {
    state = state.copyWith(
      toAccountId: accountId,
      clearToAccount: accountId == null,
      clearError: true,
    );
  }

  void setAmount(int cents) {
    state = state.copyWith(amountCents: cents, clearError: true);
  }

  /// 设置网贷期数(可选)。
  void setInstallmentPeriod(int? period) {
    state = state.copyWith(installmentPeriod: period, clearError: true);
  }

  void setNote(String note) {
    state = state.copyWith(note: note, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// 提交还款。
  ///
  /// 返回 true 表示成功,false 表示失败(校验不过或运行时异常)。
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    if (state.fromAccountId == state.toAccountId) {
      state = state.copyWith(errorMessage: '扣款账户和收款账户不能是同一个');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final db = ref.read(databaseProvider);
    try {
      await db.transactionDao.transferRepayment(
        fromAccountId: state.fromAccountId!,
        toAccountId: state.toAccountId!,
        amountCents: state.amountCents,
        note: state.note.isEmpty ? null : state.note,
        installmentPeriod: state.installmentPeriod,
      );
      // D19 修复:主动 invalidate,刷新账户卡片余额
      ref.invalidate(accountListProvider);
      // 重置状态(避免下次打开弹层残留上次输入)
      state = RepaymentFormState.initial;
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '还款失败:$e',
      );
      return false;
    }
  }
}

/// 还款表单 provider。
final repaymentFormProvider =
    AutoDisposeNotifierProvider<RepaymentFormController, RepaymentFormState>(
  RepaymentFormController.new,
);

/// 储蓄账户候选 provider(用于扣款方下拉)。
///
/// WHY 独立 provider:还款弹层打开时 watch 这个列表,而不是自己 getAll 过滤,
/// 符合 Riverpod 的 reactive 模式。
final savingsAccountListProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.accountDao.getAll();
  // 储蓄 / 现金 都可以作为扣款方(都是「现金类」账户,有余额可扣)
  return all
      .where((a) =>
          a.type == AccountType.savings || a.type == AccountType.cash)
      .toList();
});

/// 欠款账户候选 provider(用于收款方下拉)。
///
/// 信用卡 / 花呗 / 网贷 都是欠款类(ADR-0024 §1 6 种账户类型产品定位)。
final debtAccountListProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.accountDao.getAll();
  return all
      .where((a) =>
          a.type == AccountType.creditCard ||
          a.type == AccountType.huabei ||
          a.type == AccountType.onlineLoan)
      .toList();
});