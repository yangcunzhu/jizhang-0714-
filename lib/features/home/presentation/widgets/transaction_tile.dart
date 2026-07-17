import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories.dart';

/// 单条交易列表项。
///
/// 显示分类（颜色 + 名称）/ 备注 / 时间 + 金额（红=支出 / 绿=收入）。
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
  });

  final TransactionEntry transaction;
  final CategoryEntry? category;

  @override
  Widget build(BuildContext context) {
    final color = category != null ? Color(category!.colorValue) : Colors.grey;
    final isExpense = transaction.type == TransactionType.expense;
    final sign = isExpense ? '-' : '+';
    final formatted = _formatYuan(transaction.amountCents);
    final dateLabel =
        DateFormat('MM-dd HH:mm').format(transaction.occurredAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.label_outline, color: color),
      ),
      title: Text(category?.name ?? '未知分类'),
      subtitle: Text(
        transaction.note.isEmpty ? dateLabel : '$dateLabel · ${transaction.note}',
      ),
      trailing: Text(
        '$sign¥$formatted',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isExpense ? Colors.red[700] : Colors.green[700],
        ),
      ),
    );
  }

  /// 整数分 → "12.99" 格式字符串。
  static String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final centsPart = cents % 100;
    return '${yuan.toString()}.${centsPart.toString().padLeft(2, '0')}';
  }
}