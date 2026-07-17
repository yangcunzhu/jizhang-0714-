import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/daos/category_template_dao.dart';
import '../application/category_template_provider.dart';

/// 分类模板页(Day 15 — Stage 2 主页入口跳转)。
///
/// 决策:ADR-0020 — 5 个预设模板卡片 + 弹层选「覆盖 / 追加」 + 应用后 toast。
/// - 卡片:emoji 头像 + 名称 + 简介 + 分类数
/// - 应用按钮:点击卡片 → 弹策略选择层(overwrite / append)
/// - 应用后:toast 显示「删除 N / 保留 N / 新增 N / 跳过 N」
class CategoryTemplatePage extends ConsumerWidget {
  const CategoryTemplatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类模板'),
        centerTitle: true,
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('模板加载失败:$e')),
        data: (templates) => ListView.separated(
          key: const Key('template-list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: templates.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _TemplateCard(template: templates[index]),
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});
  final CategoryTemplateEntry template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final count = ref.watch(templateCategoryCountProvider(template.code));
    final isEmpty = count == 0;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('template-card-${template.code}'),
        borderRadius: BorderRadius.circular(12),
        onTap: isEmpty
            ? () => _showEmptyHint(context)
            : () => _showApplyDialog(context, ref, template.code),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  template.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty ? '空模板' : '$count 个分类',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空模板提示(自定义空 = 应用后无分类,提示去手动添加)。
  void _showEmptyHint(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('空模板'),
        content: const Text('这是一个空模板,应用后不会新增任何分类。\n请使用「分类管理」手动添加。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 应用策略选择弹层(决策 ADR-0020 — 混合策略)。
  Future<void> _showApplyDialog(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final mode = await showModalBottomSheet<TemplateApplyMode>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return SafeArea(
          child: Material(
            color: t.colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '应用方式',
                    style: t.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  key: const Key('template-mode-overwrite'),
                  leading: const Icon(Icons.refresh),
                  title: const Text('覆盖现有分类'),
                  subtitle: const Text('删除无引用的旧分类,插入新分类;有引用的旧分类保留'),
                  onTap: () =>
                      Navigator.pop(ctx, TemplateApplyMode.overwrite),
                ),
                ListTile(
                  key: const Key('template-mode-append'),
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('追加到现有分类'),
                  subtitle: const Text('保留所有旧分类,只插入新分类(自动跳过重复)'),
                  onTap: () => Navigator.pop(ctx, TemplateApplyMode.append),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (mode == null || !context.mounted) return;
    await _applyTemplate(context, ref, code, mode);
  }

  Future<void> _applyTemplate(
    BuildContext context,
    WidgetRef ref,
    String code,
    TemplateApplyMode mode,
  ) async {
    final service = ref.read(applyTemplateServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await service.apply(code, mode);
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('模板应用完成:${result.summary()}'),
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('模板应用失败:$e'),
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }
}