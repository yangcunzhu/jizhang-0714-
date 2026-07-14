# 设计系统

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有 UI 设计

---

## 🎯 设计原则

1. **iOS HIG 优先**（Human Interface Guidelines）
2. **克制**：少即是多，不堆砌颜色和动效
3. **一致性**：相同组件永远相同表现
4. **可访问性**：支持 Dynamic Type、色弱模式

---

## 🎨 颜色系统

### 主色板（Primary）

| Token | Hex | 用途 |
|---|---|---|
| `primary` | `#2E5BFF` | 主按钮、链接、关键操作 |
| `primaryLight` | `#5B8FFF` | 按钮 hover/pressed |
| `primaryDark` | `#1E3FBF` | 强调、激活态 |

### 语义色（Semantic）

| Token | Hex | 用途 |
|---|---|---|
| `success` | `#10B981` | 收入、还款成功 |
| `warning` | `#F59E0B` | 预算警告、即将逾期 |
| `danger` | `#EF4444` | 超支、逾期、错误 |
| `info` | `#3B82F6` | 提示信息 |

### 收入/支出色

| Token | Hex | 用途 |
|---|---|---|
| `incomeColor` | `#10B981` | 收入金额（绿色） |
| `expenseColor` | `#EF4444` | 支出金额（红色） |
| `transferColor` | `#6B7280` | 转账（灰色） |

### 中性色（Neutral）

| Token | Hex | 用途 |
|---|---|---|
| `textPrimary` | `#1F2937` | 主文本 |
| `textSecondary` | `#6B7280` | 次要文本 |
| `textTertiary` | `#9CA3AF` | 辅助文本 |
| `divider` | `#E5E7EB` | 分割线 |
| `background` | `#F9FAFB` | 背景 |
| `surface` | `#FFFFFF` | 卡片/弹层背景 |

### 深色模式（v1.1 启用，先预留）

| Token | Hex |
|---|---|
| `bgDark` | `#0F172A` |
| `surfaceDark` | `#1E293B` |
| `textPrimaryDark` | `#F1F5F9` |

---

## 🔤 字体系统

### iOS 默认

- **中英文混排**：PingFang SC / SF Pro
- **数字金额**：SF Pro Rounded（更圆润）
- **代码**：SF Mono

### 字号阶梯

| Token | Size | Weight | 用途 |
|---|---|---|---|
| `displayLarge` | 32 | 700 | 大标题（如净资产） |
| `displayMedium` | 28 | 700 | 页面标题 |
| `headline` | 22 | 600 | 区块标题 |
| `title` | 18 | 600 | 卡片标题 |
| `body` | 16 | 400 | 正文 |
| `bodyEmphasis` | 16 | 500 | 强调正文 |
| `caption` | 14 | 400 | 辅助文字 |
| `micro` | 12 | 400 | 极小文字 |

### 行高

- 中文：1.6
- 英文：1.4
- 数字（金额）：1.2

---

## 📏 间距系统

### 8 倍数

| Token | Size | 用途 |
|---|---|---|
| `spacing0` | 0 | - |
| `spacing1` | 4 | 极小间距 |
| `spacing2` | 8 | 小间距 |
| `spacing3` | 12 | 卡片内 padding |
| `spacing4` | 16 | 标准间距 |
| `spacing5` | 24 | 区块间距 |
| `spacing6` | 32 | 页面间距 |
| `spacing7` | 48 | 大区块 |
| `spacing8` | 64 | 极大间距 |

### 圆角

| Token | Size | 用途 |
|---|---|---|
| `radiusSmall` | 4 | 小元素 |
| `radiusMedium` | 8 | 按钮、输入框 |
| `radiusLarge` | 12 | 卡片 |
| `radiusXLarge` | 16 | 弹层 |
| `radiusCircle` | 999 | 头像、圆形按钮 |

---

## 🌗 阴影

| Token | Value | 用途 |
|---|---|---|
| `shadowSm` | `0 1px 2px rgba(0,0,0,0.05)` | 卡片轻微阴影 |
| `shadowMd` | `0 4px 6px rgba(0,0,0,0.07)` | 悬浮按钮 |
| `shadowLg` | `0 10px 25px rgba(0,0,0,0.1)` | 弹层 |

---

## 📐 布局规范

### 屏幕边距

- 左右安全边距：16px
- 顶部状态栏：自动适配
- 底部 Home Indicator：34px 安全区

### 触控目标

- 最小 44×44pt（iOS HIG）
- 按钮高度：44pt（小）/ 50pt（标准）
- 列表项高度：56-72pt

---

## 🔘 组件库

### Button

```dart
// 主要按钮
PrimaryButton(
  text: '保存',
  onPressed: () {},
)

// 次要按钮
SecondaryButton(
  text: '取消',
  onPressed: () {},
)

// 文字按钮
TextButton(
  text: '跳过',
  onPressed: () {},
)
```

**尺寸**：
- 大：高度 50，padding 16
- 中：高度 44，padding 12
- 小：高度 32，padding 8

**状态**：
- 默认、Pressed、Disabled、Loading

---

### Card

```dart
AppCard(
  child: Column(...),
  padding: EdgeInsets.all(AppSpacing.spacing4),
  elevation: AppShadow.shadowSm,
)
```

- 圆角：12
- 阴影：shadowSm
- 内边距：16

---

### ListTile

```dart
AppListTile(
  leading: Icon(...),
  title: Text('标题'),
  subtitle: Text('副标题'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)
```

- 高度：56-72
- 内边距：16
- 分割线：divider

---

### TextField

```dart
AppTextField(
  label: '金额',
  hint: '0.00',
  keyboardType: TextInputType.number,
  prefix: Text('¥'),
  validator: (v) => v == null || v.isEmpty ? '请输入金额' : null,
)
```

- 高度：48
- 圆角：8
- 边框：1px divider
- 聚焦：2px primary

---

### BottomSheet

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.radiusXLarge),
    ),
  ),
  builder: (_) => YourSheet(),
);
```

- 圆角：16（顶部）
- 背景：surface
- 拖拽指示器：12×4 圆角矩形

---

### Dialog

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('确认删除？'),
    content: Text('此操作不可撤销。'),
    actions: [
      TextButton(text: '取消', onPressed: () => Navigator.pop(context)),
      PrimaryButton(text: '删除', onPressed: () {}),
    ],
  ),
);
```

---

## 📊 数据可视化

### 图表（Stage 5）

| 图表类型 | 用途 | 颜色 |
|---|---|---|
| 折线图 | 净资产走势 | primary |
| 柱状图 | 月度收支 | incomeColor / expenseColor |
| 饼图 | 分类占比 | 分类色 |
| 热力图 | 打卡日历 | primary 透明度 |

---

## 🎬 动画规范

### 时长

| 场景 | 时长 |
|---|---|
| 按钮反馈 | 100ms |
| 弹层出现 | 250ms |
| 页面切换 | 300ms |
| 攒攒反馈 | 800ms |

### 缓动函数

- 进入：`Curves.easeOutCubic`
- 退出：`Curves.easeInCubic`
- 弹性：`Curves.elasticOut`（攒攒专用）

---

## 🎭 攒攒（ZanZan）人格化设计

### 形象

- 默认：🐷（胖乎乎的小猪）
- 攒钱成功：✨（闪亮）
- 超支：😢（哭泣）
- 危险：⚠️（警告）

### 动画

- 出现：弹跳进入（800ms elasticOut）
- 攒钱成功：旋转 + 闪光
- 失败：摇头

---

## 📱 平台适配

### iPhone 屏幕

| 设备 | 屏幕宽度 | 备注 |
|---|---|---|
| iPhone SE | 375 | 紧凑布局 |
| iPhone 15 | 393 | 标准 |
| iPhone 15 Pro Max | 430 | 宽松布局 |
| iPad（v2.0） | 768+ | 后续适配 |

### 适配策略

- 用 `MediaQuery.of(context).size` 而非硬编码
- 用 `LayoutBuilder` 做响应式
- 关键内容居中，避免拉伸

---

## 🌐 国际化（i18n · v1.0 中文 only）

v1.0 仅中文，但代码结构预留：

```dart
// ✅ 好（虽然 v1.0 不用，但留好结构）
Text(AppLocalizations.of(context).recordButton)

// ❌ 差（硬编码）
Text('记一笔')
```

Stage 1 开始就用 `intl` 包 + `.arb` 文件。

---

## 📌 一致性检查

- [ ] 所有颜色用 token，不用 hex
- [ ] 所有间距用 spacing token，不用裸数字
- [ ] 所有字体用 text style token
- [ ] 所有圆角用 radius token
- [ ] 所有阴影用 shadow token
- [ ] 所有组件用 core/widgets/

违反 → 督察审计时报告。

---

**最后更新**：2026-07-14 · 创建
**v1.1 待办**：深色模式、动态色、国际化