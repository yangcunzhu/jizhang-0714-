import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';

/// 转账表单状态(ADR-0026 §5 — 资金账户 → 资金账户)。
///
/// 与还款(RepaymentFormState)区别:转账双方都是普通资金账户,不涉及欠款;
/// 语义是「钱从这里到那里」,双方平衡。
class TransferFormState {
  const TransferFormState({
    this.fromAccountId,
    this.toAccountId,
    this.amountCents = 0,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  static const TransferFormState initial = TransferFormState();

  final int? fromAccountId;
  final int? toAccountId;
  final int amountCents;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;

  bool get canSubmit =>
      fromAccountId != null &&
      toAccountId != null &&
      amountCents > 0 &&
      !isSubmitting;

  TransferFormState copyWith({
    int? fromAccountId,
    int? toAccountId,
    int? amountCents,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearFromAccount = false,
    bool clearToAccount = false,
    bool clearError = false,
  }) {
    return TransferFormState(
      fromAccountId:
          clearFromAccount ? null : (fromAccountId ?? this.fromAccountId),
      toAccountId: clearToAccount ? null : (toAccountId ?? this.toAccountId),
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 转账表单 controller。
class TransferFormController extends AutoDisposeNotifier<TransferFormState> {
  @override
  TransferFormState build() => TransferFormState.initial;

  void setFromAccount(int? id) => state = state.copyWith(
      fromAccountId: id, clearFromAccount: id == null, clearError: true);
  void setToAccount(int? id) => state = state.copyWith(
      toAccountId: id, clearToAccount: id == null, clearError: true);
  void setAmount(int cents) =>
      state = state.copyWith(amountCents: cents, clearError: true);
  void setNote(String note) =>
      state = state.copyWith(note: note, clearError: true);

  /// 提交转账。返回 true 表示成功。
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    if (state.fromAccountId == state.toAccountId) {
      state = state.copyWith(errorMessage: '转出账户和转入账户不能是同一个');
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final db = ref.read(databaseProvider);
    try {
      await db.transactionDao.transferMoney(
        fromAccountId: state.fromAccountId!,
        toAccountId: state.toAccountId!,
        amountCents: state.amountCents,
        note: state.note.isEmpty ? null : state.note,
      );
      ref.invalidate(accountListProvider);
      state = TransferFormState.initial;
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: '转账失败:$e');
      return false;
    }
  }
}

final transferFormProvider =
    AutoDisposeNotifierProvider<TransferFormController, TransferFormState>(
  TransferFormController.new,
);

/// 转账可选账户 provider(资金 + 充值类,有余额可动的账户)。
///
/// WHY 只资金/充值:转账双方都是「有实际余额」的资产账户;信用/借贷不作为转账
/// 对象(那是还款/借贷流)。理财类余额是市值,暂不参与转账(留后续)。
final transferableAccountListProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  final all = await db.accountDao.getAll();
  return all.where((a) {
    final cat = a.subType?.category ??
        switch (a.type) {
          AccountType.cash || AccountType.savings => AccountCategory.fund,
          AccountType.investment => AccountCategory.investment,
          _ => AccountCategory.credit,
        };
    return cat == AccountCategory.fund || cat == AccountCategory.recharge;
  }).toList();
});
