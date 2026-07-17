import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../record/application/record_form_provider.dart';
import '../../../record/presentation/record_sheet.dart';
import '../home_page_keys.dart';
import 'confetti_burst.dart';

/// 长按交易项弹出的 ActionSheet(Stage 1 Day 8)。
///
/// 三个动作:
///   - 编辑:把当前交易反向填入 recordFormProvider,复用记账弹层(走 UPDATE 分支)
///   - 退款:方案 A — 插入一笔反向类型的新交易,note 自动加 "退款" 前缀
///   - 删除:直接删除 + 100ms 长振反馈
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
            subtitle: const Text('修改金额 / 分类 / 备注'),
            onTap: () async {
              // WHY: 先 pop 再 showRecordSheet(editing:) — 由新 sheet 在
              // initState 里调 loadForEdit,避开 autoDispose 时序坑(详见
              // record_sheet.dart 注释)。不能在 onTap 内直接调 loadForEdit,
              // 因为 pop 后旧 ref 已失效,notifier 引用可能指向已 dispose 的 provider。
              Navigator.of(context).pop();
              await showRecordSheet(context, editing: transaction);
            },
          ),
          ListTile(
            key: const Key('txn-action-refund'),
            leading: Icon(Icons.replay_outlined, color: colorScheme.primary),
            title: const Text('退款'),
            subtitle: const Text('反向插入一笔(收入↔支出)'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await notifier.submitAsRefund(transaction);
                navigator.pop();
                // Day 9:退款成功 → 从 FAB 位置发射攒攒动画(primary 色)
                if (context.mounted) {
                  ConfettiBurst.fire(
                    context,
                    originKey: recordFabKey,
                    color: colorScheme.primary,
                  );
                }
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('已退款'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('退款失败:$e')),
                );
              }
            },
          ),
          ListTile(
            key: const Key('txn-action-delete'),
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('删除', style: TextStyle(color: colorScheme.error)),
            subtitle: const Text('不可恢复,确认前请三思'),
            onTap: () async {
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