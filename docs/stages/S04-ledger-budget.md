# Stage 4: 账本 & 预算

> stage_id: **S04-ledger-budget**
> stage_kind: `IMPLEMENT`
> 风险等级: M(中等,业务模型扩展 + 报表计算)
> 审议方式: `SELF_CHECK`
> 授权状态: 📋 **DRAFT**(待 D29 整合装机验后启动实施)
> 计划工期: 6 天(D30-D35,2026-08-13 ~ 2026-08-18)
> 计划工时: ~35 小时

---

## 🎯 Goal

完成**账本切换 + 预算管理闭环**:用户在 v4 §P0-09/10 设计的「分类预算 / 总预算 / 动态日预算」基础上,从单账本扩展到多账本(家庭 / 工作 / 个人),预算按账本 + 分类双维度统计。

承接 S03 ACCEPTED(2026-08-06)+ D25-D29 5 ADR 实施状态:
- ✅ 主页记账闭环(支出/收入/还款/转账/借出/借入)
- ✅ 24 分类完整版(D27 实施)
- ✅ Toggle 字段(D28 实施)
- ✅ 退款 transaction 化(D26 实施)
- 📋 S04 启动前需拍板 ADR-0034 / 0035 / 0036

---

## 📋 Context

### 已批准决策
- ✅ ADR-0026 §12.4 账本表 + §14 实施清单 #3
- ✅ ADR-0027 攒钱计划 5 模式(独立 Stage — S07)
- ✅ ADR-0034 账本切换 UI(W5 拍板)
- ✅ ADR-0035 预算模型:总预算 + 分类预算 + 动态日预算
- ✅ ADR-0036 预算超额提醒(W5 拍板,本地通知暂不做,v1.1 评估)
- ✅ ADR-0015:Stage 2 写集(延续)
- ✅ ADR-0012:依赖锁定(沿用)

### 当前状态(D26 完成)
- ✅ Drift schema v8(accounts +4 + transactions +6 字段占位)
- ✅ 6 类 transaction 完整闭环(支出/收入/还款/转账/借出/借入 + 退款)
- ✅ TransactionType 7 枚举值(expense/income/repayment/transfer/lend/borrow/refund)
- ✅ 24 分类完整版(D27 实施)+ 1 退款分类自动 seed
- ✅ toggle 字段(D28 实施)
- 🔄 D29 整合装机验 5+ 场景(借出 / 借入 / 退款 / toggle / 24 分类)

### 关键依赖
- Drift schema migration v8 → v9(账本表 + 预算表 + 分类预算关联表)— **D26 已声明 v9 留 ADR-0037 部分退款使用**,S04 启动前需评估是否合并 v9 bump
- Riverpod 2.6.1(继续手写 provider,沿用)
- Flutter 3.44.6(沿用,无新依赖)

---

## 🚧 In Scope(W5 实施,6 天)

### 必须完成

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | schema v9:账本表(ledgers)+ 预算表(budgets)+ 分类预算表(category_budgets)| `app_database.dart` + 3 表 | 30 分钟 |
| 2 | LedgerDao + BudgetDao | 新建 `lib/data/db/daos/` | 2 小时 |
| 3 | 账本切换 UI(主页右上角 dropdown)| `lib/features/home/` | 2 小时 |
| 4 | 账本管理页(新增/重命名/删除/排序)| `lib/features/ledger/` | 2.5 小时 |
| 5 | 预算设置页(总预算 + 分类预算配置)| `lib/features/budget/` | 3 小时 |
| 6 | 预算展示(主页底部 widget 显示「今日可用 ¥X / 总预算 ¥Y」)| `lib/features/budget/presentation/widgets/budget_widget.dart` | 1.5 小时 |
| 7 | 预算超限检测 + 主页 snackbar 提醒 | `lib/data/db/daos/budget_dao.dart` | 1.5 小时 |
| 8 | ADR 修订(ADR-0026 §12.4 + ADR-0035 §实施清单)+ v4 §P0-09/10 字面微调(对账本区分) | `docs/adr/0035-*.md` + `product-design-v4.html` | 1 小时 |
| 9 | DAO 测试 + widget 测试 + 装机验 | test/ | 2 小时 |
| **总计** | | | **~16.5 小时(2 天 AI 自动)+ ~18 小时(4 天 UI 复杂)** |

### 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 桌面小组件(WidgetKit) | v1.1 评估 | ADR-0027 暂缓 |
| 预算超额本地通知 | v1.1 评估 | ADR-0036 暂缓 |
| 多人协作账本(共享账本)| v2.0 | 不在本期 |

### SSOT 优先级
- v4 §P0-09/10 是 SSOT(账本 + 预算 UI + 模型)
- ADR-0034/0035/0036 是补充
- 本 Stage 不修改 v4 §52 路线图(路线图走 ROADMAP.md)

---

## 📅 时间切片(W5 详细)

| Day | 日期 | 主题 | 实施内容 | commit |
|---|---|---|---|---|
| Day 30 | 2026-08-13 | schema + DAO | schema v9 + LedgerDao + BudgetDao + 5 DAO 测试 | D30 commit |
| Day 31 | 2026-08-14 | 账本 UI | 账本切换 dropdown + 账本管理页 + widget 测试 4 | D31 commit |
| Day 32 | 2026-08-15 | 预算 CRUD | 预算设置页(总 + 分类)+ BudgetDao 配对 + widget 3 | D32 commit |
| Day 33 | 2026-08-16 | 预算展示 | 主页预算 widget + 超限检测 + snackbar | D33 commit |
| Day 34 | 2026-08-17 | 文档 + IQA | ADR 修订 + v4 同步 + IQA 找 BUG + 修 | D34 commit |
| Day 35 | 2026-08-18 | 装机验 + ROA | iPhone 真机手验 5+ 场景 + CONTROL_TOWER ACCEPTED | ROA 签字 |

> ⚠ **D34 预估 S03 ROA 模式**:实施完成后跑 IQA(independence audit,一般 6-9 medium 修复),修复后 D35 ROA 装机验。

---

## 🚨 暂缓 / 溢出风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| schema v9 同时被 ADR-0037 部分退款 + S04 账本/预算用 → 版本冲突 | 🟡 中 | S04 启动前定 v9 范围(S04 独占 v9 bump,ADR-0037 v1.1 再 bump v10)|
| 预算计算复杂度(分类预算聚合 vs toggle 过滤 vs 退款抵消)| 🟡 中 | DAO 层 SUM + GROUP BY + toggle filter,widget 缓存 |
| 多人协作需求(v2.0 路线图提前) | 🟢 低 | 婉拒,V2.0 才有 |

---

## ⚠️ D26 关联(本阶段在 D26 后启动)

D26 已在 schema v8 加 toggle + 退款 + 借贷 6 字段,**S04 启动前**需准备:

- [x] ~~TransactionType refund 落地~~ (D26 完成)
- [x] ~~refundMoney DAO + 累计校验~~ (D26 完成)
- [x] ~~退款的预算抵消逻辑备注(ADR-0030 §衔接下游 S04 已留:refund 计入预算按原分类预算)~~ (D26 ADR 修订)
- [ ] S04 schema v9 bump 设计稿(W5 启动前 D29 整合装机验回报后拍板)

> S04 v9 bump 必须**不**和 D26 的 v8 字段冲突(v8 已 +10 列,v9 加新表 — 应不冲突)。

---

**最后更新**:2026-08-09(D26 实施 Day 2 启动 S04 write-set prep)
**下次更新**:W5 D30 启动前(D29 整合装机验回报 + 用户拍板 ADR-0034/35/36)
**启动条件**:S04 + ADR-0034/35/36 拍板 + D29 装机验 5 场景回报通过
