# CONTROL_TOWER.md — 项目控制塔

> 状态：`DERIVED / DO NOT EDIT / NOT_SSOT`
> 创建：2026-07-14
> 数据源：`PLAN.md` · `ROADMAP.md` · `daily/` · `stages/` · `adr/` · 实际代码与运行证据

⚠️ **本文件由上述真源派生，不允许手填修改。状态冲突时显示 UNKNOWN/CONFLICT。**

---

## 1️⃣ 总体介绍

**项目**：iOS 自用记账 App《审计官》

**用户结果**：在 iPhone 上流畅、安全、可长期使用地进行个人记账、预算管理、信用卡管理，并通过 AI 攒攒 + RPG 化机制让记账变得可持续。

**当前健康**：✅ Stage 0 ROA 完成 / 🔄 Stage 1 Day 5 启动中（W2 进行中）

**最后派生时间**：2026-07-19（Day 5 开工时重新派生）

**派生依据**：
- `git log --oneline -10`：远程 main = `5ed6a78`
- `lib/` + `test/`：Drift schema + 3 DAO + seed + 11 单测
- `docs/stages/S01-manual-record.md`：S01 7 天计划
- `docs/daily/2026-07-18.md`：Day 4 完成
- `docs/daily/2026-07-19.md`：Day 5 计划
- `docs/adr/0012-stage1-dependency-decisions.md`：依赖决策

---

## 2️⃣ 路线位置

```
Milestone v1.0.0 (MVP 上线)
└── Wave W1-W8
    ├── Stage 0: 环境验证 (S00)         ✅ ACCEPTED (2026-07-16)
    ├── Stage 1: 手动记账 (S01)         🔄 ACTIVE — Day 5/7 (2026-07-19)
    ├── Stage 2: 分类 & 账户 (S02)      📋 PLAN
    ├── Stage 3: 信用卡 & 还款 (S03)    📋 PLAN
    ├── Stage 4: 账本 & 预算 (S04)      📋 PLAN
    ├── Stage 5: 净资产 & 仪表盘 (S05)  📋 PLAN
    ├── Stage 6: 存储 & 快照 (S06)      📋 PLAN
    ├── Stage 7: 攒攒 & 异常 (S07)      📋 PLAN
    └── Stage 8: 上线验收 (S08)          📋 PLAN
```

**当前位置**：Stage 1 / Day 5（Riverpod 状态骨架 + 主页布局）

**授权终点**：S08 完成 → `READY_FOR_OWNER_ACCEPTANCE`

---

## 3️⃣ 授权边界

### ✅ 当前允许（S01 write-set）

- 读取所有 docs/ 文件
- 读取 product-design-v4.html
- 写入 `lib/`（domain / data / features/home / features/record）
- 写入 `test/`（domain / data / features/home）
- 写入 `docs/daily/2026-07-18+` (Day 4-10)
- 写入 `docs/adr/0012-*`（Stage 1 依赖决策）

### ❌ 绝不自动做

- 修改 product-design-v4.html（除非用户明确要求）
- 修改 pubspec.yaml / package.json 依赖版本（受 §11 保护）
- 修改 .github/workflows/*.yml（受 §11 保护）
- 修改 ios/Runner/Info.plist（受 §11 保护）
- 删除任何已创建文件
- 提交 git commit / push（除非用户明确授权）
- 访问 Apple ID / 付费操作
- 写 S02+ 范围的代码（超出 Stage 1 write-set）

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
| 开发文档体系 | ✅ DONE | docs/ 完整结构 | 待审计 |
| 8 周主计划 | ✅ DONE | PLAN.md | 已批准 |
| 完整路线图 | ✅ DONE | ROADMAP.md | 已批准 |
| Stage 0 ROA | ✅ ACCEPTED | Hello World + Runner.ipa 真机装机 | 2026-07-16 |
| Stage 1 Day 4 | ✅ DONE | Drift 3 表 + 3 DAO + seed + 11 单测全绿 | 独立审计通过 |
| Stage 1 Day 5 | 🔄 ACTIVE | Riverpod ProviderScope + 主页骨架 | 进行中 |
| v1.0.0 上线 | ❌ NOT_STARTED | - | - |

### Stage 1 7 天进度

| Day | 日期 | 主题 | 状态 |
|---|---|---|---|
| Day 4 | 2026-07-18 | Drift schema + DAO + seed | ✅ DONE |
| Day 5 | 2026-07-19 | Riverpod 状态骨架 + 主页布局 | 🔄 ACTIVE |
| Day 6 | 2026-07-20 | 记账卡弹层 + 金额输入 + 保存逻辑 | 📋 PLAN |
| Day 7 | 2026-07-21 | 分类图标网格 + 账户选择 | 📋 PLAN |
| Day 8 | 2026-07-22 | 修改/删除交易 + 退款 + 振动 | 📋 PLAN |
| Day 9 | 2026-07-23 | 攒攒反馈动画 + E2E 测试 | 📋 PLAN |
| Day 10 | 2026-07-24 | 真机验收 + Stage 1 结束卡 | 📋 PLAN |

---

## 5️⃣ 当前任务树

### 当前活跃 Task（Stage 1 Day 5）

- T-S01-01：main.dart 接入 ProviderScope + databaseProvider
- T-S01-02：手写 3 个核心 provider（transactionList / categoryList / defaultAccount）
- T-S01-03：主页骨架（净资产占位卡 + 交易列表 + 记一笔按钮占位）
- T-S01-04：主页 Widget 测试（ProviderScope override 注入内存库）
- T-S01-05：flutter analyze 0 + flutter test 全绿 + commit + push

### 已完成 Task（Stage 0 + Stage 1 Day 4）

- T-S00-01~09：环境验证 + Hello World + iPhone 真机装机（✅ 2026-07-16）
- T-S01-D4-01：pubspec.yaml 添加依赖（drift / riverpod / intl / vibration）— commit 6f5ac49
- T-S01-D4-02：Drift 3 表 + DAO + seed + 11 单测 — commit 68e8d3d
- T-S01-D4-03：ADR-0012 依赖决策记录 — commit 0bbc8e6
- T-S01-D4-04：独立审计修复 6 条数据完整性问题 — commit 5ed6a78

### 阻塞中

- 无

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
- 必须授权每个 Stage 开始
- 必须 Owner Acceptance 每个 Stage 完成

---

## 7️⃣ 风险与决策

### 当前风险

| 风险 | 等级 | 状态 | 缓解 |
|---|---|---|---|
| GitHub Actions 编译 iOS 失败 | 🟢 低 | 已验证（CI #12 全过 + Runner.ipa 产物） | Stage 0 ROA 已闭环 |
| iOS 原生桥接（Swift）不熟悉 | 🟡 中 | 待解决 | Stage 0 安排 Swift 学习 |
| 8 周时间是否够 | 🟢 低 | 监控中 | 每周日复盘，提前预警 |
| Apple ID 配置 | 🟢 低 | 已就绪（ADR-0008 终极方案） | 爱思助手 + SideStore 验证 |
| Drift / Riverpod 依赖冲突 | 🟢 低 | 已解决（ADR-0012 锁定 2.34.4 + 2.6.1） | 依赖图干净 |
| CI 未跑 build_runner | 🟡 中 | 已知 | 必须提交 *.g.dart（ADR-0012 §风险） |

### 待决策

| 决策项 | 状态 | 截止 | Owner |
|---|---|---|---|
| （无） | - | - | - |

### 已批准决策

| 决策 | 批准日 | ADR |
|---|---|---|
| 技术栈：Flutter + Riverpod + Drift | 2026-07-14 | ADR-0001 |
| 项目结构：Feature-based Clean Architecture | 2026-07-14 | ADR-0002 |
| 测试策略：70/20/10 + 关键模块 100% | 2026-07-14 | ADR-0003 |
| 部署：爱思助手 + SideStore + GitHub Actions | 2026-07-16 | ADR-0008 / 0010 / 0011 |
| 依赖锁定：drift_dev 2.34.4 + flutter_riverpod 2.6.1 + 移除 codegen | 2026-07-17 | ADR-0012 |
| AI 模型：MiniMax-M3 | 2026-07-14 | （待写 ADR） |
| 开发文档根目录：E:\jizhang-0714\docs\ | 2026-07-14 | （本文件） |

---

## 8️⃣ 剩余路标

### 8 周总览

```
W1 (7/15-7/21)  [■■■■■■▱] Stage 0 ✅ + Stage 1 Day 4-5
W2 (7/22-7/28)  [▱▱▱▱▱▱▱] Stage 1 Day 6-10
W3 (7/29-8/4)   [▱▱▱▱▱▱▱] Stage 2 - 分类 & 账户
W4 (8/5-8/11)   [▱▱▱▱▱▱▱] Stage 3 - 信用卡 & 还款
W5 (8/12-8/18)  [▱▱▱▱▱▱▱] Stage 4 - 账本 & 预算
W6 (8/19-8/25)  [▱▱▱▱▱▱▱] Stage 5 - 净资产 & 仪表盘
W7 (8/26-9/1)   [▱▱▱▱▱▱▱] Stage 6 - 存储 & 快照
W8 (9/2-9/9)    [▱▱▱▱▱▱▱] Stage 7+8 - 攒攒 + 上线
```

### W2 详细（Stage 1 收尾）

- Day 5 (07-19)：Riverpod + 主页骨架 🔄
- Day 6 (07-20)：记账卡弹层 + 保存逻辑
- Day 7 (07-21)：分类图标网格 + 账户选择
- Day 8 (07-22)：修改/删除 + 退款 + 振动
- Day 9 (07-23)：攒攒动画 + E2E 测试
- Day 10 (07-24)：真机验收 + Stage 1 结束卡

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
| 当前 Task | stages/S{N}.md 中的 Task 列表 | 本文件 § 5 |
| 完成度 | 实际 git commit + 运行证据 | 本文件 § 4 |
| 风险 | 实际遇到的问题 + 用户反馈 | 本文件 § 7 |
| 决策 | 用户直接指令 + ADR 文件 | 本文件 § 7 |

---

**最后更新**：2026-07-19（Day 5 开工派生）
**下次更新**：Day 5 完成 / Day 6 开工时
**维护原则**：状态变化时更新，不要为了好看而改写历史