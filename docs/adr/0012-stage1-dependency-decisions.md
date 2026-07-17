# ADR-0012: Stage 1 依赖版本决策(Drift 工具链 + Riverpod 2.x)

> 状态：**已接受**
> 日期：2026-07-17
> 决策者：用户(Owner,授权 Claude 拍板)+ Claude(执行)
> 影响范围：Stage 1+ 所有代码生成与状态管理

---

## 背景

Stage 1 Day 4 首次引入 Drift + Riverpod 依赖并跑 `build_runner` 时,`flutter pub add` 自动解析出一组**互不兼容**的版本,导致代码生成崩溃:

1. **Drift 工具链坏组合**:`drift_dev 2.34.0` 的 pubspec 声明 `sqlparser: ^0.44.0`(即 `<0.45.0`),但其**源码调用了只有 sqlparser 0.45.0 才有的 `DartPlaceholder.when`** → AOT 编译 build 脚本即失败。这是上游的打包 BUG(约束与代码不一致)。

2. **深层约束互斥**:
   - `drift_dev ≥2.34.1` 依赖 `analyzer ^13.0.0`;
   - `flutter_riverpod 3.x → riverpod 3.x` 把 `test` 拉为运行时依赖,而 `test`(受 `flutter_test` 的 `test_api 0.7.11` 约束)锁 `analyzer <13.0.0`;
   - 两者在 analyzer 13 边界互斥,pub 只能退回到坏的 `drift_dev 2.34.0`。

3. **规划偏离**:项目文档(CLAUDE §1 / S01 Context)既定 **Riverpod 2.5+**,但 `pub add` 默认装了 3.3.2(3.x),超出规划且正是冲突源。

环境:Flutter 3.44.6 / Dart SDK 3.12.2(满足 sqlparser 0.45.0 所需的 `≥3.10.0`)。

---

## 决策

**锁定以下版本组合,回归项目既定 Riverpod 2.x:**

| 包 | 版本 | 说明 |
|---|---|---|
| `drift` | `^2.34.2` | 运行时,最新稳定 |
| `drift_dev` | `^2.34.4` | **修复版**(声明 `sqlparser ^0.45.0`,与代码一致) |
| `sqlparser` | `0.45.0` | 由 drift_dev 2.34.4 拉起,提供 `.when` |
| `analyzer` | `13.0.0` | drift_dev 2.34.4 要求 |
| `flutter_riverpod` | `^2.6.1` | **回归 CLAUDE 既定 2.5+**;2.x 不拉 `test`,解开 analyzer 冲突 |

**移除** `riverpod_generator` 与 `riverpod_annotation`:

- 二者仅用于 `@riverpod` 代码生成(可选语法糖),`riverpod_generator 4.0.4` 锁 `analyzer ^12`,与 drift_dev 2.34.4 的 analyzer 13 冲突;
- Riverpod 2.x 完全支持**手写 provider**(`NotifierProvider`/`StreamProvider` 等),Stage 1 采用手写方式,更少 codegen 步骤、更稳、更符合"简单优先"。

---

## 理由

1. **Drift 代码生成是 Stage 1 刚需**(schema 无 `.g.dart` 无法编译),必须优先满足 → drift_dev 修复版不可让步。
2. **Riverpod 2.x 本就是既定决策**,降级不是妥协而是纠偏,且 2.x 生态更成熟、示例更多。
3. **移除 riverpod codegen 比 `dependency_overrides` 覆盖坏约束更干净**,不留 hack 掩盖上游问题。
4. **手写 provider 对单人 MVP 足够**,codegen 的收益(样板减少)不足以抵消其依赖冲突成本。

---

## 替代方案

### 方案 A:`dependency_overrides` 强制 `sqlparser: 0.45.0`,保留 drift_dev 2.34.0 + riverpod 3.x

- ✅ 保留全部原计划依赖(含 riverpod codegen)
- ❌ 覆盖 drift_dev 2.34.0 声明的 `<0.45.0` 约束,属"绕过坏约束"的 hack
- ❌ 违背项目既定 Riverpod 2.5+,3.x API 迁移无收益
- **为什么没选**:留 hack,且偏离规划

### 方案 B:降 drift_dev 到 2.34.0 以下的自洽旧版(analyzer 12 + sqlparser 0.44)

- ✅ 保留 riverpod 3.x
- ❌ 放弃 Drift 最新修复,长期落后
- **为什么没选**:为迁就 riverpod 3.x 牺牲核心 ORM 工具链,主次颠倒

### 方案 C(**已采纳**):drift_dev 2.34.4 + riverpod 2.6.1 + 移除 riverpod codegen

- ✅ 核心工具链最新且自洽
- ✅ 回归既定 Riverpod 版本
- ✅ 无 hack
- ⚠️ Stage 1 起用手写 provider

---

## 后果

### 正面
- `build_runner` 成功,`flutter analyze` 0 issues,`flutter test` 8/8 通过。
- 依赖图干净无 override。
- 与既定架构决策(Riverpod 2.5+)一致。

### 负面
- 放弃 `@riverpod` 代码生成,provider 需手写(样板略多)。
- Riverpod 未来若必须升 3.x,需重新评估与 drift_dev 的 analyzer 兼容(见复盘条件)。

### 风险
- **CI 未跑 build_runner**:`.github/workflows` 无代码生成步骤 → 生成的 `*.g.dart` 必须提交进 git,否则 GitHub Actions 构建 iOS 因缺文件失败。
  - 缓解:本次已将 4 个 `.g.dart` 一并 commit(68e8d3d);后续新增生成物同样须提交,或(经授权后)在 CI 增加 build_runner 步骤。

---

## 复盘条件

出现以下情况重新评估:

1. Riverpod 3.x 成为必需(如需其独有特性)→ 重评 drift_dev 与 analyzer 的兼容矩阵。
2. drift_dev / sqlparser 发布新版修复约束或引入破坏性变更。
3. 手写 provider 样板量显著拖慢开发 → 重评是否引入兼容的 riverpod codegen。
4. CI 决定改为运行 build_runner → 可评估是否停止提交 `*.g.dart`。

---

**最后更新**：2026-07-17 · 创建
