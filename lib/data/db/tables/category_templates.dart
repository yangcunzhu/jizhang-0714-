import 'package:drift/drift.dart';

import 'categories.dart';

/// 分类模板元数据表(Day 15 — Stage 2 新增,schema v3)。
///
/// WHY: 5 个预设模板(上班族 / 家庭 / 学生 / 极简 / 自定义空)的元数据
/// 存数据库供浏览 + 选择。**模板内的具体分类定义用 Dart const**,
/// 不入 categories 表(避免污染用户的分类列表)。
/// 应用模板时从 Dart const 读 → 去重 → 批量插入 categories。
@DataClassName('CategoryTemplateEntry')
class CategoryTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 模板代号,稳定不变(英文 snake_case,如 'office_worker' / 'family')。
  ///
  /// WHY: 用作 UI Key + seed 数据 key,稳定后改 description 不影响功能。
  TextColumn get code => text().withLength(min: 1, max: 32)();

  /// 模板显示名(中文,如 "上班族")。
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// 模板简介(一句话,如 "覆盖上班族日常场景,12 个高频分类")。
  TextColumn get description => text()();

  /// 模板 emoji 头像(UI 卡片用,UTF-16 字符串)。
  ///
  /// WHY: 沿用 ADR-0013 emoji 优先,跨平台一致 + 零依赖。
  TextColumn get emoji => text().withLength(min: 1, max: 10)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// 模板内单个分类定义(纯 Dart 类,不进 DB,只用于 seed 时构造数据)。
class TemplateCategoryDef {
  const TemplateCategoryDef({
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
  });

  /// 分类名称(1-20 字)。
  final String name;

  /// emoji 字符(UTF-16 字符串,见 ADR-0019)。
  final String iconName;

  /// 主题色 ARGB int。
  final int colorValue;

  /// 支出 / 收入。
  final TransactionType type;
}

/// 模板完整定义(纯 Dart,seed 时只入元数据到 DB,分类列表不入)。
class TemplateDefinition {
  const TemplateDefinition({
    required this.code,
    required this.name,
    required this.description,
    required this.emoji,
    required this.categories,
  });

  /// 模板代号(对应 [CategoryTemplates.code])。
  final String code;

  /// 模板显示名(中文,对应 [CategoryTemplates.name])。
  final String name;

  /// 模板简介(对应 [CategoryTemplates.description])。
  final String description;

  /// 模板 emoji(对应 [CategoryTemplates.emoji])。
  final String emoji;

  /// 模板内分类列表(应用模板时从此读取 → 去重 → 插入 categories)。
  final List<TemplateCategoryDef> categories;
}

/// 5 个预设模板(决策 ADR-0020 — 差异化 5~12 个分类)。
///
/// WHY:
/// - 上班族 12 = 与 Stage 1 seed 数量一致,平滑过渡
/// - 家庭 10 = 加孩子 / 医疗,场景补全
/// - 学生 8 = 学习生活精简版
/// - 极简 5 = 给"只想要最少分类"的用户出口
/// - 自定义空 0 = 给"我就要全手动"的用户出口
const List<TemplateDefinition> defaultTemplateDefinitions = [
  TemplateDefinition(
    code: 'office_worker',
    name: '上班族',
    description: '覆盖上班族日常,12 个高频分类(支出 + 收入)',
    emoji: '👔',
    categories: [
      TemplateCategoryDef(
          name: '餐饮',
          iconName: '🍔',
          colorValue: 0xFFFF7043,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '交通',
          iconName: '🚗',
          colorValue: 0xFF42A5F5,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '购物',
          iconName: '🛍️',
          colorValue: 0xFFAB47BC,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '娱乐',
          iconName: '🎮',
          colorValue: 0xFFEC407A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '居住',
          iconName: '🏠',
          colorValue: 0xFF26A69A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '医疗',
          iconName: '🏥',
          colorValue: 0xFFEF5350,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '通讯',
          iconName: '📱',
          colorValue: 0xFF5C6BC0,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '学习',
          iconName: '📚',
          colorValue: 0xFF66BB6A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '咖啡',
          iconName: '☕',
          colorValue: 0xFF8D6E63,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '其他',
          iconName: '📦',
          colorValue: 0xFF78909C,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '工资',
          iconName: '💰',
          colorValue: 0xFF26C6DA,
          type: TransactionType.income),
      TemplateCategoryDef(
          name: '兼职',
          iconName: '💼',
          colorValue: 0xFFFFB74D,
          type: TransactionType.income),
    ],
  ),
  TemplateDefinition(
    code: 'family',
    name: '家庭',
    description: '家庭日常 10 个分类,覆盖孩子 / 医疗 / 居家',
    emoji: '👨‍👩‍👧',
    categories: [
      TemplateCategoryDef(
          name: '餐饮',
          iconName: '🍔',
          colorValue: 0xFFFF7043,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '居家',
          iconName: '🏠',
          colorValue: 0xFF26A69A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '孩子',
          iconName: '👶',
          colorValue: 0xFFFFCA28,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '医疗',
          iconName: '🏥',
          colorValue: 0xFFEF5350,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '交通',
          iconName: '🚗',
          colorValue: 0xFF42A5F5,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '购物',
          iconName: '🛍️',
          colorValue: 0xFFAB47BC,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '娱乐',
          iconName: '🎮',
          colorValue: 0xFFEC407A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '教育',
          iconName: '📖',
          colorValue: 0xFF66BB6A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '其他',
          iconName: '📦',
          colorValue: 0xFF78909C,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '工资',
          iconName: '💰',
          colorValue: 0xFF26C6DA,
          type: TransactionType.income),
    ],
  ),
  TemplateDefinition(
    code: 'student',
    name: '学生',
    description: '学习生活 8 个精简分类',
    emoji: '🎓',
    categories: [
      TemplateCategoryDef(
          name: '餐饮',
          iconName: '🍔',
          colorValue: 0xFFFF7043,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '学习',
          iconName: '📚',
          colorValue: 0xFF66BB6A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '交通',
          iconName: '🚗',
          colorValue: 0xFF42A5F5,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '娱乐',
          iconName: '🎮',
          colorValue: 0xFFEC407A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '购物',
          iconName: '🛍️',
          colorValue: 0xFFAB47BC,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '通讯',
          iconName: '📱',
          colorValue: 0xFF5C6BC0,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '其他',
          iconName: '📦',
          colorValue: 0xFF78909C,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '生活费',
          iconName: '💰',
          colorValue: 0xFF26C6DA,
          type: TransactionType.income),
    ],
  ),
  TemplateDefinition(
    code: 'minimal',
    name: '极简',
    description: '只保留 5 个核心分类,刻意精简',
    emoji: '✨',
    categories: [
      TemplateCategoryDef(
          name: '餐饮',
          iconName: '🍔',
          colorValue: 0xFFFF7043,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '交通',
          iconName: '🚗',
          colorValue: 0xFF42A5F5,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '居家',
          iconName: '🏠',
          colorValue: 0xFF26A69A,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '其他',
          iconName: '📦',
          colorValue: 0xFF78909C,
          type: TransactionType.expense),
      TemplateCategoryDef(
          name: '收入',
          iconName: '💰',
          colorValue: 0xFF26C6DA,
          type: TransactionType.income),
    ],
  ),
  TemplateDefinition(
    code: 'empty',
    name: '自定义空',
    description: '空模板,应用后从零开始手动添加',
    emoji: '📝',
    categories: [],
  ),
];