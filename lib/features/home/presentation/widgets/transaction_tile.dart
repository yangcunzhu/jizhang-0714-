import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories.dart';

/// 单条交易列表项。
///
/// 显示分类（颜色 + 名称）/ 备注 / 时间 + 金额（红=支出 / 绿=收入）。
///
/// ADR-0014: 顶层 ListTile 带 Key('txn-{id}'),Day 9 E2E 直接定位。
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onLongPress,
  });

  final TransactionEntry transaction;
  final CategoryEntry? category;

  /// 长按回调(Day 8 弹 ActionSheet 用)。null 时 ListTile 不响应长按。
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = category != null ? Color(category!.colorValue) : Colors.grey;
    final isExpense = transaction.type == TransactionType.expense;
    final sign = isExpense ? '-' : '+';
    final formatted = _formatYuan(transaction.amountCents);
    final dateLabel =
        DateFormat('MM-dd HH:mm').format(transaction.occurredAt);

    return ListTile(
      key: Key('txn-${transaction.id}'),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          category?.iconName ?? '📌',
          style: const TextStyle(fontSize: 20),
        ),
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
        '$sign¥$formatted',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isExpense ? Colors.red[700] : Colors.green[700],
        ),
      ),
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