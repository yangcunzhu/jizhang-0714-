import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/tables/categories.dart';

/// 分类表单状态(Day 14 — 分类编辑弹层用,沿用 AccountFormState 模式)。
///
/// WHY: 编辑/新建分类需要保存弹层内多个字段(emoji / 名称 / 颜色 / 排序),
/// 弹层关闭时一次性提交。colorValue 存 ARGB int(同 Categories 表)。
class CategoryFormState {
  const CategoryFormState({
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.sortOrder,
    required this.type,
  });

  /// 默认初始值(新建分类,type 由调用方传入,因支出/收入分类分离展示)。
  static CategoryFormState initialFor(TransactionType type) =>
      CategoryFormState(
        name: '',
        iconName: '🍔',
        colorValue: 0xFFFF7043,
        sortOrder: 0,
        type: type,
      );

  /// 分类名称(必填,1-20 字)。
  final String name;

  /// emoji 字符(由 emoji_picker 选择)。
  final String iconName;

  /// 主题色,ARGB int(由 12 色板选择)。
  final int colorValue;

  /// 排序(新建时取 max(sortOrder)+1,编辑时为当前值)。
  final int sortOrder;

  /// 支出 / 收入(本 ADR 不支持编辑时切换 type,固定于初始化值)。
  final TransactionType type;

  bool get isNew => sortOrder < 0;

  /// 表单校验:名称非空且 ≤ 20 字 + emoji 至少 1 个字符。
  String? validate() {
    if (name.trim().isEmpty) return '分类名称不能为空';
    if (name.trim().length > 20) return '分类名称不能超过 20 字';
    if (iconName.isEmpty) return '请选择 emoji';
    return null;
  }

  /// 复制 — 5 个字段语义都允许"传同值覆盖",所以用 `param ?? this.x` 即可。
  CategoryFormState copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    int? sortOrder,
  }) {
    return CategoryFormState(
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      type: type,
    );
  }

  /// 从已有分类构造 state(编辑场景)。
  factory CategoryFormState.from(CategoryEntry c) => CategoryFormState(
        name: c.name,
        iconName: c.iconName,
        colorValue: c.colorValue,
        sortOrder: c.sortOrder,
        type: c.type,
      );
}

/// 分类表单 controller(弹层用)。
///
/// - [existingId] == null 表示新建;非 null 表示编辑已有分类
/// - [type] 仅新建场景有意义(编辑场景固定为分类原 type)
/// - [submit] 写入数据库,返回是否成功(校验失败或抛错都返回 false)
class CategoryFormController extends StateNotifier<CategoryFormState> {
  CategoryFormController(
    this._ref, {
    this.existingId,
    required this.type,
  }) : super(CategoryFormState.initialFor(type)) {
    if (existingId != null) {
      _loadExisting(existingId!);
    } else {
      // 新建:sortOrder 取 max + 1。
      _initSortOrderForNew();
    }
  }

  final Ref _ref;
  final int? existingId;
  final TransactionType type;

  Future<void> _loadExisting(int id) async {
    final db = _ref.read(databaseProvider);
    final c = await db.categoryDao.getById(id);
    if (c != null && mounted) {
      state = CategoryFormState.from(c);
    }
  }

  Future<void> _initSortOrderForNew() async {
    final db = _ref.read(databaseProvider);
    final all = await db.categoryDao.getAll();
    final maxOrder = all.fold<int>(-1, (acc, c) => c.sortOrder > acc ? c.sortOrder : acc);
    if (mounted) {
      state = state.copyWith(sortOrder: maxOrder + 1);
    }
  }

  void changeName(String name) => state = state.copyWith(name: name);
  void changeIcon(String emoji) => state = state.copyWith(iconName: emoji);
  void changeColor(int colorValue) =>
      state = state.copyWith(colorValue: colorValue);

  /// 提交:返回 true 表示写入成功,false 表示校验失败或写失败。
  Future<bool> submit() async {
    final err = state.validate();
    if (err != null) return false;

    final db = _ref.read(databaseProvider);
    try {
      if (existingId == null) {
        // 新建
        await db.categoryDao.insertCategory(
          CategoriesCompanion.insert(
            name: state.name.trim(),
            iconName: state.iconName,
            colorValue: state.colorValue,
            type: state.type,
            sortOrder: Value(state.sortOrder),
          ),
        );
      } else {
        // 更新 — 用 companion 部分更新语义,name/iconName/colorValue 都重写,
        // type 不改(决策:Day 14 不支持编辑时切换支出/收入分类)
        await db.categoryDao.updateCategoryById(
          CategoriesCompanion(
            id: Value(existingId!),
            name: Value(state.name.trim()),
            iconName: Value(state.iconName),
            colorValue: Value(state.colorValue),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 分类表单 provider(弹层用)。
///
/// WHY: family 模式 — Key 是 `({int? existingId, TransactionType type})` 组合:
///
/// - existingId:null = 新建,非 null = 编辑该 ID 的分类
/// - type:仅新建场景决定支出/收入分类,编辑场景用分类原 type(由 controller 内部覆盖)
///   family key 加 type 避免"新建支出 + 新建收入"同时打开时 state 串台。
///
/// 不用 autoDispose 是因为弹层关闭时 family key 仍可能被外部 listener 引用,
/// 立即 dispose 会导致测试和真实场景 race condition。实例数量 ≤ 1,GC 自然清理。
final categoryFormProvider = StateNotifierProvider.family<
    CategoryFormController, CategoryFormState, ({int? existingId, TransactionType type})>(
  (ref, args) => CategoryFormController(
    ref,
    existingId: args.existingId,
    type: args.type,
  ),
);

/// 分类引用计数 provider(返回 `Map<categoryId, count>`)。
///
/// WHY:管理页长按删除前需知道每个分类被引用次数,集中一次查询避免 N+1。
/// 本 provider 监听 transactions 表(若 schema 后续加新引用表,需扩展)。
/// 决策:ADR-0019 — 一次性 for-loop 查询,数量 ≤ 30 性能可接受。
final categoryReferenceCountProvider =
    FutureProvider<Map<int, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final cats = await db.categoryDao.getAll();
  final result = <int, int>{};
  for (final c in cats) {
    result[c.id] = await db.categoryDao.countTransactionsByCategory(c.id);
  }
  return result;
});