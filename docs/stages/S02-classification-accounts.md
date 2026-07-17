# Stage 2: 分类 & 账户管理

> stage_id: **S02-classification-accounts**
> stage_kind: `IMPLEMENT`
> 风险等级: M(中等,Schema 迁移 + 新 feature 单元)
> 审议方式: `SELF_CHECK`
> 授权状态: ⏳ **DRAFT**(待用户授权 ACTIVE — 基于 ADR-0015 已对齐写集)
> 计划工期: 7 天(Day 11-17,2026-07-17 ~ 2026-07-23)
> 计划工时: ~60 小时(AI 自动 + 决策快)

---

## 🎯 Goal

**完全自定义记账体系**:用户可自由增删改分类(emoji + 名称 + 颜色 + 排序)+ 添加 6 种账户类型(现金/储蓄/信用卡/花呗/网贷/理财)+ 多账户选择器。

承接 S01 ACCEPTED 状态:
- ✅ 主页能记账
- ✅ 长按编辑 / 退款 / 删除
- ✅ 攒攒动画 + 振动反馈

---

## 📋 Context

### 已批准决策

- ✅ ADR-0015:Stage 2 写集(分类 CRUD + 多账户 + 6 种账户类型 schema 扩展)
- ✅ ADR-0012:依赖锁定(沿用 drift / riverpod / flutter 3.44.6)
- ✅ ADR-0013:emoji 优先(分类图标用 emoji,不变)
- ✅ ADR-0014:E2E 暂缓到 Stage 2+ 修复 CI 后

### 当前状态(Stage 1 落地)

- ✅ 10 个 seed 分类(不可编辑,不可新增)
- ✅ 单一"现金"账户(不可切换)
- ✅ 主页交易列表 + 净资产占位卡
- ✅ 真机手验 3 场景全过(2026-07-17)

### 关键依赖

- Drift schema migration v2(已在 ADR-0015 写明字段)
- Riverpod 2.6.1(继续手写 provider,不引 codegen)
- Flutter 3.44.6(macOS 限制下 CI 跑 Build iOS 已稳定)

---

## 🚧 In Scope(7 项必须完成)

### 必须完成

1. **Schema migration v2** — accounts 表加 type / includeInNetWorth / creditLimit / billingDay / dueDay
2. **分类 CRUD UI** — 长按主页分类 → 编辑/重排/删除/新增
3. **多账户选择器** — Step 3 改为下拉账户列表 + 选中高亮
4. **账户 CRUD UI** — "添加账户"按钮实装,弹 account_edit_sheet
5. **6 种账户类型 schema + UI 区分** — type enum + 类型 emoji 头像
6. **信用卡字段** — creditLimit / billingDay / dueDay 仅信用卡账户展示
7. **分类模板(MVP)** — 5 个预设模板(上班族/家庭/学生/极简/自定义空),一键应用

### 不做(明确排除)

- ❌ 信用卡账单生成 / 还款流(S03)
- ❌ 预算管理(S04)
- ❌ 净资产计算(S05,只看 includeInNetWorth 字段)
- ❌ 花呗 / 网贷 / 理财具体业务流(只支持账户类型 + 流水记账)
- ❌ 账户间转账(S04+)
- ❌ 修改 product-design-v4.html

---

## 🚫 Out of Scope

- Stage 3+ 全部功能
- iOS 17+ visionOS / Stage Manager 适配
- 多语言(中文 only)
- 云同步 / 备份(Stage 6)

---

## 📂 允许文件(write-set,基于 ADR-0015)

```
lib/
├── data/db/
│   ├── app_database.dart            (改:schema v2 + migration)
│   ├── tables/
│   │   ├── accounts.dart            (改:新字段)
│   │   └── category_templates.dart  (新建)
│   └── daos/
│       ├── account_dao.dart         (改:CRUD + 按 type)
│       └── category_dao.dart        (改:CRUD + 排序)
├── features/
│   ├── home/
│   │   └── presentation/
│   │       ├── home_page.dart       (改:净资产占位卡加"账户数 X")
│   │       └── widgets/
│   │           └── (新增) account_summary.dart
│   ├── record/                      (改:账户下拉 + 分类管理入口)
│   │   └── presentation/
│   │       ├── record_sheet.dart    (改:Step 3 账户下拉)
│   │       └── widgets/
│   │           ├── account_picker.dart    (改:多账户)
│   │           └── category_grid.dart    (改:长按菜单)
│   ├── (新)category/                (分类管理 feature)
│   │   ├── application/
│   │   │   └── category_form_provider.dart
│   │   └── presentation/
│   │       ├── category_management_page.dart
│   │       └── widgets/
│   │           ├── category_edit_sheet.dart
│   │           └── emoji_picker.dart
│   └── (新)account/                 (账户管理 feature)
│       ├── application/
│       │   └── account_form_provider.dart
│       └── presentation/
│           ├── account_management_page.dart
│           └── widgets/
│               ├── account_card.dart       (新设计,支持 6 类型)
│               └── account_edit_sheet.dart

test/
├── data/db/                         (改:migration 测试 + 新 DAO 测试)
├── features/
│   ├── record/                      (改:下拉账户 widget 测试)
│   ├── (新)category/                (新建:分类管理 widget + provider 测试)
│   └── (新)account/                 (新建:账户管理 widget + provider 测试)

docs/
├── daily/2026-07-18..24.md          (Day 11-17 工作日志)
├── adr/0017-*.md                   (Stage 2 内决策记录,按需 — 0016 已被 Stage 7+ 占用)
└── stages/S02-classification-accounts.md  (本文件)
```

---

## 🎯 Done When

### 功能验收

- [ ] 主页 Step 3 账户下拉,可选 ≥2 个账户
- [ ] 添加账户 → 6 种类型可选 → 字段根据类型动态显示
- [ ] 信用卡账户可填 creditLimit / billingDay / dueDay
- [ ] 长按主页分类 → 编辑 emoji/名称/颜色 → 持久化
- [ ] 新增分类 → 立刻在记账弹层可见
- [ ] 删除分类(无交易引用)→ 消失;有引用 → 禁用并提示
- [ ] 分类模板 5+ 预设可一键应用
- [ ] 旧 Stage 1 数据(单账户 / 10 分类)不丢

### 技术验收

- [ ] Drift schema migration v1 → v2 不破坏数据
- [ ] flutter analyze 0
- [ ] flutter test 全绿(75 + 新增 ≥ 30 用例 = 105+)
- [ ] Build iOS .ipa CI 绿
- [ ] iPhone 真机手验 3+ 场景全过

### 文档验收

- [ ] daily/2026-07-18..24.md(7 天)写完
- [ ] S02 状态改 ACCEPTED + ROA 报告
- [ ] CONTROL_TOWER 派生更新到 S02 = ACCEPTED
- [ ] ADR-0017+(Stage 2 内决策,按需)

---

## ⚠️ 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| Schema migration 破坏数据 | 🟡 中 | 默认值兜底 + 测试覆盖 |
| 6 种账户类型 UI 复杂度 | 🟡 中 | 类型 emoji + 卡片样式区分,功能内聚 |
| 分类删除 / 重排交互 | 🟡 中 | MVP 用最简 CRUD,排序 + - 按钮 |
| Build iOS CI 又卡死 | 🟡 中 | 沿用 G-003 沉淀的 5 个 root cause 修复链 |
| 用户认知负担(6 种类型) | 🟢 低 | 文案引导 + 默认账户类型=现金 |

---

## 🔍 验证矩阵

| 场景 | 命令 / 操作 | 预期 |
|---|---|---|
| 迁移不破坏数据 | `flutter test test/data/db/migration_test.dart` | PASS |
| 分类 CRUD | `flutter test test/features/category/` | 30+ 用例全绿 |
| 账户 CRUD | `flutter test test/features/account/` | 25+ 用例全绿 |
| 下拉账户交互 | `flutter test test/features/record/account_picker_test.dart` | PASS |
| 主页 iPhone 端到端 | 真机 3 场景手验 | PASS |
| CI iOS build | GitHub Actions Build iOS .ipa #28+ | GREEN |

---

## 📅 时间切片(7 天)

- **Day 11 (07-18)**:Schema migration v2 + DAO 测试 + ADR-0017(如有新决策,如 AccountType enum 取值固定)
- **Day 12 (07-19)**:账户 CRUD UI(主页入口 + 弹层 + 6 种类型卡片)
- **Day 13 (07-20)**:多账户选择器(Step 3 下拉) + 信用卡字段
- **Day 14 (07-21)**:分类 CRUD UI(长按菜单 + 编辑弹层 + emoji picker)
- **Day 15 (07-22)**:分类模板(5 预设 + 一键应用)
- **Day 16 (07-23)**:集成测试 + 真机手验 + polish
- **Day 17 (07-24)**:Stage 2 ROA 收尾 + CONTROL_TOWER 更新

---

## 🔄 交接(Handoff)

### Stage 1 → Stage 2 交付物(已验证)

- ✅ Drift schema v1(3 表) + Riverpod ProviderScope + 主页骨架
- ✅ 完整记账闭环(选分类 → 金额 → 账户 → 保存 → 列表)
- ✅ 改 / 删 / 退款三件套
- ✅ 攒攒动画 + 50ms 短振 / 100ms 长振
- ✅ 真机 3 场景手验签字

### Stage 2 准备

- ✅ ADR-0015 写集已对齐
- ⏳ 用户授权 ACTIVE(待 daily 11 拍板"开干")

### Stage 3 准备(结束 Stage 2 后)

- 信用卡账单日 / 还款日本地通知(flutter_local_notifications)
- 信用账户流水归类逻辑(消费 → 信用卡账户)
- 还款流(从储蓄账户 → 信用卡账户)

---

## 📝 备注

### 用户视角的成功标准

**非技术语言描述**:
- "我能创建自己的分类(比如'奶茶'🍵),不只能用现成的"
- "我能添加多个账户(现金 + 招行信用卡),记账时选哪个扣哪个"
- "信用卡账户能填额度,我知道还欠多少"

### 技术视角的成功标准

- Drift schema v2 支持 6 种账户类型 + 5 个新字段
- 主页 Step 3 下拉账户列表(默认选最常用账户)
- 分类管理 UI 完整 CRUD + 排序
- 模板可一键应用 5+ 预设

---

**创建**:2026-07-17
**授权者**:用户(待批准)
**有效期**:2026-07-17 ~ 2026-07-23(7 天)
**base_sha**:Stage 1 ACCEPTED 后的 main(`bfbfa13`)