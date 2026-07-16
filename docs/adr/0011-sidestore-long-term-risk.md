# ADR-0011: SideStore 长期风险与缓解

> **状态**: ✅ 已接受(2026-07-16)
> **日期**: 2026-07-16
> **决策者**: 用户 + Claude

---

## 背景

SideStore 是 iOS 上的"自动续签引擎",基于开源 anisette 服务器绕开 Apple 协议限制。本 ADR 记录其长期风险与缓解策略。

## 风险评估

### 🔴 风险 1:Apple 改 Developer API(已发生)

**历史**:
- 2020-2022:AltStore 主导,iOS 装机生态稳定
- 2023-2024:Apple 加强 Developer API 验证,AltStore 报错增多
- 2025-2026:AltServer 1.7.4 报 3017,AltStore Classic 团队停维护;Sideloadly 因 OpenSSL 1.1 EOL 不兼容
- 2026-07:Sideloadly / AltServer 大面积失效,爱思助手 + SideStore 接棒

**未来预期**:Apple 每隔 1-3 年会再次强化验证

**缓解**:
- ✅ 开源社区(SideStore / GitHub)通常 1-3 个月跟进
- ✅ 爱思助手作为 fallback(中国生态独立,跟进更快)
- ✅ 用户的 App 数据本地存储,签名变化不影响数据

**严重程度**:🟡 中(可恢复,需 1-3 月等待)

### 🟡 风险 2:Anisette 社区服务器被封

**场景**:SideStore 依赖社区 anisette 服务器(为 Apple ID 凭证提供支持)。这些服务器可能被 Apple 干扰。

**缓解**:
- ✅ 多个公开 anisette 服务器(冗余)
- ✅ SideStore 支持自建 anisette 服务器
- ✅ 爱思助手不依赖 anisette(它直接调用 Apple 内置 API)

**严重程度**:🟢 低(多 fallback)

### 🟡 风险 3:SideStore 维护中断

**场景**:开源项目可能因维护者精力/资金问题停滞。

**缓解**:
- ✅ 开源,GitHub 社区可持续 fork
- ✅ 类似的备选项目:AltStore(欧盟版)/ SignTools / 各种 fork
- ✅ 爱思助手商业化团队长期维护

**严重程度**:🟢 低(开源生态自动修复)

### 🟢 风险 4:用户操作失误导致 SideStore 失效

**场景**:误删 SideStore / 误重置 iPhone / 换新 iPhone

**缓解**:
- ✅ 重新用爱思助手装机 SideStore(回到第 1 步)
- ✅ 15-30 分钟恢复

**严重程度**:🟢 低(可恢复)

### 🟢 风险 5:iOS 大版本升级兼容性

**场景**:iOS 19 / 20 发布后,SideStore 可能短期不兼容(几周到几月)

**缓解**:
- ✅ SideStore 通常快速跟进(开源生态)
- ✅ 过渡期:爱思助手手动 7 天重装
- ✅ App 数据不丢失

**严重程度**:🟢 低(短期问题,可恢复)

## Fallback 路径优先级

```
优先级 1(当前): SideStore + 爱思助手
   ↓ Apple 改协议,SideStore 暂时挂
优先级 2(过渡): 爱思助手手动 7 天重装(永远可用)
   ↓ SideStore 长期失效(1 年+)
优先级 3(社区): 等开源社区修复 / 换新工具(2FA 工具 / Sideloadly 替代品)
   ↓ 整个生态崩
优先级 4(逃生): 付费 Apple Developer Program($99/年)
   - 永远作为最后一道防线
   - 不会到这一步(用户硬性约束 0 成本)
```

## 长期承诺

**用户的硬性约束**(ADR-0001):
- "0 成本,绝不付费"

**SideStore 路径满足这个约束**:
- 现在用 ✅
- 5 年后大概率仍然可用(开源生态)
- Apple 改协议 → 1-3 月内社区跟进
- 极端 fallback:爱思助手

**如果 5+ 年后整个 Sideload 生态崩**:
- 这是 5 年后的技术决定,届时再评估
- 现在不预测未来 5 年的所有变化

## 相关文档

- ADR-0008: 部署架构终极方案
- ADR-0010: 爱思助手生态

## 备注

本 ADR 是风险登记,不需立刻执行任何操作。当且仅当 SideStore 失效时才参照。

**当前状态(2026-07)**:SideStore + 爱思助手完全可用,无风险触发。