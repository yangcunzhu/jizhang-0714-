import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';

/// 借入独立全屏页面(ADR-0026 §12 — 咔皮对标)。
///
/// 区别于借出(从资金方扣钱 → 借出人):
/// 借入 = 「我欠了一笔钱 → 钱到我某个资金账户」,所以字段名是 **入款账户**。
/// 借款人 → 出借人(从谁借)。
class BorrowRecordPage extends ConsumerStatefulWidget {
  const BorrowRecordPage({super.key});

  @override
  ConsumerState<BorrowRecordPage> createState() => _BorrowRecordPageState();
}

class _BorrowRecordPageState extends ConsumerState<BorrowRecordPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _counterpartyController = TextEditingController();
  final _amountController = TextEditingController(text: '0.00');

  int? _selectedFundAccountId;
  int? _borrowAccountId;
  DateTime? _startDate;
  DateTime? _borrowDate;
  DateTime? _dueDate;

  bool _includeInNetWorth = true;
  bool _isPinned = false;
  bool _isDefaultExpense = false;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _counterpartyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int _parseCents(String v) {
    final t = v.trim();
    if (t.isEmpty) return 0;
    final yuan = double.tryParse(t);
    return yuan == null ? 0 : (yuan * 100).round();
  }

  Future<void> _pickDate(BuildContext context,
      DateTime? current, ValueChanged<DateTime> onPicked) async {
    final now = current ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) onPicked(picked);
  }

  Future<List<AccountEntry>> _loadFundAccounts(AppDatabase db) async {
    final all = await db.accountDao.getAll();
    return all.where((a) {
      final cat = a.subType?.category ??
          switch (a.type) {
            AccountType.cash || AccountType.savings => AccountCategory.fund,
            AccountType.investment => AccountCategory.investment,
            _ => AccountCategory.credit,
          };
      return cat != AccountCategory.loan;
    }).toList();
  }

  Future<List<AccountEntry>> _loadBorrowAccounts(AppDatabase db) async {
    final all = await db.accountDao.getAll();
    return all.where((a) => a.subType == AccountSubType.borrowIn).toList();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('请输入账户名称');
      return;
    }
    if (_startDate == null) {
      _toast('请选择起始时间');
      return;
    }
    if (_selectedFundAccountId == null) {
      _toast('请选择入款账户');
      return;
    }
    if (_borrowAccountId == null) {
      _toast('请选择借入账户');
      return;
    }
    final amountCents = _parseCents(_amountController.text);
    if (amountCents <= 0) {
      _toast('请输入借入金额(> 0)');
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      var borrowAccId = _borrowAccountId!;
      if (_borrowAccountId == 0) {
        borrowAccId = await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: name,
            type: const Value(AccountType.onlineLoan),
            subType: const Value(AccountSubType.borrowIn),
            balanceCents: const Value(0),
            startDate: Value(_startDate),
            dueDate: Value(_dueDate),
            counterpartyName: Value(_counterpartyController.text.trim()),
            includeInNetWorth: Value(_includeInNetWorth),
            isPinned: Value(_isPinned),
            isDefaultExpenseAccount: Value(_isDefaultExpense),
          ),
        );
      }
      await db.transactionDao.borrowMoney(
        fromAccountId: borrowAccId,
        toAccountId: _selectedFundAccountId!,
        amountCents: amountCents,
        counterparty: _counterpartyController.text.trim(),
        note: _noteController.text.trim(),
        startDate: _startDate,
      );
      ref.invalidate(accountListProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _toast('保存失败:$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('借入')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('起始欠款', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text('¥ ${_amountController.text}',
                    key: const Key('borrow-amount-display'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('borrow-amount'),
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '借入金额(元)',
              border: OutlineInputBorder(),
              prefixText: '¥ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _DateTile(
            keyName: 'borrow-start-date',
            label: '起始时间',
            required: true,
            hint: '该时间之前的记录不计入余额统计',
            date: _startDate,
            onTap: () => _pickDate(context, _startDate, (d) {
              setState(() => _startDate = d);
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('borrow-account-name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '账户名称',
              hintText: '请输入账户名称',
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
          ),
          TextField(
            key: const Key('borrow-note'),
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '请输入备注',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('borrow-counterparty'),
            controller: _counterpartyController,
            decoration: const InputDecoration(
              labelText: '出借人姓名',
              hintText: '请输入出借人姓名',
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
          ),
          _DateTile(
            keyName: 'borrow-date',
            label: '借入日期',
            date: _borrowDate,
            onTap: () => _pickDate(context, _borrowDate, (d) {
              setState(() => _borrowDate = d);
            }),
          ),
          _DateTile(
            keyName: 'borrow-due-date',
            label: '还款日期',
            date: _dueDate,
            onTap: () => _pickDate(context, _dueDate, (d) {
              setState(() => _dueDate = d);
            }),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AccountEntry>>(
            future: _loadFundAccounts(db),
            builder: (context, snap) => _AccountPickerTile(
              keyName: 'borrow-fund-account',
              label: '入款账户',
              accounts: snap.data ?? const [],
              selectedId: _selectedFundAccountId,
              onChanged: (id) => setState(() => _selectedFundAccountId = id),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AccountEntry>>(
            future: _loadBorrowAccounts(db),
            builder: (context, snap) => _AccountPickerTile(
              keyName: 'borrow-account',
              label: '借入账户',
              accounts: snap.data ?? const [],
              selectedId: _borrowAccountId,
              onChanged: (id) => setState(() => _borrowAccountId = id),
              allowCreate: true,
            ),
          ),
          const SizedBox(height: 16),
          _ToggleRow(
            keyName: 'borrow-networth',
            title: '计入净资产',
            subtitle: '负债账户计入负债侧',
            value: _includeInNetWorth,
            onChanged: (v) => setState(() => _includeInNetWorth = v),
          ),
          _ToggleRow(
            keyName: 'borrow-pinned',
            title: '设为特别关注账户',
            subtitle: '特别关注的账户可在资产账户顶部查看',
            value: _isPinned,
            onChanged: (v) => setState(() => _isPinned = v),
          ),
          _ToggleRow(
            keyName: 'borrow-default-expense',
            title: '设为默认支出账户',
            subtitle: '若支出记录没有指定账户,会默认关联到默认账户',
            value: _isDefaultExpense,
            onChanged: (v) => setState(() => _isDefaultExpense = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('borrow-save'),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.keyName,
    required this.label,
    required this.date,
    required this.onTap,
    this.required = false,
    this.hint,
  });

  final String keyName;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? (hint ?? '未设置')
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('(必填)', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const Spacer(),
            Text(text,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class _AccountPickerTile extends StatelessWidget {
  const _AccountPickerTile({
    required this.keyName,
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
    this.allowCreate = false,
  });

  final String keyName;
  final String label;
  final List<AccountEntry> accounts;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool allowCreate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(keyName),
      onTap: () async {
        final result = await showModalBottomSheet<int?>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...accounts.map((a) => ListTile(
                        title: Text(
                            '${a.subType?.emoji ?? a.type.emoji} ${a.name}'),
                        trailing: selectedId == a.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () => Navigator.pop(ctx, a.id),
                      )),
                  if (allowCreate)
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.blue),
                      title: const Text('新建账户(填名自动创建)',
                          style: TextStyle(color: Colors.blue)),
                      onTap: () => Navigator.pop(ctx, 0),
                    ),
                ],
              ),
            );
          },
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            if (selectedId == 0)
              const Text('新建账户', style: TextStyle(color: Colors.blue))
            else if (selectedId == null)
              Text('请选择',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline))
            else
              Text(
                accounts
                    .where((a) => a.id == selectedId)
                    .map((a) =>
                        '${a.subType?.emoji ?? a.type.emoji} ${a.name}')
                    .firstOrNull ??
                    '已选账户',
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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