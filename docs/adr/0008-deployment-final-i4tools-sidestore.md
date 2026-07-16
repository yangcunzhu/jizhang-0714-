# ADR-0008: 部署架构终极方案(爱思助手 + SideStore)

> **状态**: ✅ 已接受(2026-07-16)
> **日期**: 2026-07-16
> **决策者**: 用户(指挥官) + Claude(大副) + 新电脑 Claude(执行)
> **替代**: ADR-0004(已 SUPERSEDED)
> **关联 ADR**: 0005(免费 Apple ID 真实路径), 0010(爱思助手生态), 0011(SideStore 风险)

---

## 背景

Stage 0 真机验证期间,经历了多次方案迭代:

| # | 方案 | 状态 | 原因 |
|---|---|---|---|
| 1 | Apple Developer Program(付费) | ❌ 放弃 | 用户硬性约束"0 成本"(ADR-0001) |
| 2 | 在 developer.apple.com 手动建证书/Profile | ❌ 失败 | 免费 Apple ID 无法访问(2026 规则) |
| 3 | AltServer + AltStore 7×24 WiFi | ⏸ 拖延 | AltServer 1.7.4 报 3017(Apple Developer API 已改,AltStore Classic 团队停维护) |
| 4 | Sideloadly v0.60 | ❌ 失败 | Python 3.8 EOL + OpenSSL 1.1 EOL,GSA 协议不兼容 Apple 当前服务器 |
| 5 | iMazing(试用 15 天) | ⚠️ 试用 | 受限 + 不识别 iPhone(开发机) |
| **6** | **爱思助手(i4Tools)** | **✅ 验证成功** | **iPhone 16 Pro Max / iOS 18.6.2 已装 "Hello 审计官"** |
| **7** | **SideStore**(自动续签) | **✅ 终极方案** | **装 1 次后,iPhone 自己续签所有 App,0 电脑依赖** |

## 决策

**部署架构采用爱思助手 + SideStore 两件套**:

```
┌──────────────────────────────────────────────────────┐
│ 第 1 步:首次装机(一次性,30 分钟)                      │
├──────────────────────────────────────────────────────┤
│ 爱思助手(i4Tools)                                    │
│   ↓ USB 连 iPhone                                    │
│   ↓ 工具箱 → IPA 签名 → 添加 Runner.ipa              │
│   ↓ 选 Apple ID 签名 + 输 Apple ID + 密码           │
│   ↓ 自动签名 + 装到 iPhone                            │
│   ↓ iPhone:设置 → VPN 与设备管理 → 信任证书           │
│   ↓ iPhone:设置 → 开发者模式 → 打开 → 重启           │
│ 结果:iPhone 看到 "Hello 审计官" ✅                  │
└──────────────────────────────────────────────────────┘
                          ↓ 升级(可选,推荐)
┌──────────────────────────────────────────────────────┐
│ 第 2 步:装 SideStore(终身免维护)                      │
├──────────────────────────────────────────────────────┤
│ 爱思助手首次 sideload SideStore IPA                   │
│   ↓ iPhone 打开 SideStore                             │
│   ↓ Apple ID 登录(用 anisette 凭证)                  │
│   ↓ SideStore 接管所有 Personal Team App 续签        │
│   ↓ 默认每天凌晨自动续签过期 App                      │
│ 结果:完全不需要电脑!所有 Personal Team App          │
│       在 iPhone 上自动续签                            │
└──────────────────────────────────────────────────────┘
```

## 关键不变量

| 项 | 值 |
|---|---|
| **Apple ID** | `[APPLE_ID_EMAIL]`(免费,非 $99 付费) |
| **Bundle ID** | iMazing 暂用 `com.shenjiguan.jizhang`,SideStore 自动调整 |
| **iPhone** | 16 Pro Max / iOS 18.6.2 / UDID [IPHONE_UDID] |
| **Runner.ipa** | `E:\jizhang-0714\.ai-work\Runner.ipa`(5.80 MB,gitignored) |
| **首次工具** | 爱思助手 i4Tools9 v9.16.038 |
| **长期续签** | SideStore(首次装后接管) |
| **旧电脑角色** | **完全退役**(不再需要 7×24 在线) |

## 后果

### 正面
- ✅ **0 成本永久方案**:SideStore + 爱思助手 + 免费 Apple ID,永久免费
- ✅ **完全 0 电脑依赖**:SideStore 装好后,iPhone 自己续签,无需任何电脑参与
- ✅ **不需要 7×24 旧电脑**:旧电脑退役,完全不需要
- ✅ **不需要 WiFi 网络依赖**:SideStore 在 iPhone 本地跑
- ✅ **不需要充电依赖**:SideStore 不依赖充电
- ✅ **Apple ID 不变**:[APPLE_ID_EMAIL] 永久使用
- ✅ **每次装机 30 秒**:爱思助手手动 7 天重装(过渡期),或者 SideStore 自动

### 负面 / 风险
- ⚠️ **Apple 改 Developer 协议**(长期风险)
  - 2020-2024:AltStore 主导,2024 后 Apple 改 API,AltServer 报错
  - 2025-2026:Sideloadly 因 OpenSSL 1.1 EOL 不兼容
  - 2026 现在:爱思助手 + SideStore 主导
  - **缓解**:开源社区通常 1-3 个月跟进(详见 ADR-0011)

### 中性
- 🟦 **过渡期(7 天手动)**:SideStore 装上前的过渡期,每 7 天用爱思助手重装
- 🟦 **爱思助手需要 PC**:首次装机需要 PC(和 SideStore 装机时各一次)

## 替代方案(已考虑并放弃)

### ~~A. AltServer + 旧电脑 7×24~~(ADR-0004 旧)
- ❌ AltServer 1.7.4 报 3017
- ❌ 旧电脑需要常开
- ❌ WiFi + 充电依赖
- 排除,已被 ADR-0008 替代

### ~~B. Sideloadly(国际工具)~~
- ❌ Python 3.8 EOL + OpenSSL 1.1 EOL
- ❌ GSA 协议不兼容
- ❌ 2FA 都发不出去
- 排除

### ~~C. iMazing 试用~~
- ⚠️ 试用 15 天,功能受限
- ⚠️ 部分机型不识别
- 排除

### D. 爱思助手单机使用(无 SideStore)
- ⚠️ 7 天手动续签
- 🟢 简单,适合"先验证"阶段
- **已采用**:Stage 0 验证用 D 方案(Day 3)
- **未来升级为**:爱思助手 + SideStore(本 ADR 终极方案)

### E. 付费 Apple Developer Program($99/年)
- ❌ 违反 0 成本约束(ADR-0001)
- 排除

## 操作步骤(SOP V4)

详见 `docs/stages/S00-day3-sop.md` V4。

## 爱思助手 + SideStore 生态

详见 ADR-0010(爱思助手生态)与 ADR-0011(SideStore 风险)。

## 历史教训

1. **2026 年的 iOS 真机部署需要本土化方案**:Sideloadly / AltServer 在国际圈知名,但 Apple 改 API 后失效。爱思助手在中国长期维护,稳定可靠。
2. **不要迷信国际主流方案**:用户的实际场景 + 国内工具生态可能与国际最优解完全不同。
3. **SideStore 是 SideStore 团队的开源贡献**:基于开源 anisette 服务器,绕开 Apple 的开发协议限制。生态虽然脆弱,但非常实用。

## 相关文档

- `docs/stages/S00-day3-sop.md` V4 — 操作手册
- `docs/adr/0004-deployment-strategy.md` — 已被 SUPERSEDED
- `docs/adr/0005-free-apple-id-real-path.md` — 免费 Apple ID 真相(仍有效)
- `docs/adr/0010-i4tools-ecosystem.md` — 爱思助手生态
- `docs/adr/0011-sidestore-long-term-risk.md` — SideStore 长期风险
- `docs/daily/2026-07-16.md` — 决策 #4
- `docs/daily/2026-07-17.md` — Day 3 结束卡
- `product-design-v4.html §2.12` — 部署架构(部分假设过时,实践后修订)

## 备注

本 ADR 是 Stage 0 完成后的总结,**Stage 0 验收(S00)正式 DONE**。

Stage 1+(手动记账 MVP)继续使用本方案,直到 Apple 协议大改导致 SideStore 失效。届时需要走 ADR-0011 的 fallback 路径。