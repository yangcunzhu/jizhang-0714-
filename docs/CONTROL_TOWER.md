# CONTROL_TOWER.md — 项目控制塔

> 状态：`DERIVED / DO NOT EDIT / NOT_SSOT`
> 创建：2026-07-14
> 最后派生:2026-07-19(S03 D20 完成 + ADR-0026 修订 + 护栏机制建立)

⚠️ **本文件由 git log + daily/ + stages/ + 实际代码 + 运行证据派生。状态冲突时显示 UNKNOWN/CONFLICT。**

---

## 1️⃣ 总体介绍

**项目**：iOS 自用记账 App《审计官》

**用户结果**：在 iPhone 上流畅、安全、可长期使用地进行个人记账、预算管理、信用卡管理，并通过 AI 攒攒 + RPG 化机制让记账变得可持续。

**当前健康**：✅ Stage 0 ROA 完成 / ✅ Stage 1 ACCEPTED / ✅ Stage 2 ACCEPTED(2026-08-01 真机 4 场景全过签字) / 🔄 Stage 3 ACTIVE(D18 启动 + D19 写还款流)

**派生依据**：
- `git log --oneline -10`：远程 main 最新 commit `2f4b833`(公开仓库触发 build)+ filter-branch 后新主链
- `lib/` + `test/` + `integration_test/`：Drift schema v4(TransactionType enum + repayment)+ 232 测试(原 227 + S03 D18 新增 5)
- `docs/stages/S03-credit-card-repayment.md`：S03 7 天计划启动(D18 ✅ schema v4 + 5 tests,D19 写还款流 DAO)
- `docs/daily/2026-07-{25..31}.md` + `docs/daily/2026-08-01.md`：Day 11-18 每日工作日志
- `docs/adr/0015-0021.md`：Stage 2 写集 + 账户/分类/模板 5 个 S02 内 ADR + S03 范围决策
- `docs/validation/audit-S02-2026-07-31.md`：ROA 报告(2026-08-01 用户签字 ACCEPTED)
- GitHub Actions：Build iOS .ipa 公开仓库后无限额度(2026-08-01 触发 build 3m 35s 跑通)

---

## 2️⃣ 路线位置

```
Milestone v1.0.0 (MVP 上线)
└── Wave W1-W8
    ├── Stage 0: 环境验证 (S00)         ✅ ACCEPTED (2026-07-16)
    ├── Stage 1: 手动记账 (S01)         ✅ ACCEPTED (2026-07-17)
    ├── Stage 2: 分类 & 账户 (S02)      ✅ ACCEPTED (2026-08-01 ROA 签字)
    ├── Stage 3: 信用卡 & 还款 (S03)    🔄 ACTIVE (D18 启动,D19 写还款流)
    ├── Stage 4: 账本 & 预算 (S04)      📋 PLAN
    ├── Stage 5: 净资产 & 仪表盘 (S05)  📋 PLAN
    ├── Stage 6: 存储 & 快照 (S06)      📋 PLAN
    ├── Stage 7: 攒攒 & 异常 (S07)      📋 PLAN
    └── Stage 8: 上线验收 (S08)          📋 PLAN
```

**当前位置**：Stage 1 = ACCEPTED ✅(2026-07-17 真机手验 3 场景全过) / Stage 2 = ACCEPTED ✅(2026-08-01 真机手验 4 场景全过)
**下一站**：Stage 3 Day 19 写还款流 DAO(transferRepayment)+ 顺手修余额管理(transaction_dao)+ 写 ADR-0022 记录

**授权终点**：S08 完成 → `READY_FOR_OWNER_ACCEPTANCE`

---

## 3️⃣ 授权边界

### ✅ 当前允许（S02 ROA 收尾,S03 ACTIVE,2026-08-01）

- 读取所有 docs/ 文件
- 读取 product-design-v4.html
- 写入 `lib/data/db/`（app_database / tables / daos — S03 写集）
- 写入 `lib/features/account/`（account_card 信用卡字段增强 — S03）
- 写入 `lib/features/repayment/`（新建 feature — S03 还款流）
- 写入 `lib/features/home/presentation/home_page.dart`（主页「+」聚合菜单 — S03 Day 20 才加,Day 18 不动）
- 写入 `test/data/db/` + `test/features/`（migration_v4 / 信用卡 widget / 还款流测试）
- 写入 `integration_test/`（S03 E2E 沿用 bootContainer 模式）
- 写入 `docs/daily/2026-08-01..07.md`（S03 7 天 daily）
- 写入 `docs/adr/0022-*.md`（余额自动更新策略 ADR — S03 Day 19 写）
- 写入 `LICENSE` + `docs/governance/error-catalog.md`

### ❌ 绝不自动做

- 修改 product-design-v4.html（除非用户明确要求）
- 修改 pubspec.yaml / package.json 依赖版本（受 CLAUDE.md §11 保护,**S03 0 新依赖**）
- 修改 .github/workflows/*.yml（受 §11 保护）
- 修改 ios/Runner/Info.plist（受 §11 保护,S03 不需要通知权限配置）
- 修改 .gitignore（受 §11 保护,需走 DR）
- 删除任何已创建文件
- 提交 git commit / push（除非用户明确授权）
- 访问 Apple ID / 付费操作
- 写 S04+ 范围的代码（超出当前授权）

### 🛑 何时停止

- 用户提出新需求但超出 v1.0 范围
- 关键依赖（Flutter / drift / riverpod）出现问题
- 连续 3 个 Stage 未达标
- 时间预算超期 20%

---

## 4️⃣ 结果状态

| 功能 | 状态 | 证据 | 验收 |
|---|---|---|---|
| v4 完整方案 | ✅ DONE | product-design-v4.html（184 KB） | 已审计 |
| 开发文档体系 | ✅ DONE | docs/ 完整结构 + governance/ + templates/ | 已审计 |
| 8 周主计划 | ✅ DONE | PLAN.md | 已批准 |
| 完整路线图 | ✅ DONE | ROADMAP.md | 已批准 |
| Stage 0 ROA | ✅ ACCEPTED | Hello World + Runner.ipa 真机装机 | 2026-07-16 |
| Stage 1 Day 4 | ✅ DONE | Drift 3 表 + 3 DAO + seed + 10 单测 | 独立审计通过 |
| Stage 1 Day 5 | ✅ DONE | Riverpod + 主页骨架 | 17/17 测试 + analyze 0 |
| Stage 1 Day 6 | ✅ DONE | 记账卡弹层 + 保存逻辑 | 45/45 测试 + analyze 0 |
| Stage 1 Day 7 | ✅ DONE | emoji 化 + 账户 UI + E2E 基建 | 54/54 测试 + ADR-0013/0014 |
| Stage 1 Day 8 | ✅ DONE | 编辑/删除/退款 + Key + 振动 | 72/72 测试 |
| Stage 1 Day 9 | ✅ DONE | 攒攒动画 + E2E CI 基建 | 75/75 测试 + E2E CI 卡死暂缓 |
| Stage 1 Day 10 | ✅ DONE | 真机手验 3 场景全过 + 收尾卡 + CONTROL_TOWER 派生 + G-003 沉淀 | 2026-07-17 |
| Stage 1 ROA | ✅ ACCEPTED | iPhone 16 Pro Max 真机手验签字 | 2026-07-17 |
| Stage 2 ROA | ✅ ACCEPTED | 自审 17 项 16 项已绿 + 真机 4 场景全过签字 | 2026-08-01 |
| v1.0.0 上线 | ❌ NOT_STARTED | - | - |

### Stage 1 7+ 天进度

| Day | 日期 | 主题 | 状态 | commit |
|---|---|---|---|---|
| Day 4 | 2026-07-18 | Drift schema + DAO + seed | ✅ DONE | `68e8d3d` 等 |
| Day 5 | 2026-07-19 | Riverpod 状态骨架 + 主页布局 | ✅ DONE | `7db25e2` |
| Day 6 | 2026-07-20 | 记账卡弹层 + 金额输入 + 保存逻辑 | ✅ DONE | `dfadac4` |
| Day 7 | 2026-07-21 | emoji 化 + 账户 UI + E2E 基建 | ✅ DONE | `5fb3655` + `efd9bb2` |
| Day 8 | 2026-07-22 | 修改/删除交易 + 退款 + 振动 + Key | ✅ DONE | `1d54d17` |
| Day 9 | 2026-07-23 | 攒攒动画 + E2E CI workflow | ✅ DONE(代码) | `721ab69` |
| Day 10 | 2026-07-24 | 真机验收 + Stage 1 结束卡 | 🔄 ROA | (本卡) |

### 累计 commit 数(filter-branch 前)

- Day 4-9 阶段开发:约 20+ 个 commit
- Day 9-10 CI 修复链:5 个 commit(`740360e` `f047b43` `3316167` `257ddd3` `afe752d` `4436c26` `720390c`)
- Day 10 隐私修复:1 个(`940a908` filter-branch 后)
- **总计:26+ 个 commit,filter-branch 后 SHA 全变**

### Stage 2 7+ 天进度

| Day | 日期 | 主题 | 状态 | commit |
|---|---|---|---|---|
| Day 11 | 2026-07-25 | Schema migration v2 + account_dao CRUD + 18 tests + ADR-0017 | ✅ DONE | `9594668` |
| Day 12 | 2026-07-26 | 账户管理 UI + 主页入口 + 37 tests + ADR-0018 | ✅ DONE | `32036fd` |
| Day 13 | 2026-07-27 | 多账户选择器 + 15 tests | ✅ DONE | `5d7c8cb` |
| Day 14 | 2026-07-28 | 分类 CRUD UI + emoji picker + 37 tests + ADR-0019 | ✅ DONE | `b6ecb31` |
| Day 15 | 2026-07-29 | 分类模板(5 预设 + 一键应用) + 30 tests + ADR-0020 | ✅ DONE | `87943d7` |
| Day 16 | 2026-07-30 | 集成测试 + 真机手验准备 + emoji picker 系统键盘接口 + 15 tests | ✅ DONE | `6984da4` + `baad6e0`(daily SHA 填入) |
| Day 17 | 2026-07-31 | ROA 自审 + analyze 0 + test 227 全绿 + 签字延后 D18 | 🔄 ROA 待签 | (待 push) |

### Stage 2 累计 commit 数

- Day 11-16 阶段开发:6 个 feat commit(`9594668` `32036fd` `5d7c8cb` `b6ecb31` `87943d7` `6984da4`)
- Day 16 daily SHA 填入:1 个 docs commit(`baad6e0`)
- Day 17 ROA 收尾:1 个 docs commit(待 push,本卡 + CONTROL_TOWER)
- **总计:8 个 commit,Stage 2 全部基于 S01 ACCEPTED 后的 main(`bfbfa13`)派生**

---

## 5️⃣ 当前任务树

### 当前活跃 Task（Stage 1 ROA）

- T-ROA-01：用户 iPhone 装 Runner.ipa(沿用 Stage 0 ROA 装机流程)
- T-ROA-02：真机手验场景 1(记账主流程 + 攒攒动画)
- T-ROA-03：真机手验场景 2(暂停 + 恢复持久化)
- T-ROA-04：真机手验场景 3(编辑 + 退款 + 删除)
- T-ROA-05：CONTROL_TOWER 更新 → Stage 1 = ACCEPTED(场景全过后)

### 已完成 Task（Stage 1 Day 4-9）

- T-S01-D4-01~04：Drift schema + DAO + seed + 依赖决策(commit `68e8d3d` `0bbc8e6` `5ed6a78`)
- T-S01-D5-01~05：Riverpod + 主页骨架 + 测试(`7db25e2`)
- T-S01-D6-01~05：记账卡弹层 + 保存(`dfadac4`)
- T-S01-D7-01~05：emoji + 账户 + E2E 基建 + ADR-0013/0014(`5fb3655` `efd9bb2`)
- T-S01-D8-01~04：编辑/删除/退款 + Key + 振动(`1d54d17`)
- T-S01-D9-01~03：攒攒动画 + E2E workflow(`721ab69`)

### CI 修复链(Day 9-10)

- T-CI-01：建 ios/Podfile (`740360e`)
- T-CI-02：Xcode 13.0 → 16.0 + workflow pod install (`f047b43`)
- T-CI-03：device_info_plus 锁 10.1.2 (`257ddd3`)
- T-CI-04：e2e.yml 加日志 (`afe752d`)
- T-CI-05：e2e timeout 20→35 (`4436c26`)
- T-CI-06：filter-branch 清 Apple ID 历史 (`940a908` + filter)

### 阻塞中

- 无

### 延后到 Stage 2+ 的工作

- CI E2E on iOS Simulator(Drift stream 在真引擎下导致 perpetual frame scheduling,需 Stage 2+ 重写)
- `.ai-work/` 加 .gitignore(走 DR,CLAUDE.md §11 保护)
- CONTROL_TOWER 自动派生脚本(目前手算)
- 爱思助手 / SideStore 装机脚本自动化

---

## 6️⃣ Agent 控制

### 当前角色

- **主 Agent（执行）**：Claude（MiniMax-M3）
  - 模式：PLAN → AUDIT → IMPLEMENT
  - 写入权限：S01 write-set 内所有文件
  - 唯一写入者

### 待启用角色

- **领域经理（架构）**：Stage 6 启用（SQLCipher + 加密设计）
- **领域经理（iOS 原生）**：Stage 1+ 启用（Siri / Vision API）
- **领域经理（AI）**：Stage 7 / v1.1 启用
- **只读检查池**：每个 Stage ROA 启用（审计）

### 用户角色

- Owner / 决策者
- **必须 Owner Acceptance Stage 1 完成**(真机 3 场景全过)

---

## 7️⃣ 风险与决策

### 当前风险

| 风险 | 等级 | 状态 | 缓解 |
|---|---|---|---|
| iOS 真机 3 场景验收失败 | 🟡 中 | ✅ 已解决(2026-07-17) | Stage 1 ROA 真机 3 场景全过签字 |
| iOS 真机 4 场景验收失败(S02) | 🟢 低 | ✅ 已解决(2026-08-01) | Stage 2 ROA 真机 4 场景全过签字(主页记账 / 分类管理 / 分类模板 / 多账户+信用卡字段)|
| emoji picker「更多 emoji(系统键盘)」真机已测 | 🟢 低 | ✅ 已解决(2026-08-01) | D18 真机 4 场景中场景二验证,「更多表情」按钮 + 系统键盘切到表情键盘 + 选 🐱 成功 |
| 余额管理缺口(transaction_dao 不更新 balanceCents) | 🟡 中 | S03 D19 修 | 写还款流 DAO 必然要更新两个账户余额,顺手在 transferRepayment 加 _updateAccountBalance() 通用方法,所有 6 种账户自动覆盖;写 ADR-0022 记录 |
| CI E2E 卡死(pumpAndSettle) | 🟡 中 | 已知,暂缓到 Stage 2+ | 用真机手验覆盖(已写 G-003) |
| GitHub Actions 编译 iOS(私有仓库额度耗尽) | 🟢 低 | ✅ 已解决(2026-08-01) | 仓库改 Public(S03 期间 11 次 build 3 秒失败,公开后无限额度,build 3m 35s 跑通) |
| Apple ID / iPhone UDID / 本地路径 git 历史泄漏 | 🟢 低 | ✅ 已解决(2026-08-01) | filter-branch --tree-filter + --msg-filter 双重重写 49 commit + force push + 加 .gitignore 挡 .ai-work/ |
| iOS 原生桥接（Swift） | 🟢 低 | Stage 1 不涉及 | 无 |
| 8 周时间是否够 | 🟢 低 | 监控中 | 每周日复盘，提前预警 |
| Apple ID 配置 | 🟢 低 | 已占位符化 | ADR-0008 终极方案 |
| Drift / Riverpod 依赖冲突 | 🟢 低 | 已解决 | 锁版本(ADR-0012) + device_info_plus 锁 10.1.2 |

### 待决策

| 决策项 | 状态 | 截止 | Owner |
|---|---|---|---|
| Stage 2 写集范围 | 等 Stage 1 ACCEPTED | - | 用户 |
| .ai-work/ 加 .gitignore | 走 DR(CLAUDE.md §11) | Stage 2 开工前 | 用户 |

### 已批准决策

| 决策 | 批准日 | ADR |
|---|---|---|
| 技术栈：Flutter + Riverpod + Drift | 2026-07-14 | ADR-0001 |
| 项目结构：Feature-based Clean Architecture | 2026-07-14 | ADR-0002 |
| 测试策略：60/30/10 + E2E 第四层 | 2026-07-14 / 2026-07-17 | ADR-0003 v1.1 + ADR-0014 |
| 部署：爱思助手 + SideStore + GitHub Actions | 2026-07-16 | ADR-0008 / 0010 / 0011 |
| 依赖锁定：drift_dev 2.34.4 + flutter_riverpod 2.6.1 + 移除 codegen | 2026-07-17 | ADR-0012 |
| emoji 优先(无 Material Icons) | 2026-07-21 | ADR-0013 |
| E2E 用 integration_test 真引擎 | 2026-07-21 | ADR-0014 |
| Stage 2 写集(分类 CRUD + 多账户 + 6 种账户类型 schema 扩展) | 2026-07-17 | ADR-0015 |
| Stage 2 账户 Schema v2 + AccountType enum 取值策略(textEnum 英文存) | 2026-07-25 | ADR-0017 |
| Stage 2 账户管理 UI(弹层 + 列表 + emoji 透明背景) | 2026-07-26 | ADR-0018 |
| Stage 2 分类 CRUD UI(iconName emoji 语义 + 自建 emoji picker + 12 色板 + ↑↓ 排序 + 引用保护禁用) | 2026-07-28 | ADR-0019 |
| Stage 2 分类模板(覆盖/追加混合策略 + 引用保护保留跳过 + 差异化 5/8/10/12/0 模板粒度) | 2026-07-29 | ADR-0020 |
| Stage 3 范围决策(最小 MVP = 还款流 + 卡片增强 + 0 新依赖,不引 flutter_local_notifications) | 2026-07-31 | ADR-0021 |
| Stage 7+ 智能记账(Siri Shortcuts / OCR / iOS 4 触发方式) | 2026-07-17 | ADR-0016 |
| LICENSE：MIT | 2026-07-23 | (新增) |
| 隐私：Apple ID 占位符 + filter-branch 清历史 | 2026-07-24 | (本卡) |

---

## 8️⃣ 剩余路标

### 8 周总览

```
W1 (7/15-7/21)  [■■■■■■■■■■] Stage 0 ✅ + Stage 1 Day 4-7
W2 (7/22-7/28)  [■■■■■■■■■▱] Stage 1 Day 8-10(本周末完成真机验收)
W3 (7/29-8/4)   [▱▱▱▱▱▱▱] Stage 2 - 分类 & 账户
W4 (8/5-8/11)   [▱▱▱▱▱▱▱] Stage 3 - 信用卡 & 还款
W5 (8/12-8/18)  [▱▱▱▱▱▱▱] Stage 4 - 账本 & 预算
W6 (8/19-8/25)  [▱▱▱▱▱▱▱] Stage 5 - 净资产 & 仪表盘
W7 (8/26-9/1)   [▱▱▱▱▱▱▱] Stage 6 - 存储 & 快照
W8 (9/2-9/9)    [▱▱▱▱▱▱▱] Stage 7+8 - 攒攒 + 上线
```

### W2 详细（Stage 1 收尾）

- Day 5 (07-19)：Riverpod + 主页骨架 ✅
- Day 6 (07-20)：记账卡弹层 + 保存逻辑 ✅
- Day 7 (07-21)：emoji + 账户 + E2E 基建 ✅
- Day 8 (07-22)：编辑/删除 + 退款 + 振动 ✅
- Day 9 (07-23)：攒攒动画 + E2E CI 基建 ✅(E2E 卡死,真机补)
- Day 10 (07-24)：真机手验 + Stage 1 结束卡 🔄 ROA

### Stage 2 准备(W3)

- ✅ 分类 CRUD UI(emoji + 颜色 + ↑↓ 排序 + 引用保护) — D14 + ADR-0019
- ✅ 6 种账户类型 schema 扩展 — D11 migration v2 + ADR-0017
- ✅ 多账户选择器(替换单一"现金") — D13
- ✅ 5 个 S02 内 ADR(0015 / 0017 / 0018 / 0019 / 0020) — 全「已接受」
- 🔄 ROA 待签(D18 真机手验后签字)

### Stage 3 准备(W4)

- ✅ ADR-0021 范围决策(最小 MVP = 还款流 + 卡片增强 + 0 新依赖)
- ✅ `docs/stages/S03-credit-card-repayment.md` 写集 + 7 天计划 + Done When(待 S02 ACCEPTED 后 ACTIVE)
- 📋 D18 真机手验 + 签字后 S03 ACTIVE → D18-D24 开发

---

## 附录 A：状态定义（来自 AGENTS.md [DASH-03]）

### Stage 状态

- `DRAFT` → `READY` → `AUTHORIZED` → `ACTIVE` → `VALIDATING`
- → `READY_FOR_OWNER_ACCEPTANCE` → `ACCEPTED`
- → `BLOCKED` / `REJECTED` / `SUPERSEDED`

### Task 状态

- `PROPOSED` → `READY` → `ACTIVE` → `REVIEW` → `DONE`
- → `BLOCKED` / `REJECTED` / `SUPERSEDED`

### Validation 结论

- `NOT_RUN` / `PASS` / `FAIL` / `BLOCKED`

---

## 附录 B：信息来源映射

| 字段 | 真源 | 派生文件 |
|---|---|---|
| 当前 Stage | stages/S{N}.md | 本文件 § 2 |
| 当前 Task | stages/S{N}.md + daily/ + ci 修复链 | 本文件 § 5 |
| 完成度 | 实际 git commit + 测试 + CI 状态 | 本文件 § 4 |
| 风险 | 实际遇到的问题 + 用户反馈 + CI 失败链 | 本文件 § 7 |
| 决策 | 用户直接指令 + ADR 文件 | 本文件 § 7 |

---

**最后更新**：2026-07-31（Day 17 收尾派生 — Stage 2 ROA 待签）
**下次更新**：Stage 2 真机手验签字后(D18) / Stage 3 开工时(D19 或 D20)
**维护原则**：状态变化时更新，不要为了好看而改写历史