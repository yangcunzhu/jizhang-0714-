import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../account/application/account_form_provider.dart';
import '../../../account/presentation/account_management_page.dart';
import '../../../account/presentation/widgets/account_card.dart';

/// 记账弹层的账户选择（Step 3）+ 备注输入。
///
/// Day 13 (Stage 2)：从 Stage 1 单一"现金"占位卡升级为**多账户选择器**。
/// - 列出 [accountListProvider] 全部账户（复用 [AccountCard]，6 类型 emoji + 余额）
/// - 当前选中账户高亮（主色描边 + 右下角 check）
/// - 点选任一账户 → [onAccountSelected] 切换记账目标账户
/// - 顶部"添加账户"跳转 [AccountManagementPage]（新增后返回即在列表可见）
///
/// WHY 复用 AccountCard：ADR-0018 明确 AccountCard 为"管理页 / 主页 / 记账 Step 3 共用"，
/// 避免重复渲染 6 类型头像 + 信用卡专项字段，保证三处视觉一致。
class AccountPicker extends ConsumerStatefulWidget {
  const AccountPicker({
    super.key,
    required this.selectedAccountId,
    required this.onAccountSelected,
    required this.initialNote,
    required this.onNoteChanged,
  });

  /// 当前选中账户 id（来自 recordFormProvider.accountId）。null = 未选中。
  final int? selectedAccountId;

  /// 点选某账户时回调（切换记账目标账户）。
  final ValueChanged<int> onAccountSelected;

  /// 备注初始值（弹层打开时一次性传入，后续不随外部更新）。
  final String initialNote;
  final ValueChanged<String> onNoteChanged;

  @override
  ConsumerState<AccountPicker> createState() => _AccountPickerState();
}

class _AccountPickerState extends ConsumerState<AccountPicker> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(label: '账户'),
          accountsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('账户加载失败：$e'),
            ),
            data: (accounts) => _AccountList(
              accounts: accounts,
              selectedAccountId: widget.selectedAccountId,
              onAccountSelected: widget.onAccountSelected,
              onAddAccount: () => _openAccountManagement(context),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: '备注（可选）'),
          TextField(
            key: const Key('record-note'),
            controller: _noteController,
            decoration: InputDecoration(
              hintText: '比如：午饭、咖啡、地铁',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            onChanged: widget.onNoteChanged,
            maxLength: 50,
          ),
        ],
      ),
    );
  }

  /// 跳转账户管理页（新增 / 编辑账户）。返回后 [accountListProvider] 自动刷新。
  void _openAccountManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountManagementPage()),
    );
  }
}

/// 账户列表：逐个渲染可选账户卡片 + 底部"添加账户"按钮。
class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
    required this.onAddAccount,
  });

  final List<AccountEntry> accounts;
  final int? selectedAccountId;
  final ValueChanged<int> onAccountSelected;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '还没有账户，先添加一个吧',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final acc in accounts) ...[
            _SelectableAccountTile(
              account: acc,
              selected: acc.id == selectedAccountId,
              onTap: () => onAccountSelected(acc.id),
            ),
            const SizedBox(height: 8),
          ],
        _AddAccountButton(onTap: onAddAccount),
      ],
    );
  }
}

/// 可选中账户卡片：复用 [AccountCard]，选中时主色描边 + 右下角 check。
class _SelectableAccountTile extends StatelessWidget {
  const _SelectableAccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final AccountEntry account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          key: Key('account-option-${account.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: AccountCard(account: account, onTap: onTap),
        ),
        if (selected)
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(
              Icons.check_circle,
              key: Key('account-selected-${account.id}'),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
      ],
    );
  }
}

/// "添加账户"按钮 → 跳转账户管理页。
class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('btn-add-account'),
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('添加账户'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
