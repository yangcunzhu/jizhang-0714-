import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/categories.dart';
import '../../account/application/account_form_provider.dart';
import 'haptics.dart';

/// 记账表单的步骤（单页内切换，不是真 3 屏）。
enum RecordStep { selectCategory, inputAmount, selectAccount }

/// 记账表单状态。
///
/// 金额一律存整数分（[amountCents]），UI 显示时除以 100。
///
/// [editingTransactionId] 为 null 时为"新建"模式,非 null 时为"编辑现有交易"模式。
/// 编辑模式下 [submit] 走 UPDATE 分支而非 INSERT。
class RecordFormState {
  const RecordFormState({
    this.step = RecordStep.selectCategory,
    this.categoryId,
    this.amountCents = 0,
    this.accountId,
    this.note = '',
    this.isSubmitting = false,
    this.editingTransactionId,
    this.excludeFromIncomeExpense = false, // D28 ADR-0033 toggle
    this.excludeFromBudget = false,
    this.isRefundLocked = false, // D28 IQA-fix:refund 编辑 toggle 锁
  });

  final RecordStep step;
  final int? categoryId;
  final int amountCents;
  final int? accountId;
  final String note;
  final bool isSubmitting;
  final int? editingTransactionId;
  // D28 ADR-0033:交易级 2 toggle(咔皮图 19/293 默认 false,保持 S02 行为)
  final bool excludeFromIncomeExpense;
  final bool excludeFromBudget;
  // D28 IQA-fix G-IQA-D28-6 (2026-08-11):编辑 refund 时锁 toggle 为 true,
  // 防止用户改 toggles 后 toggle=false 导致 refund 重复计入收入统计。
  // record_sheet UI 检测 isRefundLocked=true 时,toggle chip disabled + tooltip 提示。
  final bool isRefundLocked;

  bool get canProceedFromCategory => categoryId != null;
  bool get canProceedFromAmount => amountCents > 0;

  /// 是否可以保存：金额 > 0 + 账户已选 + 未在提交中。
  bool get canSubmit =>
      amountCents > 0 && accountId != null && !isSubmitting;

  bool get isEditing => editingTransactionId != null;

  RecordFormState copyWith({
    RecordStep? step,
    int? categoryId,
    int? amountCents,
    int? accountId,
    String? note,
    bool? isSubmitting,
    int? editingTransactionId,
    bool? excludeFromIncomeExpense,
    bool? excludeFromBudget,
    bool? isRefundLocked,
  }) {
    return RecordFormState(
      step: step ?? this.step,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      editingTransactionId: editingTransactionId ?? this.editingTransactionId,
      excludeFromIncomeExpense:
          excludeFromIncomeExpense ?? this.excludeFromIncomeExpense,
      excludeFromBudget: excludeFromBudget ?? this.excludeFromBudget,
      isRefundLocked: isRefundLocked ?? this.isRefundLocked,
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

  // D28 ADR-0033:toggle setter
  void setExcludeFromIncomeExpense(bool value) {
    // D28 IQA-fix G-IQA-D28-6:refund 锁 toggle(用户改不动)
    if (state.isRefundLocked) return;
    state = state.copyWith(excludeFromIncomeExpense: value);
  }

  void setExcludeFromBudget(bool value) {
    if (state.isRefundLocked) return;
    state = state.copyWith(excludeFromBudget: value);
  }

  /// 重置整个表单（弹层关闭时调用）。
  void reset() {
    _afterDot = false;
    _centsAccumulator = 0;
    state = const RecordFormState();
  }

  /// 从现有交易反向填充表单(进入"编辑"模式)。
  ///
  /// WHY: 长按交易 → 选"编辑"时复用同一个弹层,无需新建 EditPage。
  /// 默认直接跳到 selectAccount 步骤(分类/金额不再必选,用户可改也可只改备注)。
  ///
  /// D28 IQA-fix G-IQA-D28-6 (2026-08-11):检测 `tx.type == TransactionType.refund`
  /// 时设 `isRefundLocked = true` — toggle chip 禁用,submit 时不写 toggle(保证
  /// 「refund 不计入收入统计」不可变)。
  void loadForEdit(TransactionEntry tx) {
    _afterDot = false;
    _centsAccumulator = 0;
    final isRefund = tx.type == TransactionType.refund;
    state = RecordFormState(
      step: RecordStep.selectAccount,
      categoryId: tx.categoryId,
      amountCents: tx.amountCents,
      accountId: tx.accountId,
      note: tx.note,
      editingTransactionId: tx.id,
      // D28:load 时读 toggle(refund 锁原值,其他正常)
      excludeFromIncomeExpense: tx.excludeFromIncomeExpense,
      excludeFromBudget: tx.excludeFromBudget,
      isRefundLocked: isRefund,
    );
  }

  /// 删除一笔交易(由长按 ActionSheet → "删除"调用)。
  ///
  /// 返回影响行数;找不到 id 也返回 0 而非抛错(防御性,UI 层不依赖返回值)。
  /// 删除成功后 100ms 长振反馈。
  Future<int> deleteTransaction(int id) async {
    final db = ref.read(databaseProvider);
    final rows = await db.transactionDao.deleteById(id);
    // D19 修复:主动 invalidate accountListProvider,刷新账户卡片余额显示
    ref.invalidate(accountListProvider);
    await Haptics.heavy();
    return rows;
  }

  // ---------- 保存 ----------

  /// 保存到 Drift + 振动反馈。
  ///
  /// - 新建模式([editingTransactionId] == null):INSERT
  /// - 编辑模式([editingTransactionId] != null):UPDATE
  ///
  /// 返回:
  /// - 新建:插入的 id
  /// - 编辑:被更新的 id(等于 editingTransactionId)
  Future<int> submit() async {
    if (!state.canSubmit) {
      throw StateError('表单不完整：amount=${state.amountCents} account=${state.accountId}');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final db = ref.read(databaseProvider);
      final cats = await db.categoryDao.getAll();
      final cat = cats.firstWhere((c) => c.id == state.categoryId);

      if (state.editingTransactionId != null) {
        // 编辑模式:UPDATE 现有交易,保留原 occurredAt/createdAt。
        final old = await db.transactionDao.getById(state.editingTransactionId!);
        if (old == null) {
          throw StateError('编辑目标不存在:id=${state.editingTransactionId}');
        }
        // D28 IQA-fix G-IQA-D28-6 (2026-08-11):refund 锁 toggle
        // — 老 transaction 是 refund 时,UPDATE 不写 toggle(保留原始 true),
        // 保持「refund 不计入收入统计」不可变。
        final isRefund = old.type == TransactionType.refund;
        final updated = old.copyWith(
          amountCents: state.amountCents,
          type: cat.type,
          categoryId: state.categoryId!,
          accountId: state.accountId!,
          note: state.note,
          // D28 IQA-fix G-IQA-D28-6 (2026-08-11):refund 编辑锁 toggle
          // — refund 时 pass 老值(不写);其他写用户选的。
          // DataClass.copyWith 字段类型 bool(nullable)— pass 老值即可保留。
          excludeFromIncomeExpense: isRefund
              ? old.excludeFromIncomeExpense
              : state.excludeFromIncomeExpense,
          excludeFromBudget: isRefund
              ? old.excludeFromBudget
              : state.excludeFromBudget,
        );
        await db.transactionDao.updateTransaction(updated);
        // D19 修复:主动 invalidate accountListProvider,刷新账户卡片余额显示
        ref.invalidate(accountListProvider);
        // 编辑成功:100ms 长振(成功完成档)
        await Haptics.heavy();
        return state.editingTransactionId!;
      }

      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: state.amountCents,
          type: cat.type,
          categoryId: state.categoryId!,
          accountId: state.accountId!,
          note: Value(state.note),
          // D28 ADR-0033:toggle 写入
          excludeFromIncomeExpense:
              Value(state.excludeFromIncomeExpense),
          excludeFromBudget: Value(state.excludeFromBudget),
        ),
      );
      // D19 修复:主动 invalidate accountListProvider,刷新账户卡片余额显示
      ref.invalidate(accountListProvider);
      // 新建成功:50ms 短振(输入确认档 — 与"分类点击""数字点击"同一档)
      await Haptics.light();
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