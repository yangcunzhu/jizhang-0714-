import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../home/application/home_providers.dart';
import '../../../home/presentation/widgets/transaction_tile.dart';

/// 记账弹层的账户选择（Step 3）+ 备注输入 + "添加账户"占位。
///
/// Stage 1 简化为单一"现金"账户（占位 UI,不可切换）。
/// "添加账户"按钮点了弹出 SnackBar 提示"Stage 2 实装",为 S02 多账户管理占位。
/// Stage 2 扩展为多账户 + 6 种账户类型时下拉/弹层选择。
class AccountPicker extends ConsumerStatefulWidget {
  const AccountPicker({
    super.key,
    required this.initialNote,
    required this.onNoteChanged,
  });

  /// 备注初始值（弹层打开时一次性传入,后续不随外部更新）。
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
    final accountAsync = ref.watch(defaultAccountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(label: '账户'),
          accountAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('账户加载失败:$e'),
            ),
            data: (account) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AccountCard(account: account),
                const SizedBox(height: 8),
                _AddAccountButton(onTap: () => _showAddAccountHint(context)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: '备注(可选)'),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: '比如:午饭、咖啡、地铁',
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

  /// 点"添加账户"提示 SnackBar。
  ///
  /// WHY: Stage 2 真正实装多账户管理;Stage 1 先给用户入口占位以验证布局完整性。
  void _showAddAccountHint(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('多账户管理将在 Stage 2 实装'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

/// 单个账户卡片:emoji 头像 + 名称 + 余额 + 下拉箭头(Stage 1 不可点)。
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountEntry? account;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final balanceText = account == null
        ? '¥0.00'
        : '¥${TransactionTile.formatYuan(account!.balanceCents)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 18,
            child: const Text('💵', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account?.name ?? '未设置账户',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '余额 $balanceText',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          // Stage 1 占位:显示下拉箭头但不可点击
          Icon(
            Icons.unfold_more,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

/// "添加账户"占位按钮(Stage 2 真正实装多账户管理)。
class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
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
