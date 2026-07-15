# Day 3 SOP V2 — Sideloadly 简化版(替代 AltServer)

> **使用对象**: 旧电脑(Windows,无显示器,远程 RDP 操作)上的 Claude
> **目的**: 用 Sideloadly 把 Runner.ipa 装到 iPhone
> **重要更新 2026-07-14 晚**:**改用 Sideloadly**(AltServer 折腾几小时报错,质量优先换方案)
> **项目背景**: 你不需要懂,跟着做即可
> **敏感信息**: **Apple ID 密码 = 用户自己输入,不要让 Claude 看到**

---

## 🎯 任务目标

iPhone 上能启动《审计官》App,显示 "Hello 审计官"。

## 📁 工作目录

```
G:\altstore\
├── ipa\    ← Runner.ipa(已就位)
├── sop\    ← 本文件副本
└── logs\   ← AltServer 日志(可保留,也可清理)
```

**所有下载/操作都基于 G:\altstore\**,不要污染其他盘。

## 🌐 远程操作(旧电脑无显示器)

用户通过 **Windows RDP** 远程连接旧电脑,所以你操作的东西用户**都看得到**。

| 用户操作 | 你不用做 |
|---|---|
| iPhone USB 连接 + 信任弹窗 | ✅ 用户直接操作 |
| iPhone 设置 → 通用 → 信任证书 | ✅ 用户在 iPhone 上点 |
| Apple ID + 密码输入 | ✅ 用户自己输入(你看不到) |

**你负责**: Sideloadly 安装 + Runner.ipa 准备 + GUI 操作(用户在 RDP 里帮你点)。

---

## 📦 工具清单

| 项 | 来源 | 状态 |
|---|---|---|
| Sideloadly | https://sideloadly.io | ⏳ 待装 |
| Apple Mobile Device Service | Windows Service | ✅ 已装 |
| iTunes | Microsoft Store | ✅ 已装 |
| Runner.ipa | `G:\altstore\ipa\Runner.ipa` | ✅ 已就位 |
| Apple ID + 密码 | **用户亲自输入,你不要问** | - |

> **注**: 不再需要 AltServer / AltStore App(AltServer 已卸载或保留都行,Sideloadly 独立运行)

---

## 步骤 1:装 Sideloadly

```powershell
# 用户去 https://sideloadly.io 官网下载(Windows 版)
# 双击安装(默认选项,管理员权限)
```

**验证**: 桌面/开始菜单出现 Sideloadly 快捷方式。

---

## 步骤 2:iPhone USB 连接 + 信任

### 2.1 用户操作(物理)
1. iPhone 用数据线连旧电脑
2. iPhone 弹窗"信任此电脑"→ **用户点信任 + 输入 iPhone 锁屏密码**
3. 旧电脑上 iTunes 弹窗也点"继续"

### 2.2 验证 Sideloadly 检测到 iPhone
启动 Sideloadly.exe → 顶部 iDevice 下拉框 → 应该自动显示 iPhone 名字。
如果没显示:检查 USB 重插 + Apple Mobile Device Service Running。

---

## 步骤 3:装 Runner.ipa

```
1. 启动 Sideloadly.exe(管理员权限!)
2. 顶部 iDevice 下拉框 → 选你的 iPhone 名字
3. IPA file 框 → 选 G:\altstore\ipa\Runner.ipa
4. Apple ID 输入框 → 用户的 Apple ID(如 [APPLE_ID_EMAIL])
5. 点 Start 按钮
6. 弹窗输 Apple ID 密码:
   - 没开 2FA → 主密码
   - 开了 2FA → App 专用密码(标签 AltStore-Auditor)
7. 等 30-60 秒(屏幕显示进度条)
8. 看到 "Sideloaded Successfully" → 完成
```

---

## 步骤 4:iPhone 信任证书(首次)

iPhone 上:
```
1. 设置 → 通用 → VPN 与设备管理
2. 找到 Apple ID 证书(开发者应用)→ 点
3. 点 "信任 [Apple ID 邮箱]"
4. 返回主屏
```

---

## 步骤 5:验证

iPhone 桌面找 **审计官** App(图标 + "审计官"名字)→ 点开 → **必须看到 "Hello 审计官"**。

截图发给我。

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| Sideloadly 启动报"需要 iTunes" | 装 iTunes + iCloud from Microsoft Store(已装的话 skip) |
| iDevice 框不显示 iPhone | 拔 USB 重插 + 检查 Apple Mobile Device Service Running |
| "Apple ID 错误" | 重生成 App 专用密码(标签 AltStore-Auditor) |
| 装上但 App 闪退 | iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书 |
| Sideloadly 报"Bundle ID 不合规" | 用 Sideloadly 默认 Bundle ID(可改,我们不强求 com.shenjiguan.jizhang) |

---

## ⚠️ 续签机制(后续优化,Stage 0 不必)

Sideloadly 没有自动续签。7 天后需要:
1. USB 连 iPhone + 旧电脑
2. Sideloadly 重新装一遍 Runner.ipa
3. 重新输 Apple ID

Stage 0 验收只看今天能装上。Stage 1+ 考虑改回 AltStore 路径获取自动续签。

---

## ✅ 完成标志

- [ ] Sideloadly 装好
- [ ] iPhone USB 连接 + 信任
- [ ] Runner.ipa Sideload 成功("Sideloaded Successfully")
- [ ] iPhone 信任证书
- [ ] iPhone 桌面有《审计官》App
- [ ] 点开《审计官》看到 "Hello 审计官"
- [ ] 截图发给开发机 Claude(我)

---

## 📦 收尾清理

如果决定不再用 AltServer:
```powershell
# 卸载 AltServer(可选)
winget uninstall RileyTestut.AltServer

# 清理旧电脑日志
del G:\altstore\logs\* /q

# 保留 G:\altstore\ipa\Runner.ipa(Stage 1 还会用)
```

---

**重要提醒**:
- Apple ID 密码 = **用户输入**,你不要看 / 不要存 / 不要问
- App 专用密码(2FA 需要): 用户去 https://appleid.apple.com → App 专用密码生成
- 不要 commit 任何含凭证的文件
- 旧电脑 Claude 上一版的 HTTP server 可以关了(Sideloadly 用不上)