import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/categories.dart';
import '../../home/application/home_providers.dart';
import '../application/category_form_provider.dart';
import 'widgets/category_edit_sheet.dart';

/// 分类管理页(Day 14 — 主页入口跳转,沿用 ADR-0018 ListView 风格)。
///
/// 决策:ADR-0019 — ↑↓ 单步移动 + 长按弹菜单(编辑/删除)+ 末尾「+新增」入口。
/// - 引用计数 > 0 的分类 → 删除按钮禁用 + tooltip 提示
/// - 引用计数 = 0 的分类 → 删除前二次确认
/// - 上移 / 下移:边界(第一/最后)禁用对应按钮
class CategoryManagementPage extends ConsumerWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        centerTitle: true,
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('分类加载失败:$e')),
        data: (cats) {
          if (cats.isEmpty) {
            return _EmptyState(
              onAdd: () => _addCategory(context, TransactionType.expense),
            );
          }
          final countsAsync = ref.watch(categoryReferenceCountProvider);
          final counts = countsAsync.valueOrNull ?? const <int, int>{};
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: cats.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == cats.length) {
                return _AddEntry(
                  onAdd: () => _addCategory(context, TransactionType.expense),
                );
              }
              final c = cats[index];
              final refCount = counts[c.id] ?? 0;
              return _CategoryRow(
                key: Key('category-row-${c.id}'),
                category: c,
                isFirst: index == 0,
                isLast: index == cats.length - 1,
                referenceCount: refCount,
                onTap: () => _editCategory(context, c),
                onLongPress: () =>
                    _showActions(context, ref, cats, index, c, refCount),
                onMoveUp: () => _moveUp(ref, cats, index),
                onMoveDown: () => _moveDown(ref, cats, index),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, TransactionType type) async {
    await CategoryEditSheet.show(context, existingId: null, type: type);
  }

  Future<void> _editCategory(BuildContext context, CategoryEntry c) async {
    await CategoryEditSheet.show(context, existingId: c.id, type: c.type);
  }

  Future<void> _moveUp(
      WidgetRef ref, List<CategoryEntry> cats, int index) async {
    if (index == 0) return;
    final db = ref.read(databaseProvider);
    await db.categoryDao.swapSortOrder(cats[index].id, cats[index - 1].id);
  }

  Future<void> _moveDown(
      WidgetRef ref, List<CategoryEntry> cats, int index) async {
    if (index >= cats.length - 1) return;
    final db = ref.read(databaseProvider);
    await db.categoryDao.swapSortOrder(cats[index].id, cats[index + 1].id);
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    List<CategoryEntry> cats,
    int index,
    CategoryEntry c,
    int refCount,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Material(
          color: Theme.of(ctx).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: Key('category-action-edit-${c.id}'),
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                key: Key('category-action-delete-${c.id}'),
                leading: Icon(
                  Icons.delete_outline,
                  color: refCount > 0
                      ? Theme.of(ctx).colorScheme.outline
                      : Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  refCount > 0 ? '删除(有 $refCount 笔交易引用)' : '删除',
                  style: TextStyle(
                    color: refCount > 0
                        ? Theme.of(ctx).colorScheme.outline
                        : Theme.of(ctx).colorScheme.error,
                  ),
                ),
                enabled: refCount == 0,
                onTap: refCount > 0
                    ? null
                    : () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _editCategory(context, c);
    } else if (action == 'delete') {
      await _confirmDelete(context, ref, c);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryEntry c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确认删除分类「${c.name}」?此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: Key('category-confirm-delete-${c.id}'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(databaseProvider).categoryDao.deleteCategory(c.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('删除失败:$e'),
          duration: const Duration(seconds: 3),
        ));
    }
  }
}

/// 单行分类卡片(emoji + 名称 + 上下箭头 + 颜色点)。
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.category,
    required this.isFirst,
    required this.isLast,
    required this.referenceCount,
    required this.onTap,
    required this.onLongPress,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final CategoryEntry category;
  final bool isFirst;
  final bool isLast;
  final int referenceCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.iconName,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (referenceCount > 0)
                      Text(
                        '$referenceCount 笔交易引用',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: Key('category-up-${category.id}'),
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: '上移',
                onPressed: isFirst ? null : onMoveUp,
              ),
              IconButton(
                key: Key('category-down-${category.id}'),
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: '下移',
                onPressed: isLast ? null : onMoveDown,
              ),
              Icon(
                Icons.drag_handle,
                color: theme.colorScheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 列表末尾的「+新增分类」入口。
class _AddEntry extends StatelessWidget {
  const _AddEntry({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('category-add-entry'),
        borderRadius: BorderRadius.circular(12),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '新增分类',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分类列表为空时的空态。
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🏷️', style: TextStyle(fontSize: 64, color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          Text('还没有分类', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('点击下方按钮添加你的第一个分类', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('category-empty-add'),
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('新增分类'),
          ),
        ],
      ),
    );
  }
}