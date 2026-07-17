# ADR-0013: 分类图标采用 emoji 渲染

> 状态:**已接受**
> 日期:2026-07-21
> Stage:Stage 1 / Day 7
> 作者:Claude(执行)+ 用户(决策)

---

## 背景

分类需要可视化图标。Stage 1 Day 6 用了 Material Icons(iconName 存 `'restaurant'`、`'directions_car'` 等 codepoint 别名,UI 层 `_iconFor()` switch 映射成 `Icons.restaurant` / `Icons.directions_car` 等 `IconData` 渲染)。

Day 7 需要决定:继续 Material Icons 路径,还是切到 emoji。

---

## 决策

**采用 emoji,直接存进 `Categories.iconName` 字符串列,UI 层用 `Text(emoji)` 渲染。**

### emoji 映射(10 个默认分类)

| 名称 | 原 Material Icons codepoint | emoji |
|---|---|---|
| 餐饮 | restaurant | 🍔 |
| 交通 | directions_car | 🚗 |
| 购物 | shopping_bag | 🛍️ |
| 娱乐 | sports_esports | 🎮 |
| 居住 | home | 🏠 |
| 医疗 | local_hospital | 🏥 |
| 通讯 | smartphone | 📱 |
| 学习 | menu_book | 📚 |
| 其他 | category | 📦 |
| 工资 | payments | 💰 |

### UI 渲染

```dart
// CategoryGrid + TransactionTile + 后续账户卡片统一
Text(category.iconName, style: TextStyle(fontSize: 24))
```

---

## 后果

### 正面影响

| # | 影响 | 说明 |
|---|---|---|
| 1 | 跨平台一致 | iOS 自带 Apple Color Emoji,Android/桌面同理;无平台分支 |
| 2 | 用户直观 | 100+ 种记账 App 习惯用 emoji(MoneyWiz / Money Lover / Spendee)|
| 3 | 零依赖 | 系统字体已带 emoji,不需要引入 `font_awesome_flutter` 这类 4 MB 包 |
| 4 | Stage 2 自定义分类天然兼容 | 用户输入 emoji 当图标名,免维护图标映射表 |
| 5 | 简单 1 行 | `Text(emoji)` vs `_iconFor()` 13 行 switch + codepoint 别名管理 |
| 6 | 视觉亲和力 | emoji 比线条 icon 更"活泼",对个人记账用户更亲切 |

### 负面影响 / 风险

| # | 风险 | 缓解 |
|---|---|---|
| 1 | emoji 在小字号(< 16pt)渲染细节可能模糊 | UI 强制字号 ≥ 20pt(CategoryGrid 24pt,TransactionTile 20pt)|
| 2 | 跨平台 emoji 风格不一致(iOS vs Windows) | Stage 1 目标 iPhone,Apple Color Emoji 已是权威 |
| 3 | 自定义分类 emoji 拼写错误(用户输入乱字符) | Stage 2 输入框加 emoji picker,降低输入门槛 |
| 4 | iconName 列 schema 不需要改 | text(max=40)原生兼容 emoji(🍔 = 2 UTF-16 unit,占 4 字节)|

### 取舍说明

考虑过的替代方案:
- **Material Icons(原方案)** — 风格统一,不依赖系统,但视觉亲和力弱且需维护映射表。
- **图标包(iconfont / font_awesome)** — 风格统一,但需引入额外依赖 + 增加 APK 大小。
- **自定义 PNG** — 完全可控,但资产管理成本高,Stage 2 自定义分类上传图标又复杂一层。

emoji 是"质量 > 稳定 > 简单"三原则下的最优解。

---

## 后续影响

- [x] Day 7: `_defaultCategories` iconName 改 emoji
- [x] Day 7: `CategoryGrid` + `TransactionTile` 用 `Text` 渲染
- [ ] Stage 2: 自定义分类 UI 用 emoji picker,允许用户输入 emoji
- [ ] Stage 2: 多账户 UI 头像同样用 emoji(账户种类用 💵💳🏦 等)

---

## 参考

- iOS Human Interface Guidelines — Emoji(确认跨平台一致)
- flutter/material — `Text` widget 支持 emoji 字符串(已确认)
- 决策对齐:用户 Day 7 开工会话中确认(质量优先 > 稳定优先 > 简单优先)
