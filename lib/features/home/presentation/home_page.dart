import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/account_form_provider.dart';
import '../../account/presentation/account_management_page.dart';
import '../../record/presentation/record_sheet.dart';
import '../application/home_providers.dart';
import 'home_page_keys.dart';
import 'widgets/confetti_burst.dart';
import 'widgets/transaction_actions_sheet.dart';
import 'widgets/transaction_tile.dart';

/// 主页骨架（Stage 1 Day 5 + Stage 2 Day 12）。
///
/// - 顶部 AppBar：标题"审计官"
/// - 净资产占位卡（Stage 5 实现完整计算;Day 12 加"账户数 X"快捷入口）
/// - 交易列表：`ref.watch(transactionListProvider)` 实时渲染
/// - 底部"记一笔"按钮：Stage 1 实装记账卡弹层
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('审计官'),
        centerTitle: true,
      ),
      body: const Column(
        children: [
          _NetWorthCard(),
          Expanded(child: _TransactionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: recordFabKey,
        onPressed: () async {
          // Day 9:弹层关闭且返回 true(成功保存)→ 从 FAB 位置发射攒攒动画
          final saved = await showRecordSheet(context);
          if (saved && context.mounted) {
            ConfettiBurst.fire(context, originKey: recordFabKey);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }
}

class _NetWorthCard extends ConsumerWidget {
  const _NetWorthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);
    final count = accountsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Card(
      key: const Key('net-worth-card'),
      margin: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountManagementPage(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '净资产',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '暂未计算',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Stage 5 完善',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '账户数 $count',
                    key: const Key('net-worth-account-count'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
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

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);

    if (txAsync.isLoading || catAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (txAsync.hasError) {
      return Center(child: Text('交易加载失败：${txAsync.error}'));
    }

    if (catAsync.hasError) {
      return Center(child: Text('分类加载失败：${catAsync.error}'));
    }

    final transactions = txAsync.value ?? const [];
    final categories = {
      for (final c in catAsync.value ?? const []) c.id: c,
    };

    if (transactions.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionTile(
          transaction: tx,
          category: categories[tx.categoryId],
          onLongPress: () => TransactionActionsSheet.show(context, tx),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('home-empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '还没有记账',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角"记一笔"开始',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}