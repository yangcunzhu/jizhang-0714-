import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/home_providers.dart';
import 'widgets/transaction_tile.dart';

/// 主页骨架（Stage 1 Day 5）。
///
/// - 顶部 AppBar：标题"审计官"
/// - 净资产占位卡（Stage 5 实现完整计算）
/// - 交易列表：`ref.watch(transactionListProvider)` 实时渲染
/// - 底部"记一笔"按钮：占位（Day 6 实装记账卡弹层）
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('记账卡（Day 6 实装）'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
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
            Text(
              'Stage 5 完善',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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