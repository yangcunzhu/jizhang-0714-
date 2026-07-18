import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../build_info.dart';
import '../../../data/db/database_provider.dart';
import '../../account/application/account_form_provider.dart';
import '../../account/presentation/account_management_page.dart';
import '../../category/presentation/category_template_page.dart';
import '../../record/presentation/record_sheet.dart';
import '../../repayment/application/repayment_form_provider.dart';
import '../../repayment/presentation/repayment_sheet.dart';
import '../application/home_providers.dart';
import 'home_page_keys.dart';
import 'widgets/confetti_burst.dart';
import 'widgets/transaction_actions_sheet.dart';
import 'widgets/transaction_tile.dart';

/// 主页骨架（Stage 1 Day 5 + Stage 2 Day 12 + Day 15）。
///
/// - 顶部 AppBar：标题"审计官" + 右侧"分类模板"按钮(Day 15)
/// - 净资产占位卡（Stage 5 实现完整计算;Day 12 加"账户数 X"快捷入口）
/// - 交易列表：`ref.watch(transactionListProvider)` 实时渲染
/// - 底部"记一笔"按钮：Stage 1 实装记账卡弹层
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// 显示「+」聚合菜单(D20):记账 / 还款。
  ///
  /// 还款入口仅当存在 ≥1 信用卡账户时显示,避免还款弹层打开后没卡可选。
  /// WHY 异步:futureProvider 需要 watch,我们在菜单打开时 watch 一次,根据
  /// 结果决定显示哪几项。
  Future<void> _showPlusMenu(BuildContext context, WidgetRef ref) async {
    final hasCreditCard = await ref
        .read(creditCardAccountListProvider.future)
        .then((list) => list.isNotEmpty);

    if (!context.mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('plus-menu-record'),
              leading: const Text('➕', style: TextStyle(fontSize: 24)),
              title: const Text('记一笔'),
              subtitle: const Text('选分类 / 输金额 / 选账户'),
              onTap: () => Navigator.pop(ctx, 'record'),
            ),
            if (hasCreditCard)
              ListTile(
                key: const Key('plus-menu-repayment'),
                leading: const Text('💳', style: TextStyle(fontSize: 24)),
                title: const Text('还款'),
                subtitle: const Text('储蓄 → 信用卡 还款'),
                onTap: () => Navigator.pop(ctx, 'repayment'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (action == 'record') {
      final saved = await showRecordSheet(context);
      if (saved && context.mounted) {
        ConfettiBurst.fire(context, originKey: recordFabKey);
      }
    } else if (action == 'repayment') {
      await showRepaymentSheet(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('审计官'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('home-template-button'),
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: '分类模板',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryTemplatePage(),
              ),
            ),
          ),
        ],
      ),
      body: const Column(
        children: [
          _NetWorthCard(),
          Expanded(child: _TransactionList()),
          _BuildVersionFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: recordFabKey,
        // D20:主页「+」聚合菜单(记账 / 还款)。还款入口仅当有信用卡账户时显示,
        // 避免还款弹层打开后没卡可选。
        onPressed: () => _showPlusMenu(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('记一笔 / 还款'),
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

/// 主页底部 build 版本号 + commit SHA 显示(ADR-0023)。
///
/// 显示样式:`v0.1.0 · b3b722e · schema v4`
/// 灰色小字,不抢主界面视觉。
/// 用户装机后一眼对比 GitHub commit 列表,立刻知道是不是新版本。
///
/// 右侧 🐛 按钮:D19 期间调试入口,显示数据库真实状态(账户余额 + 最近交易),
/// 装机后无需 Xcode console 即可定位 updateAccountBalance / insertTransaction
/// 是否真的执行,排查 D19 余额 bug。
class _BuildVersionFooter extends ConsumerWidget {
  const _BuildVersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                BuildInfo.displayVersion,
                key: const Key('home-build-version'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
            ),
            IconButton(
              key: const Key('home-debug-button'),
              icon: const Icon(Icons.bug_report_outlined, size: 18),
              tooltip: '数据库实时状态(调试)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _showDebugDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示数据库实时状态对话框(D19 调试用)。
  ///
  /// 内容:
  /// - 所有账户(id + name + type + balanceCents)
  /// - 最近 5 笔 transaction(id + categoryId + type + amountCents + note + occurredAt)
  Future<void> _showDebugDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final accounts = await db.accountDao.getAll();
    final transactions = await db.transactionDao.getAll();
    final recent = transactions.take(5).toList();

    if (!context.mounted) return;

    final content = StringBuffer();
    content.writeln('=== 数据库实时状态 ===\n');
    content.writeln('【账户】(共 ${accounts.length} 条)');
    if (accounts.isEmpty) {
      content.writeln('  (空)');
    } else {
      for (final a in accounts) {
        content.writeln(
          '  • #${a.id} ${a.type.emoji} ${a.name} | type=${a.type.name} | balance=${a.balanceCents} 分 (¥${_formatYuan(a.balanceCents)})',
        );
      }
    }
    content.writeln('\n【最近 ${recent.length} 笔交易】(共 ${transactions.length} 条)');
    if (recent.isEmpty) {
      content.writeln('  (空)');
    } else {
      for (final t in recent) {
        content.writeln(
          '  • #${t.id} ${t.type.name} ¥${_formatYuan(t.amountCents)} acct=${t.accountId} cat=${t.categoryId} note="${t.note}" ${t.occurredAt.toIso8601String()}',
        );
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('数据库状态(调试)'),
        content: SingleChildScrollView(
          child: SelectableText(
            content.toString(),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final fen = cents.abs() % 100;
    return '$yuan.${fen.toString().padLeft(2, '0')}';
  }
}