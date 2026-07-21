import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';

/// 借出独立全屏页面(ADR-0026 §12 — 咔皮对标,2026-08-04 D22)。
///
/// 设计来源:v4 §3.1 + 咔皮截图 261/263/264。
/// 关键区别:与「添加账户 → 借贷大类」不同,本页面是 **记账流程** —— 借出一笔钱,
/// 自动联动资金方账户(扣款)和「借出」子类型账户(应收债权)。
/// 字段:起始余额(顶部黄框)/ 起始时间必填/ 账户名称/ 备注/ 借款人姓名/
/// 借出日期/ 收款日期/ **扣款账户**/ 3 toggle(计入净资产/特别关注/默认收账)。
class LendRecordPage extends ConsumerStatefulWidget {
  const LendRecordPage({super.key});

  @override
  ConsumerState<LendRecordPage> createState() => _LendRecordPageState();
}

class _LendRecordPageState extends ConsumerState<LendRecordPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _counterpartyController = TextEditingController();
  final _amountController = TextEditingController(text: '0.00');
  // D25 ADR-0029:借贷账户「起始余额」独立输入(账户级,与 transaction 金额分离)。
  final _initialBalanceController = TextEditingController(text: '0.00');

  int? _selectedFundAccountId;
  int? _lendAccountId; // 选中的「借出」子类型账户
  DateTime? _startDate;
  DateTime? _lendDate;
  DateTime? _dueDate;

  bool _includeInNetWorth = true;
  bool _isPinned = false;
  bool _isDefaultIncome = false;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _counterpartyController.dispose();
    _amountController.dispose();
    _initialBalanceController.dispose();
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

  /// 资金账户候选(扣款用):排除借贷类。
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

  /// 「借出」子类型账户候选。
  Future<List<AccountEntry>> _loadLendAccounts(AppDatabase db) async {
    final all = await db.accountDao.getAll();
    return all.where((a) => a.subType == AccountSubType.lendOut).toList();
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
      _toast('请选择扣款账户');
      return;
    }
    if (_lendAccountId == null) {
      _toast('请选择借出账户');
      return;
    }
    final amountCents = _parseCents(_amountController.text);
    if (amountCents <= 0) {
      _toast('请输入借出金额(> 0)');
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      // 1) 如果用户没选已有借出账户,先创建一个
      var lendAccId = _lendAccountId!;
      if (_lendAccountId == 0) {
        final initialBalanceCents = _parseCents(_initialBalanceController.text);
        lendAccId = await db.accountDao.insertAccount(
          AccountsCompanion.insert(
            name: name,
            type: const Value(AccountType.onlineLoan),
            subType: const Value(AccountSubType.lendOut),
            balanceCents: const Value(0),
            startDate: Value(_startDate),
            dueDate: Value(_dueDate),
            counterpartyName: Value(_counterpartyController.text.trim()),
            includeInNetWorth: Value(_includeInNetWorth),
            isPinned: Value(_isPinned),
            isDefaultIncomeAccount: Value(_isDefaultIncome),
            // D25 ADR-0029:借贷账户起始余额/起始时间(语义「该时间之前的记录不计入余额统计」)
            initialLendBalanceCents: Value(
                initialBalanceCents > 0 ? initialBalanceCents : null),
            initialTime: Value(_startDate),
          ),
        );
      }
      // 2) 写 lend transaction(双账户联动)
      final initialBalanceCents = _parseCents(_initialBalanceController.text);
      await db.transactionDao.lendMoney(
        fromAccountId: _selectedFundAccountId!,
        toAccountId: lendAccId,
        amountCents: amountCents,
        counterparty: _counterpartyController.text.trim(),
        note: _noteController.text.trim(),
        startDate: _startDate,
        // D25 ADR-0029:借贷 transaction 起始/结束日期 + 起始余额/起始时间
        lendStartDate: _lendDate,
        lendEndDate: _dueDate,
        initialLendBalanceCents:
            initialBalanceCents > 0 ? initialBalanceCents : null,
        initialTime: _startDate,
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
      appBar: AppBar(title: const Text('借出')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 起始余额(顶部黄框 + 可编辑 TextField,D25 ADR-0029)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('起始余额(元)', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '该时间之前的记录不计入余额统计',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('lend-initial-balance'),
                  controller: _initialBalanceController,
                  decoration: const InputDecoration(
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 借出金额(可编辑)
          TextField(
            key: const Key('lend-amount'),
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '借出金额(元)',
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
          // 起始时间(必填)+ 提示
          _DateTile(
            keyName: 'lend-start-date',
            label: '起始时间',
            required: true,
            hint: '该时间之前的记录不计入余额统计',
            date: _startDate,
            onTap: () => _pickDate(context, _startDate, (d) {
              setState(() => _startDate = d);
            }),
          ),
          const SizedBox(height: 12),
          // 账户名称
          TextField(
            key: const Key('lend-account-name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '账户名称',
              hintText: '请输入账户名称',
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
          ),
          // 备注
          TextField(
            key: const Key('lend-note'),
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '请输入备注',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          // 借款人姓名
          TextField(
            key: const Key('lend-counterparty'),
            controller: _counterpartyController,
            decoration: const InputDecoration(
              labelText: '借款人姓名',
              hintText: '请输入借款人姓名',
              border: OutlineInputBorder(),
            ),
            maxLength: 20,
          ),
          // 借出日期
          _DateTile(
            keyName: 'lend-date',
            label: '借出日期',
            date: _lendDate,
            onTap: () => _pickDate(context, _lendDate, (d) {
              setState(() => _lendDate = d);
            }),
          ),
          // 收款日期
          _DateTile(
            keyName: 'lend-due-date',
            label: '收款日期',
            date: _dueDate,
            onTap: () => _pickDate(context, _dueDate, (d) {
              setState(() => _dueDate = d);
            }),
          ),
          const SizedBox(height: 12),
          // 扣款账户
          FutureBuilder<List<AccountEntry>>(
            future: _loadFundAccounts(db),
            builder: (context, snap) {
              final accounts = snap.data ?? const [];
              return _AccountPickerTile(
                keyName: 'lend-fund-account',
                label: '扣款账户',
                accounts: accounts,
                selectedId: _selectedFundAccountId,
                onChanged: (id) =>
                    setState(() => _selectedFundAccountId = id),
              );
            },
          ),
          const SizedBox(height: 12),
          // 借出账户(可从已有借出账户选,或填名新建)
          FutureBuilder<List<AccountEntry>>(
            future: _loadLendAccounts(db),
            builder: (context, snap) {
              final accounts = snap.data ?? const [];
              return _AccountPickerTile(
                keyName: 'lend-account',
                label: '借出账户',
                accounts: accounts,
                selectedId: _lendAccountId,
                onChanged: (id) => setState(() => _lendAccountId = id),
                allowCreate: true,
              );
            },
          ),
          const SizedBox(height: 16),
          // 3 toggle
          _ToggleRow(
            keyName: 'lend-networth',
            title: '计入净资产',
            subtitle: '该账户是否计入总资产',
            value: _includeInNetWorth,
            onChanged: (v) => setState(() => _includeInNetWorth = v),
          ),
          _ToggleRow(
            keyName: 'lend-pinned',
            title: '设为特别关注账户',
            subtitle: '特别关注的账户可在资产账户顶部查看',
            value: _isPinned,
            onChanged: (v) => setState(() => _isPinned = v),
          ),
          _ToggleRow(
            keyName: 'lend-default-income',
            title: '设为默认收账账户',
            subtitle: '若收账记录没有指定账户,会默认关联到默认账户',
            value: _isDefaultIncome,
            onChanged: (v) => setState(() => _isDefaultIncome = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('lend-save'),
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

/// 日期选择行。
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
            Text(text, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

/// 账户选择行(简易版 + 可新建)。
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
                        title: Text('${a.subType?.emoji ?? a.type.emoji} ${a.name}'),
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
                    .map((a) => '${a.subType?.emoji ?? a.type.emoji} ${a.name}')
                    .firstOrNull ?? '已选账户',
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

/// toggle 行。
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