# Task 模板

> 状态：`TEMPLATE`
> 创建：2026-07-14
> 适用范围：Stage 内的子任务清单（写在 `stages/S{N}-{name}.md` 中或 `tasks/` 目录）

---

## Task 命名规范

- **Task ID**：`T-{STAGE}-{NN}`（如 `T-S01-03`）
- **状态**：`PROPOSED` → `READY` → `ACTIVE` → `REVIEW` → `DONE` → `BLOCKED` / `REJECTED` / `SUPERSEDED`
- **依赖**：用 Task ID 列表标注前置任务

---

## Task 单条模板

```markdown
### T-{STAGE}-{NN}: {任务标题}

- **状态**: `PROPOSED` | `READY` | `ACTIVE` | `REVIEW` | `DONE` | `BLOCKED`
- **优先级**: P0 | P1 | P2
- **预估工时**: {X} 小时
- **实际工时**: {Y} 小时
- **负责人**: 主 Agent / 你（用户）/ 领域经理
- **依赖**: T-{STAGE}-{MM}, T-{STAGE}-{NN}
- **阻塞**: 无 | T-{STAGE}-{XX}（依赖项未完成）

#### 描述
{2-3 句话说清楚做什么、为什么}

#### 验收标准（Done When）
- [ ] {可验证的结果 1}
- [ ] {可验证的结果 2}
- [ ] {证据要求：命令输出 / 文件路径 / 截图}

#### 实现要点
- {关键技术点 1}
- {关键技术点 2}

#### 风险
- {可能失败的地方}

#### 输出（Deliverables）
- {文件 1}
- {commit SHA}

#### 备注
- {关联文档、ADR、issue}
```

---

## Task 列表示例（Stage 内使用）

```markdown
## 📋 Stage 1 Task 列表

### 已完成
- ✅ T-S01-01: 数据库设计 + Drift 初始化（2026-07-22）
- ✅ T-S01-02: 主页布局骨架（2026-07-23）

### 进行中
- 🔄 T-S01-03: 底部"记一笔"按钮（ACTIVE）

### 待开始
- ☐ T-S01-04: 记账卡弹层（依赖 T-S01-03）
- ☐ T-S01-05: 分类图标网格（依赖 T-S01-04）

### 阻塞
- 🚫 T-S01-06: 保存逻辑（依赖 T-S01-05）
```

---

## Task 创建流程

```
1. 在 Stage 授权包络里列出所有 Task（PROPOSED）
2. 主 Agent 自审 → 标记 READY
3. 你（用户）授权 → 标记 ACTIVE
4. 主 Agent 执行 → 提交 → 标记 REVIEW
5. Check pool 审计 → 通过后标记 DONE
```

---

## Task 状态转换规则

| From | To | 触发条件 |
|---|---|---|
| PROPOSED | READY | 主 Agent 自审通过 |
| READY | ACTIVE | 用户授权 / 依赖任务完成 |
| ACTIVE | REVIEW | 代码 + 测试 + commit 完成 |
| REVIEW | DONE | Check pool 审计通过 |
| * | BLOCKED | 遇到阻塞（必须说明原因） |
| BLOCKED | ACTIVE | 阻塞解除 |
| * | REJECTED | 用户拒绝 / 不再做 |

---

## Task 完成话术

**禁止**：
- ❌ "做完了"（未验证）
- ❌ "应该可以"（没跑命令）
- ❌ "差不多"（没看证据）

**必须**：
- ✅ "T-S01-03 完成。已验证：`flutter test` 通过，commit `abc123`，截图见 `evidence/s01-button.png`"