# Day 3 SOP V4 — 爱思助手 + SideStore 终极方案

> **使用对象**: 用户(首次装机) + 短期 Sideloadly 替代人员
> **目的**: 把 Runner.ipa 装到 iPhone + 长期免维护
> **工具版本**: 爱思助手 i4Tools9 v9.16.038(2026-07 验证)
> **敏感信息**: **Apple ID 密码 = 用户自己输入,任何 Claude 都看不到**

---

## 🎯 任务目标

iPhone 上能启动《审计官》App,显示 "Hello 审计官"。后续无需任何维护。

## 📁 文件位置

| 项 | 路径 |
|---|---|
| Runner.ipa | `[REPO_PATH]/.ai-work/Runner.ipa`(5.80 MB,gitignored) |

## 📦 必备工具

| 工具 | 来源 | 说明 |
|---|---|---|
| 爱思助手 i4Tools | https://www.i4.cn | Windows 中文 iOS 管理 |
| iTunes 完整版(系统已装) | Microsoft Store 或 Apple 官网 | Apple 组件依赖 |
| Apple Mobile Device Support(系统已装) | winget / iTunes 自带 | USB 驱动 |
| iPhone USB 数据线 | 任意支持数据的 USB-C 线 | 必须支持数据 |

## 🎯 两阶段流程

### 阶段 A:爱思助手装机(30 分钟,首次)

#### 步骤 1:下载 + 装爱思助手

```
1. 浏览器开 https://www.i4.cn(爱思助手官网)
2. 下载 Windows 版(约 100MB)
3. 双击安装(默认选项)
4. 启动爱思助手(可能自动安装 Apple 驱动)
```

#### 步骤 2:iPhone USB 连电脑

```
1. iPhone 解锁 + 主屏
2. USB 数据线连电脑
3. iPhone 弹"信任此电脑"→ 点信任 + 输 iPhone 锁屏密码
4. 在电脑确认 iTunes / Apple 通知
5. 爱思助手自动识别 iPhone(左侧显示设备信息)
```

如果没识别:
```
- 检查 Apple Mobile Device Service 是否 Running
  (services.msc → Apple Mobile Device Service)
- iPhone 必须解锁 + 主屏
- 重启 iTunes / Apple Mobile Device Support
```

#### 步骤 3:IPA 签名 + 装机

```
1. 爱思助手顶部菜单 → "工具箱"(Tools)
2. 找 "IPA 签名" 或 "Install IPA" → 点
3. 点 "添加 IPA" / "选择文件" → 选 [REPO_PATH]/.ai-work/Runner.ipa
4. 签名方式 → 选 "Apple ID 签名"
5. 填写:
   - Apple ID: [APPLE_ID_EMAIL](确认真实 Apple ID)
   - 密码: [用户自己输入,不展示给任何人]
   - UDID: 爱思助手自动填(从连接的 iPhone)
6. 点 "立即签名" / "开始签名"
7. 自动完成:签名 + 装机(不生成中间 IPA 文件,直接装到 iPhone)
8. 等 30-60 秒
9. 看到 "安装成功" 提示 → 装好
```

#### 步骤 4:iPhone 信任证书(首次必须)

```
1. iPhone 主屏 → 设置 → 通用 → VPN 与设备管理
2. 找到开发者应用(Apple ID 邮箱 [APPLE_ID_EMAIL])
3. 点 → "信任 'Apple Development: [APPLE_ID_EMAIL]'"
4. 弹窗确认 → "信任"
```

#### 步骤 5:iPhone 开发者模式(首次必须,iOS 16+)

```
1. iPhone 设置 → 隐私与安全性 → 开发者模式
2. 打开 → 重启
3. 重启后确认 → "打开"
```

#### 步骤 6:验证

```
1. iPhone 主屏 → 找 "审计官" App
2. 点开 → 应该看到 "Hello 审计官" 文字 + 👋 emoji
3. 截图 2 张:
   - 主屏(显示 "审计官" 图标)
   - App 内(显示 "Hello 审计官")
```

---

### 阶段 B:装 SideStore(推荐,15 分钟,一次)

**目的**:SideStore 接管自动续签,**之后 0 电脑依赖**。

#### 步骤 7:下载 SideStore IPA

```
1. 浏览器开 https://sidestore.io/ 或 GitHub releases
2. 下载 SideStore.ipa 最新版
3. 复制到 iTunes 的 App 库:
   - iTunes(W11 → Apple Devices)→ 点 iPhone → Apps → 拖 SideStore.ipa 进去
```

或更简单:
```
1. 用爱思助手装 SideStore(类似阶段 A 步骤 3)
```

#### 步骤 8:配置 SideStore

```
1. iPhone 主屏 → 找 "SideStore" App → 点开
2. 引导设置:
   - Apple ID: [APPLE_ID_EMAIL]
   - 密码: [用户自己输入]
   - Anisette 服务器: 选默认公共(免费)
3. SideStore 接管所有 Personal Team App
4. 默认每天凌晨自动续签
5. 配置完成
```

#### 步骤 9:SideStore 自动续签验证

```
1. 等 7 天(或手动 "Refresh All")
2. SideStore 自动重签所有 Personal Team App
3. 用户无感知,App 永远可用
```

---

## ✅ 完成标志

- [ ] 爱思助手装机 Runner.ipa
- [ ] iPhone 设置 → 信任证书
- [ ] iPhone 开发者模式开启
- [ ] iPhone 桌面有《审计官》App
- [ ] 点开《审计官》看到 "Hello 审计官"
- [ ] (可选)SideStore 装好接管自动续签
- [ ] 截图 2 张发给开发机 Claude(我)

---

## 🔄 7 天续签(过渡期 / SideStore 失效时)

**没装 SideStore 的情况**:
```
Day 1:装上 → 用 7 天
Day 7(过期前):
  1. iPhone USB 连电脑
  2. 启动爱思助手
  3. 工具箱 → IPA 签名 → Runner.ipa(同上)
  4. 自动装好,继续 7 天
```

整个过程 30 秒-1 分钟。

**装了 SideStore**:无需操作,自动续签。

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| 爱思助手不识别 iPhone | 检查 Apple Mobile Device Service Running + iPhone 解锁 + 主屏 + 重插 USB |
| 装机报错"签名失败" | 确认 Apple ID 密码正确;检查密码是否需要 App 专用密码(2FA) |
| App 装上但点开闪退 | iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书 |
| iOS 16+ 看不到 App | 设置 → 隐私与安全性 → 开发者模式 → 打开 + 重启 |
| iOS 17+ 装多个个人 App | 限制 3 个 Sidecar App(Apple 限制),需要 SideStore 续签 |

---

## 🚀 未来切换路径

**当前(2026-07)**:此方案完全满足需求,无需切换

**触发 SideStore fallback(ADR-0011)**:
- Apple 改 Developer API → 1-3 月内等社区修复
- 否则 → 用爱思助手手动 7 天重装(永远可用)

详见 `docs/adr/0011-sidestore-long-term-risk.md`。

---

## 📦 收尾

```powershell
# 保留:RUNNER.IPA(.ai-work/)— Stage 1 还会用
# 保留:爱思助手(已装)— Stage 1+ 装机用
# 保留:iTunes + Apple Mobile Device Support — 系统依赖
# 可选卸载:Sideloadly(已淘汰,占资源)— 设置 → 应用卸载
# 可选卸载:AltServer(没装或失败)— 设置 → 应用卸载
# 可选卸载:iMazing(试用 15 天已过期)— 设置 → 应用卸载
```

---

## ⚠️ 重要:本 SOP 不提及以下工具(已被淘汰)

为避免后续"自我跑偏",以下工具已**废弃**,**不要**再尝试:

- ❌ **Sideloadly**(OpenSSL EOL + Python 3.8 EOL,GSA 协议不兼容)
- ❌ **AltServer / AltStore Classic**(Apple Developer API 改变,团队停维护)
- ❌ **iMazing 试用**(限制 + 部分不识别)
- ❌ **3uTools**(下载镜像被堵 + 商业限制)
- ❌ **付费 Apple Developer Program**($99/年,违反 0 成本约束 ADR-0001)

**当前有效**:爱思助手 + SideStore(终极方案,ADR-0008)