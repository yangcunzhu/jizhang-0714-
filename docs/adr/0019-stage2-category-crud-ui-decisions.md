# ADR-0019:Stage 2 分类 CRUD UI 设计决策

## 状态

已接受 — Day 14(2026-07-27)

## 背景

Stage 2 Day 14 实施分类 CRUD UI(长按菜单 + 编辑弹层 + emoji picker)前,4 个 UI/语义决策需要固定,否则实现路径发散:

1. **iconName 字段语义**:Stage 1 注释写"Material/Cupertino 图标名或 codepoint 别名",但实际 `_defaultCategories` 直接存 emoji 字符。语义模糊会误导后续维护者
2. **emoji picker 实现**:自建精选网格 vs 系统键盘
3. **分类颜色**:预设 12 色板 vs 完整取色器
4. **排序交互**:ReorderableListView 拖拽 vs 上下箭头按钮

## 决策

### 1. iconName 字段语义 = **emoji 字符(UTF-16 字符串)**

```dart
// Stage 1 表定义保持不变,但注释从「Material/Cupertino 图标名」改为「emoji 字符」
TextColumn get iconName => text().withLength(min: 1, max: 40)();
```

WHY:
- `_defaultCategories` 实际就是直接存 `'🍔'` `'🚗'` `'🛍️'` 等 emoji 字符串,不是 Material Icons codepoint
- maxLength=40 是保守上限,单个 emoji 1-3 个 UTF-16 code unit,足矣放下 emoji 序列(带 ZWJ 组合如 👨‍👩‍👧‍👦)
- 沿用 ADR-0013 emoji 优先原则,无 Material Icons 干扰
- UI 渲染 `Text(category.iconName, style: TextStyle(fontSize: 24))` 直接显示

### 2. emoji picker = **自建精选网格**

```dart
// 80-120 个 emoji 按 6 主题分类(食物/交通/居家/工作/娱乐/其他)
const _kEmojiGroups = [
  ('食物', ['🍔','🍕','🍜','🍣','🍰','🍪','☕','🍺','🍷','🥤','🍎','🥗']),
  ('交通', ['🚗','🚌','🚇','✈️','🚲','🛵','🚕','🚢','🏍️','🛴','⛽','🚏']),
  // ...
];
```

WHY:
- 离线(无外部依赖,符合 §2 "不引入新依赖")
- widget 可测(emoji_picker_flutter 等第三方包在 CI 模拟系统键盘困难)
- 80-120 个覆盖记账高频场景(餐饮/交通/居家/工作/娱乐/其他 6 主题 × 12-20 个)
- 数据 const 化,widget rebuild 零开销
- 与 ADR-0013 emoji 优先原则一脉相承

### 3. 分类颜色 = **预设 12 色板**

```dart
const _kCategoryPalette = [
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
```

WHY:
- MVP 不需要无限色域(产品设计 v4 也用 12 色风格)
- 避免引入 color_picker 包或自建 HSV 调色器(违反 §2 不引入新依赖)
- 12 色饱和度接近 Material 300 色阶,与现有 `_defaultCategories` 的 Material 500 色阶成系列
- 网格展示,3×4 一屏可见,选择快
- 测试简单(12 个固定值,无需断言 HSV 范围)

### 4. 排序交互 = **↑↓ 上下箭头按钮**(单步移动)

```dart
// 分类管理页每行:↑ ↓ [编辑] [删除]
Row(children: [
  IconButton(icon: Icon(Icons.keyboard_arrow_up), onPressed: onMoveUp),
  IconButton(icon: Icon(Icons.keyboard_arrow_down), onPressed: onMoveDown),
  IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
  IconButton(icon: Icon(Icons.delete_outline), onPressed: onDelete),
])
```

WHY:
- S02 文档 § 风险表明确说"MVP 用最简 CRUD,排序 + - 按钮"
- 实现简单,无需 ReorderableDragStartListener + 长按手势冲突处理
- 单步移动 N 次可到任意位置,语义清晰(用户知道每次移动多少)
- DAO 层做 sortOrder 原子 swap,不需批量事务
- 测试容易(只测 swap 函数,不需模拟拖拽)

### 5. 删除策略 = **有引用禁用 + 提示**(不靠外键抛错)

```dart
// 删除前 countTransactionsByCategory(id)
// > 0 → 禁用删除按钮 + tooltip "该分类有 N 笔交易引用,无法删除"
// = 0 → 二次确认对话框 → 删除
```

WHY:
- 用户体验优先 — 直接抛外键异常会显示通用 "DatabaseException",对用户无意义
- 禁用 + tooltip 让用户立刻知道"为什么不能删",而非"删失败"
- 引用计数查询放在 DAO 层(@DriftAccessor 加 Transactions 表),不碰 transaction_dao(避免越界)
- 当前不留"软删除" — 一旦禁用就没法再恢复,用户必须新建分类(避免未来误删分类的脏数据)

## 后果

### 正面影响

- iconName 语义澄清,避免后续误读"图标名 = Material codepoint"而强行解析
- emoji picker 自建可测,Coverage 100% 容易达成
- 12 色板足够区分分类(视觉上 10 个默认分类 + 用户新增 ≤ 30 个都不会撞色严重)
- ↑↓ 按钮实现最简,DAO 只暴露一个 swapSortOrder 方法
- 删除策略友好,避免"明明能删但数据库报错"的困惑

### 负面影响 / 风险

- emoji picker 自建需要维护精选列表(后续用户可能嫌 emoji 太少)
  - 缓解:Day 15 模板应用时,允许"更多 emoji"按钮调起系统键盘(留接口,不实现)
- 12 色板饱和度相近,色弱用户可能区分困难
  - 缓解:Tile 中心有 emoji + 名称,颜色只是辅助区分
- 排序需逐次点 ↑↓,分类多时(≥ 20)较繁琐
  - 缓解:Stage 4+ 引入拖拽重排(范围外,本 ADR 不展开)

### 风险缓解

- emoji 数据 const 化,新增 emoji 不需改 widget 代码(只改数据)
- 颜色常量集中,新增颜色只改 _kCategoryPalette
- sortOrder 用 int(非 enum),未来插入新分类自动取 max+1,无需重排所有
- 删除检查统一走 DAO,UI 层不写业务逻辑

## 不可逆性

- iconName 语义确定后,后续所有 emoji 渲染都按 UTF-16 字符串处理,不再尝试 codepoint 解析
- emoji picker 自建后,引入第三方包需开新 ADR
- 12 色板固定后,新增颜色需修改 const 列表 + 测试 + Stage 4+ 重新审视
- 排序交互确定 ↑↓ 后,Stage 4+ 改拖拽需开新 ADR(并行存在,不破坏)

## 关联

- ADR-0013:emoji 优先(本决策的具体实现)
- ADR-0015:Stage 2 写集(本决策在写集内)
- ADR-0018:账户 UI 决策(弹层 + 列表风格参考)
- `lib/data/db/tables/categories.dart`:iconName 注释需更新
- `lib/features/account/application/account_form_provider.dart`:StateNotifier 模式参考

## 验证

- [ ] flutter analyze 0 错误
- [ ] flutter test 全绿(Day 13 145 + Day 14 新增 ≥15 = 160+)
- [ ] category_dao CRUD 4 个测试(getById / update / delete + 引用 / swapSortOrder)
- [ ] emoji_picker widget 测试(6 主题渲染 + 选中回调)
- [ ] category_edit_sheet 测试(emoji picker / 12 色板 / 保存校验)
- [ ] category_management_page 测试(长按菜单 + 上下箭头 + 末尾新增入口)
- [ ] category_form_provider 测试(校验逻辑)
- [ ] Day 16 真机手验场景(创建/编辑/删除/重排/引用保护)