import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';

/// 还款表单状态(D20 — 信用卡还款流)。
///
/// 与 recordFormProvider 类似,但语义不同:不是记账支出,而是从储蓄账户
/// 转账到信用卡账户(语义:还款),生成 1 条 type=repayment 的 transaction。
class RepaymentFormState {
  const RepaymentFormState({
    this.fromSavingsAccountId,
    this.toCreditCardAccountId,
    this.amountCents = 0,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// 默认初始值。
  static const RepaymentFormState initial = RepaymentFormState();

  /// 储蓄账户 ID(扣款方)。
  final int? fromSavingsAccountId;

  /// 信用卡账户 ID(收款方)。
  final int? toCreditCardAccountId;

  /// 还款金额(分)。
  final int amountCents;

  /// 备注(可选)。
  final String note;

  /// 是否正在提交。
  final bool isSubmitting;

  /// 错误信息(提交失败时)。
  final String? errorMessage;

  bool get canSubmit =>
      fromSavingsAccountId != null &&
      toCreditCardAccountId != null &&
      amountCents > 0 &&
      !isSubmitting;

  RepaymentFormState copyWith({
    int? fromSavingsAccountId,
    int? toCreditCardAccountId,
    int? amountCents,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearFromSavings = false,
    bool clearToCreditCard = false,
    bool clearError = false,
  }) {
    return RepaymentFormState(
      fromSavingsAccountId: clearFromSavings
          ? null
          : (fromSavingsAccountId ?? this.fromSavingsAccountId),
      toCreditCardAccountId: clearToCreditCard
          ? null
          : (toCreditCardAccountId ?? this.toCreditCardAccountId),
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 还款表单 controller(D20 — 信用卡还款流)。
///
/// 调用 [AccountDao.getAll] 过滤出「储蓄 / 现金 / 网贷」(扣款方候选)和
/// 「信用卡 / 花呗」(收款方候选),提交时调 [TransactionDao.transferRepayment]。
class RepaymentFormController extends AutoDisposeNotifier<RepaymentFormState> {
  @override
  RepaymentFormState build() => RepaymentFormState.initial;

  void setFromSavingsAccount(int? accountId) {
    state = state.copyWith(
      fromSavingsAccountId: accountId,
      clearFromSavings: accountId == null,
      clearError: true,
    );
  }

  void setToCreditCardAccount(int? accountId) {
    state = state.copyWith(
      toCreditCardAccountId: accountId,
      clearToCreditCard: accountId == null,
      clearError: true,
    );
  }

  /// 输入金额(分)。
  ///
  /// 仿 recordFormProvider 的数字键盘逻辑:每次 digit 触发,支持小数点。
  void setAmount(int cents) {
    state = state.copyWith(amountCents: cents, clearError: true);
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
    if (state.fromSavingsAccountId == state.toCreditCardAccountId) {
      state = state.copyWith(errorMessage: '储蓄账户和信用卡不能是同一个');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final db = ref.read(databaseProvider);
    try {
      await db.transactionDao.transferRepayment(
        fromSavingsAccountId: state.fromSavingsAccountId!,
        toCreditCardAccountId: state.toCreditCardAccountId!,
        amountCents: state.amountCents,
        note: state.note.isEmpty ? null : state.note,
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
  // 储蓄 / 现金 / 网贷 都可以作为扣款方(都是「现金类」账户,有余额可扣)
  return all
      .where((a) =>
          a.type == AccountType.savings ||
          a.type == AccountType.cash ||
          a.type == AccountType.onlineLoan)
      .toList();
});

/// 信用卡账户候选 provider(用于收款方下拉)。
///
/// 仅显示 type=creditCard(花呗语义类似但当前 MVP 暂不开放,避免用户混淆)。
final creditCardAccountListProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.accountDao.getAll();
  return all.where((a) => a.type == AccountType.creditCard).toList();
});