# ADR-0002: 项目结构（Feature-based Clean Architecture）

> 状态：**已接受**
> 日期：2026-07-14
> 决策者：用户（Owner）+ Claude（执行）
> 影响范围：整个 v1.0 → v2.0 代码组织

---

## 背景

需要一个清晰的项目结构来组织 v1.0 的 20 项 P0 功能代码。约束：

- 项目预计 1-3 万行代码（不含测试）
- 多个 feature 模块（记账、分类、账户、信用卡等）
- 长期演进（v1.0 → v2.0）
- 团队可能扩展（虽然现在只有我+AI）
- 测试友好
- Clean Architecture 思想

---

## 决策

**采用 Feature-based + Clean Architecture 变体**

具体分层：

```
lib/
├── core/              ← 跨功能共享
├── data/              ← 数据层（全局共享）
├── domain/            ← 领域层（全局共享）
├── presentation/      ← 表现层（全局共享）
└── features/          ← 功能模块（feature-based）
    ├── record/
    ├── categories/
    ├── accounts/
    ├── credit_cards/
    ├── books/
    ├── budget/
    ├── dashboard/
    ├── storage/
    └── zan_zan/
```

---

## 理由

1. **Feature-based 而不是 type-based**：改一个 feature 只需在一个目录，删除/重构/移植都方便
2. **Clean Architecture 三层**：data → domain → presentation 依赖清晰
3. **共享代码放 core/**：颜色、字体、工具等全局共享的不污染 feature
4. **测试友好**：每个 feature 独立测试，不互相依赖
5. **删除 feature 简单**：`rm -rf features/xxx/` 一行搞定
6. **长期可扩展**：v2.0 加新 feature 直接加新目录

---

## 替代方案

### 方案 A：Type-based（按类型组织）

```
lib/
├── models/
├── widgets/
├── pages/
├── services/
└── repositories/
```

- ❌ 改一个 feature 要改 5 个目录
- ❌ 跨 feature 引用混乱
- ✅ 简单直接

**为什么没选**：项目大了会失控

---

### 方案 B：纯 Clean Architecture（无 feature）

```
lib/
├── data/
├── domain/
└── presentation/
```

- ❌ 没有 feature 边界，所有东西混在一起
- ❌ 删除功能时无法独立删
- ✅ 严格分层

**为什么没选**：缺少 module 概念

---

### 方案 C：Mono-file（所有代码在一个目录）

```
lib/
└── *.dart
```

- ❌ 文件多了就乱
- ✅ 最简单

**为什么没选**：项目大了不可能

---

## 后果

### 正面

- 一个 feature 集中在 `features/xxx/`
- 删除 feature 一行命令
- 跨 feature 共享有明确路径（`core/` 或 `domain/`）
- 测试可按 feature 组织

### 负面

- 初期略复杂（要在 features 和 core/domain 之间决策）
- 需要纪律（共享代码不能乱放）

### 风险

- 共享代码提升到 core/ 的判断不明确 → 通过 [governance/project-structure.md](../governance/project-structure.md) 写清楚
- Feature 之间互相 import → 通过 lint 规则禁止

---

## 实施细节

- `lib/core/` 放跨 feature 共享
- `lib/domain/` 放全局共享的领域对象
- `lib/features/xxx/data/`、`domain/`、`presentation/` 三层
- 每个 feature 内部独立，可独立测试
- 详细规范：[governance/project-structure.md](../governance/project-structure.md)

---

## 复盘条件

如果出现以下情况，重新评估：

1. Features 之间互相引用太多（违反边界）
2. 删除一个 feature 仍然影响其他代码
3. v2.0 加新平台（Android）需要完全不同的结构
4. Package 边界（每个 feature 一个 package）更适合

---

**最后更新**：2026-07-14 · 创建