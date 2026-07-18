import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/tables/accounts.dart';
import '../../application/account_form_provider.dart';

/// 账户编辑弹层(Day 12 — 主页 + 管理页共用)。
///
/// 决策:ADR-0018 — 底部弹层,6 类型切换,信用卡才出 creditLimit/billingDay/dueDay。
///
/// 用法:
/// ```dart
/// final saved = await AccountEditSheet.show(context, existingId: null);
/// if (saved) { ... }
/// ```
class AccountEditSheet extends ConsumerStatefulWidget {
  const AccountEditSheet({super.key, this.existingId});

  /// null = 新建;非 null = 编辑该 ID 的账户。
  final int? existingId;

  /// 显示弹层。返回 true 表示保存成功,false = 用户取消或保存失败。
  static Future<bool> show(BuildContext context, {int? existingId}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountEditSheet(existingId: existingId),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends ConsumerState<AccountEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _billingDayController;
  late final TextEditingController _dueDayController;

  /// 控制弹层关闭时是否真正 dismiss(校验失败时阻止)
  bool _canDismiss = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(accountFormProvider(widget.existingId));
    _nameController = TextEditingController(text: state.name);
    // D19 余额管理:初始余额输入框,从 state.balanceCents 转 ¥xxx.xx
    _balanceController = TextEditingController(
      text: state.balanceCents != null
          ? (state.balanceCents! / 100).toStringAsFixed(2)
          : '0.00',
    );
    _creditLimitController = TextEditingController(
      text: state.creditLimitCents != null
          ? (state.creditLimitCents! / 100).toStringAsFixed(2)
          : '',
    );
    _billingDayController = TextEditingController(
      text: state.billingDay?.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: state.dueDay?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _billingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(accountFormProvider(widget.existingId));
    final controller = ref.read(accountFormProvider(widget.existingId).notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: _canDismiss,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 拖动指示
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
                // 类型选择(6 个 emoji 按钮)
                _TypeSelector(
                  current: form.type,
                  onSelected: controller.changeType,
                ),
                const SizedBox(height: 16),
                // 名称
                TextField(
                  key: const Key('account-edit-name'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '账户名称',
                    hintText: '比如:招行信用卡 / 生活费',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.changeName,
                  maxLength: 20,
                ),
                const SizedBox(height: 8),
                // D19 余额管理:初始余额输入框(所有类型都显示)
                TextField(
                  key: const Key('account-edit-balance'),
                  controller: _balanceController,
                  decoration: InputDecoration(
                    labelText: widget.existingId == null ? '初始余额' : '当前余额',
                    hintText: '比如:5000',
                    border: const OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) {
                    final trimmed = v.trim();
                    if (trimmed.isEmpty) {
                      controller.changeBalanceCents(null);
                    } else {
                      final yuan = double.tryParse(trimmed);
                      controller.changeBalanceCents(
                        yuan == null ? null : (yuan * 100).round(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                // 信用卡字段(动态显隐)
                if (form.isCreditCard) ...[
                  _CreditCardFields(
                    limitController: _creditLimitController,
                    billingDayController: _billingDayController,
                    dueDayController: _dueDayController,
                    onLimitChanged: (v) => controller.changeCreditLimitCents(v),
                    onBillingChanged: (v) => controller.changeBillingDay(v),
                    onDueChanged: (v) => controller.changeDueDay(v),
                  ),
                  const SizedBox(height: 8),
                ],
                // 计入净资产
                SwitchListTile(
                  key: const Key('account-edit-include-networth'),
                  title: const Text('计入净资产'),
                  subtitle: Text(
                    form.type == AccountType.investment
                        ? '理财类账户通常不计入'
                        : '现金/储蓄账户通常计入',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: form.includeInNetWorth,
                  onChanged: controller.changeIncludeInNetWorth,
                  contentPadding: EdgeInsets.zero,
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
                          final ok = await controller.submit();
                          if (!mounted) return;
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() => _canDismiss = true);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(
                                content: Text('保存失败:请检查字段是否合法'),
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
}

/// 6 种账户类型的选择器(emoji + 中文标签)。
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.current, required this.onSelected});

  final AccountType current;
  final ValueChanged<AccountType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AccountType.values.map((type) {
        final selected = type == current;
        return ChoiceChip(
          key: Key('account-type-${type.name}'),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(type.displayName),
            ],
          ),
          selected: selected,
          onSelected: (_) => onSelected(type),
        );
      }).toList(),
    );
  }
}

/// 信用卡专项字段(额度 + 账单日 + 还款日)。
class _CreditCardFields extends StatelessWidget {
  const _CreditCardFields({
    required this.limitController,
    required this.billingDayController,
    required this.dueDayController,
    required this.onLimitChanged,
    required this.onBillingChanged,
    required this.onDueChanged,
  });

  final TextEditingController limitController;
  final TextEditingController billingDayController;
  final TextEditingController dueDayController;
  final ValueChanged<int?> onLimitChanged;
  final ValueChanged<int?> onBillingChanged;
  final ValueChanged<int?> onDueChanged;

  @override
  Widget build(BuildContext context) {
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (v) {
            final trimmed = v.trim();
            if (trimmed.isEmpty) {
              onLimitChanged(null);
            } else {
              final yuan = double.tryParse(trimmed);
              onLimitChanged(yuan == null ? null : (yuan * 100).round());
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('account-edit-billing-day'),
                controller: billingDayController,
                decoration: const InputDecoration(
                  labelText: '账单日',
                  hintText: '1-31',
                  border: OutlineInputBorder(),
                  suffixText: '号',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  onBillingChanged(n);
                },
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
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  onDueChanged(n);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}