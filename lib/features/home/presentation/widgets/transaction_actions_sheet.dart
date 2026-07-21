import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/categories.dart';
import '../../../record/application/record_form_provider.dart';
import '../../../record/presentation/record_sheet.dart';
import '../home_page_keys.dart';
import 'confetti_burst.dart';

/// 长按交易项弹出的 ActionSheet(Stage 1 Day 8)。
///
/// 两个动作:
///   - 编辑:把当前交易反向填入 recordFormProvider,复用记账弹层(走 UPDATE 分支)
///   - 删除:直接删除 + 100ms 长振反馈
///
/// 退款入口(2026-08-09 D26 IQA C7 修复):**退款入口待 D26 主体实施**——
/// 等 TransactionDetailPage 底部「删除」+「退款」按钮就绪后,ActionSheet 不再保留
/// 「退款」action。当前(2026-08-09)只 2 action(编辑/删除),等 D26 主体完成后
/// 统一清理。详 ADR-0030 §决策 5 + IQA C7。
///
/// ADR-0014: 每个动作的 ListTile 都带 Key,Day 9 E2E 可 byKey 定位。
class TransactionActionsSheet extends ConsumerWidget {
  const TransactionActionsSheet({
    super.key,
    required this.transaction,
  });

  final TransactionEntry transaction;

  /// 弹出 ActionSheet(标准 modal bottom sheet,顶部圆角)。
  static Future<void> show(
    BuildContext context,
    TransactionEntry transaction,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => TransactionActionsSheet(
        transaction: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recordFormProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    // D26 P0-08 (Q4=A):refund 行不允许编辑/删除(refund 本身是历史交易,不被允许
    // 用户改)。原交易被退过(Q2=A 详细判断走 detail page)的 case 在 detail page 内
    // 检测,actions_sheet 内只判当前行 type==refund 即可(简化 UX,无 FutureBuilder 闪烁)。
    final isRefundRow = transaction.type == TransactionType.refund;
    final disabledSubtitle = isRefundRow ? '退款记录不可修改' : null;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部把手
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: colorScheme.outline),
                const SizedBox(width: 12),
                Text(
                  '交易操作',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('txn-action-edit'),
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑'),
            subtitle: Text(
              isRefundRow ? disabledSubtitle! : '修改金额 / 分类 / 备注',
            ),
            enabled: !isRefundRow,
            onTap: isRefundRow
                ? null
                : () async {
                    // WHY: 先 pop 再 showRecordSheet(editing:) — 由新 sheet 在
                    // initState 里调 loadForEdit,避开 autoDispose 时序坑(详见
                    // record_sheet.dart 注释)。不能在 onTap 内直接调 loadForEdit,
                    // 因为 pop 后旧 ref 已失效,notifier 引用可能指向已 dispose 的 provider。
                    Navigator.of(context).pop();
                    await showRecordSheet(context, editing: transaction);
                  },
          ),
          ListTile(
            key: const Key('txn-action-delete'),
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text(
              '删除',
              style: TextStyle(
                color: isRefundRow
                    ? colorScheme.outline
                    : colorScheme.error,
              ),
            ),
            subtitle: Text(
              isRefundRow ? disabledSubtitle! : '不可恢复,确认前请三思',
            ),
            enabled: !isRefundRow,
            onTap: isRefundRow
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await notifier.deleteTransaction(transaction.id);
                      navigator.pop();
                      // Day 9:删除成功 → 从 FAB 位置发射攒攒动画(error 色 → 警示)
                      if (context.mounted) {
                        ConfettiBurst.fire(
                          context,
                          originKey: recordFabKey,
                          color: colorScheme.error,
                        );
                      }
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
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}