# 《审计官》开发文档索引

> 项目：iOS 自用记账 App · 路线：AltStore + GitHub Actions 0 成本方案
> 创建：2026-07-14 · 维护者：Claude（执行）+ 用户（决策）
> 上位文档：`[REPO_PATH]/product-design-v4.html`（v4 完整方案，52 章）

---

## 📁 目录结构

```
docs/
├── README.md                        ← 本文件（文档索引）
├── PLAN.md                          ← 主计划（8 周 / 56 天拆分）
├── ROADMAP.md                       ← 完整路线图（v1.0 → v2.0）
├── CONTROL_TOWER.md                 ← 控制塔（当前状态 / 决策 / 风险 / 下一步）
├── context-management.md            ← 上下文与幻觉管理（4 层防御）
├── collaboration-architecture.html  ← 协作架构图（6 角色 / 3 会话 / 6 模式）
│
├── adr/                             ← Architecture Decision Records
│   ├── 0001-flutter-tech-stack.md
│   └── ...
│
├── stages/                          ← Stage 授权包络（每个 Stage 一份）
│   ├── S00-hello-world.md
│   ├── S01-manual-record.md
│   └── ...
│
├── daily/                           ← 每日工作记录（每天一个 Markdown）
│   ├── 2026-07-15.md                ← Day 1
│   ├── 2026-07-16.md                ← Day 2
│   ├── 2026-07-17.md                ← Day 3
│   └── ...
│
├── templates/                       ← 模板（新建文件从这里复制）
│   ├── stage-template.md            ← Stage 授权包络
│   ├── task-template.md             ← Task 清单
│   ├── adr-template.md              ← 架构决策记录
│   ├── commit-message-template.md   ← git commit 规范
│   ├── audit-report-template.md     ← 检查池审计报告
│   ├── decision-request-template.md ← 范围 / 决策变更请求
│   ├── branch-strategy-template.md  ← git 分支管理
│   └── daily-template.md            ← 每日工作日志
│
├── governance/                      ← 治理规范（必读 · 13 个文件）
│   ├── roles.md                     ← 6 角色身份 + 性格
│   ├── scripts.md                   ← 标准化话术
│   ├── checklists.md                ← Stage/Daily/Commit 清单
│   ├── coding-standards.md          ← Dart/Flutter 编码规范
│   ├── project-structure.md         ← Flutter lib/ 组织
│   ├── test-strategy.md             ← 测试策略 + 覆盖率目标
│   ├── design-system.md             ← 颜色/字体/间距 token
│   ├── ux-guidelines.md             ← iOS HIG + 交互规则
│   ├── performance-budgets.md       ← 启动/滚动/包大小
│   ├── security-checklist.md        ← 加密/HTTPS/输入验证
│   ├── subagent-prompts.md          ← 复用 prompt 库
│   ├── error-catalog.md             ← 已知错误 + 解决方案
│   └── preview-strategy.md          ← 开发期预览（Chrome/Simulator/真机）
│
├── decisions/                       ← Decision Request 存档（按需创建）

└── validation/                      ← 验证记录与 Harness（审计报告）
    └── ...
```

---

## 🎯 当前状态（2026-07-14）

| 维度 | 状态 |
|---|---|
| **当前 Stage** | Stage 0（未授权 / 准备中）|
| **下一 Stage** | S00 - 环境验证 + Hello World |
| **计划开始日** | 2026-07-15 |
| **v1.0 MVP 目标** | 2026-09-09（8 周后）|
| **已完成文档** | 全部规划 + 治理 + 模板（13 个文件）|
| **下一步操作** | 用户授权 Stage 0，开始 Day 1 |

详见 [CONTROL_TOWER.md](./CONTROL_TOWER.md)

---

## 📖 阅读顺序建议

### 新加入者（5 分钟理解项目）
1. `product-design-v4.html`（按目录浏览 10 分钟）
2. `docs/PLAN.md`（8 周总览）
3. `docs/CONTROL_TOWER.md`（当前状态）

### 开始开发前（30 分钟准备）
1. `docs/ROADMAP.md`（完整路线）
2. `docs/adr/0001-flutter-tech-stack.md`（为什么用 Flutter）
3. `docs/stages/S00-hello-world.md`（即将开始的 Stage）
4. `docs/context-management.md`（AI 协作规则 · 必读）
5. `docs/collaboration-architecture.html`（6 角色 / 3 会话 / 6 模式）

### 每日开工（3 分钟回顾）
1. 昨天 `docs/daily/YYYY-MM-DD.md`（做了什么 / 没做什么）
2. 今天 `docs/daily/YYYY-MM-DD.md`（今天要做什么）
3. `docs/CONTROL_TOWER.md`（当前风险 / 阻塞 / 决策）

### 创建新文件时
- Stage → 复制 `templates/stage-template.md`
- Task → 复制 `templates/task-template.md`
- ADR → 复制 `templates/adr-template.md`
- Daily → 复制 `templates/daily-template.md`
- Audit → 复制 `templates/audit-report-template.md`
- Decision Request → 复制 `templates/decision-request-template.md`

---

## 🔒 命名与文件管理规则

### 文件命名
- Stage：`S{N}-{slug}.md`（如 `S00-hello-world.md`）
- ADR：`{4位序号}-{slug}.md`（如 `0001-flutter-tech-stack.md`）
- 每日：`YYYY-MM-DD.md`（如 `2026-07-15.md`）
- 模板：`{name}-template.md`
- 审计：`audit-S{N}-{YYYY-MM-DD}.md`
- Decision Request：`DR-{YYYY-MM-DD}-{slug}.md`

### 修改规则（来自 AGENTS.md）
- ✅ 所有写入必须有授权包络（Stage 文件定义 write-set）
- ✅ 修改前 `git status` 确认 worktree 干净
- ✅ 文件路径必须是仓库相对路径，不允许绝对路径
- ✅ 遵循 [commit-message-template](./templates/commit-message-template.md)
- ✅ 遵循 [branch-strategy](./templates/branch-strategy-template.md)
- ❌ 禁止把临时文件放根目录或工作目录
- ❌ 禁止把测试/调试代码提交到主分支

### 真源优先级
1. `product-design-v4.html`（产品功能真源）
2. `docs/PLAN.md`（实施计划真源）
3. `docs/ROADMAP.md`（产品路线真源）
4. `docs/CONTROL_TOWER.md`（当前状态真源，派生）
5. 代码与运行证据（CURRENT_STATE）

---

## 📞 协作流程

| 时机 | 动作 |
|---|---|
| 每日开工 | 打开今天的 daily 文件，按任务清单执行 |
| 完成 Task | 在 daily 中记录 ✅ 和证据（命令、SHA、截图）|
| 完成 Stage | 写 Stage 结束卡，更新 CONTROL_TOWER，写 audit report |
| 遇到 MATERIAL_GAP | 写 [Decision Request](./templates/decision-request-template.md)，阻塞等待决策 |
| 需要改方案 | 写 ADR，更新产品设计文档（如必要）|
| 重大变更 | 写 [ADR](./templates/adr-template.md)，更新 CONTROL_TOWER 决策表 |

---

## 🛡 治理文档（必读）

| 文档 | 何时读 |
|---|---|
| [context-management.md](./context-management.md) | 每次新会话开始 |
| [collaboration-architecture.html](./collaboration-architecture.html) | 理解 6 角色 / 3 会话 / 6 模式 |
| [templates/commit-message-template.md](./templates/commit-message-template.md) | 每次 git commit 前 |
| [templates/branch-strategy-template.md](./templates/branch-strategy-template.md) | 分支操作前 |
| [templates/audit-report-template.md](./templates/audit-report-template.md) | 每个 Stage 结束 |

---

## 🛠 工具与命令

```bash
# 查看完整计划
cat docs/PLAN.md

# 看今天要做什么
cat docs/daily/$(date +%Y-%m-%d).md

# 看当前状态
cat docs/CONTROL_TOWER.md

# 看 Stage 授权
cat docs/stages/S00-hello-world.md
```

---

**最后更新**：2026-07-14 · 补完模板体系
**下次更新**：Stage 0 完成后（写入 CONTROL_TOWER）