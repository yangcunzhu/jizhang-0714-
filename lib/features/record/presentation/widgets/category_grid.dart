import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/db/app_database.dart';
import '../../../home/application/home_providers.dart';

/// 记账弹层的分类网格（Step 1）。
///
/// 监听 [categoryListProvider]，按 4 列网格展示 10 个默认分类。
/// 选中后回调 [onSelected]（由父组件触发 recordFormProvider.selectCategory）。
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final int? selectedCategoryId;
  final ValueChanged<CategoryEntry> onSelected;

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
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final c = cats[index];
            final selected = c.id == selectedCategoryId;
            return _CategoryTile(
              category: c,
              selected: selected,
              onTap: () => onSelected(c),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryEntry category;
  final bool selected;
  final VoidCallback onTap;

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