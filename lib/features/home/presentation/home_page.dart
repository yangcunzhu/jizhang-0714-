import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../build_info.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/accounts.dart';
import '../../account/application/account_form_provider.dart';
import '../../account/presentation/account_management_page.dart';
import '../../borrow/presentation/borrow_record_page.dart';
import '../../category/presentation/category_template_page.dart';
import '../../lend/presentation/lend_record_page.dart';
import '../../record/presentation/record_sheet.dart';
import '../../repayment/application/repayment_form_provider.dart';
import '../../repayment/presentation/repayment_sheet.dart';
import '../../transfer/application/transfer_form_provider.dart';
import '../../transfer/presentation/transfer_sheet.dart';
import '../../transaction/presentation/transaction_detail_page.dart';
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

  /// 显示「+」聚合菜单(ADR-0026):记账 / 转账 / 还款 / 借出 / 借入。
  ///
  /// - 记账:任意时候可用
  /// - 转账:需 ≥2 个可转账资金账户(否则无从转到)
  /// - 还款:需 ≥1 欠款账户(信用卡/花呗/网贷),否则没卡可选
  /// - 借出/借入:任意时候可用,路由到账户弹层预选借贷大类
  Future<void> _showPlusMenu(BuildContext context, WidgetRef ref) async {
    final hasDebt = await ref
        .read(debtAccountListProvider.future)
        .then((list) => list.isNotEmpty);
    final canTransfer = await ref
        .read(transferableAccountListProvider.future)
        .then((list) => list.length >= 2);

    if (!context.mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
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
            if (canTransfer)
              ListTile(
                key: const Key('plus-menu-transfer'),
                leading: const Text('🔄', style: TextStyle(fontSize: 24)),
                title: const Text('转账'),
                subtitle: const Text('资金账户之间转移'),
                onTap: () => Navigator.pop(ctx, 'transfer'),
              ),
            if (hasDebt)
              ListTile(
                key: const Key('plus-menu-repayment'),
                leading: const Text('💳', style: TextStyle(fontSize: 24)),
                title: const Text('还款'),
                subtitle: const Text('储蓄 → 信用卡 还款'),
                onTap: () => Navigator.pop(ctx, 'repayment'),
              ),
            ListTile(
              key: const Key('plus-menu-lend'),
              leading: const Text('📤', style: TextStyle(fontSize: 24)),
              title: const Text('借出'),
              subtitle: const Text('借钱给别人(应收债权)'),
              onTap: () => Navigator.pop(ctx, 'lend'),
            ),
            ListTile(
              key: const Key('plus-menu-borrow'),
              leading: const Text('📥', style: TextStyle(fontSize: 24)),
              title: const Text('借入'),
              subtitle: const Text('从别人借钱(应付债务)'),
              onTap: () => Navigator.pop(ctx, 'borrow'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    switch (action) {
      case 'record':
        final saved = await showRecordSheet(context);
        if (saved && context.mounted) {
          ConfettiBurst.fire(context, originKey: recordFabKey);
        }
      case 'transfer':
        await showTransferSheet(context);
      case 'repayment':
        await showRepaymentSheet(context);
      case 'lend':
        // D22 修复:借出独立全屏页面,非账户弹层(咔皮截图 §3.1)
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LendRecordPage()),
        );
      case 'borrow':
        // D22 修复:借入独立全屏页面
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BorrowRecordPage()),
        );
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
          _RepaymentReminderCard(),
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
    // BUG-1 用户反馈(2026-08-12):「现金余额有减少,首页资产没有汇总」—
    // 旧版 D28 占位 v0 显示「本月收入-支出净额」(过滤 toggle),但用户期望
    // 「净资产 = 所有账户余额 SUM」(v4 §P0-12 公式)。修法:用 accountListProvider
    // 实时聚合 balanceCents,负余额自然扣(信用卡/网贷/花呗)— 净资产 = 资产 - 负债
    final accountsAsync = ref.watch(accountListProvider);

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
          child: accountsAsync.when(
            data: (list) {
              final totalCents = list.fold<int>(0, (s, a) => s + a.balanceCents);
              final count = list.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '净资产',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatYuanShort(totalCents),
                    key: const Key('net-worth-balance'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: totalCents >= 0 ? Colors.black87 : Colors.red[700],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '总资产(账户余额聚合 ¥${_formatYuanShort(totalCents)})',
                    key: const Key('net-worth-monthly-detail'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
              );
            },
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '资产加载失败:$e',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 月度统计 Provider(D28 ADR-0033)— 主页净资产占位 v0。
///
/// 复用 [databaseProvider] 的 [StatisticsDao.getMonthlyStats] 计算本月收支净额。
///
/// **D28 IQA-fix (2026-08-11)**:为解决 submit 后主页不刷新 UX bug(C-IQA-D28-1),
/// (2026-08-12 BUG-1 修后删除:_NetWorthCard 改用 accountListProvider 实时 SUM 聚合,
/// 不再依赖 _monthlyStatsProvider。S05/S04 实施时按需重写。)

/// 整数分 → "¥1,234" 格式(用于卡片显示)— 复用类似 formatYuan。
String _formatYuanShort(int cents) {
  final yuan = cents ~/ 100;
  final fen = cents.abs() % 100;
  // 千位分隔
  final yuanStr = yuan.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '¥$yuanStr.${fen.toString().padLeft(2, '0')}';
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
          // D26 (ADR-0030 §决策 5):短按进 TransactionDetailPage
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailPage(transactionId: tx.id),
            ),
          ),
          // D8:长按弹 ActionSheet(编辑/删除)
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
/// 主页「距离还款日 X 天」提醒卡片(ADR-0024 §1)。
///
/// 列出所有欠款账户(信用卡 / 花呗 / 网贷),按 dueDay 排序,显示最近的 1 个。
/// 不引本地通知(ADR-0021),卡片显示是 v1.0 简化方案,v1.1 加通知(ADR-0025)。
class _RepaymentReminderCard extends ConsumerWidget {
  const _RepaymentReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountListProvider);
    final theme = Theme.of(context);

    return asyncAccounts.when(
      data: (accounts) {
        // 过滤欠款类 + 有 dueDay
        final debts = accounts.where((a) =>
            (a.type == AccountType.creditCard ||
                a.type == AccountType.huabei ||
                a.type == AccountType.onlineLoan) &&
            a.dueDay != null).toList();
        if (debts.isEmpty) return const SizedBox.shrink();

        // 按「距下次还款日天数」升序
        final now = DateTime.now();
        debts.sort((a, b) {
          final daysA = _daysUntilDueDay(now, a.dueDay!);
          final daysB = _daysUntilDueDay(now, b.dueDay!);
          return daysA.compareTo(daysB);
        });
        final next = debts.first;
        final daysLeft = _daysUntilDueDay(now, next.dueDay!);

        // 不显示已过期(负数)或超过 30 天的(避免噪音)
        if (daysLeft < 0 || daysLeft > 30) {
          return const SizedBox.shrink();
        }

        final urgencyColor = daysLeft <= 3
            ? Colors.red[700]
            : daysLeft <= 7
                ? Colors.orange[700]
                : theme.colorScheme.outline;
        final urgencyText = daysLeft == 0
            ? '今天'
            : daysLeft == 1
                ? '明天'
                : '$daysLeft 天后';

        return Container(
          key: const Key('home-repayment-reminder'),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: urgencyColor!.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: urgencyColor, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_outlined, size: 16, color: urgencyColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$urgencyText 还 ${next.type.emoji} ${next.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// 计算当前日期到下一个 dueDay 的天数。
  ///
  /// 逻辑:如果本月 dueDay 已过,返回下月 dueDay 的差值;否则本月。
  int _daysUntilDueDay(DateTime now, int dueDay) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime nextDue = DateTime(now.year, now.month, dueDay);
    if (nextDue.isBefore(today)) {
      // 本月已过,跳到下月
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      nextDue = DateTime(nextYear, nextMonth, dueDay);
    }
    return nextDue.difference(today).inDays;
  }
}
