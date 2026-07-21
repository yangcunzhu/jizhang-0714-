// RefundSheet — D26 新建(ADR-0030 §决策 5 + 咔皮图 4 复刻)
//
// 半屏弹层,4 字段:
//   1. 退款金额(可改,默认 = 原金额,validator 1..original,2026-08-09 Q3=B 拍板)
//   2. 退款账户(default 原付款账户,可改,2026-08-09 Q3=A 拍板)
//   3. 退款时间(date + time picker,默认 = now)
//   4. 备注(可选)
// 「确认」按钮 → 调 refundMoney,成功 → 返回 true 给 detail page 关闭用。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/categories.dart';

class RefundSheet extends ConsumerStatefulWidget {
  const RefundSheet({super.key, required this.originalTransaction});

  final TransactionEntry originalTransaction;

  @override
  ConsumerState<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends ConsumerState<RefundSheet> {
  late TextEditingController _amountController;
  late DateTime _refundTime;
  late TextEditingController _noteController;
  int? _selectedAccountId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 默认金额 = 原金额(可改,Q3=B 拍板)
    _amountController = TextEditingController(
      text: _formatYuan(widget.originalTransaction.amountCents),
    );
    _refundTime = DateTime.now();
    _noteController = TextEditingController();
    _selectedAccountId = widget.originalTransaction.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<bool?> _submit() async {
    final cents = _parseAmountToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      _showError('请输入有效金额');
      return null;
    }
    if (cents > widget.originalTransaction.amountCents) {
      _showError(
        '退款金额不能超过原交易金额 ¥${_formatYuan(widget.originalTransaction.amountCents)}',
      );
      return null;
    }
    if (_selectedAccountId == null) {
      _showError('请选择退款账户');
      return null;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final db = ref.read(databaseProvider);
      await db.transactionDao.refundMoney(
        originalTransactionId: widget.originalTransaction.id,
        refundAccountId: _selectedAccountId!,
        amountCents: cents,
        refundTime: _refundTime,
        refundNote:
            _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('退款成功 ¥${_formatYuan(cents)}'),
          duration: const Duration(seconds: 1),
        ),
      );
      navigator.pop(true);
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('退款失败:$e')));
      return null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  /// "8.96" → 896 cents
  static int? _parseAmountToCents(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final v = double.tryParse(trimmed);
    if (v == null || v < 0) return null;
    return (v * 100).round();
  }

  static String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final centsPart = cents.abs() % 100;
    return '${yuan.toString()}.${centsPart.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.read(databaseProvider);
    final originalAmount =
        _formatYuan(widget.originalTransaction.amountCents);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部把手
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '退款详情',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '原交易:${_typeLabel(widget.originalTransaction.type)} ¥$originalAmount',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 20),
              // 退款金额
              TextField(
                key: const Key('refund-amount-field'),
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: '退款金额',
                  helperText:
                      '可改,范围 ¥0.01 ~ ¥$originalAmount(Q3=B 拍板)',
                  border: const OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
              ),
              const SizedBox(height: 12),
              // 退款账户 picker
              FutureBuilder<List<AccountEntry>>(
                future: db.accountDao.getAll(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done ||
                      snapshot.data == null) {
                    return const LinearProgressIndicator();
                  }
                  final accounts = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    key: const Key('refund-account-picker'),
                    initialValue: _selectedAccountId != null &&
                            accounts
                                .any((a) => a.id == _selectedAccountId)
                        ? _selectedAccountId
                        : (accounts.isNotEmpty ? accounts.first.id : null),
                    items: accounts
                        .map((a) => DropdownMenuItem<int>(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedAccountId = v),
                    decoration: const InputDecoration(
                      labelText: '退款账户',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // 退款时间 picker
              ListTile(
                key: const Key('refund-time-tile'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('退款时间'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_refundTime),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _refundTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date == null) return;
                    if (!mounted) return;
                    final time = await showTimePicker(
                      // ignore: use_build_context_synchronously
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_refundTime),
                    );
                    if (time == null) return;
                    setState(() {
                      _refundTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  child: const Text('选择'),
                ),
              ),
              const SizedBox(height: 8),
              // 备注
              TextField(
                key: const Key('refund-note-field'),
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注(可选)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // 确认按钮
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('refund-submit'),
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认退款'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.expense:
        return '支出';
      case TransactionType.income:
        return '收入';
      case TransactionType.repayment:
        return '还款';
      case TransactionType.transfer:
        return '转账';
      case TransactionType.lend:
        return '借出';
      case TransactionType.borrow:
        return '借入';
      case TransactionType.refund:
        return '退款';
    }
  }
}

/// 公开 show API(给 detail page 调用)
Future<bool?> showRefundSheet(
  BuildContext context, {
  required TransactionEntry originalTransaction,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => RefundSheet(originalTransaction: originalTransaction),
  );
}
