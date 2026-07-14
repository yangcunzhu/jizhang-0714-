# ADR-0001: 技术栈选型（Flutter + Riverpod + Drift）

> 状态：**已接受**
> 日期：2026-07-14
> 决策者：用户（Owner）+ Claude（执行）
> 影响范围：整个 v1.0 → v2.0

---

## 背景

需要为 iOS 自用记账 App 选择前端技术栈。约束条件：
- 开发机是 Windows 11（无法直接编译 iOS）
- 必须能编译成 iOS .ipa
- 0 现金成本（无 Apple Developer 账号）
- 用户不懂技术，维护成本要低
- 需要长期演进（v1.0 → v2.0）

## 决策

**采用 Flutter 3.24+ + Riverpod 2.5+ + Drift 2.20+ 作为核心技术栈**

具体版本和组件：
| 层 | 技术 | 版本 | 理由 |
|---|---|---|---|
| 前端框架 | Flutter | 3.24+ | 跨平台、Windows 写代码、macOS 编译 |
| 语言 | Dart | 3.5+ | Flutter 原生 |
| 状态管理 | Riverpod | 2.5+ | 类型安全、测试友好 |
| 路由 | go_router | 14+ | 声明式路由、深度链接 |
| 数据库 | Drift | 2.20+ | 类型安全 ORM |
| 数据库加密 | SQLCipher | 4.5+ | AES-256 加密 |
| 图表 | fl_chart | 0.69+ | Flutter 生态最成熟 |
| 本地通知 | flutter_local_notifications | 17+ | iOS/Android 通用 |
| Siri Shortcuts | flutter_siri_shortcuts | 1.0+ | Siri 集成 |
| OCR | iOS Vision API（原生） | - | 本地 OCR，免费 |
| HTTP 客户端 | dio | 5+ | LLM API 调用 |
| 测试 | flutter_test + mocktail | - | 官方 + Mock |

## 理由

1. **跨平台**：Flutter 一套代码可在 Windows 开发，GitHub Actions macOS runner 编译 iOS
2. **类型安全**：Dart 的强类型 + Riverpod 的 Provider 系统，能在编译期捕获大部分错误
3. **生态成熟**：Drift / Riverpod / fl_chart 等都是 Flutter 生态主流库
4. **测试友好**：Riverpod 的 Provider 模式天然支持依赖注入和单元测试
5. **长期维护**：Dart 和 Flutter 都是 Google 主推，5 年内不会过时
6. **数据库选择**：Drift 支持类型安全查询 + SQL 迁移，比 Hive / sqflite 更适合复杂关系

## 替代方案

### 方案 A：原生 Swift
- ❌ Windows 不能开发 iOS，需要 Mac
- ❌ 单平台，无法扩展到 Android
- ❌ 学习曲线陡
- ✅ 性能最好

### 方案 B：React Native
- ❌ 性能不如 Flutter（动画卡顿）
- ❌ 桥接复杂
- ❌ TypeScript 类型推断不如 Dart 强
- ✅ 生态大

### 方案 C：SwiftUI（仅 iOS 16+）
- ❌ Windows 完全无法开发
- ❌ 单平台

### 方案 D：Uni-app / Taro
- ❌ 性能介于原生和 RN 之间
- ❌ 生态不如 Flutter
- ❌ 主要面向 Web/小程序

## 后果

### 正面
- 一套代码双平台（未来可加 Android）
- 热重载开发效率高
- Riverpod + Drift 让大型 App 可维护
- 类型安全减少运行时错误

### 负面
- App 包体积略大（~30-50 MB vs 原生 ~10 MB）
- 复杂动画性能略低于原生
- iOS 原生 API（Vision / Siri）需要写桥接代码
- Flutter 版本升级偶尔需要 breaking change 适配

### 风险
- Flutter 长期支持：Google 主推 5+ 年，但需关注 Web/desktop 路线
- 包维护：Riverpod 3.x 即将发布（2026），需评估升级
- iOS 政策风险：Apple 可能对非原生 App 政策变化（极低概率）

## 复盘条件

如果出现以下情况，重新评估：
1. Flutter 被 Google 抛弃（极低概率）
2. iOS Vision API 在 Flutter 中无法桥接（用原生代码 + Pigeon 已验证可行）
3. Riverpod 3.x 升级破坏现有代码（延期升级）
4. 包体积超过 80 MB（实际估算 ~40 MB）

## 实施细节

- Pubspec.yaml 锁定 minor 版本：`^3.24.0` 而非 `>=3.24.0`
- 所有原生桥接代码放 `ios/Runner/`
- 数据库 schema 用 Drift code generation
- 状态管理用 Riverpod 2.x（暂不升级 3.x）

---

**最后更新**：2026-07-14 · 创建
**下次更新**：Flutter 大版本升级前重新评估
