# ADR-0015: Stage 2 写集决策(分类 & 账户管理)

> 状态:**已接受**
> 日期:2026-07-17(Day 11 开工)
> Stage:**S02-classification-accounts**(Day 11-17)
> 作者:Claude(执行)+ 用户(决策)

---

## 背景

Stage 1(S01-manual-record)已 ACCEPTED(2026-07-17 真机 3 场景全过)。

当前 Stage 1 实现的边界:
- **分类**:10 个 seed emoji 分类(餐饮/交通/购物等),**不可编辑**
- **账户**:单一"现金"账户,**不可添加/切换**

产品方案(`product-design-v4.html` §P0-03 + P0-04)要求:
- **P0-03 分类模板库**:5+ 模板(上班族/家庭/极简等)
- **P0-04 多账户管理**:6 种账户类型(现金/储蓄/信用卡/花呗/网贷/理财)

需要 Stage 2 扩展这两块。

---

## 决策

### Stage 2 范围(写集)

**核心新增**:
1. **分类 CRUD**(emoji + 名称 + 颜色 + 排序 + 类型)
   - 用户可添加/编辑/删除自定义分类
   - 可重排(sortOrder)
   - 软删除(已有交易引用时禁用删除)
2. **多账户选择器**
   - 主页 Step 3 改为账户下拉(不止"现金")
   - 当前选中账户高亮
3. **6 种账户类型 schema 扩展**
   - 现金 / 储蓄 / 信用卡 / 花呗 / 网贷 / 理财
   - 新增字段:type(enum) / includeInNetWorth(bool) / creditLimit(int cents,信用卡) / billingDay / dueDay(信用卡)
4. **账户 CRUD**(添加/编辑/删除账户)
   - 信用卡账户有"额度"+"账单日"+"还款日"
   - 普通账户有"余额"
5. **分类模板**(5+ 预设模板,一键应用)

**Stage 2 不做(明确排除)**:
- ❌ 预算管理(S04)
- ❌ 信用卡账单生成/还款流(S03)
- ❌ 净资产计算(S05)
- ❌ 花呗 / 网贷 / 理财具体业务流(账户类型可建,但流水走"信用账户"通用记账)

### Schema 迁移策略

```dart
// accounts 表新增字段(migration v2)
ALTER TABLE accounts ADD COLUMN type TEXT NOT NULL DEFAULT 'cash';
ALTER TABLE accounts ADD COLUMN include_in_net_worth INTEGER NOT NULL DEFAULT 1;
ALTER TABLE accounts ADD COLUMN credit_limit INTEGER;  -- NULL 表示非信用卡
ALTER TABLE accounts ADD COLUMN billing_day INTEGER;  -- 1-31
ALTER TABLE accounts ADD COLUMN due_day INTEGER;     -- 1-31

// 新表:account_categories(账户-分类关联表,信用卡归类用)
// 新表:category_templates(分类模板定义,Stage 2 后期)
```

**WHY 软迁移**:本地数据库,无用户备份,Schema 直接演进即可。**WHY 不破坏 Stage 1 数据**:`type` 默认 `'cash'`,所有现有账户自动归类"现金"。

### 写集(本 Stage 允许的文件)

```
lib/
├── data/db/
│   ├── app_database.dart        (改:schema v2 + migration)
│   ├── tables/
│   │   ├── accounts.dart        (改:加 type + includeInNetWorth + 信用卡字段)
│   │   └── (新)category_templates.dart
│   └── daos/
│       ├── account_dao.dart     (改:+ add/update/delete + 按 type 查询)
│       └── category_dao.dart    (改:+ add/update/delete/重排)
├── features/
│   ├── home/                    (不变,但需要响应新账户)
│   ├── record/                  (改:账户下拉 + 分类管理入口)
│   └── (新)category/            (新 feature:分类管理 UI)
│       ├── application/
│       │   └── category_form_provider.dart
│       └── presentation/
│           ├── category_management_page.dart
│           └── widgets/
│               ├── category_edit_sheet.dart
│               └── emoji_picker.dart
└── features/(新)account/        (新 feature:账户管理 UI)
    ├── application/
    │   └── account_form_provider.dart
    └── presentation/
        ├── account_management_page.dart
        └── widgets/
            ├── account_card.dart  (替换单一账户卡片)
            └── account_edit_sheet.dart

test/
├── data/db/                     (改:migration 测试 + 新 DAO 测试)
├── features/
│   ├── record/                  (改:下拉账户测试)
│   ├── category/                (新:分类管理 widget 测试)
│   └── account/                 (新:账户管理 widget 测试)
└── integration_test/            (E2E 推迟到 Stage 2+ 修复 CI 后)

docs/
├── daily/2026-07-18..24.md      (Day 11-17 工作日志)
├── adr/0016-*.md               (Stage 2 内决策记录)
└── stages/S02-classification-accounts.md  (Stage 2 ROA 卡)
```

### 不在写集(明确排除)

- ❌ `product-design-v4.html` 修改
- ❌ `pubspec.yaml` 依赖增删(除非新功能必须)
- ❌ `.github/workflows/*.yml`(受 §11 保护)
- ❌ `ios/Runner/Info.plist`
- ❌ `lib/features/credit_card/`(S03 范围)
- ❌ `lib/features/budget/`(S04 范围)
- ❌ 修改 Stage 1 已 ACCEPTED 代码的核心逻辑(只能"扩展"不能"改写")

---

## 后果

### 正面影响

- ✅ 用户可完全自定义记账体系(分类 + 账户都自己造)
- ✅ 信用卡 / 花呗 / 网贷账户支持(为 S03 还款流程铺路)
- ✅ "暂未计算"净资产占位卡可在 Stage 5 替换成真计算
- ✅ 多账户让"转账"概念(S04)有基础

### 负面影响 / 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| Schema migration 破坏 Stage 1 数据 | 🟢 低 | 默认值兜底(现有账户 type='cash') |
| 6 种账户类型混淆(用户认知负担) | 🟡 中 | UI 引导文案 + 类型 emoji 头像区分 |
| 信用卡账户"还款"流误入 Stage 2 | 🟡 中 | write-set 明确排除,只做"账户类型"层 |
| 分类软删除 / 重排的复杂交互 | 🟡 中 | MVP 用最简单 CRUD,排序用 + - 按钮 |

### 衔接下游

- **Stage 3(信用卡 & 还款)**:基于"信用卡账户"字段(creditLimit / billingDay / dueDay)扩展
- **Stage 5(净资产)**:基于 `includeInNetWorth` 字段计算
- **Stage 6(存储 & 快照)**:可基于现有 Drift 加密
- **Stage 7(攒攒)**:不依赖 Stage 2

---

## 关键参考

- ADR-0012(依赖锁定):Stage 2 沿用现有 drift / riverpod 版本
- ADR-0013(emoji):分类仍用 emoji 字符串,不变
- ADR-0014(E2E):Stage 2 E2E 仍 CI 卡死,**写测试但不入 E2E workflow**,待 Stage 2+ 修复 CI 后再加
- `product-design-v4.html` §P0-03 + P0-04 + §分类管理 UI 章节

---

**最后更新**:2026-07-17(Day 11 开工拍板)
**生效日期**:Stage 2 Day 11 起
**下次复审**:Stage 2 ROA 时