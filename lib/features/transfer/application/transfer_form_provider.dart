import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
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

/// 转账可选账户 provider(D22 修正:全部账户类型)。
///
/// WHY 不再过滤:用户反馈「每种都可以转账」(咔皮对标 v4 §3.1 转账是普通账户间
/// 转移,实际场景涵盖储蓄↔信用卡还款外的灵活转账,例如股票赎回 → 储蓄)。
/// 借贷类在转账弹层仍可被选,但提交时由 DAO 校验(toAccountId 必须存在即可,
/// 余额联动语义由 [TransactionDao.transferMoney] 通用处理)。
final transferableAccountListProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.accountDao.getAll();
});
