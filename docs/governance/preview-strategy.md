# 开发期预览策略（Chrome / Simulator / 真机）

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：v1.0 全期开发流程

---

## 🎯 目的

- 明确开发期三种预览方式的**适用场景**
- 避免在 Chrome Web 上看到 iOS 风格组件显示成 Material 而误判 UI
- 确保关键 Stage 收尾都用真机验收

---

## 📊 三种预览方式对比

| 方式 | 启动速度 | iOS 真实性 | 关键能力 | 本项目角色 |
|---|---|---|---|---|
| **Chrome (Web)** | ⚡ 秒开 | ⭐ 完全不同（Material 风） | 纯 UI 调试 | ⚠️ 辅助（仅 layout/颜色微调）|
| **iOS Simulator** | 🚀 10 秒 | ⭐⭐⭐ 接近真机 | 90% iOS API | ✅ **主力开发预览** |
| **真机 (AltStore)** | 🐢 5-10 分钟打包 | ⭐⭐⭐⭐⭐ 100% | 全部硬件 API | ✅ Stage 收尾验收 |

---

## 🛠 推荐组合

### 主力：iOS Simulator（每日 90% 时间）

**何时用**：
- 写新功能、热重载看效果
- 调试布局、字号、颜色
- 验证交互逻辑、动画

**启动命令**：
```bash
# 列出可用设备
flutter devices

# 指定模拟器启动（Mac）
flutter run -d "iPhone 15"
flutter run -d "iPhone SE (3rd generation)"

# Web 调试（仅 layout 测试）
flutter run -d chrome
```

**优势**：
- 热重载 1 秒看到改动
- iOS 风格 100% 真实（CupertinoNavigationBar 等）
- 安全区（Safe Area）、状态栏、刘海屏全部正确
- 免费，Mac 自带

**局限**（与真机差异）：
- 性能比真机略好（Mac CPU 强）
- 无相机、相册、推送、触感
- 无 iCloud Keychain
- 无法测试弱网、杀后台、低电量

---

### 辅助：Chrome Web（每周 5% 时间）

**何时用**：
- 调试 widget 的 padding/margin 数值
- 对比 Material vs Cupertino 同名组件
- 截图做文档（不需要完整 iOS 风格时）

**⚠️ 警告**：
- iOS 专属组件（CupertinoNavigationBar、CupertinoButton 等）在 Chrome 上显示为 Material 风格
- **不要用 Chrome 的截图当 v1.0 UI 验收标准**
- 不要在 Chrome 上判断 Cupertino 组件是否正确

---

### 关键节点：真机（每个 Stage 收尾 1 次）

**何时用**：
- 每个 Stage 进入 ROA 阶段时
- 涉及以下功能时**必须**真机测：
  - 摄像头 / 相册（OCR）
  - 触感反馈（Haptics）
  - iCloud Keychain
  - 推送通知
  - 后台任务
  - 性能（启动时间、滚动 FPS）

**安装方式**：
- 本项目用 **AltStore** + GitHub Actions 打包 IPA
- 详见 [governance/error-catalog.md § A-002](./error-catalog.md) 安装排错

---

## 📐 分辨率自适应

### Flutter 自动适配

Flutter 用**逻辑像素（pt/dp）**，写死数值即可：

```dart
// 不用关心实际像素密度，Flutter 自动处理
Container(
  width: 200,        // 所有 iPhone 都显示为"200 逻辑宽"
  padding: EdgeInsets.all(16),
  fontSize: 17,
)
```

### 测试矩阵（必须覆盖）

| 设备 | 分辨率 | 用途 |
|---|---|---|
| **iPhone SE (3rd)** | 375 × 667 | 小屏极限（文字不溢出、按钮不挤） |
| **iPhone 14** | 390 × 844 | 主流机型 |
| **iPhone 15 Pro Max** | 430 × 932 | 大屏极限（布局不空荡、留白合理） |

**最低要求**：每个 Stage 收尾在 **小屏 + 大屏** 各跑一次。

### 字体/图标自适应

```dart
// 启用系统字体缩放
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
  child: ...,
)

// 或者尊重用户设置
Text('Hello', style: TextStyle(fontSize: 17))  // 系统"动态字体"开启时自动放大
```

**注意**：本项目面向**单人自用**，可锁定缩放为 1.0 简化逻辑，但仍需在 Simulator 设置中切换试一次。

---

## 🧪 验收清单（每次 Stage ROA 前）

- [ ] iPhone SE 模拟器：布局不溢出、按钮可点、文字不截断
- [ ] iPhone 15 Pro Max 模拟器：布局不空荡、留白合理
- [ ] 真机：本 Stage 新增的核心功能跑通
- [ ] 真机：启动时间 ≤ 性能预算（见 [performance-budgets.md](./performance-budgets.md)）
- [ ] 真机：与下一 Stage 衔接的接口正常工作

---

## 🚨 常见陷阱

| 陷阱 | 后果 | 避免方法 |
|---|---|---|
| 在 Chrome 上调 Cupertino 组件 | iOS 上显示完全错位 | iOS 组件必须在 Simulator 调 |
| 只用一种尺寸模拟器 | 小屏/大屏出问题 | SE + Pro Max 各跑一次 |
| 模拟器判断"性能 OK" | 真机卡顿 | 关键 Stage 必须真机测 FPS |
| 模拟器测 OCR / 相机 | 完全跑不通 | 硬件 API 必须真机 |
| 真机没配证书 | 装不上 | 见 [error-catalog.md § A-003](./error-catalog.md) |

---

## 📌 开发期命令速查

```bash
# 列出设备
flutter devices

# 启动 iPhone 15 模拟器
flutter run -d "iPhone 15"

# 启动 iPhone SE 模拟器
flutter run -d "iPhone SE (3rd generation)"

# 切换到 Chrome（仅辅助）
flutter run -d chrome

# 热重载（保存代码自动触发，按 r 手动）
# 热重启（按 R，状态丢失）
# 退出（按 q）

# 查看性能 profile
flutter run --profile
```

---

**最后更新**：2026-07-14 · 创建
**下次更新**：Stage 1 完成后补充实战经验
