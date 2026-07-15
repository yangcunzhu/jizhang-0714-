# Day 3 SOP V3 — Sideloadly(短期开发期)

> **使用对象**: 用户(开发机,不在旧电脑)
> **目的**: 用 Sideloadly 把 Runner.ipa 装到 iPhone
> **阶段**: 开发期(2026-07 → v1.0 上线前)
> **敏感信息**: **Apple ID 密码 = 用户自己输入**
> **项目背景**: 不需要懂,跟着做即可

---

## 🎯 任务目标

iPhone 上能启动《审计官》App,显示 "Hello 审计官"。

## 📁 文件位置

| 项 | 路径 |
|---|---|
| Runner.ipa | `E:\jizhang-0714\.ai-work\Runner.ipa`(5.80 MB) |
| iPhone | 用户手边,USB-C 连开发机 |

## 📦 工具清单

| 项 | 来源 | 状态 |
|---|---|---|
| Sideloadly | https://sideloadly.io | ✅ 已装 |
| iTunes / Apple Mobile Device Service | Windows Service | ✅ 已装 |
| Runner.ipa | `.ai-work\Runner.ipa` | ✅ 已就位 |
| Apple ID | `[APPLE_ID_EMAIL]` | ✅ |
| App 专用密码(2FA) | https://appleid.apple.com | ⏳ 可能需要 |

---

## 步骤 1:验证 Sideloadly 已装

```
1. 打开开始菜单 → 搜 "Sideloadly"
2. 应该看到 Sideloadly.exe 快捷方式
3. 右键 → 以管理员身份运行(必须!)
```

---

## 步骤 2:iPhone USB 连开发机

```
1. iPhone 用 USB-C 数据线连开发机
2. iPhone 解锁
3. iPhone 弹"信任此电脑" → 点 "信任" + 输入 iPhone 锁屏密码
4. 开发机第一次会弹 iTunes 通知 → 点 "继续"
```

---

## 步骤 3:装 Runner.ipa

```
1. Sideloadly 主界面 → iDevice 下拉框 → 应该自动显示你的 iPhone 名字
   (如果不显示:拔 USB 重插 + 确认 Apple Mobile Device Service 在运行)

2. IPA file 输入框 → 选 E:\jizhang-0714\.ai-work\Runner.ipa

3. Apple ID 输入框 → 填 [APPLE_ID_EMAIL]

4. 点 Start 按钮

5. 弹窗输 Apple ID 密码:
   - 没开 2FA → 主密码
   - 开了 2FA → App 专用密码(标签 AltStore-Auditor)
     生成:https://appleid.apple.com → 登录 → App 专用密码

6. 等 30-60 秒(屏幕显示进度)

7. 看到 "Sideloaded Successfully" → 装好
```

---

## 步骤 4:iPhone 信任证书(首次)

```
1. iPhone 主屏 → 设置 → 通用 → VPN 与设备管理
2. 找到 Apple ID 证书(开发者应用)→ 点
3. 点 "信任 [APPLE_ID_EMAIL]"
4. 返回主屏
```

---

## 步骤 5:验证

```
1. iPhone 主屏 → 找 "审计官" 图标(应该是中文显示)
2. 点开
3. 必须看到 "Hello 审计官" 文字 + 蓝色背景 + 👋 emoji
4. 截图 2 张:
   - 主屏有"审计官"图标
   - 点开 App 显示 "Hello 审计官"
```

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| Sideloadly 不显示 iPhone | 拔 USB 重插 + 检查 Apple Mobile Device Service Running |
| "Apple ID 错误" | 重生成 App 专用密码(标签 AltStore-Auditor) |
| 装上但 App 闪退 | iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书 |
| "Bundle ID 不合规" | 用 Sideloadly 默认 Bundle ID(我们不强求 com.shenjiguan.jizhang) |
| 进度条卡住 | 等 90 秒,如果还卡 → 关 Sideloadly 重试 |

---

## 🔄 7 天后续签(开发期常态)

```
Day 1:装上 → 用 7 天
Day 7(过期前):
  1. iPhone USB 连开发机
  2. Sideloadly → 选 Runner.ipa → Start
  3. 30 秒完成
```

**整个过程 30 秒**,比切 AltServer 省事得多。

---

## 🚀 未来切换 AltServer(2026 年 v1.0 上线后)

**触发条件**:
- ✅ v1.0 上线
- ✅ 用户希望"零维护"(不想每 7 天手动)
- ✅ 旧电脑 7:00-24:00 开机(用户已具备)

**切换步骤**(一次性,30 分钟):
1. 旧电脑装 AltServer(已装)
2. iPhone USB 连旧电脑(仅这一次)
3. AltServer 系统托盘 → Install AltStore → 输 Apple ID
4. iPhone 设置 → 信任证书
5. 之后 AltStore 自动续签,7×24 WiFi

**Apple ID 不变** — Personal Team 证书两种方案共用。

详见 `docs/adr/0004-deployment-strategy.md` ADR。

---

## ✅ 完成标志

- [ ] Sideloadly 启动并检测到 iPhone
- [ ] Runner.ipa 装成功("Sideloaded Successfully")
- [ ] iPhone 设置 → 信任证书
- [ ] iPhone 桌面有《审计官》App
- [ ] 点开《审计官》看到 "Hello 审计官"
- [ ] 截图 2 张发给开发机 Claude(我)

---

## 📦 收尾(可选)

```powershell
# 清理:Runner.ipa 留在 .ai-work/(Stage 1 还会用)
# 卸载:旧电脑 AltServer 可以卸了(短期不需要)
# 保留:Sideloadly 留装在开发机(每 7 天用一次)
```