import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/tables/accounts.dart';
import '../../application/account_form_provider.dart';

/// 账户编辑弹层(ADR-0026 重做 — 5 大类 × 23 子类)。
///
/// 决策:ADR-0026 §10-12 — 大类分组 → 品牌子类 → 按大类动态字段表单 + 4 toggle。
/// - 信用类:额度 / 起始欠款 / 可用额度(自动算) / 出账日 / 还款日 / 起始时间
/// - 借贷类:本金 / 借款人 / 起始日期 / 还款日期
/// - 资金/充值/理财:初始余额
class AccountEditSheet extends ConsumerStatefulWidget {
  const AccountEditSheet({super.key, this.existingId, this.initialSubType});

  final int? existingId;

  /// 新建时预选子类型(如「+」菜单借出/借入直接进借贷类)。仅 existingId==null 生效。
  final AccountSubType? initialSubType;

  static Future<bool> show(
    BuildContext context, {
    int? existingId,
    AccountSubType? initialSubType,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          AccountEditSheet(existingId: existingId, initialSubType: initialSubType),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends ConsumerState<AccountEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _initialDebtController;
  late final TextEditingController _billingDayController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _counterpartyController;

  bool _canDismiss = true;
  AccountSubType? _lastSyncedSubType;

  @override
  void initState() {
    super.initState();
    // 新建 + 预选子类型:先切到目标子类(如借出/借入)。
    if (widget.existingId == null && widget.initialSubType != null) {
      ref
          .read(accountFormProvider(widget.existingId).notifier)
          .changeSubType(widget.initialSubType!);
    }
    final s = ref.read(accountFormProvider(widget.existingId));
    _nameController = TextEditingController(text: s.name);
    _brandController = TextEditingController(text: s.brandName ?? '');
    _balanceController = TextEditingController(text: _yuan(s.balanceCents, '0.00'));
    _creditLimitController =
        TextEditingController(text: _yuan(s.creditLimitCents, ''));
    _initialDebtController =
        TextEditingController(text: _yuan(s.initialDebtCents, ''));
    _billingDayController =
        TextEditingController(text: s.billingDay?.toString() ?? '');
    _dueDayController =
        TextEditingController(text: s.dueDay?.toString() ?? '');
    _counterpartyController =
        TextEditingController(text: s.counterpartyName ?? '');
    _lastSyncedSubType = s.subType;
  }

  String _yuan(int? cents, String fallback) =>
      cents != null ? (cents / 100).toStringAsFixed(2) : fallback;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _initialDebtController.dispose();
    _billingDayController.dispose();
    _dueDayController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  /// 子类切换后同步文本框(清空跨大类字段的残留文本)。
  void _syncControllersTo(AccountFormState s) {
    if (s.subType == _lastSyncedSubType) return;
    _lastSyncedSubType = s.subType;
    _creditLimitController.text = _yuan(s.creditLimitCents, '');
    _initialDebtController.text = _yuan(s.initialDebtCents, '');
    _billingDayController.text = s.billingDay?.toString() ?? '';
    _dueDayController.text = s.dueDay?.toString() ?? '';
    _counterpartyController.text = s.counterpartyName ?? '';
    if (!s.isCustom) _brandController.text = '';
  }

  int? _parseCents(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final yuan = double.tryParse(t);
    return yuan == null ? null : (yuan * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(accountFormProvider(widget.existingId));
    final c = ref.read(accountFormProvider(widget.existingId).notifier);
    final theme = Theme.of(context);
    _syncControllersTo(form);

    return PopScope(
      canPop: _canDismiss,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.existingId == null ? '添加账户' : '编辑账户',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 大类选择(5 大类)
                _CategorySelector(
                  current: form.category,
                  onSelected: (cat) => c.changeSubType(cat.subTypes.first),
                ),
                const SizedBox(height: 12),
                // 子类选择(当前大类下的品牌子类)
                _SubTypeSelector(
                  category: form.category,
                  current: form.subType,
                  onSelected: c.changeSubType,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('account-edit-name'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '账户名称',
                    hintText: '比如:招行信用卡 / 生活费',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: c.changeName,
                  maxLength: 20,
                ),
                if (form.isCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('account-edit-brand'),
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: '品牌/机构名',
                      hintText: '比如:某银行 / 某平台',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: c.changeBrandName,
                    maxLength: 20,
                  ),
                ],
                const SizedBox(height: 8),
                // 按大类分支字段
                if (form.isCreditLike)
                  _CreditFields(
                    form: form,
                    limitController: _creditLimitController,
                    initialDebtController: _initialDebtController,
                    billingDayController: _billingDayController,
                    dueDayController: _dueDayController,
                    onLimit: (v) => c.changeCreditLimitCents(_parseCents(v)),
                    onDebt: (v) => c.changeInitialDebtCents(_parseCents(v)),
                    onBilling: (v) => c.changeBillingDay(int.tryParse(v.trim())),
                    onDue: (v) => c.changeDueDay(int.tryParse(v.trim())),
                    onPickStart: () => _pickDate(context, form.startDate, c.changeStartDate),
                  )
                else if (form.isLoan)
                  _LoanFields(
                    form: form,
                    balanceController: _balanceController,
                    counterpartyController: _counterpartyController,
                    onBalance: (v) => c.changeBalanceCents(_parseCents(v)),
                    onCounterparty: c.changeCounterparty,
                    onPickStart: () => _pickDate(context, form.startDate, c.changeStartDate),
                    onPickDue: () => _pickDate(context, form.dueDate, c.changeDueDate),
                  )
                else
                  TextField(
                    key: const Key('account-edit-balance'),
                    controller: _balanceController,
                    decoration: InputDecoration(
                      labelText: widget.existingId == null ? '初始余额' : '当前余额',
                      hintText: '比如:5000',
                      border: const OutlineInputBorder(),
                      prefixText: '¥ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (v) => c.changeBalanceCents(_parseCents(v)),
                  ),
                const SizedBox(height: 8),
                // 4 toggle
                _ToggleTile(
                  keyName: 'account-edit-include-networth',
                  title: '计入净资产',
                  subtitle: form.subType?.isLiability == true
                      ? '负债账户计入负债侧'
                      : '资产账户计入资产侧',
                  value: form.includeInNetWorth,
                  onChanged: c.changeIncludeInNetWorth,
                ),
                _ToggleTile(
                  keyName: 'account-edit-pinned',
                  title: '特别关注',
                  subtitle: '置顶显示在资产账户顶部',
                  value: form.isPinned,
                  onChanged: c.changeIsPinned,
                ),
                _ToggleTile(
                  keyName: 'account-edit-default-income',
                  title: '默认收账账户',
                  subtitle: '收入未指定账户时自动关联',
                  value: form.isDefaultIncomeAccount,
                  onChanged: c.changeIsDefaultIncome,
                ),
                _ToggleTile(
                  keyName: 'account-edit-default-expense',
                  title: '默认支出账户',
                  subtitle: '支出未指定账户时自动关联',
                  value: form.isDefaultExpenseAccount,
                  onChanged: c.changeIsDefaultExpense,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('account-edit-cancel'),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('account-edit-save'),
                        onPressed: () async {
                          setState(() => _canDismiss = false);
                          final ok = await c.submit();
                          if (!mounted) return;
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() => _canDismiss = true);
                            final err = ref
                                .read(accountFormProvider(widget.existingId))
                                .validate();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content: Text(err ?? '保存失败:请检查字段是否合法'),
                              ));
                          }
                        },
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? current,
    ValueChanged<DateTime?> onPicked,
  ) async {
    final now = current ?? DateTime(2026, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }
}

/// 5 大类选择器。
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.current, required this.onSelected});

  final AccountCategory current;
  final ValueChanged<AccountCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AccountCategory.values.map((cat) {
        return ChoiceChip(
          key: Key('account-category-${cat.name}'),
          label: Text('${cat.emoji} ${cat.displayName}'),
          selected: cat == current,
          onSelected: (_) => onSelected(cat),
        );
      }).toList(),
    );
  }
}

/// 子类选择器(当前大类下的品牌)。
class _SubTypeSelector extends StatelessWidget {
  const _SubTypeSelector({
    required this.category,
    required this.current,
    required this.onSelected,
  });

  final AccountCategory category;
  final AccountSubType? current;
  final ValueChanged<AccountSubType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: category.subTypes.map((sub) {
        return ChoiceChip(
          key: Key('account-type-${sub.name}'),
          label: Text('${sub.emoji} ${sub.displayName}'),
          selected: sub == current,
          onSelected: (_) => onSelected(sub),
        );
      }).toList(),
    );
  }
}

/// 信用类字段:额度 / 起始欠款 / 可用额度(只读) / 出账日 / 还款日 / 起始时间。
class _CreditFields extends StatelessWidget {
  const _CreditFields({
    required this.form,
    required this.limitController,
    required this.initialDebtController,
    required this.billingDayController,
    required this.dueDayController,
    required this.onLimit,
    required this.onDebt,
    required this.onBilling,
    required this.onDue,
    required this.onPickStart,
  });

  final AccountFormState form;
  final TextEditingController limitController;
  final TextEditingController initialDebtController;
  final TextEditingController billingDayController;
  final TextEditingController dueDayController;
  final ValueChanged<String> onLimit;
  final ValueChanged<String> onDebt;
  final ValueChanged<String> onBilling;
  final ValueChanged<String> onDue;
  final VoidCallback onPickStart;

  @override
  Widget build(BuildContext context) {
    final avail = form.availableCreditCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('account-edit-credit-limit'),
          controller: limitController,
          decoration: const InputDecoration(
            labelText: '信用额度(元)',
            hintText: '比如:50000',
            border: OutlineInputBorder(),
            prefixText: '¥ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: onLimit,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('account-edit-initial-debt'),
          controller: initialDebtController,
          decoration: const InputDecoration(
            labelText: '起始欠款(元)',
            hintText: '初始已用额度,默认 0',
            border: OutlineInputBorder(),
            prefixText: '¥ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: onDebt,
        ),
        const SizedBox(height: 8),
        // 可用额度(自动算,只读)
        InputDecorator(
          decoration: const InputDecoration(
            labelText: '可用额度(自动计算)',
            border: OutlineInputBorder(),
            prefixText: '¥ ',
          ),
          child: Text(
            key: const Key('account-edit-available'),
            avail != null ? (avail / 100).toStringAsFixed(2) : '—',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('account-edit-billing-day'),
                controller: billingDayController,
                decoration: const InputDecoration(
                  labelText: '出账日',
                  hintText: '1-31',
                  border: OutlineInputBorder(),
                  suffixText: '号',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: onBilling,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('account-edit-due-day'),
                controller: dueDayController,
                decoration: const InputDecoration(
                  labelText: '还款日',
                  hintText: '1-31',
                  border: OutlineInputBorder(),
                  suffixText: '号',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: onDue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DateTile(
          keyName: 'account-edit-start-date',
          label: '起始时间',
          date: form.startDate,
          onTap: onPickStart,
        ),
      ],
    );
  }
}

/// 借贷类字段:本金 / 借款人 / 起始日期 / 还款日期。
class _LoanFields extends StatelessWidget {
  const _LoanFields({
    required this.form,
    required this.balanceController,
    required this.counterpartyController,
    required this.onBalance,
    required this.onCounterparty,
    required this.onPickStart,
    required this.onPickDue,
  });

  final AccountFormState form;
  final TextEditingController balanceController;
  final TextEditingController counterpartyController;
  final ValueChanged<String> onBalance;
  final ValueChanged<String> onCounterparty;
  final VoidCallback onPickStart;
  final VoidCallback onPickDue;

  @override
  Widget build(BuildContext context) {
    final isLend = form.subType == AccountSubType.lendOut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('account-edit-balance'),
          controller: balanceController,
          decoration: InputDecoration(
            labelText: isLend ? '借出金额(元)' : '借入金额(元)',
            hintText: '本金',
            border: const OutlineInputBorder(),
            prefixText: '¥ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: onBalance,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('account-edit-counterparty'),
          controller: counterpartyController,
          decoration: InputDecoration(
            labelText: isLend ? '借款人(借给谁)' : '出借人(从谁借)',
            hintText: '姓名',
            border: const OutlineInputBorder(),
          ),
          onChanged: onCounterparty,
          maxLength: 20,
        ),
        _DateTile(
          keyName: 'account-edit-start-date',
          label: isLend ? '借出日期' : '借入日期',
          date: form.startDate,
          onTap: onPickStart,
        ),
        const SizedBox(height: 8),
        _DateTile(
          keyName: 'account-edit-due-date',
          label: '约定还款日期',
          date: form.dueDate,
          onTap: onPickDue,
        ),
      ],
    );
  }
}

/// 日期选择行。
class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.keyName,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? '未设置'
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
    return OutlinedButton(
      key: Key(keyName),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(text)],
      ),
    );
  }
}

/// 通用 toggle。
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: Key(keyName),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
