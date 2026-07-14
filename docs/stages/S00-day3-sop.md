# Day 3 SOP — 给旧电脑 Claude 的操作手册

> **使用对象**: 旧电脑(Windows)上的 Claude
> **目的**: 安装 AltServer + 配对 iPhone AltStore + 安装 Runner.ipa
> **项目背景**: 你不需要懂,跟着做即可
> **敏感信息**: **Apple ID 密码 = 用户自己输入,不要让 Claude 看到**

---

## 🎯 任务目标

iPhone 上能启动《审计官》App,显示 "Hello 审计官"。

## 📦 你的工具清单

| 项 | 来源 |
|---|---|
| AltServer | https://altstore.io |
| iTunes (Microsoft Store) | 用户已装 |
| iCloud (Microsoft Store) | 用户已装 |
| Runner.ipa | https://github.com/yangcunzhu/jizhang-0714-/actions/runs(最新成功 run 的 Artifacts) |
| Apple ID + 密码 | **用户亲自输入,你不要问** |

---

## 步骤 1:装 AltServer

```powershell
# 用 winget 装(用户已经装过 winget)
winget install --id AltStore.AltServer

# 或者手动:从 https://altstore.io 下载 → 解压 → 跑 AltServer.exe
```

**验证**: 系统托盘右下角出现 AltServer 图标(像一个方块)。

---

## 步骤 2:iPhone USB 连接 + 装 AltStore

### 2.1 用户操作(物理)
1. iPhone 用数据线连旧电脑
2. iPhone 弹窗"信任此电脑"→ **用户点信任 + 输入 iPhone 锁屏密码**
3. 旧电脑上 iTunes 弹窗也点"继续"

### 2.2 AltServer 操作
1. 右键系统托盘 AltServer 图标
2. 选择 **Install AltStore** → 选择 iPhone 名称
3. 弹出窗口:**用户亲自输入 Apple ID + 密码**(你看不到)
4. 等待 30 秒 → iPhone 上出现 AltStore App

### 2.3 iPhone 信任证书
1. iPhone → 设置 → 通用 → VPN 与设备管理
2. 找到刚装的 Apple ID 证书 → 点"信任"
3. 返回桌面点 AltStore → 看到主界面 = 成功

---

## 步骤 3:下载 Runner.ipa

### 3.1 找到最新的成功 workflow run
**问用户**: "请提供 Runner.ipa 的下载链接"

或自己去: https://github.com/yangcunzhu/jizhang-0714-/actions
- 找最新一个绿色 ✅ 的 run
- 点进去 → 底部 Artifacts → 下载 `jizhang-app-unsigned.zip`
- 解压到 `C:\altstore-work\Runner.ipa`

### 3.2 用 curl 下载(更快)
用户会给 token 或 GitHub Actions 直接公开 URL:
```powershell
curl -L -o C:\altstore-work\Runner.ipa "URL_FROM_USER"
```

---

## 步骤 4:用 AltStore 装 .ipa

### 方式 A:在 iPhone 上 AltStore 里装
1. iPhone AltStore → My Apps → 左上角 +
2. 选 **Downloads** 或 **Files**(看 Runner.ipa 在哪)
3. 找到 Runner.ipa → 点
4. 输入 Apple ID + 密码 → 等待签名 + 安装

### 方式 B:在旧电脑上 AltServer 直接 Sideload
1. 把 `Runner.ipa` 复制到 `C:\altstore-work\`
2. AltServer 系统托盘图标右键 → **Sideload .ipa**
3. 选择 `C:\altstore-work\Runner.ipa`
4. 输入 Apple ID + 密码 → 等待

---

## 步骤 5:验证

iPhone 桌面找 **审计官** App(图标 + "审计官"名字)→ 点开 → **必须看到 "Hello 审计官"**。

截图发给我。

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| AltServer 找不到 iPhone | 重启 AltServer + 重新插 USB |
| AltStore 装不上("Apple ID 错误") | 用户确认 ID 密码正确 + 是否启用了 2FA(需要 App 专用密码) |
| 安装后 App 打不开 | iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书 |
| 7 天后 App 打不开 | 旧电脑不能关,AltServer 自动续签 |
| App 显示 "无法验证 App" | 信任步骤没做,见上面 |

---

## ✅ 完成标志

- [ ] AltServer 系统托盘有图标
- [ ] iPhone 有 AltStore App
- [ ] iPhone 有《审计官》App
- [ ] 点开《审计官》看到 "Hello 审计官"
- [ ] 截图发给开发机 Claude(我)

---

**重要提醒**:
- Apple ID 密码 = **用户输入**,你不要看 / 不要存 / 不要问
- App 专用密码(2FA 需要): 用户去 https://appleid.apple.com → App 专用密码生成
- 不要 commit 任何含凭证的文件