import 'package:flutter/material.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/accounts.dart';
import '../../../home/presentation/widgets/transaction_tile.dart';

/// 账户卡片 widget(账户管理页 / 主页列表 / 记账 Step 3 共用)。
///
/// 决策:ADR-0018 — 列表 + emoji 透明背景。
///
/// 显示内容:
/// - 类型 emoji(沿用 [AccountType.emoji])+ 名称 + 余额
/// - 信用卡专项:额度 / 账单日 / 还款日(单行)
/// - 投资类账户 `includeInNetWorth=false` 时显示「不计入净资产」标记
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onLongPress,
    this.showBalance = true,
  });

  final AccountEntry account;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceText = showBalance
        ? '余额 ¥${TransactionTile.formatYuan(account.balanceCents)}'
        : null;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('account-card-${account.id}'),
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (balanceText != null)
                          Text(
                            balanceText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _SubInfo(account: account),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 副信息行:类型标签 + 信用卡专项 + 净资产标记。
class _SubInfo extends StatelessWidget {
  const _SubInfo({required this.account});
  final AccountEntry account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <Widget>[
      Text(
        account.type.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    ];

    // 信用卡专项字段(任意子字段非空都显示)
    if (account.type == AccountType.creditCard &&
        (account.creditLimit != null ||
            account.billingDay != null ||
            account.dueDay != null)) {
      final pieces = <String>[];
      if (account.creditLimit != null) {
        final limitYuan = TransactionTile.formatYuan(account.creditLimit!);
        pieces.add('额度 ¥$limitYuan');
      }
      if (account.billingDay != null && account.dueDay != null) {
        pieces.add('${account.billingDay} 号账 / ${account.dueDay} 号还');
      } else if (account.billingDay != null) {
        pieces.add('${account.billingDay} 号账');
      } else if (account.dueDay != null) {
        pieces.add('${account.dueDay} 号还');
      }
      if (pieces.isNotEmpty) {
        parts.add(_dot());
        parts.add(Text(
          pieces.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ));
      }
    }

    // 不计入净资产标记
    if (!account.includeInNetWorth) {
      parts.add(_dot());
      parts.add(Text(
        '不计入净资产',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.tertiary,
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: parts,
    );
  }

  Widget _dot() => const Text('·', style: TextStyle(color: Colors.grey));
}