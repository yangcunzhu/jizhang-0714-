# ADR-0031:收入分类 8 子类(S02 扩 5→8,基于咔皮图 285)

> 状态:**DRAFT — 待用户拍板**
> 日期:2026-08-06(D23 治理收尾,基于咔皮图 9/27/30/285)
> Stage:**S02 → S03 衔接**(S02 已实施 5 预设,需扩到 8)
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0019 分类 CRUD UI** + **ADR-0020 分类模板** + **ADR-0025 v1.1 backlog** + **产品设计 v4 §3.1**

---

## 背景

S02 阶段(2026-07-25 ~ 2026-08-01)实施了 **5 收入预设分类**(基于自创,没对标咔皮):
1. 工资收入 💰
2. 红包收入 🧧
3. 退款收入 ↩️(待 ADR-0030 改名为「退款」)
4. 投资收益 📈
5. 其他收入 📦

咔皮图 9(7/18 22:25)+ 图 27(7/18 22:25)+ 图 30(7/18 22:25)+ **图 285(7/21 9:38 完整版)** 都显示**咔皮收入分类 = 8 子类**:
1. 职业收入 💳(WAGE CARD)
2. 经营收入 💰
3. 保险理财 🛡️
4. 资金往来 💬
5. 二手买卖 🎁
6. 好运收入 🎁(惊喜)
7. 生活费 💰
8. 其他收入 📦

**对照 S02 5 预设**:
| S02 5 预设 | 咔皮 8 子类 | 关系 |
|---|---|---|
| 工资收入 💰 | **职业收入 💳** | 改名(更通用)|
| 红包收入 🧧 | **好运收入** | 改名 |
| 退款收入 ↩️ | (独立) | 留(ADR-0030 改名「退款」)|
| 投资收益 📈 | **保险理财** | 改名 + 范围缩(去掉股票等) |
| 其他收入 📦 | **其他收入** | 保留 |
| (缺) | **经营收入** | 增 |
| (缺) | **资金往来** | 增(放贷/借入利息等)|
| (缺) | **二手买卖** | 增 |
| (缺) | **生活费** | 增 |

**D23 治理收尾** → 写本 ADR 关闭该差距。

---

## 决策

### 决策 1:DefaultIncomeTemplate 8 分类(seed 一次性)

```dart
// lib/data/db/seeds/default_income_categories.dart(新建)
const defaultIncomeCategories = [
  {
    'name': '职业收入',
    'iconName': '💳',
    'colorValue': 0xFF2196F3,  // 蓝色
    'sortOrder': 1,
  },
  {
    'name': '经营收入',
    'iconName': '💰',
    'colorValue': 0xFF4CAF50,  // 绿色
    'sortOrder': 2,
  },
  {
    'name': '保险理财',
    'iconName': '🛡️',
    'colorValue': 0xFFFF9800,  // 橙色
    'sortOrder': 3,
  },
  {
    'name': '资金往来',
    'iconName': '💬',
    'colorValue': 0xFF9C27B0,  // 紫色
    'sortOrder': 4,
  },
  {
    'name': '二手买卖',
    'iconName': '🎁',
    'colorValue': 0xFF00BCD4,  // 青色
    'sortOrder': 5,
  },
  {
    'name': '好运收入',
    'iconName': '🎉',
    'colorValue': 0xFFE91E63,  // 粉色
    'sortOrder': 6,
  },
  {
    'name': '生活费',
    'iconName': '🛍️',
    'colorValue': 0xFF8BC34A,  // 浅绿
    'sortOrder': 7,
  },
  {
    'name': '其他收入',
    'iconName': '📦',
    'colorValue': 0xFF9E9E9E,  // 灰色
    'sortOrder': 99,  // 最后
  },
];
```

### 决策 2:迁移策略(S02 5 预设 → 8 子类)

| S02 5 预设 | 迁移动作 | 原因 |
|---|---|---|
| 工资收入 | **rename** → 职业收入 | 通用化 |
| 红包收入 | **rename** → 好运收入 | 覆盖更广(红包/抽奖等)|
| 退款收入 | **rename** → 退款(原 transactionId 引用 + 关联 type=refund) | 跟随 ADR-0030 |
| 投资收益 | **rename** → 保险理财 | 范围缩 |
| 其他收入 | **keep** | 保留兜底 |
| (新)| **insert** 经营收入 | 新增 |
| (新)| **insert** 资金往来 | 新增 |
| (新)| **insert** 二手买卖 | 新增 |
| (新)| **insert** 生活费 | 新增 |

**schema v8 migration**:
- `onUpgrade from 7 to 8`:执行 `defaultIncomeCategoriesMigrate()` 函数
- 不删 S02 5 预设(用户可能自定义了 5 预设的名称/icon,改名/合并风险大)
- 改名:`UPDATE categories SET name='职业收入' WHERE name='工资收入' AND type='income'`
- 改名:`UPDATE categories SET name='好运收入' WHERE name='红包收入' AND type='income'`
- 改名:`UPDATE categories SET name='保险理财' WHERE name='投资收益' AND type='income'`
- 改名:`UPDATE categories SET name='退款' WHERE name='退款收入' AND type='income'`(跟随 ADR-0030,改名 + type 改 refund)
- 保留:`其他收入` 不动
- 新增 4 个:用 `INSERT OR IGNORE` 防重复

### 决策 3:DefaultExpenseTemplate 跟随 ADR-0032 扩 16

详见 **ADR-0032**(本会话并行写)+ ADR-0031 决策 4(支出分类图标颜色不冲突)。

### 决策 4:分类模板(用户首次启动)

- 用户首次启动(seed 阶段),**写 8 收入 + 16 支出 = 24 个分类**(ADR-0031 + ADR-0032)
- 覆盖率达 **100%**(咔皮对标)
- 模板名称:DefaultIncomeTemplate(8) + DefaultExpenseTemplate(16)

### 决策 5:记账弹层收入 tab 8 分类完整显示

- D21 已实施 5 收入预设
- D24+ 升级:**8 收入 + 16 支出 完整显示**(覆盖弹层所有 24 分类)
- 主页记账入口**无变化**(弹层渲染所有 8 收入,无折叠)

---

## 不可逆性

| 项 | 永不变更 | 理由 |
|---|---|---|
| DefaultIncomeTemplate = 8 分类 | ✅ | 咔皮对标真源,无回退 |
| Category enum name(分类名) | ✅ | 迁移后已统一(职业收入/经营收入等),用户自定义可保留 |
| 8 分类 icon + color 锁定 | ✅ | UI 渲染依赖,改 icon = 改用户视觉习惯 |
| S02 5 预设 → 8 子类 迁移策略(rename + insert)| ✅ | 不删旧数据,用户自定义保留 |
| 退款分类改名 + type 改 refund | ✅ | 跟随 ADR-0030 |

---

## 后果

### 正面影响
- ✅ 收入分类 100% 覆盖咔皮对标
- ✅ 「职业/经营/资金往来/二手买卖/生活费」5 个新分类覆盖**中小企业主 + 个人经营 + 借贷利息 + 二手交易 + 家庭生活费** 等真实场景
- ✅ 「保险理财」替代「投资收益」更准确(理财 ≠ 投资)
- ✅ 模板 seed 一次性,无后续用户负担

### 负面影响 / 风险
| 风险 | 等级 | 缓解 |
|---|---|---|
| S02 已有的「工资收入」用户自定义(改了 icon/名称)被 rename 覆盖 | 🟡 中 | 迁移策略:**仅当 name 完全匹配「工资收入」时 rename**;否则跳过(rename 条件严格化) |
| 退款分类与 ADR-0030 时序 | 🟡 中 | ADR-0030 + ADR-0031 + ADR-0032 + ADR-0033 同时上 schema v8 migration,本 ADR 包含退款分类 seed 逻辑 |
| 24 分类总图(8+16)过密,记账弹层太挤 | 🟡 中 | 8 收入 / 16 支出全显示,**不折叠**(咔皮对标);小屏适配(`isScrollControlled` 沿用 D21 模式)|

### 衔接下游
- **S04 预算**:8 收入 + 16 支出 = 24 分类预算可设(覆盖精细)
- **S05 净资产仪表盘**:收入分类饼图 8 段(替代 5 段)
- **S07 异常检测**:「好运收入」+ 异常金额 = 可疑;「资金往来」高频 = 风险信号

---

## 实施清单(D24+ 装机验后)

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | 新建 `seeds/default_income_categories.dart` 8 项 | `lib/data/db/seeds/` | 30 分钟 |
| 2 | 迁移函数 `migrateV7ToV8()` 执行 rename + insert | `app_database.dart` | 1 小时 |
| 3 | schema v8 migration_v8_test 4 用例(rename + insert + 重复 idempotent + 数据保护) | `test/data/db/migration_v8_test.dart` | 1 小时 |
| 4 | 记账弹层收入 tab 验证 8 分类全显示 | `record_sheet.dart` widget test | 1 小时 |
| 5 | 主页「+」→「记录」→ 收入 8 分类按钮渲染 | widget test | 30 分钟 |
| 6 | ADR-0031 自审 + 真机验 2 场景(首次启动看到 8 收入 / 旧数据兼容) | 收尾 | 30 分钟 |
| **总计** | | | **~5 小时(1 天)** |

---

## 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 收入二级分类(如「职业收入 → 工资 / 奖金 / 股票 / 期权」)| v1.1 评估 | 8 子类已够用,细分 v1.1 |
| 自定义收入分类排序 | v1.0 已支持(D19 ADR-0019) | 8 预设 sortOrder 锁定,用户可拖 |
| 收入分类 emoji 自定义 | v1.0 已支持(D19 ADR-0019) | 8 预设 emoji 默认,用户可改 |

---

## 验证

- [ ] flutter analyze 0 issues
- [ ] flutter test 314 + 4(migration) + 2(widget) 全绿
- [ ] schema v8 migration_v8_test 4 用例 PASS
- [ ] 首次启动 8 收入分类全显示(seed 正确)
- [ ] 旧 S02 数据兼容(5 预设 rename 成功,用户自定义保留)
- [ ] 弹层收入 tab 8 分类全显示(不折叠)
- [ ] iPhone 真机手验 2 场景(首次启动 / 旧数据迁移)

---

## 关联

- **CLAUDE.md 铁律 1**(极致体验)— 8 收入分类真实场景覆盖
- **CLAUDE.md 铁律 8**(简化≠边界)— 5 → 8 不漏边界
- **ADR-0019** §1 分类 CRUD UI(emoji + 颜色 + sortOrder)
- **ADR-0020** 分类模板(seed + 引用保护)
- **ADR-0025** v1.1 backlog(收入二级分类)
- **ADR-0026** §10 5 大类账户(无直接关系,但 8 收入对应「资金账户」余额)
- **ADR-0032** 支出 16 子类(并行写,8+16=24 完整模板)
- **咔皮图 9/27/30/285**(7/18-7/21 收入 8 子类完整版)
- **产品设计 v4 §3.1** 真实生活场景

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻
**下次复审**:D24+ 实施 + S04 预算接入时
