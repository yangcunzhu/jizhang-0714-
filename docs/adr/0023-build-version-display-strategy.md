# ADR-0023:开发过程中版本号显示策略(S03 D19 经验沉淀)

> 状态:**已接受**
> 日期:2026-08-02(D19 收尾)
> Stage:**S03-credit-card-repayment**(Day 19,2026-08-02)
> 作者:Claude(执行)+ 用户(决策)
> 关联:ADR-0022(余额自动更新)+ G-003(iOS 真机调试经验)

---

## 背景

S03 D19 期间发生**装机排查耗时**事故:

| 阶段 | 时长 | 原因 |
|---|---|---|
| 装错旧 Runner.ipa(从迅雷下载) | 30 分钟 | 我之前给的手册说「下载 Runner.ipa」实际 artifact 名是 `jizhang-app-unsigned`,误导用户从第三方下载旧文件 |
| 覆盖装 iOS 缓存旧代码 | 15 分钟 | 怀疑装的 Runner.ipa 是 7.82 MB 但行为没变,完全卸载重装才解决部分问题 |
| 余额 bug 根因未定位 | 持续 | 无法快速判断「装的 Runner.ipa 是不是真的包含 D19 commit `ed8a4da` 的代码」 |

**根因**:App 内**没有显示版本号 + commit SHA** 的入口,装机后无法立即验证「我装的是不是新代码」。如果用户能在 App 内看到 `v0.1.0 · b3b722e`,**一眼对比 GitHub commits 列表**就知道是不是新版。

CLAUDE.md §铁律 10「不忽略错误」+ S03 D19 教训:开发过程中,**任何用户/调试动作都可能因为「装错版本」浪费时间**,必须有**快速识别版本**的入口。

---

## 决策

### 1. App 内显示 4 个 build 元信息

| 字段 | 来源 | 显示 |
|---|---|---|
| 版本号 | 硬编码 `0.1.0` | 主页底部 |
| Commit SHA 前 7 位 | `--dart-define=GIT_SHA=${{ github.sha }}` → `String.fromEnvironment` | 主页底部 + 错误日志 |
| Schema 版本 | 硬编码(从 `AppDatabase.schemaVersion` 读)| 主页底部 |
| Build 时间(可选) | `--dart-define=BUILD_TIME=ISO8601` | 暂不显示,需要再加 |

### 2. 显示位置:主页底部(灰色小字)

```dart
// lib/features/home/presentation/home_page.dart 底部 SafeArea 之上
Text(
  'v${BuildInfo.version} · ${BuildInfo.shortSha} · schema v${BuildInfo.schemaVersion}',
  style: TextStyle(fontSize: 10, color: Colors.grey),
)
```

**WHY 主页底部**:
- 用户每次打开 App 都能看到,无需专门进「关于」页
- 灰色 + 小字,不抢主界面视觉
- 调试时一眼对比 GitHub commit 列表,立刻知道是不是新 build

### 3. build-ios.yml 注入 GIT_SHA

build-ios.yml 的 `flutter build ios` 命令加:

```yaml
- name: Build IPA
  run: |
    flutter build ipa --release \
      --dart-define=GIT_SHA=${{ github.sha }} \
      --dart-define=BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

**WHY 用 `--dart-define`**:
- 编译期常量,AOT 编译到原生代码,无运行时开销
- 不引入新依赖(CLAUDE.md §2「不引入新依赖」)
- `String.fromEnvironment('GIT_SHA')` 是 Dart 标准库 API,稳

### 4. 新建 `lib/build_info.dart`

```dart
/// 构建元信息(版本号 + commit SHA + schema 版本)。
///
/// WHY: 装机后用户/开发者能在 App 内看到自己装的是哪个 commit,
/// 避免「装错版本」浪费时间(参见 ADR-0023)。
///
/// 来源:
/// - GIT_SHA: --dart-define=GIT_SHA=${{ github.sha }} 注入
/// - BUILD_TIME: --dart-define=BUILD_TIME=$(date -u +...) 注入
/// - version / schemaVersion: 硬编码(改时手动更新)
class BuildInfo {
  BuildInfo._();

  static const String gitSha = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: 'dev',
  );

  static const String buildTime = String.fromEnvironment(
    'BUILD_TIME',
    defaultValue: '',
  );

  /// 主版本号(每次 release 大改动 +1)
  static const String version = '0.1.0';

  /// 数据库 schema 版本(随 migration 升级,见 app_database.dart)
  static const int schemaVersion = 4; // S03 D18 升至 4

  /// commit SHA 前 7 位(GitHub commit 列表用 7 位)
  static String get shortSha => gitSha.length >= 7
      ? gitSha.substring(0, 7)
      : gitSha;

  /// 全版本号显示字符串(主页底部用)
  static String get displayVersion =>
      'v$version · $shortSha · schema v$schemaVersion';
}
```

**WHY 集中到 `build_info.dart`**:
- 单一来源,所有需要显示版本的地方(主页底部 + 错误日志 + 未来「关于」页)都用同一个常量
- 测试时可 mock
- 升级 schema 时,改 `schemaVersion` 常量 + 改 `app_database.dart` 的 schemaVersion getter,两个地方(容易漏)

### 5. S03 ROA 移除版本号(发布版)

| 版本 | 显示策略 |
|---|---|
| 开发期 / 测试版(现在) | 显示 `v0.1.0 · b3b722e · schema v4` |
| 发布版(S08 上线验收后) | 隐藏底部版本号,改成「设置 → 关于」页可查 |

**WHY**:开发期需要快速定位 build 来源,发布版用户不需要看 commit SHA。

---

## 不可逆性

| 项 | 不可变性 | 理由 |
|---|---|---|
| `BuildInfo.gitSha` 默认值 `'dev'` | 必须保留 | 本地开发未走 CI 时,git SHA 是 'dev',不能 crash |
| `BuildInfo.shortSha` 用 7 位 | 不可变更 | GitHub commit 列表用 7 位,保持一致便于对比 |
| `BuildInfo.schemaVersion` 必须与 `AppDatabase.schemaVersion` 同步 | **必须保持**| 主页显示的 schema v4 必须真实反映数据库 v4,否则误导调试 |

---

## 后果

### 正面影响

- ✅ 装机后立刻知道装的 Runner.ipa 是不是新版本(一眼对比 GitHub commit)
- ✅ 调试效率大幅提升(用户回报截图时自动带 commit SHA,我立刻知道是哪次 build)
- ✅ 不引入新依赖(只用 Dart 标准库)
- ✅ 编译期常量,无运行时开销

### 负面影响 / 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| 主页底部小字可能分散用户注意力 | 🟢 低 | 灰色 + 字号 10,可忽略 |
| 用户截图反馈时忘了带版本号 | 🟢 低 | 已集成到 BuildInfo.displayVersion,我主动问即可 |
| `BuildInfo.schemaVersion` 与 AppDatabase 不同步 | 🟡 中 | 在 AppDatabase.schemaVersion getter 加注释「同步 BuildInfo.schemaVersion」|
| `--dart-define=GIT_SHA` 在本地 flutter run 不带,gitSha = 'dev' | 🟢 低 | 'dev' 默认值,本地开发不报错 |

### 衔接下游

- **所有 Stage**(S03-S08):每个 build 都有 commit SHA,调试时直接看版本号定位
- **S08 上线验收**:发布版隐藏主页版本号,改成「关于」页
- **v2.0+**:可扩展到「设置 → 关于」页显示完整信息

---

## 验证

- [ ] flutter analyze 0 错误
- [ ] flutter test 全绿(244 + 新增 ≥ 1 = 245+)
- [ ] BuildInfo 单元测试:default value / shortSha / displayVersion
- [ ] build-ios.yml 加 `--dart-define=GIT_SHA` 后,新 Runner.ipa 主页底部显示 `v0.1.0 · <7 位 sha> · schema v4`
- [ ] 本地 `flutter run` 不带 --dart-define,显示 `v0.1.0 · dev · schema v4`(不 crash)

---

## 关联

- ADR-0022:余额自动更新策略(本 ADR 是其调试教训沉淀)
- G-003:iOS 真机调试经验(error-catalog.md)
- CLAUDE.md §2:不引入新依赖 — `--dart-define` 是 Dart 标准 API,无新依赖
- `lib/build_info.dart`:实施位置
- `lib/features/home/presentation/home_page.dart`:主页底部显示
- `.github/workflows/build-ios.yml`:CI 注入 GIT_SHA
- `docs/daily/2026-08-02.md`:D19 装机教训记录

---

**最后更新**:2026-08-02(D19 拍板)
**生效日期**:S03 D19+ 立即生效
**下次复审**:S08 上线验收前(发布版隐藏版本号)