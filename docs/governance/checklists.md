# 检查清单库

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：Stage / Daily / Commit / 验收 全流程

---

## 📋 Stage 启动清单（Stage 开始前大副必做）

```
□ 读 CONTROL_TOWER.md → 知道当前 Stage 状态
□ 读上一 Stage 结束卡 → 知道交付物和教训
□ 复制 templates/stage-template.md → 创建 S{N}-{name}.md
□ 填写 Goal / Context / In Scope / Out of Scope
□ 列出所有 Task（PROPOSED）
□ 估算工时
□ 风险评估 + 缓解
□ 验证矩阵
□ 写时间切片（每天详细）
□ 标记状态：DRAFT
□ 自审 → READY
□ 等指挥官授权
```

---

## 📅 Daily 启动清单（每天开工大副必做）

```
□ 读昨天的 daily/YYYY-MM-DD.md → 知道 EOD 卡写了什么
□ 读 CONTROL_TOWER.md → 当前风险/阻塞/决策
□ 读 git log --oneline -10 → 看最近改动
□ flutter doctor → 验证环境健康
□ 检查今日 daily 文件是否存在
□ 列出今日 Top 3 任务
□ 设定今日 commit 目标
□ 开始执行
```

---

## 💾 Commit 提交清单（每次 git commit 必做）

```
□ git status → 确认 worktree 干净（除当前改动）
□ git diff --staged → 检查改动是否完整
□ 改动是否符合 commit-message-template.md
□ commit message 包含 Task ID（如 T-S01-03）
□ commit message 描述"为什么"而非"是什么"
□ 测试通过（如果改了代码）
□ 没包含敏感信息（密钥、token、.env）
□ 没包含临时文件（*.tmp, debug_*, *.log）
□ 没包含 build 产物（build/, .dart_tool/）
□ 没包含 IDE 配置（.vscode/, .idea/）
□ git push → 立即推送到远程
```

---

## ✅ Task 完成清单（每个 Task 完工时大副必做）

```
□ 代码写完（commit 完成）
□ flutter analyze 通过（0 issues）
□ flutter test 通过
□ 修改/新增测试覆盖了改动
□ git push 完成
□ daily 文件更新：标记 Task ✅
□ 列出证据（命令输出、commit SHA、截图路径）
□ 通知指挥官验收
```

---

## 🎯 Stage 完成清单（Stage 完工时大副必做）

```
□ 所有 Task 完成
□ 所有验收清单走查
□ 写 Stage 结束卡（附录在 Stage 授权包络或 daily）
□ 请督察审计（写 audit report）
□ 修复督察发现的阻塞项
□ 更新 CONTROL_TOWER.md：Stage → DONE
□ 创建下一个 Stage 授权包络（草稿）
□ git tag（如发布版本）
□ commit + push
□ 通知指挥官走 ROA 流程
```

---

## 🏆 Owner Acceptance 清单（指挥官验收时必走）

```
□ 打开 Stage 授权包络的 Done When 部分
□ 逐项核对（功能 / 技术 / 文档）
□ 对照实际产物（截图、文件、命令输出）
□ 对照审计报告（PASS / PASS WITH NOTES）
□ 用户视角验证（iPhone 上能看到的）
□ 通过 → 签字，状态 ACCEPTED
□ 不通过 → 写打回原因，请大副返工
```

---

## 🔒 安全检查清单（任何涉及敏感操作的 Task）

```
□ 密钥/密码用环境变量或 Keychain，不硬编码
□ HTTPS 调用，无 HTTP
□ 输入验证（用户输入、API 响应、文件路径）
□ SQL 参数化查询，无字符串拼接
□ 日志不含敏感信息
□ .gitignore 包含 *.key *.p12 *.cer *.mobileprovision
□ git status 不显示敏感文件
□ 文档中无凭证
```

---

## 📦 发布前清单（Stage 8 上线前）

```
□ 所有 P0 功能验收通过
□ 测试覆盖率 ≥ 80%
□ flutter analyze 0 issues
□ flutter test 全 PASS
□ 性能测试达标（启动 ≤ 2s，滚动 ≥ 55 FPS）
□ iPhone 真机烟雾测试通过
□ CHANGELOG.md 更新
□ git tag v1.0.0
□ AltStore 安装成功
□ 7 天无 P0 崩溃
□ 备份到本地（防止云端丢失）
```

---

## 🧹 收尾清单（每个 Stage 结束 + git push 前）

```
□ 没有残留临时文件（.tmp, *.log, debug_*）
□ .ai-work/ 不存在或已清空
□ 核心配置文件未被意外修改
□ 所有改动已 commit
□ git status 干净
□ git log --oneline 清晰
□ CONTROL_TOWER.md 已更新
□ daily 文件已更新并 commit
```

---

## 🔄 重启会话清单（用户开新会话时大副必做）

```
□ Step 1: 读 MEMORY.md（5 秒）
□ Step 2: 读 CONTROL_TOWER.md（5 秒）
□ Step 3: 读当前 Stage 文件 S{N}-*.md（5 秒）
□ Step 4: 读最近 daily 文件（5 秒）
□ Step 5: 读相关 ADR（如有）（5 秒）
□ Step 6: 向指挥官报告"已恢复上下文"（5 秒）
```

---

## 📌 通用约定

- 每个清单项都是**可勾选**的（用 □ 而非 ✓）
- 大副完成任务后**主动勾选**（不是等指挥官问）
- 清单不通过 → 不进入下一阶段
- 清单本身可以更新（遇到新情况补充）

---

**最后更新**：2026-07-14 · 创建