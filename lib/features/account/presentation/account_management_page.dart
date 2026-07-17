import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../application/account_form_provider.dart';
import 'widgets/account_card.dart';
import 'widgets/account_edit_sheet.dart';

/// 账户管理页(Day 12 — 主页入口跳转)。
///
/// 决策:ADR-0018 — ListView 单列 + emoji 透明背景卡片。
class AccountManagementPage extends ConsumerWidget {
  const AccountManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账户管理'),
        centerTitle: true,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('账户加载失败:$e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _EmptyState(
              onAdd: () => _addAccount(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return AccountCard(
                key: Key('account-list-card-${acc.id}'),
                account: acc,
                onTap: () => _editAccount(context, acc),
                onLongPress: () => _showActions(context, ref, acc),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-account-fab'),
        onPressed: () => _addAccount(context),
        icon: const Icon(Icons.add),
        label: const Text('添加账户'),
      ),
    );
  }

  Future<void> _addAccount(BuildContext context) async {
    await AccountEditSheet.show(context, existingId: null);
  }

  Future<void> _editAccount(BuildContext context, AccountEntry acc) async {
    await AccountEditSheet.show(context, existingId: acc.id);
  }

  Future<void> _showActions(
      BuildContext context, WidgetRef ref, AccountEntry acc) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Material(
          color: Theme.of(ctx).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  '删除',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _editAccount(context, acc);
    } else if (action == 'delete') {
      await _confirmDelete(context, ref, acc);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AccountEntry acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确认删除账户「${acc.name}」?此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(databaseProvider).accountDao.deleteAccount(acc.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('删除失败:该账户可能有交易引用'),
          duration: const Duration(seconds: 3),
        ));
    }
  }
}

/// 账户列表为空时的空态。
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💵', style: TextStyle(fontSize: 64, color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          Text('还没有账户', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('点击右下角添加你的第一个账户', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加账户'),
          ),
        ],
      ),
    );
  }
}