# ADR-0014: E2E 测试策略(integration_test 全生命周期)

> 状态:**已接受**
> 日期:2026-07-21(Day 7 加班)
> Stage:**全生命周期**(Stage 1-8 持续生效)
> 作者:Claude(执行)+ 用户(决策)

---

## 背景

Stage 1 Day 7 完成 emoji 化后,用户反思:**"代码层面的测试够了,但真机环境问题还是非常多"**。

当前测试体系(54 用例,Day 7 末)全是 `flutter_test` + fake_async + 内存 SQLite + test renderer。这覆盖了 ~95% 业务逻辑,但**以下真机场景完全没覆盖**:

| # | 真实场景 | widget test 覆盖? | 后果 |
|---|---|---|---|
| 1 | **emoji 字体渲染**(Apple Color Emoji) | ❌ test renderer 用 Ahem 字体 | iOS 真机字体回退可能导致 emoji 丢字 |
| 2 | **SQLCipher 真机 native linking**(Stage 6) | ❌ 内存 SQLite 跳过 native channel | 发布时才 crash |
| 3 | **振动 API 真触发**(`Vibration.vibrate`) | ❌ widget test 抛 MissingPluginException 直接吞 | 真机振不振动未知 |
| 4 | **SQLite 真机文件路径**(Documents dir + iOS sandbox) | ❌ 内存数据库 | iOS sandbox 权限可能拒写 |
| 5 | **真实 FPS / 掉帧**(16ms 帧预算) | ❌ test runner 不渲染帧 | UI 卡顿未知 |
| 6 | **Impeller vs Skia 渲染差异**(Flutter 3.24+ iOS 默认 Impeller)| ❌ test renderer 默认 Skia | iOS 真机图片/文字渲染差异 |
| 7 | **iOS 生命周期**(background/foreground) | ❌ 不触发 AppLifecycleState | 锁屏回来数据丢失? |
| 8 | **Plugin MethodChannel 真实通信**(Stage 6 SQLCipher / Stage 7 AI)| ❌ mock platform channel | Stage 6/7 发布即埋雷 |

**用户决策**:真机问题**不能堆积到 Stage 7/8 才发现**,必须从现在开始系统性加 E2E。

---

## 决策

**采用 `integration_test` 包(Flutter 团队官方包,与 SDK 同步发布,pubspec 用 `{ sdk: flutter }` 写法),建立真 Flutter engine 集成测试**

### 三层结构(扩展 ADR-0003 测试金字塔)

```
         /\
        /  \         E2E(真 Flutter engine / 真机 / 真 SQLite)
       /----\
      / 集成 \        integration_test(本 ADR)
     /--------\
    /  Widget   \     Widget 测试(复杂 UI)
   /-------------\
  /    单元测试     \  单元测试(业务规则、计算)
 /------------------\
```

比例调整(ADR-0003 更新):
- 单元 **60%** (原 70%)
- Widget **20%** (不变)
- Widget + Integration **20%** (原 20% widget)
- **E2E 10%** (新增)

### E2E 实施规范

**包选择**:
- ✅ `integration_test`(Flutter 团队官方包,与 SDK 同步发布;`{ sdk: flutter }` 写法跟 SDK 版本走,无版本锁定冲突)
- ❌ `patrol`(学习曲线陡,Native hook 改 UI 易碎)
- ❌ `maestro`(跨平台但黑盒,Finder 需要 Semantics 适配)
- ❌ `xcrun xctest` / `xcuitest`(违反 0 成本路线)

**测试目录**:

```
integration_test/
├── _helpers/
│   ├── test_harness.dart       # 共享 ProviderScope + DB override + 杀进程辅助
│   └── selectors.dart          # 命名查找('emoji-餐饮' / 'btn-step-next')
├── e2e_record_flow_test.dart   # 主页 → 弹层 → 记账 → 列表显示
├── e2e_persistence_test.dart   # 写交易 → 杀进程 → 重启 → 数据还在
└── e2e_emoji_render_test.dart  # 10 emoji 真渲染无 missing glyph
```

**每个 Stage 至少 1 个 E2E**:
- Stage 1:记账主流程 + emoji + 持久化(本 ADR 直接产出)
- Stage 2:分类 CRUD 流程 + 多账户流程
- Stage 3:信用卡还款流程
- Stage 4:预算执行触发警告
- Stage 5:净资产计算 + 仪表盘
- Stage 6:**SQLCipher 加密生效 + 错误密钥拒开**(关键)
- Stage 7:**AI 攒攒推理 + 异常检测**(关键)
- Stage 8:完整端到端验收

### 跑测试方式

**本地**:
```bash
# iOS 模拟器(macOS 开发机)
xcrun simctl boot "iPhone 15"
flutter test integration_test/ -d "iPhone 15"

# Android 模拟器(本项目只在 macOS 用,但代码统一)
flutter test integration_test/ -d emulator-5554
```

**CI(Stage 8 收尾时接入)**:
```yaml
# GitHub Actions 免费 macOS runner(每月 2000 分钟)
- name: Run E2E (iOS Simulator)
  uses: appleboy/flutter-action@v2
  with:
    flutter-version: "3.24.5"
- run: |
    xcrun simctl boot "iPhone 15"
    flutter test integration_test/ -d "iPhone 15"
```

**真机手动验收**(0 成本路线):
- Stage 1 Day 10:用户在 iPhone 上手动跑 3 个核心场景(等同 E2E 断言)
- Stage 6/7/8:每天手动跑 1 个新加场景

### 字段标注:真机专属标记

需要在 widget 上加 Key 便于 E2E 查找:

```dart
// find.byKey(const Key('record-fab'))
FloatingActionButton(
  key: const Key('record-fab'),
  onPressed: () => showRecordSheet(context),
)

// find.byKey(const Key('emoji-餐饮'))
Container(
  key: Key('emoji-${category.name}'),
  child: Text(category.iconName, ...),
)
```

**S01 Day 8 落实**:所有交互性 Widget 必须加 `Key('语义')` 便于 E2E 查找,**不可后续大改**。

---

## 后果

### 正面影响

| # | 影响 | 量化 |
|---|---|---|
| 1 | 真 Flutter engine + 真 SQLite 文件 | 表 1-8 全场景覆盖 |
| 2 | Plugin channel 真触发 | 振动 / Stage 6 SQLCipher / Stage 7 AI 推理**测试期间就能验** |
| 3 | iOS 生命周期可控 | `binding.handleAppLifecycleStateChanged` 在 E2E 中可模拟 |
| 4 | 真机 = 用户场景最接近 | 主页卡顿、首屏白屏、字体回退**测试阶段就发现** |
| 5 | 0 成本扩展 | `integration_test` 是 Flutter 团队官方包,跟 SDK 同步,无需额外依赖 + 许可证 |
| 6 | Stage 6/7 风险前置 | 不再"发布即埋雷" |

### 负面影响 / 成本

| # | 成本 | 数量 |
|---|---|---|
| 1 | Widget 加 Key 时间 | Stage 1 ≈ 1-2h |
| 2 | 每个新 Stage 写 E2E 时间 | 2-3h(每 Stage 1 个核心流程 E2E) |
| 3 | E2E 跑测试时间 | iOS simulator 单测 ~30s × N;全量 ~5-10min |
| 4 | Flaky 处理 | Impeller 渲染差异 + 真机动画 → 加 retry / stable pump |
| 5 | 本地无法跑 | **项目环境是 Windows,must use macOS for flutter test integration_test** |

### 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| iOS simulator 跑 E2E 需要 macOS | 🟡 中 | 现阶段代码层先就位 + Day 10 真机手验 + GitHub Actions 接入 |
| E2E 跑通 Windows 上的 widget test 不破 | 🟢 低 | E2E 文件用 ignore_for_file 不让普通 flutter test 抓到 |
| E2E Flaky(impeller 渲染时机) | 🟡 中 | 用 `pumpAndSettle` + `await Future.delayed` + 必要时 `binding.takeScreenshot` 调试 |
| Key 命名漂移 | 🟢 低 | governance/test-strategy.md 加 Key 命名规范,Day 9 起强制 |
| E2E 测试代码变多 | 🟢 低 | 限制每 Stage 1 个核心流程 E2E + 不重复 widget test 已覆盖 |

---

## 实施计划

### Stage 1(Day 7 加班 + Day 8-10)
- [x] ADR-0014 写完并接受(**本文件**)
- [x] pubspec.yaml 加 `integration_test: { sdk: flutter }`(git backup + ADR 授权)
- [ ] `integration_test/` 目录 + helper(本会话)
- [ ] E2E 测试 1:记账主流程(本会话)
- [ ] E2E 测试 2:emoji 真渲染(本会话)
- [ ] E2E 测试 3:真持久化(本会话)
- [ ] Day 8:Widget 补 Key + 修改/删除 + 退款
- [ ] Day 9:E2E 调通(需 macOS) + Stage 1 E2E 套件验收
- [ ] Day 10:真机手动跑 3 个核心场景 + Stage 1 ROA

### Stage 2-8(每 Stage 至少 1 个 E2E)
- 每个 Stage 启动时:写 E2E 测试 → 实施功能 → E2E 通过 → Stage ROA

### CI 集成(Stage 8)
- GitHub Actions 免费 macOS runner 跑 E2E
- E2E 失败 → 不让 merge main

---

## 关键决策对比

| 维度 | 现状(无 E2E) | 本 ADR 加 E2E |
|---|---|---|
| 用户旅程覆盖 | ~70%(单测 + widget 可控部分) | 95%(覆盖真机/真引擎) |
| Stage 6 SQLCipher 风险 | 🔴 发布即埋雷 | 🟢 测试期间发现 |
| Stage 7 AI 推理风险 | 🔴 性能数据不可知 | 🟢 真推理运行时长可测 |
| iOS 生命周期 | 🔴 完全盲区 | 🟢 AppLifecycleState 可在 E2E 触发 |
| 真机问题前置 | ❌ 用户装到 iPhone 才发现 | ✅ 本地 CI / 真机日 1 跑即知 |
| 维护成本 | 🟢 低 | 🟡 中(E2E 文件 + Key 标注 + Flaky 治理) |

---

## 复盘条件

如果出现以下情况,重新评估:

1. E2E 跑时间 > 10 分钟(优化目标或减少 E2E 数)
2. Stage 6/7 仍出现 E2E 未覆盖的真机 BUG(Key/路径不够)
3. iOS simulator 跑 E2E 频繁 flake(impeller 渲染等待)
4. 用户抵触"每 Stage 加 E2E"的成本

---

## 参考

- Flutter 官方 [`integration_test` 包](https://docs.flutter.dev/testing/integration-tests)
- ADR-0003(测试金字塔)+ ADR-0012(依赖决策)
- CLAUDE.md §9 关键决策(此 ADR 不可推翻,除非新 ADR 替换)

---

**最后更新**:2026-07-21 · Day 7 加班创建 v1.0
