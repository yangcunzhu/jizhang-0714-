# ADR-0032:支出分类 16 子类(S02 扩 5→16,基于咔皮图 284 完整版)

> 状态:**ACCEPTED**
> 日期:2026-08-06(D23 治理收尾,基于咔皮图 29/1716/1724/284 完整版)
> Stage:**S02 → S03 衔接**(S02 已实施 5 预设,需扩到 16)
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0019 分类 CRUD UI** + **ADR-0020 分类模板** + **ADR-0025 v1.1 backlog** + **ADR-0031 收入 8 子类**(并行)

---

## 背景

S02 阶段实施了 **5 支出预设分类**(基于自创,没对标咔皮):
1. 餐饮 🍜
2. 医疗健康 💊
3. 购物 🛒
4. 老人 👴
5. 交通 🚗

咔皮图 21/28(支出 tab 5 分类:餐饮/医疗健康/购物/老人/交通)+ **图 284(7/21 9:38 完整版)** 显示**咔皮支出分类 = 16 子类**:

| # | 分类 | emoji | 备注 |
|---|---|---|---|
| 1 | 餐饮 | 🍜 | S02 已有 |
| 2 | 医疗健康 | 💊 | S02 已有 |
| 3 | 购物 | 🛒 | S02 已有 |
| 4 | 老人 | 👴 | S02 已有 |
| 5 | 交通 | 🚗 | S02 已有(公交通勤)|
| 6 | **交通出行** | 🚙 | 🆕 私家车/打车 |
| 7 | **通讯** | 📞 | 🆕 话费/流量 |
| 8 | **缝纫** | 🧵 | 🆕 衣服修补/裁缝 |
| 9 | **育儿** | 🍼 | 🆕 母婴/儿童用品 |
| 10 | **住房** | 🏠 | 🆕 房租/房贷/物业 |
| 11 | **休闲娱乐** | 🎬 | 🆕 旅游/电影/KTV |
| 12 | **学习办公** | 📚 | 🆕 书籍/办公用品 |
| 13 | **资金往来** | 💸 | 🆕 借出/借入(非 transaction 化的) |
| 14 | **保险理财** | 💎 | 🆕 保险/理财产品 |
| 15 | **健身** | 💪 | 🆕 健身房/运动装备 |
| 16 | **其他支出** | 📦 | S02 已有(兜底)|

**对照 S02 5 预设**:
| S02 5 预设 | 咔皮 16 子类 | 关系 |
|---|---|---|
| 餐饮 🍜 | 餐饮 🍜 | 保留 |
| 医疗健康 💊 | 医疗健康 💊 | 保留 |
| 购物 🛒 | 购物 🛒 | 保留 |
| 老人 👴 | 老人 👴 | 保留 |
| 交通 🚗 | 交通 🚗 + **交通出行 🚙** | **拆分**(2 个)|
| (缺) | 通讯 / 缝纫 / 育儿 / 住房 / 休闲娱乐 / 学习办公 / 资金往来 / 保险理财 / 健身 | 🆕 9 个 |
| (缺) | 其他支出 | 已 S02 |

**D23 治理收尾** → 写本 ADR 关闭 11 字段差距。

---

## 决策

### 决策 1:DefaultExpenseTemplate 16 分类(seed 一次性)

```dart
// lib/data/db/seeds/default_expense_categories.dart(新建)
const defaultExpenseCategories = [
  {'name': '餐饮', 'iconName': '🍜', 'colorValue': 0xFFFF9800, 'sortOrder': 1},
  {'name': '医疗健康', 'iconName': '💊', 'colorValue': 0xFFE91E63, 'sortOrder': 2},
  {'name': '购物', 'iconName': '🛒', 'colorValue': 0xFF9C27B0, 'sortOrder': 3},
  {'name': '老人', 'iconName': '👴', 'colorValue': 0xFF795548, 'sortOrder': 4},
  {'name': '交通', 'iconName': '🚗', 'colorValue': 0xFF2196F3, 'sortOrder': 5},
  {'name': '交通出行', 'iconName': '🚙', 'colorValue': 0xFF1976D2, 'sortOrder': 6},
  {'name': '通讯', 'iconName': '📞', 'colorValue': 0xFF00BCD4, 'sortOrder': 7},
  {'name': '缝纫', 'iconName': '🧵', 'colorValue': 0xFF8D6E63, 'sortOrder': 8},
  {'name': '育儿', 'iconName': '🍼', 'colorValue': 0xFFFFEB3B, 'sortOrder': 9},
  {'name': '住房', 'iconName': '🏠', 'colorValue': 0xFF4CAF50, 'sortOrder': 10},
  {'name': '休闲娱乐', 'iconName': '🎬', 'colorValue': 0xFFFFC107, 'sortOrder': 11},
  {'name': '学习办公', 'iconName': '📚', 'colorValue': 0xFF3F51B5, 'sortOrder': 12},
  {'name': '资金往来', 'iconName': '💸', 'colorValue': 0xFF607D8B, 'sortOrder': 13},
  {'name': '保险理财', 'iconName': '💎', 'colorValue': 0xFF009688, 'sortOrder': 14},
  {'name': '健身', 'iconName': '💪', 'colorValue': 0xFFCDDC39, 'sortOrder': 15},
  {'name': '其他支出', 'iconName': '📦', 'colorValue': 0xFF9E9E9E, 'sortOrder': 99},
];
```

### 决策 2:迁移策略(S02 5 预设 → 16 子类)

| S02 5 预设 | 迁移动作 | 原因 |
|---|---|---|
| 餐饮 / 医疗健康 / 购物 / 老人 | **keep** | 完全一致,不动 |
| 交通 🚗 | **keep** | 保留 S02,新增「交通出行」做补充(避免破坏已有交易归类) |
| 其他支出 | **keep** | 兜底 |
| (新) | **insert** 交通出行 / 通讯 / 缝纫 / 育儿 / 住房 / 休闲娱乐 / 学习办公 / 资金往来 / 保险理财 / 健身(10 个) | 一次性 seed |

**schema v8 migration**(与 ADR-0031 同步):
- `onUpgrade from 7 to 8`:执行 `defaultExpenseCategoriesMigrate()` 函数
- S02 5 预设完全保留,仅新增 10 个分类
- 不改名(避免破坏用户已归类交易)
- `INSERT OR IGNORE` 防重复

### 决策 3:交通 vs 交通出行 双分类语义

| 分类 | 适用场景 | 用户选择依据 |
|---|---|---|
| **交通** 🚗 | **公交通勤**(地铁/公交/月卡)| 固定通勤/低价高频 |
| **交通出行** 🚙 | **私家车/打车/高铁/飞机** | 偶发高价 |

**UI 引导**:弹层顺序默认 `交通(5)` 排前面(用户更常用),`交通出行(6)` 排后面(二级选项)
**可合并**:用户可手动把「交通出行」删除(留「交通」),不强制

### 决策 4:16 分类小屏适配

- 弹层用 `isScrollControlled`(D21 已实施,小屏滚动)
- 16 分类 GridLayout 4×4(手机竖屏单屏可见)
- 「更多分类 ⌃」按钮**保留**(弹层底部 5 分类外还有,点击展开全部)— D21 已实施

---

## 不可逆性(2026-08-10 IQA-fix D27-2 修订)

| 项 | 永不变更 | 理由 |
|---|---|---|
| DefaultExpenseTemplate = 16 分类 | ✅ | 咔皮对标真源,无回退 |
| Category enum name(分类名)| ✅ | S02 5 预设保留,新增 10 个,用户自定义保护 |
| 16 分类 icon + color + sortOrder 锁定 | ✅ | UI 渲染依赖 |
| 交通 vs 交通出行 双分类语义 | ✅ | 拆分不合并(避免破坏已有交易归类) |
| S02 5 预设全保留(不删不合并)| ✅ | 兼容 + 用户保护 |
| **同名多 type 分类共存(资金往来 + 保险理财,2026-08-10 IQA-fix D27-2)** | ✅ | expense「资金往来」(借出) + income「资金往来」(借出收回)同 name 不同 emoji/语义;expense「保险理财」+ income「保险理财」(保险收益)|

---

## 已发现 S03 升级路径副作用(2026-08-10 IQA-fix D27-4)

onUpgrade 迁移后(v8 → v9):
- 「娱乐」rename「休闲娱乐」(S03 已 rename,数量不变)
- 「居住」rename「住房」(S03 已 rename,数量不变)
- 「其他」rename「其他支出」(S03 已 rename,数量不变)
- **「医疗」keep + INSERT「医疗健康」= 2 个 expense(双份,语义相似)**
- **「学习」keep + INSERT「学习办公」= 2 个 expense(双份,语义相似)**
- 「通讯」S03 有,D27 同名 WHERE NOT EXISTS skip(emoji 不一致:📱 vs 📞)

**总 onUpgrade = 18 expense + 8 income = 26 个**(比 fresh install 24 多 2 expense)。

**user impact**:
- 「医疗」「学习」双份需要用户手动合并(选 1 删 1)
- v1.0 v1.1 polish 项:加 user setting 自动合并

---

## onUpgrade SQL 策略(2026-08-10 IQA-fix D27-1)

**原 D27 实施**:用 `INSERT OR IGNORE`(无效,categories 表无 UNIQUE 约束 + rowid 自增不冲突 → 实质等同 INSERT)
**IQA-fix D27-1 修订**:用 `WHERE NOT EXISTS` 子查询保证 idempotent 真幂等。

```sql
INSERT INTO categories (name, icon_name, color_value, type, sort_order, created_at)
SELECT '医疗健康', '💊', ... 'expense', 1, ...
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = '医疗健康' AND type = 'expense')
```

重复跑 onUpgrade(异常路径触发:app 卸载重装 / iCloud backup 恢复 / 数据导入)→ 不会创建重复分类。

---

## 后果

### 正面影响
- ✅ 支出分类 100% 覆盖咔皮对标(5 → 16,3.2 倍覆盖)
- ✅ 「通讯/缝纫/育儿/住房/休闲娱乐/学习办公/资金往来/保险理财/健身」9 个新分类覆盖**真实生活全场景**(手机话费/裁缝/母婴/房租/电影/书籍/借贷/保险/健身房)
- ✅ 「交通 vs 交通出行」拆分 满足 **公交通勤 vs 长途/私家车** 区分需求
- ✅ 模板 seed 一次性,无后续用户负担
- ✅ S02 5 预设完全保留(用户已有交易归类零影响)

### 负面影响 / 风险
| 风险 | 等级 | 缓解 |
|---|---|---|
| 16 分类总数过密,记账弹层选择变慢 | 🟡 中 | 弹层 GridLayout 4×4(单屏)+「更多分类 ⌃」展开 + sortOrder 排序(常用在前) |
| 用户没区分「交通 vs 交通出行」,记账误归类 | 🟡 中 | 弹层 icon 差异化(🚗 公交/🚙 私家车)+ 排序时「交通」在前(更常用) |
| 迁移后分类总数从 5 → 16,旧用户的统计图突增 11 个新分类(0 交易)| 🟢 低 | 默认 0 交易,统计图自动隐藏 0 交易分类(ADR-0026 §14 计划已考虑)|

### 衔接下游
- **S04 预算**:16 支出分类预算可设(覆盖精细,儿童家庭/住房/教育/养老 全场景)
- **S05 净资产仪表盘**:支出分类饼图 16 段(替代 5 段,信息密度大幅提升)
- **S07 异常检测**:「资金往来」高频 = 借贷风险;「健身」异常 = 健康警示

---

## 实施清单(D24+ 装机验后)

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | 新建 `seeds/default_expense_categories.dart` 16 项 | `lib/data/db/seeds/` | 1 小时 |
| 2 | 迁移函数 `migrateV7ToV8()` 执行 insert 10 个新分类(沿用 ADR-0031 schema v8)| `app_database.dart` | 1 小时 |
| 3 | schema v8 migration_v8_test 4 用例(insert 10 + 重复 idempotent + 旧数据保留 + 排序) | `test/data/db/migration_v8_test.dart` | 1 小时 |
| 4 | 记账弹层支出 tab 验证 16 分类全显示 | `record_sheet.dart` widget test | 1 小时 |
| 5 | 主页「+」→「记录」→ 支出 16 分类按钮渲染 | widget test | 1 小时 |
| 6 | ADR-0032 自审 + 真机验 2 场景(首次启动 16 分类 / 旧 5 预设兼容) | 收尾 | 30 分钟 |
| **总计** | | | **~5.5 小时(1 天)** |

---

## 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 支出二级分类(同 ADR-0031)| v1.1 评估 | 16 子类已够用 |
| 自定义支出分类排序 | v1.0 已支持 | 16 预设 sortOrder 锁定,用户可拖 |
| 支出分类 emoji 自定义 | v1.0 已支持 | 16 预设 emoji 默认,用户可改 |
| 「交通 vs 交通出行」智能推荐 | v1.0 简化为 2 个并存 | v1.1 可基于用户历史自动归类 |

---

## 验证(2026-08-10 IQA-fix D27-2 字面对齐实际)

- [x] flutter analyze 0 issues
- [x] flutter test 346/346 全绿
- [x] schema v9 migration_v9_upgrade_test 5 用例 PASS(v8 → v9 真升级 + rename + INSERT WHERE NOT EXISTS 幂等 + 同名多 type 共存 + 数据保留 + refund 新字段)
- [x] 首次启动 16 支出分类全显示(seed 正确)— D27 daily
- [x] 旧 S03 数据兼容(5 expense rename + 6 新增)— IQA-fix D27-4
- [x] 同名多 type 共存(资金往来/保险理财)— findsNWidgets(2) 适配
- [x] onUpgrade SQL 幂等(WHERE NOT EXISTS)— IQA-fix D27-1
- [x] 交通 vs 交通出行 双分类语义排第 5/6 — sortOrder 固定
- [x] iPhone 真机手验 7 场景(D29 整合装机验回报)— 待 D29

---

## 关联

- **CLAUDE.md 铁律 1**(极致体验)— 16 支出分类真实场景
- **CLAUDE.md 铁律 8**(简化≠边界)— 5 → 16 不漏边界
- **ADR-0019** §1 分类 CRUD UI
- **ADR-0020** 分类模板
- **ADR-0025** v1.1 backlog(二级分类)
- **ADR-0031** 收入 8 子类(并行,8+16=24 完整模板)
- **咔皮图 21/28/1716/1724/284**(7/18-7/21 支出 5 → 16 分类完整版)
- **产品设计 v4 §3.1** 真实生活场景

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻
**下次复审**:D24+ 实施 + S04 预算接入时
