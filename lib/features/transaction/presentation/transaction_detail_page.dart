// TransactionDetailPage — D26 新建(ADR-0030 §决策 5)
//
// Stage 3 D26 主页短按入口:展示交易详情 + 底部「退款」+「删除」+「编辑」三按钮。
//
// 关键:
// - isRefunded 检测(DAO getRefundedAmount)→ 已退过的原交易,3 按钮全灰
// - type=refund 行 → 3 按钮全灰(refund 行本身是历史交易,不可修改)
// - type 校验:只有 expense/repayment/lend/borrow 才显示退款按钮
// - 「退款」按钮 → 弹 RefundSheet(Q3=B 金额可改 + Q4=α2 多次拆分)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/categories.dart';
import '../../record/application/record_form_provider.dart';
import '../../record/presentation/record_sheet.dart';
import 'refund_sheet.dart';

class TransactionDetailPage extends ConsumerStatefulWidget {
  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  final int transactionId;

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends ConsumerState<TransactionDetailPage> {
  late Future<TransactionEntry?> _txFuture;

  @override
  void initState() {
    super.initState();
    _txFuture = _loadTransaction();
  }

  Future<TransactionEntry?> _loadTransaction() async {
    final db = ref.read(databaseProvider);
    return db.transactionDao.getById(widget.transactionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<TransactionEntry?>(
        future: _txFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final tx = snapshot.data;
          if (tx == null) {
            return const Center(child: Text('交易不存在(可能已删除)'));
          }
          return _DetailBody(transaction: tx);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<Object?>>(
      future: Future.wait([
        db.accountDao.getById(transaction.accountId),
        // IQA-fix M3 (2026-08-09):用 getById 单查替换 getAll() 全表扫(N+1 反模式)。
        // getAll() 每次查全部分类只为 1 个 lookup,主页列表加载会卡。
        db.categoryDao.getById(transaction.categoryId).then((c) =>
            c ??
            CategoryEntry(
              id: 0,
              name: '未知',
              iconName: '📌',
              colorValue: 0xFF9E9E9E,
              type: TransactionType.expense,
              sortOrder: 0,
              createdAt: DateTime.now(),
            )),
        db.transactionDao.getRefundedAmount(transaction.id),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null) {
          return const Center(child: Text('加载失败'));
        }
        final account = snapshot.data![0] as AccountEntry?;
        final category = snapshot.data![1] as CategoryEntry;
        final refunded = snapshot.data![2] as int;

        final isRefundRow = transaction.type == TransactionType.refund;
        final isRefundedOriginal = refunded > 0 && !isRefundRow;
        final canRefund = !isRefundRow &&
            !isRefundedOriginal &&
            (transaction.type == TransactionType.expense ||
                transaction.type == TransactionType.repayment ||
                transaction.type == TransactionType.lend ||
                transaction.type == TransactionType.borrow);
        final amountColor = isRefundRow
            ? Colors.blueGrey[700]
            : (transaction.type == TransactionType.income
                ? Colors.green[700]
                : (transaction.type == TransactionType.expense
                    ? Colors.red[700]
                    : Colors.blueGrey[600]));
        final sign = transaction.type == TransactionType.expense ? '-' : '+';
        final formatted = '$sign¥${_formatYuan(transaction.amountCents)}';

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: isRefundRow
                  ? Colors.blueGrey.shade50
                  : theme.colorScheme.surfaceContainerLow,
              child: Column(
                children: [
                  if (isRefundRow)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '↩️ 退款记录',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  // ─── 字段表(IQA-fix D29-2 2026-08-12:toggle 顶部平级 + refund 状态独立区块底部)───
                  //
                  // 顺序设计(咔皮对标 图 19 真实账单详情页布局):
                  // 1. 基础信息(账户/时间/备注)— 交易核心
                  // 2. **toggle 行顶部平级** — 交易级状态(全局),与「账户」「时间」同等级
                  // 3. refund 状态(已退金额/退款备注)— 仅退款相关交易显示
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '账户',
                    value: account?.name ?? '未知账户',
                  ),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: '时间',
                    value: DateFormat('yyyy-MM-dd HH:mm')
                        .format(transaction.occurredAt),
                  ),
                  if (transaction.note.isNotEmpty)
                    _DetailRow(
                      icon: Icons.notes,
                      label: '备注',
                      value: transaction.note,
                    ),
                  // D28 ADR-0033 + IQA-fix D29-2:2 toggle 顶部平级
                  // 决策 5 不可改 — toggle 改 = 改历史统计 = 不可逆,锁只读
                  _DetailRow(
                    icon: transaction.excludeFromIncomeExpense
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    label: '不计收支',
                    value: transaction.excludeFromIncomeExpense ? '开' : '关',
                    valueColor: transaction.excludeFromIncomeExpense
                        ? Colors.orange[700]
                        : Colors.grey[500],
                  ),
                  _DetailRow(
                    icon: transaction.excludeFromBudget
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    label: '不计预算',
                    value: transaction.excludeFromBudget ? '开' : '关',
                    valueColor: transaction.excludeFromBudget
                        ? Colors.orange[700]
                        : Colors.grey[500],
                  ),
                  // refund 状态独立区块(仅 isRefundedOriginal 或有 refundNote 显示)
                  if (isRefundedOriginal)
                    _DetailRow(
                      icon: Icons.refresh,
                      label: '已退金额',
                      value:
                          '¥${_formatYuan(refunded)} / ¥${_formatYuan(transaction.amountCents)}',
                      valueColor: Colors.blueGrey[700],
                    ),
                  if (transaction.refundNote != null &&
                      transaction.refundNote!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.bookmark_outline,
                      label: '退款备注',
                      value: transaction.refundNote!,
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('detail-action-edit'),
                        onPressed: (isRefundRow || isRefundedOriginal)
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await showRecordSheet(
                                  context,
                                  editing: transaction,
                                );
                              },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('编辑'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('detail-action-delete'),
                        onPressed: (isRefundRow || isRefundedOriginal)
                            ? null
                            : () async {
                                final notifier =
                                    ref.read(recordFormProvider.notifier);
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                try {
                                  await notifier.deleteTransaction(
                                      transaction.id);
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('已删除'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('删除失败:$e')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('删除'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('detail-action-refund'),
                        onPressed: canRefund
                            ? () async {
                                final result = await showRefundSheet(
                                  context,
                                  originalTransaction: transaction,
                                );
                                if (result == true && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('退款'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final centsPart = cents.abs() % 100;
    return '${yuan.toString()}.${centsPart.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.outline),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }
}
