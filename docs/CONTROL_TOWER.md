# CONTROL_TOWER.md — 项目控制塔

> 状态：`DERIVED / DO NOT EDIT / NOT_SSOT`
> 创建：2026-07-14
> 数据源：`PLAN.md` · `ROADMAP.md` · `daily/` · `stages/` · `adr/` · 实际代码与运行证据

⚠️ **本文件由上述真源派生，不允许手填修改。状态冲突时显示 UNKNOWN/CONFLICT。**

---

## 1️⃣ 总体介绍

**项目**：iOS 自用记账 App《审计官》

**用户结果**：在 iPhone 上流畅、安全、可长期使用地进行个人记账、预算管理、信用卡管理，并通过 AI 攒攒 + RPG 化机制让记账变得可持续。

**当前健康**：✅ 规划完整 / ⏳ 待开始开发

**更新时间**：2026-07-14（创建）

---

## 2️⃣ 路线位置

```
Milestone v1.0.0 (MVP 上线)
└── Wave W1-W8
    ├── Stage 0: 环境验证 (S00)         ⏳ DRAFT
    ├── Stage 1: 手动记账 (S01)         📋 PLAN
    ├── Stage 2: 分类 & 账户 (S02)      📋 PLAN
    ├── Stage 3: 信用卡 & 还款 (S03)    📋 PLAN
    ├── Stage 4: 账本 & 预算 (S04)      📋 PLAN
    ├── Stage 5: 净资产 & 仪表盘 (S05)  📋 PLAN
    ├── Stage 6: 存储 & 快照 (S06)      📋 PLAN
    ├── Stage 7: 攒攒 & 异常 (S07)      📋 PLAN
    └── Stage 8: 上线验收 (S08)          📋 PLAN
```

**当前位置**：Stage 0 DRAFT（未授权）

**授权终点**：S08 完成 → `READY_FOR_OWNER_ACCEPTANCE`

---

## 3️⃣ 授权边界

### ✅ 当前允许

- 阅读所有 docs/ 文件
- 读取 product-design-v4.html
- 创建 S00 Stage 授权包络文件
- 创建 daily/2026-07-15.md
- 创建 adr/0001-*.md

### ❌ 绝不自动做

- 修改 product-design-v4.html（除非用户明确要求）
- 删除任何已创建文件
- 提交 git commit / push（除非用户明确授权）
- 安装 Flutter SDK 或其他工具（需要用户执行）
- 访问 Apple ID / 付费操作
- 写生产代码（需要 Stage 授权后才能 ACTIVE）

### 🛑 何时停止

- 用户提出新需求但超出 v1.0 范围
- 关键依赖（Flutter / GitHub Actions）出现问题
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
| Stage 0 授权 | ⏳ DRAFT | stages/S00-hello-world.md | 待用户授权 |
| Day 1 计划 | ⏳ DRAFT | daily/2026-07-15.md | 待用户授权 |
| Hello World 跑通 | ❌ NOT_STARTED | - | - |
| v1.0.0 上线 | ❌ NOT_STARTED | - | - |

---

## 5️⃣ 当前任务树

### 当前活跃 Stage
- 无（Stage 0 尚未 AUTHORIZED）

### 下一个 READY Task
- T-S00-01：创建 Stage 0 授权包络文件（等待中）

### 已完成 Task
- T-PRE-01：阅读 AGENTS.md（✅ 2026-07-14）
- T-PRE-02：阅读产品设计文档（✅ 2026-07-14）
- T-PRE-03：建立 docs/ 目录结构（✅ 2026-07-14）
- T-PRE-04：编写 PLAN.md（✅ 2026-07-14）
- T-PRE-05：编写 ROADMAP.md（✅ 2026-07-14）

### 阻塞中
- 无

### 下一步
1. 用户授权 Stage 0 开始
2. 创建 stages/S00-hello-world.md 详细授权
3. 创建 daily/2026-07-15.md Day 1 详细计划
4. 用户开始执行 Flutter SDK 安装

---

## 6️⃣ Agent 控制

### 当前角色
- **主 Agent（执行）**：Claude（MiniMax-M3）
  - 模式：PLAN → AUDIT → IMPLEMENT
  - 写入权限：docs/ 所有文件（按 Stage 授权）
  - 唯一写入者

### 待启用角色
- **领域经理（架构）**：Stage 6 启用（SQLCipher + 加密设计）
- **领域经理（iOS 原生）**：Stage 1 启用（Siri / Vision API）
- **领域经理（AI）**：Stage 7 / v1.1 启用
- **只读检查池**：每个 Stage 完成后启用（审计）

### 用户角色
- Owner / 决策者
- 必须授权每个 Stage 开始
- 必须 Owner Acceptance 每个 Stage 完成

---

## 7️⃣ 风险与决策

### 当前风险

| 风险 | 等级 | 状态 | 缓解 |
|---|---|---|---|
| GitHub Actions 编译 iOS 失败 | 🟡 中 | 待验证 | Stage 0 Day 2 验证 |
| iOS 原生桥接（Swift）不熟悉 | 🟡 中 | 待解决 | Stage 0 安排 Swift 学习 |
| 8 周时间是否够 | 🟢 低 | 监控中 | 每周日复盘，提前预警 |
| Apple ID 配置 | 🟡 中 | 待用户准备 | Day 1 用户准备 |

### 待决策

| 决策项 | 状态 | 截止 | Owner |
|---|---|---|---|
| Stage 0 是否授权开始 | ⏳ 待决策 | 2026-07-14 | 用户 |
| Apple ID 是否专门注册 | ⏳ 待决策 | Day 1 前 | 用户 |
| 旧电脑是否准备好 | ⏳ 待决策 | Day 3 前 | 用户 |

### 已批准决策

| 决策 | 批准日 | ADR |
|---|---|---|
| 技术栈：Flutter + Riverpod + Drift | 2026-07-14 | adr/0001 |
| 部署：**爱思助手 + SideStore + GitHub Actions** | 2026-07-16 | ADR-0008(终极方案) + ADR-0010 + ADR-0011 |
| AI 模型：MiniMax-M3 | 2026-07-14 | （待写 ADR）|
| 开发文档根目录：E:\jizhang-0714\docs\ | 2026-07-14 | （本文件）|

---

## 8️⃣ 剩余路标

### 8 周总览

```
W1 (7/15-7/21)  [▱▱▱▱▱▱▱] Stage 0 - 环境验证
W2 (7/22-7/28)  [▱▱▱▱▱▱▱] Stage 1 - 手动记账
W3 (7/29-8/4)   [▱▱▱▱▱▱▱] Stage 2 - 分类 & 账户
W4 (8/5-8/11)   [▱▱▱▱▱▱▱] Stage 3 - 信用卡 & 还款
W5 (8/12-8/18)  [▱▱▱▱▱▱▱] Stage 4 - 账本 & 预算
W6 (8/19-8/25)  [▱▱▱▱▱▱▱] Stage 5 - 净资产 & 仪表盘
W7 (8/26-9/1)   [▱▱▱▱▱▱▱] Stage 6 - 存储 & 快照
W8 (9/2-9/9)    [▱▱▱▱▱▱▱] Stage 7+8 - 攒攒 + 上线
```

### 唯一主操作

**👉 用户需要决定**：是否授权 Stage 0 开始？

选项 A：✅ 授权，开始 Day 1（Flutter SDK 安装）
选项 B：⏸ 暂停，需要先讨论/调整某些事项
选项 C：❌ 修改 PLAN，调整 Stage 0 范围

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

**最后更新**：2026-07-14（创建）
**下次更新**：Stage 0 AUTHORIZED 时
**维护原则**：状态变化时更新，不要为了好看而改写历史
