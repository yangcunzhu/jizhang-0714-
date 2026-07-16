# ADR-0010: 爱思助手(i4Tools)在中国 iOS 装机生态的真实地位

> **状态**: ✅ 已接受(2026-07-16)
> **日期**: 2026-07-16
> **决策者**: 用户 + Claude

---

## 背景

在 2026 年尝试真机部署 iOS App 时,发现国际工具链(Sideloadly / AltServer / AltStore)在 Apple 修改 Developer API 后**大面积失效**:

| 工具 | 状态 | 原因 |
|---|---|---|
| Sideloadly v0.60 | ❌ Invalid file / 2FA 发不出 | Python 3.8 EOL + OpenSSL 1.1 EOL,GSA 协议不兼容 |
| AltServer 1.7.4 | ❌ 3017 错误 | Apple Developer API 改动,AltStore Classic 团队 2025 停维护 |
| iMazing 试用 | ⚠️ 受限 | 功能限制 + 不识别新机型 |
| AltStore (iOS) | ❌ 需 AltServer 配对 | 同 AltServer 问题 |

**爱思助手(i4Tools)**作为中国本土 iOS 装机工具,在 2026 年仍然**正常工作**(成功装机验证:2026-07-16,iPhone 16 Pro Max / iOS 18.6.2)。

## 爱思助手核心能力

| 功能 | 爱思助手支持 |
|---|---|
| iPhone 设备信息(UDID / iOS 版本) | ✅ |
| **IPA 签名 + 装机**(Apple ID 签名) | ✅ 验证 |
| 越狱(新机型部分支持) | ✅ |
| 备份 / 恢复 | ✅ |
| 文件管理 | ✅ |
| 性能监控 | ✅ |
| **免费** | ✅ |
| **中文界面** | ✅ |
| 2026 年仍维护 | ✅ |

## 爱思助手装机流程(实测 2026-07-16)

```
1. USB 连 iPhone
2. 启动爱思助手(Windows 版, i4Tools9 v9.16.038)
3. 自动识别 iPhone(几秒)
4. 顶部菜单 → "工具箱"
5. "IPA 签名" → 添加 Runner.ipa
6. 选 "Apple ID 签名"
7. 输 Apple ID + 密码 + UDID
8. 点 "立即签名" → 自动装机(不生成签名后的 IPA 文件,直接装)
9. iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书
10. iPhone 设置 → 隐私与安全性 → 开发者模式 → 打开 + 重启
```

**关键特点**:
- 爱思助手直接调用 Apple 内部签名 API(类似 Xcode)
- 不依赖第三方 Anisette 服务器
- 7 天证书 + iOS 18.x 兼容良好

## 国内 vs 国际工具生态

| 维度 | 国际(Sideloadly / AltServer) | 国内(爱思助手) |
|---|---|---|
| **维护状态(2026)** | ⚠️ 部分停滞 | ✅ 活跃维护 |
| **新 iOS 兼容** | ❌ AltServer 不支持 iOS 18 完全 | ✅ i4Tools9 支持 iOS 18 |
| **新机型支持** | ⚠️ Sideloadly 偶发识别问题 | ✅ 第一时间支持新款 iPhone |
| **社区维护** | ✅ GitHub 开源 | ⚠️ 闭源(thinkvd 公司) |
| **中文文档** | ❌ 英文为主 | ✅ 中文 |
| **长期可用性** | 🟡 依赖社区(SideStore 接力) | 🟢 商业公司持续维护 |

## 中国开发者场景适配

**爱思助手天然适合**:
- 中国开发者/个人用户
- 自用 App / 测试 App
- 不需要上架 App Store
- 需要快速装机

**爱思助手不适合**:
- 多设备签名管理(企业场景)
- App Store 上架
- 自动化 CI/CD 装机(GitHub Actions 不支持)

## SideStore 作为自动续签伴侣

**SideStore(由 SideStore 开源团队)** 是 iOS 上的"个人 App 商店 + 续签引擎":

```
首次: 爱思助手装机 SideStore.app 到 iPhone
之后: SideStore 在 iPhone 自己续签已装的 Personal Team App
特点: 0 电脑依赖,完全 iPhone 本地操作
```

**SideStore vs AltStore 关系**:
- AltStore:经典方案,需要 AltServer 后台运行
- SideStore:新一代,自托管 anisette 服务,**不依赖 PC**

## 风险

| 风险 | 缓解 |
|---|---|
| 爱思助手闭源(thinkvd 公司) | 国内常用商业产品,公司一直在运营 |
| Apple 改协议 | 中国用户已习惯(类似酷我/QQ 音乐等生态独立),爱思助手通常 1 个月内跟进 |
| SideStore anisette 服务器被封 | 开源社区,多服务器备份,有 fallback |

## 相关文档

- ADR-0008: 部署架构终极方案
- ADR-0011: SideStore 长期风险与缓解
- SOP V4: 实操步骤

## 备注

**用户的洞察**:
- "我开发还有时间成本和算力成本,所以只可能是免费的"
- 用户早就知道爱思助手方案,但需要我"加上下文的认知"
- 本 ADR 把这个本土化方案正式记录到决策系统

**教训**:
- 国际化 AI 的工具推荐可能不匹配国内场景
- 用户在中国,工具在中国,需要本土化认知
- "质量优先、稳定优先"在国内场景 = 爱思助手 + SideStore