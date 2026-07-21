# CONTROL_TOWER.md — 项目控制塔

> 状态:`DERIVED / DO NOT EDIT / NOT_SSOT`
> 创建:2026-07-14
> 最后派生:**2026-08-06**(S03 ROA 签字 + ACCEPTED + D23 daily + 8 文档同步 + 65 张图整理)

⚠️ **本文件由 git log + daily/ + stages/ + 实际代码 + 运行证据派生。状态冲突时显示 UNKNOWN/CONFLICT。**

---

## 1️⃣ 总体介绍

**项目**:iOS 自用记账 App《审计官》

**用户结果**:在 iPhone 上流畅、安全、可长期使用地进行个人记账、预算管理、信用卡管理,并通过 AI 攒攒 + RPG 化机制让记账变得可持续。

**当前健康**:
- ✅ Stage 0 ROA 完成(2026-07-16)
- ✅ Stage 1 ACCEPTED(2026-07-17)
- ✅ Stage 2 ACCEPTED(2026-08-01 真机 4 场景全过签字)
- ✅ **Stage 3 ACCEPTED**(2026-08-06 真机 3 场景全过 + 治理收尾)
- 📋 Stage 4 账本 & 预算(待启动)

**派生依据**:
- `git log --oneline -10`:远程 main 最新 commit `6888552`(D22 真机验 3 修复已 push)
- `lib/` + `test/` + `integration_test/`:Drift schema v7(TransactionType lend/borrow + 借贷 transaction 化 4 列)+ 314 测试(原 232 + D18 +5 + D20 +12 + D21 +26 + D22 +11)
- `docs/validation/audit-S03-2026-08-06.md`:S03 ROA 报告,8 大项全过
- `docs/daily/2026-08-06.md`:D23 daily(装机验回报 + 治理收尾 + 65 张图整理)
- `docs/adr/0028-s03-scope-expansion-and-debt-transactionization.md`:S03 范围扩写 + 借贷业务流程独立化 + pubspec §11 例外授权
- `docs/audit/2026-08-06-doc-and-code.md`:深度审计 PASS
- GitHub Actions:Build iOS .ipa 公开仓库后无限额度,沿用 S03 build 链

---

## 2️⃣ 路线位置

```
Milestone v1.0.0 (MVP 上线)
└── Wave W1-W8
    ├── Stage 0: 环境验证 (S00)         ✅ ACCEPTED (2026-07-16)
    ├── Stage 1: 手动记账 (S01)         ✅ ACCEPTED (2026-07-17)
    ├── Stage 2: 分类 & 账户 (S02)      ✅ ACCEPTED (2026-08-01)
    ├── Stage 3: 信用卡 & 还款 (S03)    ✅ ACCEPTED (2026-08-06)
    ├── Stage 4: 账本 & 预算 (S04)      📋 PLAN
    ├── Stage 5: 净资产 & 仪表盘 (S05)  📋 PLAN
    ├── Stage 6: 存储 & 快照 (S06)      📋 PLAN
    ├── Stage 7: 攒攒 & 异常 (S07)      📋 PLAN
    └── Stage 8: 上线验收 (S08)          📋 PLAN
```

**当前位置**:Stage 3 = ✅ **ACCEPTED**(2026-08-06 真机手验 3 项全过)
**下一站**:Stage 4 账本 & 预算 启动(待 8 个 ADR 0029-0036 拍板 + 写集扩展)

**授权终点**:S08 完成 → `READY_FOR_OWNER_ACCEPTANCE`

---

## 3️⃣ 授权边界

### ✅ 当前允许(S03 ACTIVE,D22 完成 2026-08-05,治理收尾 2026-08-06)

**代码层(S03 write-set,D18-D22 实际)**:
- 读取所有 `docs/` 文件 + `product-design-v4.html`
- 写入 `lib/data/db/`(app_database / tables / daos — 已扩写 5 大类 × 23 子类 + 5 类 transaction)
- 写入 `lib/features/account/`(account_card / account_edit_sheet / account_form_provider — 5 大类 UI 重做)
- 写入 `lib/features/repayment/`(还款流 — D19-D20)
- 写入 `lib/features/transfer/`(转账流 — D21 新建)
- 写入 `lib/features/lend/presentation/`(LendRecordPage 全屏借贷记账 — D22 新建)
- 写入 `lib/features/borrow/presentation/`(BorrowRecordPage 全屏借贷记账 — D22 新建)
- 写入 `lib/features/home/presentation/home_page.dart`(「+」5 入口聚合菜单 — D21)
- 写入 `lib/main.dart`(localizationsDelegates + locale — D22)
- 写入 `test/data/db/` + `test/features/`(migration_v4-v7 / transfer / lend / borrow / repayment 测试)
- 写入 `integration_test/`(S03 E2E 沿用 bootContainer 模式)

**文档层(S03 治理收尾 P0-P3,2026-08-06)**:
- 写入 `docs/adr/0028-*.md`(S03 范围扩写 + 借贷业务流程独立化 + pubspec §11 例外授权)
- 写入 `docs/adr/0026-*.md`(§6/§8 净资产公式删借贷 SUM 项 + §12.1/§12.3 加注借贷 transaction 化 + §1 主页设计加注 D21「5 入口聚合菜单」)
- 写入 `docs/adr/0024-*.md`(§实施清单加注「作废 — D21/D22 已迁移 lendMoney/borrowMoney + transferMoney」)
- 写入 `docs/adr/0022-*.md`(§1/§3 表格扩到 5 类 transaction)
- 写入 `docs/CONTROL_TOWER.md`(本文件全重写)
- 写入 `docs/stages/S03-credit-card-repayment.md`(§In Scope + §时间切片)
- 写入 `docs/PLAN.md`(§S02/§S03 任务清单同步)
- 写入 `docs/ROADMAP.md`(P0-04 改「5 大类 × 23 子类」)
- 写入 `docs/daily/2026-08-04.md` + `2026-08-05.md`(commit SHA 补填)
- 写入 `docs/governance/scripts.md`(加注「话术库,非 Stage 生命周期」)
- 写入 `docs/audit/2026-08-06-doc-and-code.md`(本会话深度审计)

### ❌ 绝不自动做

- 修改 `product-design-v4.html`(除非用户明确要求)
- 修改 `pubspec.yaml` 依赖版本(受 CLAUDE.md §11 保护,**S03 已例外授权 flutter_localizations + intl 0.20.2,详 ADR-0028 §3**)
- 修改 `.github/workflows/*.yml`(受 §11 保护)
- 修改 `ios/Runner/Info.plist`(受 §11 保护)
- 修改 `.gitignore`(受 §11 保护,需走 DR)
- 删除任何已创建文件
- 提交 git commit / push(除非用户明确授权)
- 访问 Apple ID / 付费操作
- 写 S04+ 范围的代码(超出当前授权)

### 🛑 何时停止

- 用户提出新需求但超出 v1.0 范围
- 关键依赖(Flutter / drift / riverpod)出现问题
- 连续 3 个 Stage 未达标
- 时间预算超期 20%

---

## 4️⃣ 结果状态

| 功能 | 状态 | 证据 | 验收 |
|---|---|---|---|
| v4 完整方案 | ✅ DONE | product-design-v4.html(184 KB)| 已审计 |
| 开发文档体系 | ✅ DONE | docs/ 完整结构 + governance/ + templates/ | 已审计 |
| 8 周主计划 | ✅ DONE | PLAN.md | 已批准 |
| 完整路线图 | ✅ DONE | ROADMAP.md | 已批准 |
| Stage 0 ROA | ✅ ACCEPTED | Hello World + Runner.ipa 真机装机 | 2026-07-16 |
| Stage 1 ROA | ✅ ACCEPTED | iPhone 16 Pro Max 真机手验 3 场景签字 | 2026-07-17 |
| Stage 2 ROA | ✅ ACCEPTED | 自审 17 项 16 项已绿 + 真机 4 场景签字 | 2026-08-01 |
| Stage 3 D18 | ✅ DONE | schema v4 + TransactionType 加 repayment + 5 tests | D18 commit(派生)|
| Stage 3 D19 | ✅ DONE | transferRepayment DAO + ADR-0022/0023 + 余额联动 | D19 commit(派生)|
| Stage 3 D20 | ✅ DONE | 还款流 UI 4 收款类型 + 网贷期数 + ADR-0024/0025/0026 + schema v5 + 主页提醒 + 12 tests | `401e7ce` `ec2d83c` `8c3f21a` |
| Stage 3 D21 | ✅ DONE | 5 大类 × 23 子类 schema v6 + 转账流 + 主页 5 入口聚合菜单 + 26 tests | `ce11073` |
| Stage 3 D22 | ✅ DONE | 借贷业务流程独立化(schema v7 + lendMoney/borrowMoney + Lend/BorrowRecordPage)+ 日期 locale + 转账去过滤 + 11 tests | `6888552` |
| Stage 3 ROA | ✅ ACCEPTED | 装机验 3 项全过 + 治理收尾 + 65 张图整理 + 8 ADR(0021-0028) | 2026-08-06 |
| 5 ADR 实施期 D25 | ✅ DONE | ADR-0029 借贷字段修补 + schema v8 整合 + 6 Medium IQA fix + 329 tests | `3b1fda8` `b02bd77` `2a5f3db` |
| 5 ADR 实施期 D26 决策准备 | ✅ DONE | v4 §P0-05 接受 ADR-0030 + 删 D9 submitAsRefund + actions_sheet 改 2 action(假完成注释) | `6b1fd67` |
| 5 ADR 实施期 D26 主体 | ✅ DONE | ADR-0030 退款 transaction 化 + ADR-0037 DRAFT + SSOT 治理 + DetailPage/RefundSheet/tile/grid 全套 + 337 tests | `ea893f6` |
| D27 / D28 / D29 | 📋 待实施 | 24 分类完整 + toggle + 整合装机验 | (本表派生)|
| v1.0.0 上线 | ❌ NOT_STARTED | - | - |

### Stage 3 D18-D22 进度

| Day | 日期 | 主题 | 状态 | commit |
|---|---|---|---|---|
| Day 18 | 2026-08-01 | schema migration v4 + TransactionType 加 repayment + 5 tests | ✅ DONE | (派生)|
| Day 19 | 2026-08-02 | 还款流 DAO + ADR-0022 余额联动 + 12 tests | ✅ DONE | (派生)|
| Day 20 | 2026-08-03 | 还款流 UI 4 收款类型 + 网贷期数 + 主页提醒 + ADR-0024/0025/0026 + schema v5 + 12 tests | ✅ DONE | `401e7ce` `ec2d83c` `8c3f21a` |
| Day 21 | 2026-08-04 | 5 大类 × 23 子类 schema v6 + transferMoney + 主页 5 入口聚合菜单 + 26 tests | ✅ DONE | `ce11073` |
| Day 22 | 2026-08-05 | 借贷业务流程独立化 schema v7 + lendMoney/borrowMoney + Lend/BorrowRecordPage + 日期 locale(pubspec §11 例外)+ 转账去过滤 + 11 tests | ✅ DONE | `6888552` |
| Day 23 | 2026-08-06 | **真机装机验 3 项全过(用户回报) + S03 ROA 签字 + 治理收尾(ADR-0028 + 9 文档同步 + 深度审计) + 65 张咔皮图整理** | ✅ **DONE** | (本会话派生)|
| Day 25 | 2026-08-08 | ADR-0029 借贷字段修补 + schema v8 整合 + 6 Medium IQA fix | ✅ DONE | `3b1fda8` `b02bd77` `2a5f3db` |
| Day 26 决策准备 | 2026-08-08 | v4 §P0-05 接受 ADR-0030 + D9 submitAsRefund 撤回 + actions_sheet 改 2 action | ✅ DONE | `6b1fd67` |
| Day 26 主体 | 2026-08-09 | ADR-0030 退款 transaction 化 + ADR-0037 DRAFT + TransactionDetailPage/RefundSheet + 主页短按进详情 + 治理决策翻转(用户拍 Q3=B/Q4=α2/Q1/Q2) | ✅ DONE | `ea893f6` |
| Day 27 / 28 / 29 | 2026-08-10 ~ 12 | 24 分类完整 + toggle + 整合装机验 | 📋 TODO | - |

> ⭐ **S03 全部完成,提前 1 天到 D23**(原计划 D24 ROA 签字)。Stage 3 = **ACCEPTED**,Stage 4 账本 & 预算 启动条件就位。

### Stage 3 累计 commit 数

- D18-D20 阶段开发:~5 个 commit(`401e7ce` `ec2d83c` `8c3f21a` + 派生)
- D21 阶段开发:`ce11073`
- D22 阶段开发:`6888552`
- **D23 治理收尾**:本会话 ~10 个 docs commit(ADR-0028 + 9 文档同步)
- **总计**:~13+ 个 commit,Stage 3 全部基于 S02 ACCEPTED 后的 main(`bfbfa13`)派生

---

## 5️⃣ 当前任务树(IQA-fix C-IQA-4 2026-08-09 重写)

> **状态**:S03 ACCEPTED + 5 ADR 实施期 D25/D26 完成 + D27-D29 待做 + D29 整合装机验。
> 本节为手写任务树(SSOT 派生一部分;actual commit 由 git log 派生)。

### 已完成 Task(Stage 3 — S03 ACCEPTED 2026-08-06)

- T-S03-D18-01~05:schema v4 + TransactionType repayment + 5 tests
- T-S03-D19-01~04:transferRepayment DAO + ADR-0022 余额联动 + 12 tests
- T-S03-D20-01~08:还款流 UI 4 收款类型 + 网贷期数 + 主页提醒 + ADR-0024/0025/0026 + schema v5 + 12 tests
- T-S03-D21-01~03:5 大类 × 23 子类 schema v6 + transferMoney + 主页 5 入口聚合菜单 + 26 tests
- T-S03-D22-01~04:借贷业务流程独立化 schema v7 + lendMoney/borrowMoney + Lend/BorrowRecordPage + 日期 locale + 转账去过滤 + 11 tests
- T-S03-D23:真机装机验 3 项全过 + S03 ROA 签字 + 治理收尾(ADR-0028 + 9 文档同步 + 深度审计) + 65 张咔皮图整理

### 已完成 Task(5 ADR 实施期 Day 25-26/5)

- T-D25:ADR-0029 借贷字段修补 + schema v8 整合(accounts +4 + transactions +6)+ 6 Medium IQA fix + 329 tests + commit `3b1fda8` `b02bd77` `2a5f3db`
- T-D26 决策准备:refactor(s03) v4 §P0-05 接受 ADR-0030 + 删 D9 submitAsRefund + actions_sheet 改 2 action(假完成 IQA C7)+ commit `6b1fd67`
- T-D26 主体:feat(s03) ADR-0030 退款 transaction 化 + TransactionDetailPage / RefundSheet / tile 视觉差异化 / actions_sheet isRefunded 一致 + 9 DAO + 4 widget tile + 1 migration = 337 tests + commit `ea893f6`
- T-D26 派生:docs(control-tower) D26 主体状态更新 + commit `968dd5d`
- T-D26 IQA-fix(本卡实施):真 BUG + 治理漏洞 + 性能 + 字面对齐 — 详见 commits 后续

### 当前活跃 Task(5 ADR 实施期 Day 27-29/5)

- **T-D27(2026-08-10)**:ADR-0031 + 0032 收入 8 + 支出 16 seed
  - [ ] DefaultIncomeTemplate 8 分类(seed)
  - [ ] DefaultExpenseTemplate 16 分类(seed)
  - [ ] **M4 必 skip DAO 自动 seed 的「退款」分类**(互斥路径避免重复创建)
  - [ ] 迁移 rename 5 旧预设 → 8 新(收入)+ insert 10 新(支出)
  - [ ] 记账弹层收入/支出 tab 全显示
  - [ ] 16 分类小屏适配(GridLayout 4×4)

- **T-D28(2026-08-11)**:ADR-0033 交易 2 toggle + StatisticsDao
  - [ ] StatisticsDao 新建,过滤 toggle
  - [ ] 主页「+」记账弹层加 2 toggle chip
  - [ ] 交易详情页 toggle 只读显示
  - [ ] 定时记账同步支持 toggle

- **T-D29(2026-08-12)**:整合 + 装机验 7 场景 + ROA 签字
  - [ ] 5 ADR 全部代码完成后的整合(D25 + D26 + D27 + D28)
  - [ ] iPhone 真机手验 7 场景:借出新建 / 借入新建 / 借贷二次记账 / 退款单笔 / 退款拆分 / ALREADY_REFUNDED 按钮灰 / toggle / 24 分类
  - [ ] ROA 报告 + CONTROL_TOWER 派生 ACCEPTED
  - [ ] S04 启动准备(ADR-0034/0035/0036)

### 装机验(D29 整合日执行)

- T-ROA-01:用户 iPhone 装 Runner.ipa(沿用 Stage 2 ROA 装机流程)
- T-ROA-02:真机手验 7 场景(详 §5 D29 列表)
- T-ROA-03:CONTROL_TOWER 更新 → Stage 3 = ACCEPTED + 5 ADR 实施期 = ACCEPTED(场景全过后)

### Stage 3 D21/D22 显式简化清单(铁律 8,合并自 D21/D22 daily)

| # | 项 | 简化原因 | 何时补 | 优先级 |
|---|---|---|---|---|
| 1 | 借贷「扣款/入款账户」资金联动 — DAO 已实现,UI 显示完整 | subType=lendOut/borrowIn 字段保留 = 死代码 | D24+ 评估 schema v8 删除 | P0 |
| 2 | LendRecordPage / BorrowRecordPage widget 测试 | DAO 已覆盖(11 测试),UI 是 DAO 上层 | D24+ 装机验后补 | P1 |
| 3 | pubspec.yaml 加 flutter_localizations | 修日期 picker locale(ADR-0028 §3 追溯授权)| 已做 | — |
| 4 | 借贷账户 subType 字段落库保留但 UI 不暴露 | schema v6 已加,UI 入口不放借贷;后续评估删 | D24+ 评估 | P0 |
| 5 | 账户详情 + 余额变动明细 2 tab | 咔皮截图 #9,D21 简化项 | D24+ | P1 |
| 6 | 资产页拆分(资产 ¥X / 负债 ¥Y)| 咔皮截图 #6,ADR-0026 §14 #11 | D24+ | P1 |
| 7 | FAB 文案「记一笔 / 还款」,5 入口菜单未全部标 | 范围控制,避免破测试 | D24+ 微调 | P3 |
| 8 | 记账弹层加转账 tab(ADR-0026 §14 #9)| D22 走独立 transfer_sheet,是否需 tab 待评估 | D24+ 评估 | P2 |
| 9 | 退款按钮语义未确认 | ADR-0026 §9 自审盲点,需用户点咔皮一次 | D23 装机验同步 | P0 |
| 10 | 收入分类 8 子类 | D21 简化项 | D24+ | P3 |

### 阻塞中

- 无

### 延后到 D24+ / Stage 4+ 的工作

- 借贷 subType 字段删除(可选 schema v8)— ADR-0028 §5 P0
- ADR-0026 §9 退款按钮语义确认 + ADR-0030 决策
- LendRecordPage / BorrowRecordPage widget 测试
- §14 实施清单 #10 账户详情 + 余额变动明细 2 tab
- §14 实施清单 #11 资产页拆分
- §14 实施清单 #9 记账弹层加转账 tab(评估)
- §14 实施清单 #3 + §12.4 账本表(独立 Stage — S04)
- ADR-0027 攒钱计划 5 模式(独立 Stage — S07)
- `.ai-work/` 加 .gitignore(走 DR,CLAUDE.md §11 保护)
- CONTROL_TOWER 自动派生脚本(目前手算)
- 爱思助手 / SideStore 装机脚本自动化

---

## 6️⃣ Agent 控制

### 当前角色

- **主 Agent(执行)**:Claude(MiniMax-M3)
  - 模式:PLAN → AUDIT → IMPLEMENT
  - 写入权限:S03 write-set + 治理文档 write-set 内所有文件
  - 唯一写入者

### 待启用角色

- **领域经理(架构)**:Stage 6 启用(SQLCipher + 加密设计)
- **领域经理(iOS 原生)**:Stage 1+ 启用(Siri / Vision API)
- **领域经理(AI)**:Stage 7 / v1.1 启用
- **只读检查池**:每个 Stage ROA 启用(审计)— 本会话 T-治理-14 启用

### 用户角色

- Owner / 决策者
- **必须 Owner Acceptance Stage 3 完成**(真机 3 场景全过 + 治理收尾签字)

---

## 7️⃣ 风险与决策

### 当前风险

| 风险 | 等级 | 状态 | 缓解 |
|---|---|---|---|
| iOS 真机 7 场景验收失败(D29 整合装机验) | 🟡 中 | D29 待做 | D25+26+27+28 整合 commit 装机手验(沿用 G-003)|
| **actions_sheet isRefunded 检查不一致(D26 IQA-fix C-IQA-1)** | 🟢 已解决(2026-08-09) | `TransactionActionsSheet` 改 ConsumerStatefulWidget + FutureBuilder 异步查 `getRefundedAmount`,与 `TransactionDetailPage` 完全一致 |
| **α2 SUM 性能 N+1 + 全表扫(D26 IQA-fix M1)** | 🟢 短期已解决(2026-08-09),🟡 长期 ADR-0037 v1.1 | DAO 加 `_refundedSumCache` 内存缓存;refundMoney 写后 invalidate。下次 S07 几万笔交易时触发 schema v9 + refundedAmountCents 字段原子化 |
| iOS 真机 3 场景验收失败(S03 — 历史,已 ACCEPTED) | ✅ 已解决(2026-08-06) | S03 ROA 真机 3 场景签字 |
| 治理漏洞(D21/D22 未走 DR)| 🟡 中 | ✅ 已解决(2026-08-06)| ADR-0028 追溯授权 + 13 文档同步 + 深度审计 |
| 借贷 subType=lendOut/borrowIn 字段保留 = 死代码 | 🟢 低 | D24+ 评估 | ADR-0028 §5 P0,可选 schema v8 |
| 借贷 transaction 化与 ADR-0026 §12.1 修订版「独立账户」矛盾 | 🟡 中 | ✅ 已解决 | ADR-0028 §1.3 + §2.1 显式记录;ADR-0026 §12.1 加注「transaction 化」|
| 借贷与 ADR-0026 §6/§8 净资产公式 SUM 借贷项矛盾 | 🟡 中 | ✅ 已解决 | P1-4 删 SUM 项(本会话)|
| pubspec.yaml 加 flutter_localizations 未走 §11 流程 | 🟡 中 | ✅ 已解决 | ADR-0028 §3 追溯授权 + 必要性论证 |
| iOS 真机 4 场景验收失败(S02)| 🟢 低 | ✅ 已解决(2026-08-01)| Stage 2 ROA 真机 4 场景全过签字 |
| 余额管理缺口 | 🟢 低 | ✅ 已解决 | ADR-0022(D19)+ D21 扩到 5 类 transaction |
| CI E2E 卡死(pumpAndSettle)| 🟡 中 | 已知,暂缓到 Stage 2+ | 用真机手验覆盖(已写 G-003)|
| GitHub Actions 编译 iOS(私有仓库额度耗尽)| 🟢 低 | ✅ 已解决(2026-08-01)| 仓库改 Public |
| Apple ID / iPhone UDID / 本地路径 git 历史泄漏 | 🟢 低 | ✅ 已解决(2026-08-01)| filter-branch 双重重写 49 commit + force push |
| iOS 原生桥接(Swift)| 🟢 低 | Stage 1 不涉及 | 无 |
| 8 周时间是否够 | 🟢 低 | 监控中 | 每周日复盘,提前预警 |
| Apple ID 配置 | 🟢 低 | 已占位符化 | ADR-0008 终极方案 |
| Drift / Riverpod 依赖冲突 | 🟢 低 | 已解决 | 锁版本(ADR-0012)+ device_info_plus 锁 10.1.2 |

### 待决策

| 决策项 | 状态 | 截止 | Owner |
|---|---|---|---|
| 借贷 subType 字段是否删除(schema v8)| D24+ 评估 | S03 ROA 后 | 用户 |
| ADR-0026 §9 退款按钮语义 | D23 装机验同步 | 用户点咔皮一次 | 用户 |
| CLAUDE.md 铁律 13(治理自审)| 待 ADR-0028 §3.2 风险缓解落地 | 用户决策 | 用户 |
| §14 实施清单 #9 记账弹层加转账 tab 是否需要 | D24+ 评估 | S03 ROA 后 | 用户 |
| §14 实施清单 #3 + §12.4 账本表是否独立 Stage | S04 启动前 | 用户 | 用户 |

### 已批准决策

| 决策 | 批准日 | ADR |
|---|---|---|
| 技术栈:Flutter + Riverpod + Drift | 2026-07-14 | ADR-0001 |
| 项目结构:Feature-based Clean Architecture | 2026-07-14 | ADR-0002 |
| 测试策略:60/30/10 + E2E 第四层 | 2026-07-14 / 2026-07-17 | ADR-0003 v1.1 + ADR-0014 |
| 部署:爱思助手 + SideStore + GitHub Actions | 2026-07-16 | ADR-0008 / 0010 / 0011 |
| 依赖锁定:drift_dev 2.34.4 + flutter_riverpod 2.6.1 + 移除 codegen | 2026-07-17 | ADR-0012 |
| emoji 优先(无 Material Icons)| 2026-07-21 | ADR-0013 |
| E2E 用 integration_test 真引擎 | 2026-07-21 | ADR-0014 |
| Stage 2 写集 | 2026-07-17 | ADR-0015 |
| Stage 2 账户 Schema v2 + AccountType enum textEnum 英文存 | 2026-07-25 | ADR-0017 |
| Stage 2 账户管理 UI | 2026-07-26 | ADR-0018 |
| Stage 2 分类 CRUD UI | 2026-07-28 | ADR-0019 |
| Stage 2 分类模板 | 2026-07-29 | ADR-0020 |
| Stage 3 范围决策(最小 MVP = 还款流 + 卡片增强 + 0 新依赖)| 2026-07-31 | ADR-0021(PARTIALLY_SUPERSEDED by 0028)|
| Stage 3 余额自动更新策略(D19)| 2026-08-02 | ADR-0022(扩展为 5 类 transaction by 0028)|
| Stage 3 build_info 版本管理(D19)| 2026-08-02 | ADR-0023 |
| Stage 3 6 种账户类型产品设计补丁(D19 后期)| 2026-08-02 | ADR-0024(被超越 by 0028)|
| Stage 3 v1.1 高级功能 backlog(D20)| 2026-08-03 | ADR-0025 |
| Stage 3 咔皮对标完整产品设计(D20)| 2026-08-03 | ADR-0026(§6/§8/§12.1 修订 by 0028)|
| 攒钱计划模块 + 桌面小组件(咔皮对标 #16-#21)| 2026-08-03 | ADR-0027 |
| **S03 范围扩写 + 借贷业务流程独立化 + pubspec §11 例外授权** | **2026-08-06** | **ADR-0028**(本会话新加)|
| Stage 7+ 智能记账(Siri Shortcuts / OCR / iOS 4 触发方式)| 2026-07-17 | ADR-0016 |
| LICENSE:MIT | 2026-07-23 | (新增)|
| 隐私:Apple ID 占位符 + filter-branch 清历史 | 2026-07-24 | (本卡)|

---

## 8️⃣ 剩余路标

### 8 周总览

```
W1 (7/15-7/21)  [■■■■■■■■■■] Stage 0 ✅ + Stage 1 Day 4-7
W2 (7/22-7/28)  [■■■■■■■■■▱] Stage 1 Day 8-10(本周末完成真机验收)
W3 (7/29-8/4)   [■■■■■■■■■■] Stage 2 ✅ + Stage 3 Day 18-20
W4 (8/5-8/11)   [■■■■■■■■■■] Stage 3 Day 21-24(D21 ✅ D22 ✅ D23 治理收尾+装机验 🔄 D24 ROA 待做)
W5 (8/12-8/18)  [▱▱▱▱▱▱▱] Stage 4 - 账本 & 预算
W6 (8/19-8/25)  [▱▱▱▱▱▱▱] Stage 5 - 净资产 & 仪表盘
W7 (8/26-9/1)   [▱▱▱▱▱▱▱] Stage 6 - 存储 & 快照
W8 (9/2-9/9)    [▱▱▱▱▱▱▱] Stage 7+8 - 攒攒 + 上线
```

### W4 详细(Stage 3 D18-D24)

- Day 18 (08-01):schema v4 + TransactionType 加 repayment ✅
- Day 19 (08-02):还款流 DAO + ADR-0022 余额联动 ✅
- Day 20 (08-03):还款流 UI 4 收款类型 + 网贷期数 + ADR-0024/0025/0026 ✅
- Day 21 (08-04):5 大类 × 23 子类 schema v6 + 转账流 + 主页 5 入口聚合菜单 ✅
- Day 22 (08-05):借贷业务流程独立化 schema v7 + lendMoney/borrowMoney + Lend/BorrowRecordPage + 日期 locale ✅
- Day 23 (08-06):**真机装机验 3 项修复 + 治理收尾(本会话 ADR-0028 + 9 文档同步 + 深度审计)** 🔄
- Day 24 (08-07):S03 ROA 收尾 + 用户签字 + CONTROL_TOWER 派生 ACCEPTED 📋

### Stage 4 准备(W5,基于 ADR-0028 §5 + ADR-0027 §4)

- 📋 §14 实施清单 #3 + §12.4 账本表(独立 Stage 子任务)
- 📋 ADR-0027 攒钱计划 5 模式(v1.0 范围「记账模式」+ UI,6 天工作量)
- 📋 总预算 / 分类预算 / 动态日预算(v4 §P0-09/10)

---

## 附录 A:状态定义(来自 AGENTS.md [DASH-03])

### Stage 状态

- `DRAFT` → `READY` → `AUTHORIZED` → `ACTIVE` → `VALIDATING`
- → `READY_FOR_OWNER_ACCEPTANCE` → `ACCEPTED`
- → `BLOCKED` / `REJECTED` / `SUPERSEDED`

### ADR 状态

- `DRAFT`(草稿)→ `ACCEPTED`(已接受)→ `PARTIALLY_SUPERSEDED`(部分被超越)→ `SUPERSEDED`(被超越)
- 本期 ADR-0021 / ADR-0024 / ADR-0026(部分)状态变更由 ADR-0028 §1.3 / §2.2 / §2.3 显式记录

### Task 状态

- `PROPOSED` → `READY` → `ACTIVE` → `REVIEW` → `DONE`
- → `BLOCKED` / `REJECTED` / `SUPERSEDED`

### Validation 结论

- `NOT_RUN` / `PASS` / `FAIL` / `BLOCKED`

---

## 附录 B:信息来源映射

| 字段 | 真源 | 派生文件 |
|---|---|---|
| 当前 Stage | stages/S{N}.md | 本文件 §2 |
| 当前 Task | stages/S{N}.md + daily/ + ci 修复链 | 本文件 §5 |
| 完成度 | 实际 git commit + 测试 + CI 状态 | 本文件 §4 |
| 风险 | 实际遇到的问题 + 用户反馈 + CI 失败链 | 本文件 §7 |
| 决策 | 用户直接指令 + ADR 文件 | 本文件 §7 |

---

**最后更新**:2026-08-09(D26 退款 transaction 化主体完成 + ADR-0037 DRAFT + SSOT 治理 + 5 ADR 实施期 D25/D26 状态同步)
**下次更新**:S04 启动前(D29 整合装机验回报 + ADR-0034/0035/0036 拍板 + 改写 §3 §5 授权边界)
**维护原则**:状态变化时更新,不要为了好看而改写历史
**派生依据补充**:`git log --oneline -5` 最新 `ea893f6`(D26 主体);`test/` 337 tests;D26 衍生 ADR-0037 DRAFT;v4 §P0-05 字面已对 ADR-0030 §决策 3 修订,SSOT 一致。
