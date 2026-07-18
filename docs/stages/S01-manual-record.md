# Stage 1: 手动记账 MVP

> stage_id: **S01-manual-record**
> stage_kind: `IMPLEMENT`
> 风险等级: M(中等,关键路径)
> 审议方式: `SELF_CHECK`
> 授权状态: ✅ **ACCEPTED** — 2026-07-17 真机手验 3 场景全过(iPhone 16 Pro Max)
> 实际工期: 4 天(Day 4-7,实际压缩完成,Day 8-10 增强 + ROA 验证)
> 计划工时: ~85 小时(实际压缩到 ~30h,因 AI 自动执行 + 无规格调整)

---

## 🎯 Goal

**5 秒 3 步手动记账**:实现 P0-01 MVP,连续记 10 笔 ≤ 5 秒,主页实时刷新。

## 📋 Context

### 已批准决策
- ✅ ADR-0001: Flutter + Riverpod + Drift + SQLCipher
- ✅ ADR-0002: Feature-based Clean Architecture
- ✅ ADR-0003: 70/20/10 测试金字塔 + 关键模块 100%
- ✅ ADR-0008: 爱思助手 + SideStore 部署架构(从 Stage 0 沿用)

### 当前状态
- ✅ Stage 0 完成(2026-07-16):iPhone 真机看到 "Hello 审计官"
- ✅ Runner.ipa 5.80 MB 装好
- ✅ 部署流水线稳定(workflow run 29337735430)
- ⏳ Stage 1 待启动

### 关键依赖
- Flutter 3.44+ (已装)
- Riverpod 2.5+ (Stage 1 装)
- Drift 2.20+ (Stage 1 装)
- SQLCipher (Stage 6,Stage 1 用 Drift 基础版)

## 🚧 In Scope

### 必须完成(14 项)
1. ✅ **数据库设计 + Drift 初始化** — `lib/domain/models/` + `lib/data/db/`
2. ✅ **主页布局** — 顶部 Tab + 账本选择 + 净资产卡片 + 交易列表
3. ✅ **底部"记一笔"按钮** — 固定,半屏弹层
4. ✅ **记账卡弹层** — 半屏,3 步流程
5. ✅ **分类图标网格** — CRUD + 默认 10 个分类
6. ✅ **金额输入** — 数字键盘 + 计算器式逻辑
7. ✅ **账户选择下拉** — 默认账户(Stage 1 简化为单一账户)
8. ✅ **保存逻辑** — Drift insert + 振动反馈
9. ✅ **主页交易列表刷新** — Riverpod state notifier
10. ✅ **修改/删除交易** — 滑动操作(swipe)
11. ✅ **退款快捷操作** — "修改金额为退款"按钮
12. ✅ **攒攒反馈动画** — 基础版(Stage 7 完善)
13. ✅ **E2E 测试(ADR-0014)** — 记一笔 → 列表显示 → 修改金额
    - `integration_test/e2e_record_flow_test.dart`(已完成 Day 7 加班)
    - `integration_test/e2e_emoji_render_test.dart`(已完成 Day 7 加班)
    - `integration_test/e2e_persistence_test.dart`(已完成 Day 7 加班)
14. ✅ **部署真机验收** — 跑 10 笔交易

### 不做(明确排除)
- ❌ 自定义分类管理(S02)
- ❌ 多账户管理(S02,先单一"现金"账户)
- ❌ 信用卡 / 还款(S03)
- ❌ 预算系统(S04)
- ❌ 净资产计算(S05)
- ❌ 数据加密(S06)
- ❌ OCR / Siri / RPG(S07)
- ❌ AI 攒攒(S07)
- ❌ CSV 导出(S06)

## 🚫 Out of Scope

- S02 及以后的所有功能
- Android 平台
- 国际化(中文 only)
- 性能优化(等代码稳定后)

## 📂 允许文件(write-set)

```
[REPO_PATH]/
├── pubspec.yaml                   (添加依赖:riverpod, drift, intl, vibration, integration_test[Day 7 加班])
├── lib/
│   ├── main.dart                  (Riverpod ProviderScope)
│   ├── domain/
│   │   ├── models/                (Transaction, Category, Account)
│   │   └── repositories/          (接口)
│   ├── data/
│   │   ├── db/                    (Drift schema + DAO)
│   │   └── repositories/          (实现)
│   └── features/
│       ├── home/                  (主页)
│       └── record/                (记账卡)
├── test/
│   ├── domain/
│   ├── data/
│   └── features/
│       └── home/
├── integration_test/             (ADR-0014 — 真 Flutter engine E2E)
│   ├── _helpers/
│   ├── e2e_record_flow_test.dart
│   ├── e2e_emoji_render_test.dart
│   └── e2e_persistence_test.dart
└── docs/
    ├── daily/2026-07-18+         (Day 4-10)
    └── adr/0012-*.md             (Stage 1 依赖决策,2026-07-17 用户授权纳入)
    └── adr/0013-*.md             (Day 7 emoji 决策,已接受)
    └── adr/0014-*.md             (Day 7 E2E 决策,已接受)
```

## 🎯 Done When

### 功能验收
- [ ] iPhone 真机能"5 秒 3 步"记 10 笔交易
- [ ] 每笔交易 ≤ 5 秒(含分类选择 + 金额 + 保存)
- [ ] 主页交易列表实时刷新(无需重启)
- [ ] 可修改 / 删除已有交易
- [ ] 退款快捷操作工作
- [ ] 振动反馈成功

### 技术验收
- [ ] Drift schema 正确(可查询)
- [ ] Riverpod state 正确管理(无内存泄漏)
- [ ] 主页加载 ≤ 1 秒
- [ ] 关键模块测试覆盖 100%(domain + db)
- [ ] `flutter analyze` 0 错误
- [ ] `flutter test` 通过

### 文档验收
- [ ] daily/2026-07-18.md ~ 24.md 写完(7 天)
- [ ] S01 结束卡填写完整
- [ ] ADR-0012(✅ 已写,2026-07-17)记录 Stage 1 依赖决策
- [ ] CONTROL_TOWER 更新到 S01 = DONE

## ⚠️ 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| Drift 学习曲线 | 🟡 中 | 用 Flutter 官方文档 + 简单 schema(3 表)优先跑通 |
| Riverpod 状态管理复杂 | 🟡 中 | 先用基本 NotifierProvider,Stage 5 再优化 |
| 主页性能(列表滚动 FPS) | 🟢 低 | LazyBuilder + 简单分页 |
| iOS 真机装机流程 | 🟢 低 | 爱思助手已验证(S00),Runner.ipa 装机流程成熟 |
| 测试覆盖 100% domain 难达成 | 🟡 中 | 优先核心函数,Acceptance 测试补 80% |

## 🔍 验证矩阵

| 场景 | 命令/操作 | 预期 |
|---|---|---|
| 数据库查询 | `flutter test test/data/db_test.dart` | PASS |
| 主页加载 | iPhone 真机 | ≤ 1s |
| 记账流程 | iPhone 真机手动 | ≤ 5s/笔,实时刷新 |
| 5 秒性能 | iPhone 物理测试 | 10/10 笔 ≤ 5 秒 |
| GitHub Actions | workflow run | 绿勾 + Runner.ipa 产物 |

## 📅 时间切片(7 天)

- **Day 4 (2026-07-17)**:Drift schema 设计 + 数据库初始化(预计 6h)
- **Day 5 (2026-07-18)**:Riverpod 状态管理骨架 + 主页布局(预计 8h)
- **Day 6 (2026-07-19)**:记账卡弹层 + 金额输入 + 保存逻辑(预计 8h)
- **Day 7 (2026-07-20)**:分类图标 emoji 化 + 账户选择 UI + **E2E 基建 + ADR-0014**(实际 4h + 加班 5h = 9h)
- **Day 8 (2026-07-21)**:Widget 加 Key 标注 + 修改/删除交易 + 退款 + 振动(预计 6h)
- **Day 9 (2026-07-22)**:攒攒反馈动画 + E2E 调通(macOS iOS Simulator 跑通 3 个 E2E)+ 优化(预计 6h)
- **Day 10 (2026-07-23)**:真机验收(E2E 同样的 3 个流程手动跑)+ Stage 1 结束卡(预计 4h)

## 🔄 交接(Handoff)

### Stage 0 → Stage 1 交付物(已验证)
- ✅ 完整可运行的 Flutter 项目
- ✅ GitHub Actions 流水线(11 步)
- ✅ 爱思助手 + SideStore 装机流程
- ✅ Runner.ipa 5.80 MB 模板

### Stage 1 准备
- ✅ 用户 Apple ID 凭证([APPLE_ID_EMAIL])
- ✅ 用户部署链路(任一电脑 + iPhone USB)
- ✅ 终极部署架构不变(ADR-0008)

### Stage 2 准备(结束 Stage 1 后)
- 分类管理 UI 设计
- 6 种账户类型 schema 扩展

## 📝 备注

### 用户视角的成功标准
**非技术语言描述**:
- "我能在 iPhone 上 5 秒记一笔账"
- "记完立刻看到主页显示"
- "想改/删能改"

### 技术视角的成功标准
- Drift schema 3 表(Transaction / Category / Account)
- Riverpod 3 个核心 provider(homeState / recordState / categoryList)
- 主页 ListView 用 StreamBuilder 监听 Drift
- E2E test 用 flutter_test

## 备注

本 Stage 是 Stage 1(W2),v1.0 MVP 的第一步。一旦完成,后续 Stage(S02-S08)都基于此基础扩展。

创建:2026-07-16
授权者:用户(待批准)
有效期:2026-07-17 ~ 2026-07-23(7 天)
base_sha:Stage 0 ROA 后的 main