import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../home/application/home_providers.dart';

/// 记账弹层的分类网格（Step 1）。
///
/// Day 7: 监听 [categoryListProvider]，按 4 列网格展示分类,选中后回调 [onSelected]。
/// Day 14 (ADR-0019): + 长按回调 [onManageCategory] + 末尾「+新增」入口。
///
/// 父组件(record_sheet) 持有导航逻辑,本 widget 不直接 Navigator.push,
/// 以保持纯展示逻辑。
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
    this.onManageCategory,
  });

  final int? selectedCategoryId;
  final ValueChanged<CategoryEntry> onSelected;

  /// 长按分类 / 点击「+新增」tile 时触发,父组件导航到分类管理页。
  ///
  /// 为 null 时,长按和「+」入口均不响应(向下兼容 + 单元测试友好)。
  final VoidCallback? onManageCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoryListProvider);

    return catsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('分类加载失败：$e')),
      data: (cats) {
        if (cats.isEmpty) {
          return const Center(child: Text('暂无分类'));
        }
        // 末尾追加「+新增」tile(条件:onManageCategory 非 null)。
        final showAdd = onManageCategory != null;
        final itemCount = cats.length + (showAdd ? 1 : 0);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.95,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (showAdd && index == cats.length) {
              return _AddTile(
                key: const Key('category-grid-add'),
                onTap: onManageCategory!,
              );
            }
            final c = cats[index];
            final selected = c.id == selectedCategoryId;
            return _CategoryTile(
              key: Key('emoji-${c.name}'),
              category: c,
              selected: selected,
              onTap: () => onSelected(c),
              onLongPress: onManageCategory,
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final CategoryEntry category;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.18)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  category.iconName,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 末尾「+新增」tile(与分类 tile 同尺寸,虚线边框区分)。
class _AddTile extends StatelessWidget {
  const _AddTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '新增',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}