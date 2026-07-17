import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/tables/categories.dart';
import '../../application/category_form_provider.dart';
import 'emoji_picker.dart';

/// 分类编辑弹层(Day 14 — 决策 ADR-0019 弹层 + emoji 自建 + 12 色板)。
///
/// 用法:
/// ```dart
/// final saved = await CategoryEditSheet.show(
///   context,
///   existingId: null,           // 新建
///   type: TransactionType.expense,
/// );
/// if (saved) { ... }
/// ```
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({
    super.key,
    this.existingId,
    required this.type,
  });

  /// null = 新建;非 null = 编辑该 ID 的分类。
  final int? existingId;

  /// 支出 / 收入(仅新建场景有意义;编辑场景固定为分类原 type)。
  final TransactionType type;

  /// 显示弹层。返回 true 表示保存成功,false = 用户取消或保存失败。
  static Future<bool> show(
    BuildContext context, {
    int? existingId,
    required TransactionType type,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditSheet(existingId: existingId, type: type),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _nameController;

  /// 控制弹层关闭时是否真正 dismiss(校验失败时阻止)。
  bool _canDismiss = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(categoryFormProvider((
      existingId: widget.existingId,
      type: widget.type,
    )));
    _nameController = TextEditingController(text: state.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formKey = (
      existingId: widget.existingId,
      type: widget.type,
    );
    final form = ref.watch(categoryFormProvider(formKey));
    final controller = ref.read(categoryFormProvider(formKey).notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: _canDismiss,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.existingId == null ? '新建分类' : '编辑分类',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 实时预览
                _Preview(
                  iconName: form.iconName,
                  colorValue: form.colorValue,
                  name: form.name,
                ),
                const SizedBox(height: 16),
                // emoji 选择按钮(点击弹 emoji_picker)
                OutlinedButton.icon(
                  key: const Key('category-edit-emoji-button'),
                  onPressed: () async {
                    final picked = await EmojiPicker.show(
                      context,
                      initial: form.iconName,
                    );
                    if (picked != null) {
                      controller.changeIcon(picked);
                    }
                  },
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  label: const Text('选择 Emoji'),
                ),
                const SizedBox(height: 16),
                // 名称
                TextField(
                  key: const Key('category-edit-name'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    hintText: '比如:奶茶 / 兼职',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.changeName,
                  maxLength: 20,
                ),
                const SizedBox(height: 8),
                // 12 色板
                Text('颜色', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _ColorPalette(
                  current: form.colorValue,
                  onSelected: controller.changeColor,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('category-edit-cancel'),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('category-edit-save'),
                        onPressed: () async {
                          setState(() => _canDismiss = false);
                          final ok = await controller.submit();
                          if (!mounted) return;
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() => _canDismiss = true);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(
                                content: Text('保存失败:请检查字段是否合法'),
                              ));
                          }
                        },
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 实时预览 tile(emoji + 颜色 + 名称)。
class _Preview extends StatelessWidget {
  const _Preview({
    required this.iconName,
    required this.colorValue,
    required this.name,
  });

  final String iconName;
  final int colorValue;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(iconName, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? '（未命名分类）' : name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: name.isEmpty ? theme.colorScheme.outline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 12 色板(决策 ADR-0019)。
class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.current, required this.onSelected});

  final int current;
  final ValueChanged<int> onSelected;

  static const List<int> _colors = [
    0xFFE57373, // 红
    0xFFFFB74D, // 橙
    0xFFFFD54F, // 黄
    0xFF81C784, // 绿
    0xFF4DD0E1, // 青
    0xFF64B5F6, // 蓝
    0xFF9575CD, // 紫
    0xFFF06292, // 粉
    0xFFA1887F, // 棕
    0xFF90A4AE, // 灰
    0xFF455A64, // 暗灰
    0xFF26A69A, // 蓝绿
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((c) {
        final isSelected = c == current;
        final color = Color(c);
        return InkWell(
          key: Key('category-color-${c.toRadixString(16)}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelected(c),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}