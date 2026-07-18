import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../application/repayment_form_provider.dart';

/// 打开还款弹层(D20 — 信用卡还款)。
///
/// 流程(单页布局,不切换 step):
///   1. 选储蓄账户(下拉 / 列表)
///   2. 输入还款金额(数字键盘)
///   3. 选信用卡账户(下拉 / 列表)
///   4. 备注(可选)
///   5. 点「还款」→ 调 transferRepayment,关闭弹层
///
/// 返回 `Future<bool>`:
///   - true:还款成功
///   - false:用户主动关闭或保存失败
Future<bool> showRepaymentSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const RepaymentSheet(),
  ).then((result) => result ?? false);
}

/// 还款弹层主体。
class RepaymentSheet extends ConsumerStatefulWidget {
  const RepaymentSheet({super.key});

  @override
  ConsumerState<RepaymentSheet> createState() => _RepaymentSheetState();
}

class _RepaymentSheetState extends ConsumerState<RepaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(repaymentFormProvider);
    final notifier = ref.read(repaymentFormProvider.notifier);
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.of(context).pop(false)),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle('扣款账户'),
                    _SavingsAccountPicker(
                      selectedId: form.fromAccountId,
                      onSelected: notifier.setFromAccount,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('还款金额'),
                    _AmountInput(
                      controller: _amountController,
                      onChanged: (cents) => notifier.setAmount(cents),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('欠款账户'),
                    _CreditCardAccountPicker(
                      selectedId: form.toAccountId,
                      onSelected: notifier.setToAccount,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('备注(可选)'),
                    _NoteInput(
                      controller: _noteController,
                      onChanged: notifier.setNote,
                    ),
                    if (form.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          form.errorMessage!,
                          key: const Key('repayment-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _SubmitBar(form: form, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

/// 顶部关闭栏。
class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                '还款',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            key: const Key('repayment-sheet-close'),
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}

/// 区块标题(灰色小字)。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 储蓄账户选择器(从 savingsAccountListProvider 读数据)。
class _SavingsAccountPicker extends ConsumerWidget {
  const _SavingsAccountPicker({
    required this.selectedId,
    required this.onSelected,
  });

  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(savingsAccountListProvider);
    return asyncAccounts.when(
      data: (accounts) => _AccountSelector(
        accounts: accounts,
        selectedId: selectedId,
        onSelected: onSelected,
        keyPrefix: 'from-debit',
        emptyMessage: '请先在账户管理添加储蓄账户',
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('加载失败:$e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

/// 信用卡账户选择器(从 debtAccountListProvider 读数据)。
class _CreditCardAccountPicker extends ConsumerWidget {
  const _CreditCardAccountPicker({
    required this.selectedId,
    required this.onSelected,
  });

  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(debtAccountListProvider);
    return asyncAccounts.when(
      data: (accounts) => _AccountSelector(
        accounts: accounts,
        selectedId: selectedId,
        onSelected: onSelected,
        keyPrefix: 'to-debt',
        emptyMessage: '请先在账户管理添加信用卡账户',
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('加载失败:$e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

/// 账户选择器(单选,横向 Wrap)。
class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    required this.keyPrefix,
    required this.emptyMessage,
  });

  final List<AccountEntry> accounts;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final String keyPrefix;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          emptyMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: accounts.map((acc) {
          final selected = acc.id == selectedId;
          return ChoiceChip(
            key: Key('$keyPrefix-${acc.id}'),
            label: Text('${acc.type.emoji} ${acc.name}'),
            selected: selected,
            onSelected: (_) => onSelected(acc.id),
          );
        }).toList(),
      ),
    );
  }
}

/// 金额输入框(¥xxx.xx 格式)。
class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        key: const Key('repayment-amount'),
        controller: controller,
        decoration: const InputDecoration(
          labelText: '还款金额',
          hintText: '比如:1500',
          border: OutlineInputBorder(),
          prefixText: '¥ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        onChanged: (v) {
          final trimmed = v.trim();
          if (trimmed.isEmpty) {
            onChanged(0);
          } else {
            final yuan = double.tryParse(trimmed);
            onChanged(yuan == null ? 0 : (yuan * 100).round());
          }
        },
      ),
    );
  }
}

/// 备注输入框(可选)。
class _NoteInput extends StatelessWidget {
  const _NoteInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        key: const Key('repayment-note'),
        controller: controller,
        decoration: const InputDecoration(
          labelText: '备注',
          hintText: '比如:还 8 月账单',
          border: OutlineInputBorder(),
        ),
        maxLength: 50,
        onChanged: onChanged,
      ),
    );
  }
}

/// 底部「还款」主按钮。
class _SubmitBar extends ConsumerWidget {
  const _SubmitBar({required this.form, required this.notifier});

  final RepaymentFormState form;
  final RepaymentFormController notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            key: const Key('repayment-submit'),
            onPressed: form.canSubmit
                ? () async {
                    final ok = await notifier.submit();
                    if (context.mounted && ok) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('还款成功'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                : null,
            child: Text(form.isSubmitting ? '还款中...' : '还款'),
          ),
        ),
      ),
    );
  }
}