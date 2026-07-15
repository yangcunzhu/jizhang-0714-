# ADR-0005: 免费 Apple ID 在 iOS 真机部署的真实路径

> **状态**: 已接受
> **日期**: 2026-07-14
> **决策者**: 用户(指挥官) + Claude(大副执行)
> **ADR 系列**: 0001 Flutter 技术栈 · 0002 项目结构 · 0003 测试策略 · 0004 部署策略

---

## 背景

用户硬性约束:"0 成本,绝不付费 Apple Developer Program($99/年)"

最初按 `product-design-v4.html §8.48` 文档规划:在 developer.apple.com 网站创建 App ID / Apple Development 证书 / Provisioning Profile。

实操时报错:

> This resource is only for developers enrolled in a developer program or members of an organization's team in a developer program.

## 真相(2026 年 7 月 Apple 当前规则)

| 操作 | 免费 Apple ID | 付费 Developer Program($99/年) |
|---|---|---|
| 登录 developer.apple.com | ✅ | ✅ |
| **手动**创建 Explicit App ID | ❌ | ✅ |
| **手动**创建 Certificate / Profile | ❌ | ✅ |
| Xcode **自动**签名(Personal Team) | ✅ | ✅ |
| AltStore / Sideloadly 自动签名 | ✅ | ✅ |
| TestFlight / App Store 发布 | ❌ | ✅ |

**关键洞察**:免费 Apple ID 也能在 iPhone 真机跑 App,但**不能用 developer.apple.com 网站手动操作**,必须借助以下任一工具:

1. **Xcode** 的"Sign in with Apple ID"(自动生成 7 天有效证书)
2. **AltStore** + AltServer(后台自动续签)
3. **Sideloadly**(独立 GUI,每次手动 30 秒)

## 决策

**真机部署路径**(0 成本 + 免费 Apple ID):

```
短期: Runner.ipa → Sideloadly → iPhone(每 7 天手动一次)
长期: Runner.ipa → AltServer + AltStore → iPhone(WiFi 自动续签)
```

**禁止路径**(已放弃):
- ❌ 在 developer.apple.com 手动创建证书/Profile
- ❌ GitHub Actions 签名 build(改产出未签名 .ipa)
- ❌ 付费 Developer Program

## Bundle ID 真相

| 路径 | Bundle ID |
|---|---|
| AltServer + AltStore | **自动生成**(`<your-name>.*`,不能显式指定) |
| Sideloadly | **可自定义**(可写 `com.shenjiguan.jizhang`) |

短期 Sideloadly 阶段可以用 `com.shenjiguan.jizhang`,长期 AltServer 阶段会被 Xcode 改写成自动生成的 ID。

## 个人 Team 证书机制

免费 Apple ID 登录后,Xcode 自动创建一个"个人团队"(Personal Team):
- Team ID: 10 位字符(Apple 随机分配)
- 个人开发者证书(免费)
- 7 天有效(续签延长)
- 仅自己设备可用
- 不能用付费功能(push / IAP / Wallet 等)

**限制说明**:v1.0 MVP 是自用记账 App,不依赖这些高级功能,免费方案完全够用。

## 后果

### 正面
- ✅ 0 成本永久方案
- ✅ Apple ID 不变(切换工具不换账号)
- ✅ Bundle ID 短期可自定义(Sideloadly 阶段)

### 负面 / 风险
- ⚠️ 长期 AltServer 阶段 Bundle ID 自动生成(不能 `com.shenjiguan.jizhang`)
  - 缓解:Apple ID 自动生成形式仍可用,功能不受影响
- ⚠️ 不能用付费功能
  - 缓解:v1.0 MVP 不需要,后续功能(如 push)考虑 v1.1 升级到付费 Program

### 中性
- 🟦 Sideloadly 和 AltServer 共享同一个 Personal Team 证书
- 🟦 切换方案时,iPhone 上已装的 App 数据不丢失

## 替代方案(已考虑并放弃)

### A. 付费 Developer Program($99/年)
- ❌ 违反 0 成本硬性约束
- ✅ 完整功能 + TestFlight
- 排除

### B. 咔皮 / 其他记账 App
- ❌ 用户要自建,不是用第三方
- 排除

### C. App Store 上架(免费)
- ❌ 审核 + 自用不适合上架
- 排除

## 关键经验(教训)

1. **产品文档可能基于过时假设**:`product-design-v4.html §8.48` 描述的"手动创建 App ID/证书"路径在 2026 年需要付费 Program 才能访问。
2. **动手前先验证假设**:Day 2 直接走文档写的路径,失败后才回头找真实方案。理想顺序:先读文档 + 实操验证可行性 → 再写实施计划。
3. **0 成本路线完全可行**:虽然手动配置限制多,但借助工具(Sideloadly / AltStore)可以 100% 达到目的。

## 相关文档

- `docs/daily/2026-07-16.md` 决策 #1(放弃付费 Program)
- `docs/daily/2026-07-16.md` 决策 #2(GitHub Actions 不签名)
- `docs/daily/2026-07-16.md` 决策 #3(两阶段部署)
- `docs/adr/0004-deployment-strategy.md` 部署策略
- `product-design-v4.html §2.12 / §8.48`(原始假设)

## 参考

- [Apple Developer Program enrollment](https://developer.apple.com/programs/enroll/)
- [AltStore 官方文档](https://altstore.io)
- [Sideloadly 官方文档](https://sideloadly.io)