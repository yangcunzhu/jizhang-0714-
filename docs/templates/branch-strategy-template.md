# Git 分支策略

> 状态：`TEMPLATE` / `GOVERNANCE`
> 创建：2026-07-14
> 适用范围：项目所有 git 分支管理

---

## 为什么需要分支策略（即使单人项目）

- ✅ main 永远保持可运行
- ✅ 实验性改动隔离
- ✅ 紧急修复有专用通道
- ✅ 历史可追溯

---

## 分支命名规范

### 主分支（永久）

| 分支 | 作用 | 保护规则 |
|---|---|---|
| `main` | 生产可用代码 | 只能通过 PR 合并 / 禁止 force push |

### 阶段性分支（短期）

| 分支 | 命名 | 作用 | 生命周期 |
|---|---|---|---|
| Stage 分支 | `stage/S{N}-{slug}` | 一个 Stage 的开发 | Stage 结束合并 → 删除 |
| 实验分支 | `exp/{description}` | 试错 / 验证想法 | 验证后合并或删除 |

### 功能分支（更短期）

| 分支 | 命名 | 作用 |
|---|---|---|
| Feature | `feature/T-{STAGE}-{NN}-{slug}` | 单个 Task |
| Bugfix | `bugfix/{issue-id}-{slug}` | 修 BUG |
| Hotfix | `hotfix/{issue-id}-{slug}` | 紧急修复 main |
| Docs | `docs/{description}` | 仅文档 |

### 命名示例

```
main                              # 主分支
stage/S01-manual-record          # S01 阶段开发
stage/S06-storage-snapshot       # S06 阶段开发
feature/T-S01-03-record-button   # S01 第 3 个 Task
bugfix/42-keyboard-overlap        # 修复 issue #42
hotfix/99-crash-on-launch         # 紧急修复崩溃
docs/update-roadmap-v1.1          # 文档更新
exp/test-sqlcipher-performance    # 性能实验
```

---

## 分支工作流

### 默认流程

```
main（生产）
  │
  ├── stage/S01-manual-record        # 创建 Stage 分支
  │     │
  │     ├── feature/T-S01-03-button  # 可选：细分到 Task
  │     ├── feature/T-S01-04-form
  │     └── ...
  │
  ├── stage/S02-categories-accounts
  │     └── ...
  │
  └── ...
```

### 推荐流程（单人项目简化版）

```
直接 main 上开发（每天 1-3 个 commit）
  - 每个 commit 符合 commit-message-template
  - 每天结束时 main 处于可运行状态
  - 不开 stage 分支（除非特别大的改动）

或：
main
  │
  └── stage/S{N}-{name}（中等改动）
        │
        └── feature/...（可选细分）
```

**对于本项目（单人，8 周）推荐**：
- ✅ 大部分时间在 main 上工作（每天 commit）
- ✅ 大型 Stage 开始前创建 stage/S{N}-{name} 分支
- ✅ 紧急修复用 hotfix/
- ❌ 不需要 develop / release 分支（单人项目过度设计）

---

## Commit 规范

每个 commit 必须遵循 `commit-message-template.md`：

```bash
git commit -m "feat(record): 添加记账按钮

实现底部 FloatingActionButton，点击触发弹层。

Stage: S01
Task: T-S01-03"
```

---

## 合并 / 推送策略

### Stage 分支 → main

```bash
# 在 stage 分支上完成 Stage
git checkout stage/S01-manual-record
git log --oneline  # 检查提交历史

# 合并到 main
git checkout main
git merge --no-ff stage/S01-manual-record
# --no-ff 保留分支历史

# 推送
git push origin main

# 删除已合并的 stage 分支
git branch -d stage/S01-manual-record
git push origin --delete stage/S01-manual-record
```

### Hotfix 直接到 main

```bash
git checkout main
git pull origin main
git checkout -b hotfix/99-crash
# 修 BUG + commit
git checkout main
git merge --no-ff hotfix/99-crash
git push origin main
git branch -d hotfix/99-crash
```

---

## Tag 策略（版本）

每个发布版本打 tag：

```bash
# v1.0.0 发布
git tag -a v1.0.0 -m "Release v1.0.0 - MVP 上线"
git push origin v1.0.0

# 查看所有 tag
git tag -l

# 检出某个版本
git checkout v1.0.0
```

### 版本号规范（语义化版本）

```
v{MAJOR}.{MINOR}.{PATCH}

v1.0.0   # 首次发布
v1.0.1   # 修 BUG
v1.1.0   # 加新功能（不破坏兼容）
v2.0.0   # 破坏性变更
```

本项目预期 tag：

```
v0.1.0   # S00 完成（Hello World）
v0.2.0   # S01 完成（手动记账）
...
v1.0.0   # S08 完成（MVP 上线）
```

---

## 推送策略

### 何时 push

- ✅ 每个 commit 后立即 push（避免本地丢失）
- ✅ 每天结束必 push
- ❌ 不要积累 N 个 commit 再 push

### 推送命令

```bash
# 首次推送
git push -u origin main

# 之后
git push

# 推送 tag
git push --tags

# 推送当前分支
git push origin <branch-name>
```

---

## 危险操作（避免）

### ❌ 绝对禁止

```bash
git push --force              # 强制推送会丢失远程历史
git push --force-with-lease   # 同样危险
git reset --hard HEAD~10      # 丢失 10 个 commit
git checkout -- .             # 撤销所有未提交改动
git clean -fd                 # 删除未跟踪文件
```

### ✅ 安全的替代

```bash
# 用 revert 撤销已 push 的 commit
git revert <commit-sha>
git push

# 用 stash 保存未提交改动
git stash
git stash pop  # 恢复

# 用 reflog 找回丢失的 commit
git reflog
```

---

## 紧急恢复流程

如果 main 被搞坏了：

```bash
# 1. 查看历史
git reflog

# 2. 找到最后一个好 commit
git log --oneline

# 3. 重置到那个 commit（保留工作区）
git reset --soft <good-commit-sha>

# 4. 验证
git status
flutter doctor
flutter test
```

如果实在不行：

```bash
# 从最近的 tag 恢复
git checkout v1.0.0
git checkout -b recovery

# 然后 cherry-pick 丢失的 commit
git cherry-pick <commit-sha>
```

---

## 常用 Git 别名（建议设置）

```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg 'log --oneline --graph --decorate'
git config --global alias.ac '!git add -A && git commit -m'
```

之后就可以用 `git co`、`git br`、`git lg` 等简写。

---

## 检查清单（每个 Stage 结束）

- [ ] 所有 commit 已 push
- [ ] stage 分支已合并到 main
- [ ] stage 分支已删除（本地 + 远程）
- [ ] git log 干净清晰
- [ ] 没有未追踪的临时文件
- [ ] .gitignore 正确

---

**最后更新**：2026-07-14 · 创建
**强制级别**：✅ 强约束（main 永远要保持可运行）