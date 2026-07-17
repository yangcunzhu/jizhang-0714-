import 'package:flutter/material.dart';

/// 记账弹层的金额数字键盘（计算器式）。
///
/// 布局：3×4 网格
/// ```
/// 1  2  3
/// 4  5  6
/// 7  8  9
/// .  0  ⌫
/// ```
///
/// 通过 [onDigit] / [onDot] / [onBackspace] 回调把按键事件外抛，
/// 父组件（或 recordFormProvider）维护金额状态。键盘自身无状态。
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDot;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([_digit(1), _digit(2), _digit(3)]),
        _row([_digit(4), _digit(5), _digit(6)]),
        _row([_digit(7), _digit(8), _digit(9)]),
        _row([
          _Key(
            label: '.',
            onTap: onDot,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          _digit(0),
          _Key(
            icon: Icons.backspace_outlined,
            onTap: onBackspace,
            color: Theme.of(context).colorScheme.errorContainer,
          ),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _digit(int d) {
    return _Key(
      label: d.toString(),
      onTap: () => onDigit(d),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
  }) : assert(label != null || icon != null, '必须提供 label 或 icon');

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 22)
                : Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}