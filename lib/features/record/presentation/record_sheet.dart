import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../home/application/home_providers.dart';
import '../../category/presentation/category_management_page.dart';
import '../application/record_form_provider.dart';
import 'widgets/account_picker.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/category_grid.dart';

/// 打开记账弹层（半屏，可滚动超 50%）。
///
/// WHY: 5 秒 3 步手动记账的入口。HomePage "记一笔"FAB 调用。
/// [editing] 非 null 时进入"编辑模式":弹层打开后由 [RecordSheet.initState] 调
/// `loadForEdit` 反向填充表单,走 UPDATE 分支提交。
///
/// 返回 `Future<bool>`:
///   - true:成功保存(create 或 edit 都算)
///   - false:用户主动关闭(点 X / 上一步退回主页 / 点击外部关闭)
/// 主页根据返回值决定是否触发攒攒动画 + SnackBar 已记账提示。
Future<bool> showRecordSheet(
  BuildContext context, {
  TransactionEntry? editing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => RecordSheet(editing: editing),
  ).then((result) => result ?? false);
}

/// 记账弹层主体。
///
/// 3 步单页内切换（[RecordStep]）：
///   selectCategory → inputAmount → selectAccount
///
/// 状态由 [recordFormProvider] 统一管理。
///
/// Day 8: 转为 ConsumerStatefulWidget 以支持 [editing] 在 initState 调 loadForEdit,
/// 避开 autoDispose 时序坑(ActionSheet pop → showRecordSheet 期间 provider 被 dispose)。
class RecordSheet extends ConsumerStatefulWidget {
  const RecordSheet({super.key, this.editing});

  final TransactionEntry? editing;

  @override
  ConsumerState<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<RecordSheet> {
  @override
  void initState() {
    super.initState();
    // 编辑模式:在弹层已挂载(recordFormProvider 已被 watch)后调 loadForEdit,
    // 不会因 autoDispose 丢失状态。
    if (widget.editing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recordFormProvider.notifier).loadForEdit(widget.editing!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(recordFormProvider);
    final notifier = ref.read(recordFormProvider.notifier);

    // Stage 1 自动选中默认账户（"现金"），用户无需手动选。
    //
    // WHY: 用 ref.watch 而非 ref.listen，因为 ref.listen 不会回调初始值，
    // 弹层打开时 defaultAccountProvider 已经有值，需要主动触发 setAccount。
    // 编辑模式下 accountId 已由 loadForEdit 填充,跳过。
    final accAsync = ref.watch(defaultAccountProvider);
    final acc = accAsync.valueOrNull;
    if (!form.isEditing && acc != null && form.accountId == null) {
      // 用 post-frame callback 避免 build 阶段 mutate state 触发警告。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setAccount(acc.id);
      });
    }

    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              canBack: form.step != RecordStep.selectCategory,
              onBack: notifier.previousStep,
              onClose: () => Navigator.of(context).pop(false),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _StepBody(step: form.step, form: form, notifier: notifier),
              ),
            ),
            _PrimaryAction(form: form, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.form,
    required this.notifier,
  });

  final RecordStep step;
  final RecordFormState form;
  final RecordFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case RecordStep.selectCategory:
        return CategoryGrid(
          selectedCategoryId: form.categoryId,
          onSelected: (c) => notifier.selectCategory(c.id),
          onManageCategory: () {
            // 弹层已 isScrollControlled=true,新开页面用普通 push 即可。
            // ignore: use_build_context_synchronously
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoryManagementPage(),
              ),
            );
          },
        );
      case RecordStep.inputAmount:
        return _AmountStep(
          amountCents: form.amountCents,
          onDigit: notifier.appendDigit,
          onDot: notifier.appendDot,
          onBackspace: notifier.backspace,
          onClear: notifier.clearAmount,
        );
      case RecordStep.selectAccount:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccountPicker(
              selectedAccountId: form.accountId,
              onAccountSelected: notifier.setAccount,
              initialNote: form.note,
              onNoteChanged: notifier.setNote,
            ),
            // D28 ADR-0033:2 toggle(图 19/293 复刻)
            // 默认 false(保持 S02 行为,旧数据零影响)。
            // ⚠️ 决策 5 不可改实际由 detail_page 锁 — 但 record_sheet 编辑入口
            // 仍可临时调整(写完即锁),用户大概率不会察觉。
            // 真实业务场景:报销/代付/预算外
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      key: const Key('record-toggle-no-income-expense'),
                      value: form.excludeFromIncomeExpense,
                      // D28 IQA-fix G-IQA-D28-6 (2026-08-11):refund 锁 toggle
                      onChanged: form.isRefundLocked
                          ? null
                          : (v) => notifier.setExcludeFromIncomeExpense(v),
                      title: Text(
                        form.isRefundLocked ? '不计收支(锁定)' : '不计收支',
                      ),
                      subtitle: const Text(
                          '此交易不计入本月收支统计(账户余额照常更新)'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      key: const Key('record-toggle-no-budget'),
                      value: form.excludeFromBudget,
                      onChanged: form.isRefundLocked
                          ? null
                          : (v) => notifier.setExcludeFromBudget(v),
                      title: Text(
                        form.isRefundLocked ? '不计预算(锁定)' : '不计预算',
                      ),
                      subtitle: const Text(
                          '此交易不计入分类预算统计'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.canBack,
    required this.onBack,
    required this.onClose,
  });

  final bool canBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            key: const Key('record-sheet-back'),
            onPressed: canBack ? onBack : null,
            icon: const Icon(Icons.arrow_back),
            tooltip: '上一步',
          ),
          const Expanded(
            child: Center(
              child: Text(
                '记一笔',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            key: const Key('record-sheet-close'),
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.amountCents,
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
    required this.onClear,
  });

  final int amountCents;
  final ValueChanged<int> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountDisplay(cents: amountCents, onClear: onClear),
          const SizedBox(height: 16),
          AmountKeypad(
            onDigit: onDigit,
            onDot: onDot,
            onBackspace: onBackspace,
          ),
        ],
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.cents, required this.onClear});

  final int cents;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final yuan = cents ~/ 100;
    final centsPart = cents % 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '¥',
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${yuan.toString()}.${centsPart.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (cents > 0)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '清空',
            ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.form, required this.notifier});

  final RecordFormState form;
  final RecordFormNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, enabled, action) = _resolve(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            key: const Key('record-sheet-primary'),
            onPressed: enabled ? action : null,
            child: Text(form.isSubmitting ? '保存中...' : label),
          ),
        ),
      ),
    );
  }

  /// 根据当前 step 决定底部主按钮文案、enabled 状态和点击动作。
  ///
  /// WHY: step 1 没有金额 → 只能回退；step 2 需要"下一步"按钮主动推进（避免用户输入完金额后无入口）；
  /// step 3 才显示"保存"。
  (String, bool, VoidCallback) _resolve(BuildContext context) {
    switch (form.step) {
      case RecordStep.selectCategory:
        // step 1 无金额按钮槽位;这里放空按钮占位(用户已选分类会自动跳到 step 2,实际不会停留)
        return ('下一步', form.canProceedFromCategory, notifier.nextStep);
      case RecordStep.inputAmount:
        return ('下一步', form.canProceedFromAmount, notifier.nextStep);
      case RecordStep.selectAccount:
        return ('保存', form.canSubmit, () => _submit(context));
    }
  }

  Future<void> _submit(BuildContext context) async {
    final wasEditing = form.isEditing;
    try {
      await notifier.submit();
      if (context.mounted) {
        // pop(true) → 主页 showRecordSheet 返回 true → 触发攒攒动画。
        // SnackBar 仍由 sheet 内触发(ScaffoldMessenger 向上找到主页 Scaffold)，
        // 动画 + SnackBar 并存不冲突。
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasEditing ? '已修改' : '已记账'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }
}