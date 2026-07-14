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
4. [AltStore](#altstore)
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
✅ E:\jizhang-0714
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

## 📱 AltStore

### A-001: AltStore 配对失败

**症状**：
```
AltStore could not connect to AltServer
```

**排查**：
1. AltServer 在旧电脑上运行？
2. iPhone 和电脑**同一 WiFi**？
3. 防火墙允许 AltServer？
4. Apple ID 正确？

**解决**：
- 重启 AltServer
- 重新连接 USB
- 检查网络

---

### A-002: .ipa 安装失败 "Unable to install"

**症状**：
```
Unable to install "审计官"
```

**排查**：
1. Apple ID 证书过期？（免费 7 天，付费 1 年）
2. Bundle ID 冲突？
3. iOS 版本不兼容（v1.0 要 iOS 16+）

**解决**：
- 重新签名（AltStore → My Apps → Refresh）
- 卸载重装
- 检查设备 iOS 版本

---

### A-003: App 启动闪退

**症状**：点击图标立刻闪退。

**原因**：证书未信任。

**解决**：
1. iPhone 设置 → 通用 → VPN 与设备管理
2. 找到开发者 App（你的 Apple ID）
3. 点击 → 信任 "Apple Development: ..."
4. 返回主屏，重新启动 App

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