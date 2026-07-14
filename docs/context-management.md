# 上下文与幻觉管理手册

> 状态：`GOVERNANCE` · 治理文件
> 创建：2026-07-14
> 适用范围：整个项目期间所有 AI 会话

---

## 🎯 问题陈述

**为什么这是严重问题？**

1. **上下文窗口有限**：任何 LLM 都有 token 上限（即使 200K / 1M），8 周项目的内容必然超限
2. **压缩会丢信息**：上下文被压缩时，早期信息会被总结，可能丢失关键细节
3. **幻觉是真实风险**：
   - 长上下文中，模型可能在模糊处"脑补"细节
   - 模型可能编造看似合理但实际不存在的命令、文件、配置
   - 模型可能记错之前的决策
4. **单会话集中处理**：所有决策、代码、命令都在一个会话里，风险叠加
5. **质量后果**：可能产生 BUG、回归、决策矛盾、文档与代码不一致

**我们不能假装这个问题不存在。**

---

## 🛡 4 层防御体系

### 1️⃣ SSOT（Single Source of Truth · 真源在文件）

**核心原则：所有决策的"权威版本"在磁盘文件里，不在 AI 脑子里。**

| 文件 | 作用 |
|---|---|
| `docs/PLAN.md` | 8 周主计划 |
| `docs/ROADMAP.md` | 产品路线图 |
| `docs/CONTROL_TOWER.md` | 状态仪表盘（派生） |
| `docs/adr/*.md` | 不可逆决策记录 |
| `docs/stages/S{N}-*.md` | Stage 授权包络 |
| `docs/daily/YYYY-MM-DD.md` | 每日工作日志 |
| `docs/collaboration-architecture.html` | 协作架构图 |
| 产品代码本身 | 真实运行证据 |

**操作纪律**：
- ✅ AI 不靠记忆回答"我们之前决定 X"
- ✅ 不确定时必须重读 SSOT
- ✅ 用户问"现在状态是什么" → 读 CONTROL_TOWER.md 重新生成答案
- ❌ 禁止 AI 凭印象编造决策、命令、版本号

### 2️⃣ 显式记忆系统（跨会话持久化）

`C:\Users\Administrator\.claude\projects\E--jizhang-0714\memory\MEMORY.md` 是常驻索引：

```yaml
- 项目背景 → project_setup.md
- 产品方案 v4 → product_design_v4.md
- 协作架构 → collaboration_architecture.md
- 上下文管理 → context_management.md
```

**新会话开始时的恢复序列**（30 秒）：
1. 读 MEMORY.md → 知道项目是什么
2. 读 CONTROL_TOWER.md → 知道当前 Stage
3. 读当前 Stage 文件 → 知道今天该做什么
4. 读最近 daily 文件 → 知道昨天发生了什么
5. 开始工作

**操作纪律**：
- ✅ 每个 Stage 关键事实写进 memory
- ✅ 用户提到重要信息 → 立即存 memory
- ✅ 新会话开始 → 先读 memory 再读 SSOT

### 3️⃣ 只读检查池（Fresh Eyes）

每个 Stage 完成后调用 **general-purpose subagent** 做代码审计：

**为什么有效**：
- Subagent 是全新的 context（无"上下文疲劳"）
- 没有 AI 主体的偏见和假设
- 专门找 BUG、矛盾、安全漏洞
- 输出结构化审计报告

**审计内容**：
- [ ] 代码与 PLAN.md 是否一致
- [ ] 是否有未声明的副作用
- [ ] 测试覆盖率是否达标
- [ ] 是否有 TODO / FIXME 残留
- [ ] 是否有死代码
- [ ] 是否有安全漏洞
- [ ] git commit message 是否清晰

### 4️⃣ Stage 边界（Decomposition）

**每个 Stage 是独立的"上下文单元"**：

| Stage | 工作量 | 上下文风险 |
|---|---|---|
| S00 环境验证 | ~30h | 低 |
| S01-S07 主体 | ~85h/个 | 中（需要 subagent 辅助） |
| S08 验收 | ~50h | 低 |

**重启策略**：
- Stage 边界是天然的"重启点"
- 上一 Stage 结束 → 用户开新会话 → AI 30 秒读 SSOT 恢复全部状态
- 不需要用户重复解释任何事

---

## ⚠️ 残余风险（不能 100% 消除）

| 风险 | 等级 | 缓解 |
|---|---|---|
| 上下文压缩时丢失细节 | 🟡 中 | 关键决策写 ADR（永久）；每天 EOD 卡 |
| AI 在模糊处脑补 | 🟡 中 | 用户随时质疑；零伪造成功规则 |
| 大文件读不全 | 🟡 中 | 分层结构 + offset/limit + grep 定位 |
| 8 周累积内容矛盾 | 🟢 低 | CONTROL_TOWER 显式标记 DERIVED；ADR 记录变更 |
| Subagent 自己也幻觉 | 🟢 低 | Subagent 输出必须经过 AI 主体复核 |
| 多个 Stage 间遗忘早期决策 | 🟢 低 | SSOT + 每次 Stage 开始重读 |

---

## 📋 AI 主体必须遵守的操作纪律

### 必做

1. **不确定时，重读文件**（永远不要凭记忆答）
2. **每个 Stage 开始前**，重读 SSOT（PLAN, ROADMAP, CONTROL_TOWER, ADR）
3. **每天结束写 EOD 卡**（不靠记忆记录当天产出）
4. **关键决策写 ADR**（不可逆决策必须 ADR 化）
5. **复杂逻辑必走 TDD**（测试不撒谎）
6. **check pool 强制启用**（每个 Stage 结束审计）
7. **被质疑时立即给证据**（命令输出、文件路径、commit SHA、截图）
8. **避免在长对话里承担过多样本**（该派 subagent 就派）

### 必不做

1. ❌ 凭记忆回答"我们之前决定 X"
2. ❌ 编造命令、文件名、版本号、commit SHA
3. ❌ 跳过测试说"代码没问题"
4. ❌ 一个会话硬撑到底（该重启就重启）
5. ❌ 把幻觉当事实（"我认为应该能工作"不算完成）

---

## 🔄 会话重启策略（关键）

**8 周项目不可能一个会话完成。必须分阶段。**

### 触发重启的时机

- ✅ 每个 Stage 结束（新 Stage = 新会话）
- ✅ 用户主动说"我们重新整理一下"
- ✅ AI 主体感觉上下文变重（token 使用 > 70%）
- ✅ 跨 Stage 跨度过大（如 S00 → S06）

### 重启时 AI 主体要做的（30 秒流程）

```
Step 1: 读 MEMORY.md（5 秒）
Step 2: 读 CONTROL_TOWER.md（5 秒）
Step 3: 读当前 Stage 文件 S{N}-*.md（5 秒）
Step 4: 读最近 daily 文件 daily/YYYY-MM-DD.md（5 秒）
Step 5: 读相关 ADR（如果当前 Stage 涉及不可逆决策）（5 秒）
Step 6: 向用户报告"已恢复上下文，准备开始 Stage X Day Y"（5 秒）
```

### 用户要做的

- 不需要重复解释任何事
- 只需要说"开始 S0X"或继续昨天的任务
- AI 主体自动从文件恢复

---

## 🚨 幻觉紧急处理流程

如果用户怀疑 AI 主体在幻觉：

```
👤 用户："你怎么知道的？给我证据"
            ↓
🧠 AI 主体：
   Step 1: 承认不确定（"让我查证"）
   Step 2: 读相关 SSOT 文件（用 Read 工具）
   Step 3: 跑命令验证（用 Bash 工具）
   Step 4: 给用户证据（文件路径 + 行号 + 命令输出）
            ↓
👤 用户：根据证据判断是否接受
```

**反例**（禁止）：
```
❌ AI："我记得是 X"（凭印象）
❌ AI："应该是 Y 吧"（没证据）
❌ AI："我相信没问题"（未验证）
```

---

## ✅ 完成定义（Definition of Done）

**AI 主体声称"完成"之前必须满足**：

- [ ] 代码写完
- [ ] 测试通过（`flutter test` PASS）
- [ ] 类型检查通过（`flutter analyze` 0 issues）
- [ ] 相关命令实际跑过（不是预测）
- [ ] git commit 完成（不是"打算 commit"）
- [ ] daily 文件已更新（产出已记录）
- [ ] 关键决策已写 ADR（如果是不可逆决策）
- [ ] 给用户可重现的验证步骤（不只是说"好了"）

**禁止话术**：
- ❌ "应该没问题"
- ❌ "我觉得可以"
- ❌ "理论上能跑通"

**必须话术**：
- ✅ "已验证：X 命令返回 Y，测试 Z 通过"
- ✅ "证据在 `file:line` 和 commit `abc123`"

---

## 📊 上下文健康度监控

每个 Stage 结束时，AI 主体报告：

```yaml
本 Stage 上下文使用：
  起始 token: ___
  峰值 token: ___
  压缩次数: ___
  subagent 调用次数: ___

风险评估：
  残余上下文压力: 低/中/高
  下一 Stage 是否需要重启会话: 是/否
  SSOT 完整性: 完整/部分/缺失
```

写入 daily 文件的"结束卡"。

---

## 🔗 相关文档

- [协作架构](collaboration-architecture.html)
- [CONTROL_TOWER](CONTROL_TOWER.md)
- [ADR 目录](adr/)
- [Stage 授权包络](stages/)
- [Daily 日志](daily/)

---

**最后更新**：2026-07-14 · 创建
**下次更新**：出现新幻觉场景时追加
**维护原则**：真实问题、真实对策，不为了好看而写