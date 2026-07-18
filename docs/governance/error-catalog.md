# 错误库

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：项目开发过程中遇到的常见错误 + 解决方案

---

## 🎯 目的

- 沉淀解决方案，避免重复踩坑
- 新会话开始时快速排查已知问题
- 培训和参考

---

## 📚 目录

1. [Flutter 环境](#flutter-环境)
2. [GitHub Actions](#github-actions)
3. [iOS 代码签名](#ios-代码签名)
4. ~~[AltStore](#altstore)~~(已废弃,见 ADR-0004 SUPERSEDED → ADR-0008 爱思助手 + SideStore)
5. [Drift 数据库](#drift-数据库)
6. [Riverpod](#riverpod)

---

## 🔧 Flutter 环境

### F-001: `flutter doctor` 警告 Android Studio 未配置

```
[✓] Flutter (Channel stable, 3.24.5)
[✗] Android toolchain - develop for Android devices
    ✗ Android Studio not configured
```

**影响**：v1.0 不开发 Android，可忽略。

**解决**：
```bash
# 可选：用 --android-studio-dir 指向安装位置
flutter config --android-studio-dir "C:\Program Files\Android Studio"
```

---

### F-002: `pub get` 下载慢

**症状**：
```
Resolving dependencies... (5 minutes, still running)
```

**解决**：配置国内镜像
```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

# 永久（写入 PowerShell profile）
notepad $PROFILE
# 添加以上两行
```

---

### F-003: `flutter analyze` 报 `prefer_const_constructors`

**症状**：
```
warning: This constructor should be const (prefer_const_constructors at lib/main.dart:5)
```

**解决**：按 lint 提示加 `const`
```dart
// 改前
Text('Hello')

// 改后
const Text('Hello')
```

**禁用 lint**（不推荐）：
```yaml
# analysis_options.yaml
linter:
  rules:
    prefer_const_constructors: false
```

---

### F-004: Windows 路径含空格导致问题

**症状**：
```
Error: Could not find Dart in 'C:\Program Files\...'
```

**解决**：把 Flutter SDK 装到**无空格路径**
```
✅ C:\src\flutter
✅ [REPO_PATH]
❌ C:\Program Files\flutter
❌ C:\Users\My User\flutter
```

---

## 🚀 GitHub Actions

### G-001: macOS runner 排队太久

**症状**：workflow 触发后 10+ 分钟还在排队。

**原因**：GitHub 共享 runner 用的人多。

**解决**：
1. 等待（一般 5-15 分钟）
2. 错峰触发（避开美西时间上午 9-11 点）
3. 升级到 GitHub Team 计划（专用 runner，付费，本项目不用）

---

### G-002: Code signing 失败

**症状**：
```
error: No signing certificate "iOS Development" found
```

**排查**：
1. 检查 Apple 证书是否过期（开发者网站）
2. 检查 Provisioning Profile 是否包含设备 UDID
3. 检查 `ExportOptions.plist` 是否正确
4. 检查 GitHub Secrets 是否正确配置

**解决**：
```bash
# 本地验证
security find-identity -v -p codesigning
# 应显示你的 Apple Development 证书
```

---

### G-003: 证书导入失败 - "user interaction is not allowed"

**症状**：
```
security: SecKeychainAddImport failed: User interaction is not allowed.
```

**解决**：在 GitHub Actions 用 `apple-actions/import-codesign-certs@v3`：

```yaml
- name: Import certificates
  uses: apple-actions/import-codesign-certs@v3
  with:
    p12-file-base64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
    p12-password: ${{ secrets.KEY_PASSWORD }}
```

---

### G-004: Provisioning Profile 不匹配 Bundle ID

**症状**：
```
error: Provisioning profile "jizhang-dev" doesn't include signing certificate "Apple Development: ..."
```

**解决**：
1. Apple Developer 网站 → Profiles → 编辑 Profile
2. 重新勾选证书 + 设备
3. 重新生成 Profile
4. 更新 GitHub Secrets

---

### G-005: .ipa 找不到

**症状**：
```
error: Could not find build/ios/iphoneos/Runner.ipa
```

**排查**：
```yaml
# 检查 workflow 的 build 步骤
- name: Build .ipa
  run: |
    flutter build ios --release --export-options-plist=ios/ExportOptions.plist
- name: Verify .ipa exists
  run: ls -la build/ios/iphoneos/
```

可能原因：build 失败但 workflow 没报错。检查前面步骤。

---

## 🔧 GitHub Actions: iOS Build 链(Stage 1 ROA 沉淀)

> **场景**:macOS runner + `flutter build ios --release --no-codesign` 失败
> **Day 0-3 早期 build 巧合通过**(没原生依赖,无 pod 编译),Day 4 加 drift 后开始持续失败。
> 5 个 root cause 叠加,Day 9-10 修复链沉淀。

### G-003: iOS deployment target 编译错(5 层 root cause)

**症状**:`flutter build ios` 失败,日志最后一行通常是 `** BUILD FAILED **` + 几行 clang error。

**根因链(按修复顺序)**:

| # | 根因 | 触发条件 | 修复 |
|---|---|---|---|
| 1 | 缺 `ios/Podfile` | 任何带原生 plugin 的依赖(drift / path_provider / vibration 等) | 新建标准 Flutter 3.x Podfile(从 `flutter create -t app .` 模板复制) |
| 2 | Xcode `IPHONEOS_DEPLOYMENT_TARGET=13.0` ≠ Podfile `platform :ios, '16.0'` | CocoaPods 报 platform mismatch,pod install 失败 | 编辑 `ios/Runner.xcodeproj/project.pbxproj` 三处 13.0 → 16.0;Podfile `post_install` 钩子也设 16.0 |
| 3 | `device_info_plus` ≥ 13.x 用 `isiOSAppOnVision`(iOS 17+ API),无 `@available` 守卫 | iOS 16 deployment target 编译报 "no visible @interface" | `pubspec.yaml` 加 `dependency_overrides: device_info_plus: ^10.0.0`(锁 10.1.2,无 visionOS API) |
| 4 | workflow 缺 `flutter precache --ios` + 显式 `pod install --repo-update` | 首次 runner 启动慢,build 隐式失败栈混乱 | 在 `flutter build ios` 之前显式跑两步,失败栈清晰 |
| 5 | workflow timeout 设太小(默认 20 分钟) | E2E 卡在 iOS Simulator 启动 + 真引擎测试,撞 timeout | `timeout-minutes: 20 → 35`(iOS Simulator 首次启动需 10-15 分) |

**完整修复 commit 链**(`<type>(<scope>): <subject>` 格式):

```
fix(ci): 新建 ios/Podfile(Day 0 漏写导致 Day 4 起 iOS build 红)        740360e
fix(ci): 修 iOS deployment target 冲突 + 显式 pod install 步骤        f047b43
fix(ci): 锁 device_info_plus 10.1.2 避开 iOS 17 visionOS API 编译错   257ddd3
fix(ci): e2e.yml 加 --verbose + tee e2e.log 捕获完整日志             afe752d
fix(ci): e2e timeout 20→35 分钟,iOS Simulator 首次启动需 10-15 分   4436c26
```

**预防措施**(后续 Stage 2+ 起新项目时必做):
- [ ] Day 0 `flutter create .` 后检查 `ios/Podfile` 是否存在(默认应该存在)
- [ ] 任何带原生 plugin 的依赖加入前,先跑 `flutter build ios` 验证 CI
- [ ] iOS deployment target Xcode project + Podfile 必须一致(改 Xcode 用 `xcodebuild -showBuildSettings` 确认)
- [ ] `integration_test` E2E workflow 必须有日志捕获(`tee e2e.log` + artifact 上传)
- [ ] workflow timeout 设 ≥ 35 分钟(iOS Simulator 首次启动慢)

**避免:** 在 Podfile post_install 用 per-pod IPHONEOS_DEPLOYMENT_TARGET 单独覆盖某个 pod —— `installer.pods_project.targets` 可能不包含 pod 自身 target,override 不生效。**改用 `dependency_overrides` 锁版本更可靠**。

---

## 🍎 iOS 代码签名

### I-001: Apple ID 登录失败 "Verification failed"

**原因**：用了账号密码，Apple 现在要求 App-Specific Password。

**解决**：
1. https://appleid.apple.com → Sign in
2. App-Specific Passwords → Generate
3. 标签：`AltStore-Auditor`
4. 用生成的密码登录

---

### I-002: 设备 UDID 获取不到

**方法 A**：用 AltStore
1. iPhone 安装 AltStore
2. 设置 → 设备信息 → UDID

**方法 B**：用 iTunes（旧版 Windows）
1. iTunes → 编辑设备 → 摘要
2. 点序列号直到显示 UDID

**方法 C**：用 3uTools
1. 连接 iPhone → 设备信息 → UDID

---

## 📱 iOS 真机部署(爱思助手 + SideStore)

> **2026-07 修订**:AltStore / AltServer 章节已废弃。详见 ADR-0008。

### I4A-001: 爱思助手不识别 iPhone

**症状**：爱思助手左侧"设备 0",iPhone 不显示。

**排查**：
1. Apple Mobile Device Service 是否 Running(`services.msc`)
2. iPhone 是否解锁 + 主屏
3. USB 数据线是否**支持数据**(不是纯充电线)
4. iPhone 是否已**信任此电脑**(USB 连后 iPhone 弹窗)

**解决**：
- 重启 Apple Mobile Device Service
- iPhone 重启
- 换 USB 数据线 / 换 USB 端口
- iPhone 设置 → 通用 → 复位 → 复位位置和隐私,然后重连

---

### I4A-002: 爱思助手装机报"Apple ID 错误"

**症状**：输 Apple ID 后提示登录失败。

**排查**：
1. Apple ID 是否正确([APPLE_ID_EMAIL])
2. 是否启用 2FA:若是,**必须**用 App 专用密码(不是主密码)
   - 生成:https://appleid.apple.com → App 专用密码 → 标签:`AltStore-Auditor` 或 `Auditor-i4Tools`
3. 密码是否含特殊字符(部分字符在爱思助手有 bug)

**解决**：
- 重生成 App 专用密码
- 用纯字母数字密码测试

---

### I4A-003: iPhone 装上 .ipa 但点开闪退

**症状**：点击图标立刻闪退。

**原因**：证书未信任 + 开发者模式未开(iOS 16+)。

**解决**：
1. iPhone 设置 → 通用 → VPN 与设备管理 → 信任 Apple ID 证书
2. iPhone 设置 → 隐私与安全性 → **开发者模式** → 打开 → 重启 → 确认
3. 重启后,App 可正常打开

---

### SS-001: SideStore 自动续签失败

**症状**：SideStore 已装,但 App 过期,提示"无法验证"。

**排查**：
1. iPhone 当前不在 SideStore 控制下 → 看 SideStore App 内"凭证"状态
2. Anisette 服务器失效 → SideStore 设置 → 切换服务器
3. iCloud 登录失效 → Apple ID 登出再登入

**解决**：
- SideStore 设置 → Apple ID → Sign Out → Sign In
- SideStore 设置 → Anisette 服务器 → 切换(默认 → AltKit 等)
- 手动 Refres All:SideStore App → My Apps → Refresh All

---

### SS-002: SideStore 装不上(签名失败)

**症状**：爱思助手首次装 SideStore.IPA 时报错。

**排查**：
1. Apple ID 凭证问题(同 I4A-002)
2. Runner.ipa / SideStore.ipa 文件损坏 → 重新下载
3. Personal Team 3 App 限制(免费 ID 限制 3 个 active App)

**解决**：
- 卸载已装的 App(释放 Personal Team 名额)
- 重新生成凭证

---

> **历史章节**(已废弃,仅供参考):
>
> ~~## 📱 AltStore~~
> ~~### A-001: AltStore 配对失败~~(2026-07 已替代)
> ~~### A-002: .ipa 安装失败~~(2026-07 已替代)
> ~~### A-003: App 启动闪退~~(2026-07 已替代)
>
> 替代方案:**爱思助手 + SideStore**(见上 I4A-*/SS-*)

---

## 🗄 Drift 数据库

### D-001: 代码生成失败 `build_runner` 报错

**症状**：
```
[INFO] Running build...
[SEVERE] drift_dev on lib/data/database/tables/transactions.dart:
Expected identifier
```

**解决**：
1. 检查 Dart 文件语法
2. 跑 `flutter clean`
3. 删除 `.dart_tool/`
4. 重新跑：
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

### D-002: 迁移失败 "no such column"

**症状**：
```
Error: no such column: account_id
```

**原因**：迁移脚本没正确加列。

**解决**：
```dart
// ✅ 正确（迁移 v2 加列）
MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(transactions, transactions.accountId);
    }
  },
)
```

---

## 🎯 Riverpod

### R-001: Provider 状态不更新

**症状**：改了 provider，UI 不刷新。

**解决**：
```dart
// ✅ 好（用 ref.watch）
final value = ref.watch(myProvider);

// ❌ 差（只读一次，不会刷新）
final value = ref.read(myProvider);
```

---

### R-002: NotifierProvider 报错 "ref is not defined"

**症状**：
```
Error: 'ref' is not defined for the type 'MyNotifier'
```

**解决**：用新版 Riverpod 2.x 语法

```dart
// ✅ 好
class MyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void increment() {
    state = state + 1;
  }
}

final myProvider = NotifierProvider<MyNotifier, int>(MyNotifier.new);
```

---

## 📌 添加新错误

遇到新错误时：
1. 解决后立即记录到本文件
2. 格式：编号 + 标题、症状、原因、解决、参考链接
3. 提交到 git

---

**最后更新**：2026-07-14 · 创建（初始）
**下次更新**：遇到新错误时追加