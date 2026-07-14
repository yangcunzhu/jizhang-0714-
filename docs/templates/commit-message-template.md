# Commit Message 规范

> 状态：`TEMPLATE` / `GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有 git commit（强约束）

---

## 为什么需要规范

- ✅ 历史可读（一眼看出改了什么）
- ✅ 自动生成 CHANGELOG
- ✅ 方便 Code Review
- ✅ 出问题时能精准 revert

---

## 格式（Conventional Commits）

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type（必填）

| Type | 含义 | 示例 |
|---|---|---|
| `feat` | 新功能 | `feat: 添加底部记账按钮` |
| `fix` | 修 BUG | `fix: 修复键盘遮挡输入框` |
| `docs` | 仅文档 | `docs: 更新 PLAN.md 工期` |
| `style` | 代码格式（无逻辑变化） | `style: 统一使用单引号` |
| `refactor` | 重构（既不修 BUG 也不加功能） | `refactor: 拆分 TransactionRepository` |
| `perf` | 性能优化 | `perf: 优化列表滚动` |
| `test` | 测试相关 | `test: 补充分类 CRUD 测试` |
| `chore` | 工具/构建 | `chore: 升级 Flutter 到 3.24.5` |
| `ci` | CI/CD 配置 | `ci: 添加 iOS build workflow` |
| `build` | 构建系统 | `build: 升级 Gradle 到 8.0` |
| `revert` | 回滚 | `revert: 回滚 abc1234` |

### Scope（可选）

- 表示影响范围，如 `feat(auth):`、`fix(db):`
- 项目可选 scope：`auth`、`db`、`ui`、`nav`、`data`、`domain`、`ci`、`docs`

### Subject（必填）

- **不超过 50 字符**
- **首字母小写**（中文不受影响）
- **不用句号结尾**
- **动词开头**（添加、修复、优化、升级）
- 中文 OK，英文更通用

### Body（可选）

- 与 subject 之间空一行
- 解释"为什么"而不是"是什么"
- 每行不超过 72 字符
- 多段用 `-` 列表

### Footer（可选）

- `Refs: #issue` 关联 issue
- `Closes: #issue` 关闭 issue
- `BREAKING CHANGE: {描述}` 标记破坏性变更

---

## 完整示例

### 中文版

```
feat(ui): 添加主页底部"记一笔"按钮

- 使用 FloatingActionButton.extended 实现
- 点击触发底部弹层
- 动画时长 200ms
- 适配深色模式

Refs: T-S01-03
```

### 英文版

```
feat(auth): add biometric authentication

- Support Face ID and Touch ID
- Fallback to PIN if biometric fails
- Encrypted biometric key in Keychain

Closes: #42
```

### 修复 BUG

```
fix(input): 修复金额输入框键盘遮挡

在 Android 上数字键盘弹起时，输入框会被遮挡。
改用 SingleChildScrollView 包裹，让输入框上滑。

Refs: T-S02-07
```

### 文档

```
docs: 更新 ROADMAP v1.1 新增 OCR + AI 集成
```

### 重大变更

```
feat(api): 重构数据库 schema 从 v1 到 v2

BREAKING CHANGE: Transaction 表增加 account_id 外键
需要运行 migration v2，否则旧数据无法访问。
```

---

## 项目实际示例（参考）

### Stage 0 Day 1

```
feat: init Flutter project with Hello 审计官

- flutter create with iOS-only platform
- customize main.dart to show 'Hello 审计官'
- update Info.plist display name
- add widget test

Stage: S00 Day 1
```

### Stage 0 Day 1 (文档)

```
docs: Day 1 结束卡 + README + GitHub Actions 草稿
```

### Stage 0 Day 2

```
ci: configure signed iOS build with Apple cert
```

---

## 反例（禁止）

```
❌ "fix bug"              # 太模糊，不知道修什么
❌ "update"               # 没说明改什么
❌ "WIP"                  # 不完整
❌ "asdfasdf"             # 乱写
❌ "提交一下"              # 没意义
❌ "feat: 添加功能。"       # 句号结尾
❌ "feat: A very long subject that exceeds 50 characters and is hard to read"  # 超长
```

---

## 多 commit 规范

一个 PR/commit 应该只解决一个问题：

| ✅ 推荐 | ❌ 避免 |
|---|---|
| `feat: 添加记账按钮`<br>`fix: 修复按钮颜色`<br>`test: 补充按钮测试` | `feat: 添加按钮 + 修复颜色 + 补充测试` |

**多个独立改动 → 多个 commit**

---

## 验证工具

提交前可用 `commitlint` 验证：

```bash
npm install -g @commitlint/cli @commitlint/config-conventional
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
commitlint --from HEAD~1 --to HEAD
```

详见：`https://www.conventionalcommits.org/zh-hans/`

---

## 与 Stage / Task 关联

每个 commit 应在 body 或 footer 标注关联的 Task ID：

```
feat(record): 实现 5 秒 3 步记账

- 主页底部按钮 → 弹层 → 输入金额 → 保存
- 振动反馈
- 攒攒反馈动画

Stage: S01
Task: T-S01-03, T-S01-04
```

这样 `git log --grep="S01"` 就能找到 S01 阶段的所有 commit。

---

**最后更新**：2026-07-14 · 创建
**强制级别**：✅ 强约束（违反会被 PR Review 打回）