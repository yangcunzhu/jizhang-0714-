import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories.dart';

/// 单条交易列表项。
///
/// 显示分类（颜色 + 名称）/ 备注 / 时间 + 金额（红=支出 / 绿=收入）。
///
/// D26 (ADR-0030) 增强:
/// - 加 [onTap](短按进 TransactionDetailPage)+ 保留 [onLongPress](D8 弹 ActionSheet)
/// - type=refund 显示 ↩️ overlay + 蓝灰色(0xFF607D8B)+ blueGrey.shade50 底色
///
/// ADR-0014: 顶层 ListTile 带 Key('txn-{id}'),Day 9 E2E 直接定位。
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
    this.onLongPress,
  });

  final TransactionEntry transaction;
  final CategoryEntry? category;

  /// 短按回调(D26 起跳 TransactionDetailPage)。null 时 ListTile 不响应短按。
  final VoidCallback? onTap;

  /// 长按回调(Day 8 弹 ActionSheet 用)。null 时 ListTile 不响应长按。
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = category != null ? Color(category!.colorValue) : Colors.grey;
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isRefund = transaction.type == TransactionType.refund;
    // BUG-5 用户反馈(2026-08-12):还款 ↩️ + 退款 ↩️ icon 撞色 — 都用 ↩️
    // 修法:还款 = 💳(信用卡/现金还款)+ ↩️(流向),退款 = ↩️(单向回退)
    final isRepayment = transaction.type == TransactionType.repayment;
    final sign = isTransfer ? '⇄ ' : (isExpense ? '-' : '+');
    final amountColor = isRefund
        ? Colors.blueGrey[700] // D26:refund 用蓝灰色 0xFF607D8B
        : (isTransfer
            ? Colors.blueGrey[600]
            : (isExpense ? Colors.red[700] : Colors.green[700]));
    final formatted = _formatYuan(transaction.amountCents);
    final dateLabel =
        DateFormat('MM-dd HH:mm').format(transaction.occurredAt);
    // D26 + BUG-5:refund 用 ↩️ 区分,repayment 用 💳 区分(不再撞色)
    final signWithIcon = isRefund
        ? '↩$sign'
        : (isRepayment ? '💳$sign' : sign);

    return ListTile(
      key: Key('txn-${transaction.id}'),
      tileColor: isRefund ? Colors.blueGrey.shade50 : null,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              category?.iconName ?? '📌',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          // D26:refund 行 ↩️ overlay 在右上角(ADR-0030 §决策 6)
          if (isRefund)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                key: Key('txn-refund-overlay-${transaction.id}'),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[700],
                  shape: BoxShape.circle,
                ),
                child: const Text('↩️', style: TextStyle(fontSize: 10)),
              ),
            ),
        ],
      ),
      title: Text(category?.name ?? '未知分类'),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              transaction.note.isEmpty
                  ? dateLabel
                  : '$dateLabel · ${transaction.note}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ADR-0024:网贷还款时显示「12 期」徽章
          if (transaction.installmentPeriod != null) ...[
            const SizedBox(width: 6),
            Container(
              key: const Key('txn-installment-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${transaction.installmentPeriod} 期',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.purple[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        '$signWithIcon¥$formatted',
        key: Key('txn-tile-amount-${transaction.id}'),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: amountColor,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// 整数分 → "12.99" 格式字符串。
  ///
  /// WHY: 由 [AccountPicker] 复用,不让两边各自实现一套 cents → 元 格式。
  static String formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final centsPart = cents % 100;
    return '${yuan.toString()}.${centsPart.toString().padLeft(2, '0')}';
  }

  /// 兼容旧代码保留的 internal alias。
  static String _formatYuan(int cents) => formatYuan(cents);
}