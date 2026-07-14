# 安全清单

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有涉及数据 / 网络 / 凭证的操作

---

## 🎯 安全原则

1. **零信任**：所有外部输入都不可信
2. **最小权限**：只请求必要权限
3. **加密优先**：敏感数据加密存储和传输
4. **不记录敏感**：日志不含密钥、token、密码、个人数据
5. **可审计**：所有敏感操作有日志

---

## 🔐 数据加密

### 必须加密的数据

- [x] **数据库文件**（Stage 6）— SQLCipher AES-256
- [x] **数据库密钥** — iOS Keychain（Keychain Services）
- [x] **API Key / Token**（如用 LLM）— Keychain

### 不要做的事

- ❌ 不要把密钥存 SharedPreferences
- ❌ 不要把密钥硬编码
- ❌ 不要把密钥写在 git commit
- ❌ 不要把密钥传给第三方 API

### 实现

```dart
// ✅ 好
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  static Future<void> saveKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  static Future<String?> getKey(String key) async {
    return _storage.read(key: key);
  }
}
```

---

## 🌐 网络安全

### HTTPS Only

```dart
// ✅ 好
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  // 强制 HTTPS
  validateStatus: (status) => status != null && status < 400,
));

// ❌ 差（HTTP 明文）
'http://api.example.com/endpoint'
```

### 证书锁定（可选，v1.1+）

```dart
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => false;
  return client;
};
```

---

## 🔑 认证与授权

### 生物认证（Stage 6+）

```dart
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  static final _auth = LocalAuthentication();
  
  static Future<bool> authenticate() async {
    if (!await _auth.canCheckBiometrics) return false;
    
    return await _auth.authenticate(
      localizedReason: '解锁审计官',
      options: AuthenticationOptions(
        biometricOnly: false,  // 允许密码 fallback
        stickyAuth: true,
      ),
    );
  }
}
```

### 权限申请最小化

只在用到时申请，且说明原因：

```dart
// ✅ 好（用到时申请）
final status = await Permission.notification.request();
if (status.isGranted) {
  // 启用通知
}

// ❌ 差（启动时申请所有）
await [Permission.notification, Permission.camera, ...].request();
```

---

## 📝 输入验证

### 所有外部输入必须验证

| 输入类型 | 验证 |
|---|---|
| 用户文本 | 长度限制、特殊字符过滤 |
| 金额 | 数值范围、精度 |
| 日期 | 合法日期、合理范围 |
| 文件路径 | 路径遍历检查（不允许 `../`） |
| URL | HTTPS only、域名白名单 |

### 示例

```dart
// ✅ 好
double? parseAmount(String text) {
  final value = double.tryParse(text);
  if (value == null || value <= 0 || value > 10000000) {
    return null;  // 非法输入返回 null
  }
  return value;
}

// ❌ 差
double parseAmount(String text) {
  return double.parse(text);  // 可能抛异常
}
```

---

## 🗄 SQL 注入防护

### 必须用参数化查询

```dart
// ✅ 好（Drift 用参数化）
Future<List<Transaction>> findByCategory(String categoryId) async {
  return _db.transactions.select()
    ..where((t) => t.categoryId.equals(categoryId))
    ..get();
}

// ❌ 差（字符串拼接）
Future<List<Transaction>> findByCategory(String categoryId) async {
  final sql = "SELECT * FROM transactions WHERE category_id = '$categoryId'";
  // SQL 注入风险
}
```

---

## 📊 日志安全

### 不能记录的内容

```dart
// ❌ 绝对禁止
logger.i('API key: $apiKey');
logger.d('User password: $password');
logger.i('Token: $token');
logger.i('Credit card: ${card.number}');

// ✅ 好（脱敏）
logger.i('API key loaded: ${apiKey.substring(0, 4)}***');
logger.d('User authenticated: true');
logger.i('Token rotated');
logger.i('Card: **** **** **** ${card.last4}');
```

### 日志工具

```dart
// lib/core/utils/logger.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    colors: false,  // 生产关闭颜色
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: kReleaseMode ? Level.warning : Level.debug,  // 生产只 warning+
);
```

---

## 🔒 iOS Keychain 配置

### Info.plist 必需

```xml
<key>NSFaceIDUsageDescription</key>
<string>用于解锁审计官，保护你的财务数据</string>
```

### Podfile 配置

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      # 启用 Keychain 共享（如果需要）
      config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
    end
  end
end
```

---

## 🛡 备份与恢复（Stage 6）

### 加密快照

- [ ] 快照文件加密（AES-256）
- [ ] 快照密钥从 Keychain 读取
- [ ] 不存到 iCloud 自动同步（避免泄露）
- [ ] 用户主动选择导出位置

### 恢复时验证

```dart
Future<bool> verifySnapshot(String path) async {
  // 1. 检查文件签名
  final signature = await computeSignature(path);
  if (signature != expectedSignature) return false;
  
  // 2. 尝试解密
  try {
    final decrypted = await decryptSnapshot(path);
    return decrypted.isNotEmpty;
  } catch (e) {
    return false;
  }
}
```

---

## 🚨 紧急安全响应

### 如果发现安全漏洞

```
1. 大副立即停止相关功能
   ↓
2. 通知指挥官
   ↓
3. 评估影响范围（哪些数据可能泄露）
   ↓
4. 修复 + 加测试
   ↓
5. 写 ADR 记录 + 改进流程
   ↓
6. 督察紧急审计
```

### 如果密钥泄露

```
1. 立即重置密钥
   ↓
2. 加密现有数据（新密钥）
   ↓
3. 通知用户（如有云端数据）
   ↓
4. 审计访问日志
   ↓
5. 写 ADR + 改进存储策略
```

---

## 📌 安全检查清单（每次 Commit）

```
□ 无硬编码密钥/密码/token
□ 无明文 HTTP
□ SQL 用参数化
□ 输入验证
□ 错误处理不泄露敏感信息
□ 日志脱敏
□ .gitignore 包含 *.key *.p12 *.cer *.mobileprovision
□ git status 不显示敏感文件
```

---

## 📌 安全检查清单（每个 Stage 完成）

```
□ 数据库加密（Stage 6）
□ 密钥管理（Keychain）
□ 生物认证（Stage 6）
□ HTTPS 配置（Stage 7+）
□ 输入验证覆盖
□ 日志脱敏
□ 无安全漏洞（督察审计）
□ 无密钥泄露（git 历史扫描）
```

---

## 🔍 安全扫描工具

```bash
# 扫描密钥泄露
gitleaks detect --source . -v

# 扫描依赖漏洞
flutter pub outdated --mode=null-safety
dart pub deps --json | jq '.packages[].name'

# 静态分析
flutter analyze --fatal-infos
```

---

**最后更新**：2026-07-14 · 创建