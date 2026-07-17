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
                child: Icon(
                  _iconFor(category.iconName),
                  color: color,
                  size: 22,
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

  /// 10 个默认分类 iconName → IconData 映射。
  ///
  /// WHY: iconName 在 DB 中存字符串（Material Icon codepoint 别名），
  /// UI 层映射为 [IconData] 以便渲染。Stage 2 自定义分类后此映射需扩展。
  static IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'smartphone':
        return Icons.smartphone;
      case 'menu_book':
        return Icons.menu_book;
      case 'category':
        return Icons.category;
      case 'payments':
        return Icons.payments;
      default:
        return Icons.label_outline;
    }
  }
}