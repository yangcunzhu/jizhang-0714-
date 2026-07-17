import 'package:flutter/material.dart';

/// 分类 emoji 选择器(Day 14 — 决策 ADR-0019 自建精选网格)。
///
/// 6 主题 × 12 emoji = 72 个,覆盖记账高频场景。数据 const 化,widget 零开销 rebuild。
///
/// Day 16 polish:末尾加「更多 emoji（系统键盘）」入口,弹 TextField
/// autofocus 调起系统键盘 → 用户切到 emoji 键盘输入 → 提取首个 grapheme cluster
/// 作为 emoji 返回。补 ADR-0019 §6 留的系统键盘接口。
///
/// 用法:
/// ```dart
/// final picked = await EmojiPicker.show(context, initial: '🍔');
/// if (picked != null) controller.changeIcon(picked);
/// ```
class EmojiPicker extends StatelessWidget {
  const EmojiPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// 当前选中的 emoji(用于高亮)。
  final String selected;

  /// 选中回调。
  final ValueChanged<String> onSelected;

  /// 显示 emoji picker 弹层。返回选中的 emoji,null = 取消。
  static Future<String?> show(BuildContext context, {String initial = '🍔'}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmojiPicker(
        selected: initial,
        onSelected: (e) => Navigator.pop(context, e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '选择 Emoji',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              for (final group in kEmojiGroups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(
                    group.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                _EmojiGrid(
                  emojis: group.emojis,
                  selected: selected,
                  onSelected: onSelected,
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  key: const Key('emoji-picker-more'),
                  onPressed: () => _showMoreDialog(context, onSelected),
                  icon: const Icon(Icons.keyboard_outlined),
                  label: const Text('更多 emoji（系统键盘）'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹系统键盘输入 Dialog(TextField autofocus 调起系统键盘)。
  ///
  /// WHY: 72 个精选 emoji 可能不够用户用(ADR-0019 §6 缓解措施)。
  /// iOS 系统键盘顶部有 globe 切换到 emoji 键盘,用户输入后取首个
  /// grapheme cluster(用 `characters.first`,支持 ZWJ 组合 emoji)。
  Future<void> _showMoreDialog(
    BuildContext context,
    ValueChanged<String> onPicked,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => const _MoreEmojiDialog(),
    );
    if (picked != null && picked.isNotEmpty) {
      onPicked(picked);
    }
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.emojis,
    required this.selected,
    required this.onSelected,
  });

  final List<String> emojis;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((e) {
        final isSelected = e == selected;
        return InkWell(
          key: Key('emoji-pick-$e'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelected(e),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Text(e, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }
}

/// 6 主题 × 12 emoji = 72 个精选记账 emoji。
///
/// WHY:const 数据 + 静态访问,widget 渲染零开销。
/// 决策:ADR-0019 — 自建精选网格,无需依赖第三方包。
const List<({String name, List<String> emojis})> kEmojiGroups = [
  (
    name: '食物',
    emojis: [
      '🍔', '🍕', '🍜', '🍣', '🍰', '🍪',
      '☕', '🍺', '🥗', '🍎', '🥤', '🍩',
    ]
  ),
  (
    name: '交通',
    emojis: [
      '🚗', '🚌', '🚇', '✈️', '🚲', '🛵',
      '🚕', '🚢', '⛽', '🚏', '🏍️', '🛴',
    ]
  ),
  (
    name: '居家',
    emojis: [
      '🏠', '🛏️', '🚿', '🔑', '💡', '🪑',
      '🛋️', '🧺', '🧹', '🧴', '🪞', '🪟',
    ]
  ),
  (
    name: '工作',
    emojis: [
      '💼', '📱', '💻', '📚', '✏️', '📎',
      '📊', '💰', '📈', '🖊️', '📅', '💵',
    ]
  ),
  (
    name: '娱乐',
    emojis: [
      '🎮', '🎬', '🎵', '🎁', '🎨', '🎭',
      '⚽', '🏀', '📷', '🎤', '🎲', '🎯',
    ]
  ),
  (
    name: '其他',
    emojis: [
      '❤️', '⭐', '🔔', '📞', '💊', '💝',
      '🎉', '🌟', '🔒', '🌈', '🌹', '🎂',
    ]
  ),
];

/// 「更多 emoji」系统键盘输入 Dialog(Day 16 polish)。
///
/// WHY: 72 个精选 emoji 可能不够(ADR-0019 §6)。弹 Dialog + TextField
/// autofocus 调起系统键盘 → 用户切到 emoji 键盘 → 选 emoji → 提取首个
/// grapheme cluster(用 `characters`,支持 ZWJ 组合如 👨‍👩‍👧)返回。
class _MoreEmojiDialog extends StatefulWidget {
  const _MoreEmojiDialog();

  @override
  State<_MoreEmojiDialog> createState() => _MoreEmojiDialogState();
}

class _MoreEmojiDialogState extends State<_MoreEmojiDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 取首个 grapheme cluster(emoji 可能由多个 UTF-16 code unit 组成,
  /// 如 👨‍👩‍👧 含 8 个 code unit 但只算 1 个 grapheme)。
  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final firstGrapheme = text.characters.first;
    Navigator.pop(context, firstGrapheme);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('emoji-picker-more-dialog'),
      title: const Text('更多 Emoji'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('从系统键盘选 emoji,点确认'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('emoji-picker-more-input'),
            controller: _controller,
            autofocus: true,
            maxLength: 10,
            decoration: const InputDecoration(
              hintText: '例如:🐱',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('emoji-picker-more-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('emoji-picker-more-confirm'),
          onPressed: _submit,
          child: const Text('确认'),
        ),
      ],
    );
  }
}