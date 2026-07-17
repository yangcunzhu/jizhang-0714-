# ADR-0020:Stage 2 分类模板设计决策

## 状态

已接受 — Day 15(2026-07-29)

## 背景

Stage 2 Day 15 实施分类模板(5 预设 + 一键应用)前,3 个 UX / 数据决策需要固定,否则实现路径发散:

1. **应用策略**:用户点「应用模板」时,如何处理现有分类?
2. **引用保护**:模板应用涉及删旧分类时,遇到「有交易引用」的老分类怎么办?
3. **模板粒度**:5 个预设模板(上班族/家庭/学生/极简/自定义空)各自带多少个分类?

3 个决策相互关联(应用策略 → 引用保护的处理逻辑;模板粒度 → seed 数据量),合并到一个 ADR,符合 Day 14 ADR-0019 同模式。

## 决策

### 1. 应用策略 = **混合(弹层让用户每次选「覆盖 / 追加」)**

```dart
// 用户点「应用模板」卡片 → 弹策略选择层
// 选项 A:覆盖(删旧 + 插新)
// 选项 B:追加(只插新,跳过重复)
// WHY 默认选「覆盖」:大多数用户首次用模板是从零起步,推荐更直觉的语义。
```

WHY:
- 单选「覆盖」会强制删用户已建分类,破坏性大,违背"产品对用户温柔"原则
- 单选「追加」会让分类越用越多,失去模板"重新规划"的本意
- 混合让用户在两种场景(首次 vs 迭代)都能拿到合适语义,UX 仅多 1 个 tap
- 实现复杂度可控(DAO 接受 enum 参数 + UI 多一层 dialog),不引新依赖
- 与 Day 14「引用计数禁用删除」的 UX 一脉相承 — 都是"危险操作前先确认"

### 2. 引用保护 = **保留跳过(应用日志)**

```dart
// 「覆盖」模式:
//   1. 取所有现有分类 → countTransactionsByCategory(c.id) for each
//   2. 引用计数 == 0 的分类 → 删除
//   3. 引用计数 > 0 的分类 → 保留(跳过)
//   4. 插入模板分类(去重 name + iconName)
//   5. 返回 ApplyResult(保留数 / 删除数 / 插入数),UI toast
//
// 「追加」模式:
//   - 不删任何分类
//   - 插入模板分类(去重 name + iconName)
//   - 无引用保护需要(根本不删)
```

WHY:
- 「保留跳过」比「整个禁用」友好 — 用户已有交易数据时仍能享受模板补全
- 「保留跳过」比「强制迁移」简单 — 不弹迁移助手,避免 Day 15 工作量爆炸(目标 6h)
- 应用后 toast「已保留 N 个有引用分类」,用户清楚知道发生了什么
- 与 ADR-0019 §5「删除有引用禁用」一致 — 都走 `countTransactionsByCategory` 判断
- 模板应用的事务在 DAO 层(transaction {}),中间任何步骤失败回滚

### 3. 模板粒度 = **差异化(5 ~ 12 个)**

| 模板 | emoji | 分类数 | 定位 |
|---|---|---|---|
| 上班族 | 👔 | 12 | 全场景,通用支出 + 收入 |
| 家庭 | 👨‍👩‍👧 | 10 | 家庭日常,加孩子/医疗 |
| 学生 | 🎓 | 8 | 学习生活,精简 |
| 极简 | ✨ | 5 | 只保留核心,刻意少 |
| 自定义空 | 📝 | 0 | 空模板,提示手动添加 |

WHY:
- 差异化体现每个模板的语义定位(用户能"看出区别")
- 上班族 12 = 与 Stage 1 seed 默认分类数一致(平滑过渡)
- 极简 5 = 给"只想要最少分类"的用户一个出口
- 自定义空 0 = 给"我就要全手动"的用户一个出口
- 全部统一 12 会让"极简"语义不复存在(用户不会选"极简"然后看 12 个)
- 分类数差异(5/8/10/12/0)足够用户感知"风格不同"

## 后果

### 正面影响

- 应用策略混合让首次用户 + 迭代用户都能拿到合适语义
- 引用保护保留跳过 = 用户已有数据无损,模板可放心试
- 差异化让 5 个模板语义清晰,选哪个都"看得出来"
- 事务保证模板应用是原子操作(中间失败回滚)
- 与 Day 14 ADR-0019 的引用计数逻辑一脉相承,不引新代码模式

### 负面影响 / 风险

- 混合策略让 applyTemplate 入参 = enum(API 复杂度 +1),但收益明显
- 保留跳过会让"覆盖"语义不完全(用户预期全删,实际保留部分),需要 toast 明确告知
- 差异化模板数据需要逐个维护(seed 代码量 +30 行),但 seed 是一次性成本
- 模板应用可能产生重复分类(模板 A 已应用 → 模板 B 追加时去重),需要去重逻辑

### 风险缓解

- DAO 接受 `TemplateApplyMode { overwrite, append }` 强类型 enum,避免传错
- ApplyResult 数据类返回(保留 / 删除 / 插入 / 跳过重复),UI 可视化反馈
- 模板分类插入前用 `name + iconName` 双重去重,避免重复
- seed 数据用 const list,代码即文档,后续调整直接改 seed
- 模板表稳定 schema(id / code / name / description / emoji),加新模板只插数据不改 schema

## 不可逆性

- 决策 #1「混合策略」确定后,applyTemplate API 形态固定;改单选策略需开新 ADR
- 决策 #2「保留跳过」确定后,模板应用默认不删有引用分类;改"强制迁移"需开新 ADR + 弹层 UI
- 决策 #3「差异化」确定后,5 个模板的分类数固定;改"全统一"需重新设计 seed
- 模板表 schema(id / code / name / description / emoji)固定后,加字段需 migration

## 关联

- ADR-0015:Stage 2 写集(本决策在写集内 — `category_templates.dart`)
- ADR-0019:分类 CRUD UI(沿用引用计数逻辑 ADR-0019 §5)
- ADR-0017:账户 UI(账户卡片风格参考)
- `lib/data/db/tables/category_templates.dart`:新表 schema
- `lib/data/db/app_database.dart`:schemaVersion 2 → 3 + onUpgrade v2→v3
- `lib/data/db/daos/category_template_dao.dart`:新增 applyTemplate 方法
- `lib/features/category/application/category_template_provider.dart`:Riverpod provider
- `lib/features/category/presentation/category_template_page.dart`:UI

## 验证

- [ ] flutter analyze 0 错误
- [ ] flutter test 全绿(Day 14 182 + Day 15 新增 ≥ 15 = 200+)
- [ ] category_template_dao CRUD 测试(getAllTemplates / getTemplateCategories / applyTemplate 覆盖 / applyTemplate 追加)
- [ ] 引用保护测试(覆盖模式有引用保留 + 无引用删除)
- [ ] 事务回滚测试(applyTemplate 中间失败不污染数据)
- [ ] category_template_provider 测试(策略选择 / 应用状态)
- [ ] category_template_page 测试(5 模板卡片渲染 + 应用弹层)
- [ ] Day 16 真机手验场景(选模板 + 覆盖/追加 + 引用保护 toast)