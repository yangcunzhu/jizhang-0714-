import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';

/// 记账表单的步骤（单页内切换，不是真 3 屏）。
enum RecordStep { selectCategory, inputAmount, selectAccount }

/// 记账表单状态。
///
/// 金额一律存整数分（[amountCents]），UI 显示时除以 100。
class RecordFormState {
  const RecordFormState({
    this.step = RecordStep.selectCategory,
    this.categoryId,
    this.amountCents = 0,
    this.accountId,
    this.note = '',
    this.isSubmitting = false,
  });

  final RecordStep step;
  final int? categoryId;
  final int amountCents;
  final int? accountId;
  final String note;
  final bool isSubmitting;

  bool get canProceedFromCategory => categoryId != null;
  bool get canProceedFromAmount => amountCents > 0;

  /// 是否可以保存：金额 > 0 + 账户已选 + 未在提交中。
  bool get canSubmit =>
      amountCents > 0 && accountId != null && !isSubmitting;

  RecordFormState copyWith({
    RecordStep? step,
    int? categoryId,
    int? amountCents,
    int? accountId,
    String? note,
    bool? isSubmitting,
  }) {
    return RecordFormState(
      step: step ?? this.step,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// 记账表单 Notifier（手写无 codegen，符合 ADR-0012）。
///
/// 维护 3 步表单 + 计算器式金额累计 + 保存到 Drift + 触发振动。
class RecordFormNotifier extends AutoDisposeNotifier<RecordFormState> {
  /// 标记当前是否在"分位"输入阶段（用户按过 .）。
  bool _afterDot = false;

  /// 分位累计值（0..99），输入点号后被赋值。
  int _centsAccumulator = 0;

  @override
  RecordFormState build() => const RecordFormState();

  // ---------- 分类 ----------

  /// 选中分类后直接跳到金额输入步骤（5 秒 3 步优化）。
  void selectCategory(int categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      step: RecordStep.inputAmount,
    );
  }

  // ---------- 金额（计算器式）----------

  /// 追加一位数字（0-9）。
  ///
  /// 整元阶段：cents = cents * 10 + d。
  /// 分位阶段：_centsAccumulator = _centsAccumulator * 10 + d（最多 2 位）。
  void appendDigit(int digit) {
    if (_afterDot) {
      if (_centsAccumulator >= 10) return; // 已满 2 位数字，忽略
      _centsAccumulator = _centsAccumulator * 10 + digit;
      final whole = state.amountCents ~/ 100;
      state = state.copyWith(amountCents: whole * 100 + _centsAccumulator);
    } else {
      // 防止金额过大溢出（cents 上限 ≈ 21 亿元，足够家用记账）
      if (state.amountCents > 0x7FFFFFF) return;
      state = state.copyWith(amountCents: state.amountCents * 10 + digit);
    }
  }

  /// 追加小数点（幂等：第二次按忽略）。
  void appendDot() {
    if (_afterDot) return;
    _afterDot = true;
    _centsAccumulator = 0;
    // 把当前 cents 转为"整元 × 100"形式（12 → 1200，分位占 0）
    state = state.copyWith(amountCents: state.amountCents * 100);
  }

  /// 删除最后一位数字或小数点。
  void backspace() {
    if (_afterDot && _centsAccumulator > 0) {
      _centsAccumulator = _centsAccumulator ~/ 10;
      final whole = state.amountCents ~/ 100;
      state = state.copyWith(amountCents: whole * 100 + _centsAccumulator);
    } else if (_afterDot && _centsAccumulator == 0) {
      // 删掉小数点，回到整元阶段
      _afterDot = false;
      state = state.copyWith(amountCents: state.amountCents ~/ 100);
    } else {
      state = state.copyWith(amountCents: state.amountCents ~/ 10);
    }
  }

  /// 清空金额（重置计算器状态）。
  void clearAmount() {
    _afterDot = false;
    _centsAccumulator = 0;
    state = state.copyWith(amountCents: 0);
  }

  // ---------- 步骤导航 ----------

  void nextStep() {
    switch (state.step) {
      case RecordStep.selectCategory:
        if (state.canProceedFromCategory) {
          state = state.copyWith(step: RecordStep.inputAmount);
        }
      case RecordStep.inputAmount:
        if (state.canProceedFromAmount) {
          state = state.copyWith(step: RecordStep.selectAccount);
        }
      case RecordStep.selectAccount:
        // 最后一步通过 submit() 提交
        break;
    }
  }

  void previousStep() {
    switch (state.step) {
      case RecordStep.selectCategory:
        break; // 已是最前
      case RecordStep.inputAmount:
        state = state.copyWith(step: RecordStep.selectCategory);
      case RecordStep.selectAccount:
        state = state.copyWith(step: RecordStep.inputAmount);
    }
  }

  void setAccount(int accountId) {
    state = state.copyWith(accountId: accountId);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  /// 重置整个表单（弹层关闭时调用）。
  void reset() {
    _afterDot = false;
    _centsAccumulator = 0;
    state = const RecordFormState();
  }

  // ---------- 保存 ----------

  /// 保存到 Drift + 振动反馈。返回插入的 id。
  Future<int> submit() async {
    if (!state.canSubmit) {
      throw StateError('表单不完整：amount=${state.amountCents} account=${state.accountId}');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final db = ref.read(databaseProvider);
      final cats = await db.categoryDao.getAll();
      final cat = cats.firstWhere((c) => c.id == state.categoryId);
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: state.amountCents,
          type: cat.type,
          categoryId: state.categoryId!,
          accountId: state.accountId!,
          note: Value(state.note),
        ),
      );
      // 振动反馈（50ms 短振，模拟器/无振设备静默忽略）
      try {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(duration: 50);
        }
      } catch (_) {
        // 振动失败不阻断保存
      }
      return id;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

/// Provider 入口。
///
/// autoDispose：弹层关闭后没人 watch → Notifier 自动销毁，
/// 下次打开弹层拿全新 state（避免上次半填状态污染）。
final recordFormProvider =
    NotifierProvider.autoDispose<RecordFormNotifier, RecordFormState>(
  RecordFormNotifier.new,
);