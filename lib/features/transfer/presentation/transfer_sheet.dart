import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../application/transfer_form_provider.dart';

/// 显示转账弹层。返回 true 表示转账成功。
Future<bool> showTransferSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const TransferSheet(),
  );
  return result ?? false;
}

/// 转账弹层(ADR-0026 §5)—— 扣款账户 → 入款账户,金额 + 备注。
class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key});

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseCents(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final yuan = double.tryParse(t);
    return yuan == null ? null : (yuan * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(transferFormProvider);
    final c = ref.read(transferFormProvider.notifier);
    final accountsAsync = ref.watch(transferableAccountListProvider);
    final theme = Theme.of(context);

    return Padding(
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
              Text('转账', style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              accountsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('账户加载失败:$e'),
                data: (accounts) {
                  if (accounts.length < 2) {
                    return const Padding(
                      key: Key('transfer-not-enough-accounts'),
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('转账至少需要 2 个资金账户',
                          textAlign: TextAlign.center),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AccountDropdown(
                        keyName: 'transfer-from-account',
                        label: '扣款账户',
                        accounts: accounts,
                        selectedId: form.fromAccountId,
                        onChanged: c.setFromAccount,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Icon(Icons.arrow_downward,
                            color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 12),
                      _AccountDropdown(
                        keyName: 'transfer-to-account',
                        label: '入款账户',
                        accounts: accounts,
                        selectedId: form.toAccountId,
                        onChanged: c.setToAccount,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('transfer-amount'),
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: '转账金额',
                          hintText: '比如:1000',
                          border: OutlineInputBorder(),
                          prefixText: '¥ ',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (v) => c.setAmount(_parseCents(v) ?? 0),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('transfer-note'),
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: '备注(可选)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: c.setNote,
                        maxLength: 30,
                      ),
                    ],
                  );
                },
              ),
              if (form.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  form.errorMessage!,
                  key: const Key('transfer-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('transfer-cancel'),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('transfer-save'),
                      onPressed: form.canSubmit
                          ? () async {
                              final ok = await c.submit();
                              if (!context.mounted) return;
                              if (ok) Navigator.pop(context, true);
                            }
                          : null,
                      child: const Text('确认转账'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账户下拉选择。
class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.keyName,
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final List<AccountEntry> accounts;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: Key(keyName),
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts.map((a) {
        final emoji = a.subType?.emoji ?? a.type.emoji;
        return DropdownMenuItem<int>(
          value: a.id,
          child: Text('$emoji ${a.name}（¥${_yuan(a.balanceCents)}）'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _yuan(int cents) =>
      '${cents ~/ 100}.${(cents.abs() % 100).toString().padLeft(2, '0')}';
}
