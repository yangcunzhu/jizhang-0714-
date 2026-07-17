# Stage 3: 信用卡 & 还款

> stage_id: **S03-credit-card-repayment**
> stage_kind: `IMPLEMENT`
> 风险等级: M(中等,Schema 迁移 + 还款流新 feature 单元)
> 审议方式: `SELF_CHECK`
> 授权状态: 🔄 **DRAFT**(待用户授权 ACTIVE — 基于 ADR-0021 范围已确定)
> 计划工期: 7 天(Day 18-24,2026-08-01 ~ 2026-08-07)
> 计划工时: ~55 小时(AI 自动 + 决策快)

---

## 🎯 Goal

**完成信用卡还款闭环**:用户在 S02 已建「信用卡账户」基础上,可执行「从储蓄账户 → 信用卡账户」的还款流,还款记录作为特殊 transaction 持久化,账户卡片显示账单日/还款日让用户主动跟踪还款时间。

承接 S02 DRAFT(ROA 待签)状态:
- ✅ 主页能记账
- ✅ 分类 CRUD + 多账户
- ✅ 6 种账户类型 + 信用卡字段(creditLimit / billingDay / dueDay)
- 🔄 S02 ROA 待签(D18 早上真机手验后)

---

## 📋 Context

### 已批准决策

- ✅ ADR-0021:S03 范围 = 最小 MVP(还款流 + 卡片增强 + 不引通知)— 见 `docs/adr/0021-stage3-credit-card-scope.md`
- ✅ ADR-0015:Stage 2 写集(延续 — S03 基于 S02 6 种账户类型)
- ✅ ADR-0017:AccountType enum + schema v2(信用卡字段已就位)
- ✅ ADR-0012:依赖锁定(沿用 drift / riverpod / flutter 3.44.6 — **S03 不引新依赖**)
- ✅ ADR-0013:emoji 优先(沿用)

### 当前状态(S02 落地)

- ✅ Drift schema v3(accounts 加 5 字段 + category_templates 新表)
- ✅ 6 种账户类型 + 信用卡字段(creditLimit / billingDay / dueDay)
- ✅ 多账户选择器(主页 Step 3)
- ✅ 信用卡账户 CRUD UI
- 🔄 S02 ROA 待签(D18 真机手验后)

### 关键依赖

- Drift schema migration v3 → v4(transaction type 扩展为 repayment)
- Riverpod 2.6.1(继续手写 provider)
- Flutter 3.44.6(沿用,无新依赖)
- **不引 flutter_local_notifications**(用户决策,见 ADR-0021)

---

## 🚧 In Scope(3 项必须完成)

### 必须完成

1. **Schema migration v3 → v4** — transactions 表 type 字段扩展,加 `repayment` 类型(S02 已有 `expense` / `income`)
   - 决策点:TransactionType enum 加值 `repayment`(不可逆,见 ADR-0021 §「不可逆性」)
   - migration 用 `textEnum` 自动处理(已沿用 ADR-0017 模式)
2. **还款流 UI** — 「从储蓄账户 → 信用卡账户」转账交互
   - 入口:信用卡账户卡片菜单 / 主页「+」长按菜单(从 S02 多账户选择器扩展)
   - 步骤:选储蓄账户 → 输入金额 → 选信用卡账户 → 备注(可选)→ 保存
   - 落地:生成 1 条 type=repayment 的 transaction(内部逻辑 = 从储蓄账户扣款 + 信用卡账户"增加可用额度")
   - 验证:账户余额正确更新(transaction.amount 储蓄账户为负,信用卡账户为正)
3. **信用卡账户卡片增强** — 显示「距离还款日 X 天」+ 账单日 / 还款日字段
   - 当前位置:`lib/features/account/presentation/widgets/account_card.dart`
   - 显示逻辑:仅 `type=creditCard` 的卡片显示这两个字段
   - 「距离还款日 X 天」计算:从当前日期到 `dueDay`(本月或下月)的差值

### 不做(明确排除 — ADR-0021 §1)

- ❌ flutter_local_notifications 本地通知(不引新依赖,违反 CLAUDE.md §2)
- ❌ 信用卡账单生成(自动抓取 / 手动输入账单明细)
- ❌ 自动还款(扣款日自动从储蓄账户转账)
- ❌ 多币种(只支持 CNY)
- ❌ 信用评分 / 最低还款额计算
- ❌ 信用账户流水归类逻辑(消费 → 信用卡账户)—— 已在 S02 多账户选择器实现,记账时选信用卡账户即可

---

## 🚫 Out of Scope

- Stage 4+ 全部功能
- iOS 17+ visionOS / Stage Manager 适配
- 多语言(中文 only)
- 云同步 / 备份(Stage 6)
- 通知中心集成(Android / iOS Push)

---

## 📂 允许文件(write-set,基于 ADR-0021)

```
lib/
├── data/db/
│   ├── app_database.dart              (改:schema v4 + migration v3→v4)
│   ├── tables/
│   │   └── transactions.dart          (改:TransactionType enum 加 repayment)
│   └── daos/
│       └── transaction_dao.dart       (改:+ 还款流事务方法 transferRepayment)
├── features/
│   ├── account/
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── account_card.dart  (改:信用卡卡片显示账单日/还款日)
│   │           └── (新) repayment_sheet.dart  (新:还款流弹层)
│   └── (新)repayment/                 (新 feature:还款流)
│       ├── application/
│       │   └── repayment_form_provider.dart
│       └── presentation/
│           └── (暂时内联在 repayment_sheet)
└── features/home/
    └── presentation/
        └── home_page.dart             (改:主页「+」菜单加「还款」入口)

test/
├── data/db/                           (改:migration v3→v4 测试)
├── features/
│   ├── account/                       (改:account_card 信用卡字段 widget 测试)
│   └── (新)repayment/                 (新建:还款流 widget + provider 测试)
└── integration_test/                  (S03 E2E 沿用 S02 widget test + bootContainer 模式)

docs/
├── daily/2026-08-01..07.md            (Day 18-24 工作日志)
├── adr/0021-*.md                     (本 Stage 范围决策)
└── stages/S03-credit-card-repayment.md  (本文件)
```

### 不在写集(明确排除)

- ❌ `product-design-v4.html` 修改
- ❌ `pubspec.yaml` 依赖增删(**关键** — S03 0 新依赖)
- ❌ `.github/workflows/*.yml`(受 §11 保护)
- ❌ `ios/Runner/Info.plist`(不需要通知权限配置)
- ❌ `lib/features/notification/`(S03 不引通知)
- ❌ `lib/features/budget/`(S04 范围)
- ❌ 修改 Stage 1/2 已 ACCEPTED 代码的核心逻辑

---

## 🎯 Done When

### 功能验收(7 项)

- [ ] TransactionType enum 加 `repayment` 值(textEnum 自动处理)
- [ ] 主页「+」菜单有「还款」入口(仅当存在 ≥1 信用卡账户时显示)
- [ ] 还款流弹层 3 步骤:选储蓄账户 → 输入金额 → 选信用卡账户 → 保存
- [ ] 还款 transaction 正确生成:储蓄账户扣款 + 信用卡账户"增加可用额度"(TransactionType=repayment)
- [ ] 信用卡账户卡片显示:账单日 / 还款日 / 「距离还款日 X 天」
- [ ] 旧 S02 数据(无 repayment transaction)不丢
- [ ] 集成测试覆盖还款全链路

### 技术验收(5 项)

- [ ] Drift schema migration v3 → v4 不破坏数据(沿用 ADR-0017 默认值兜底)
- [ ] flutter analyze 0
- [ ] flutter test 全绿(227 + 新增 ≥ 25 用例 = 252+)
- [ ] Build iOS .ipa CI 绿
- [ ] iPhone 真机手验 3+ 场景全过

### 文档验收(4 项)

- [ ] daily/2026-08-01..07.md(7 天)写完
- [ ] S03 状态改 ACCEPTED + ROA 报告
- [ ] CONTROL_TOWER 派生更新到 S03 = ACCEPTED
- [ ] ADR-0021 已接受(本 Stage 范围决策)

---

## ⚠️ 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| 还款流事务失败导致账户余额不一致 | 🟡 中 | 用 `transaction {}` 包裹,任何步骤失败回滚 |
| TransactionType 加 repayment 破坏历史行 | 🟢 低 | textEnum 兼容性已验证(ADR-0017 模式);旧行 type='expense'/'income' 不动 |
| 信用卡「距离还款日」跨月计算错误 | 🟡 中 | 单测覆盖 1/15/28/31 + 跨月边界 |
| Build iOS CI 又卡死 | 🟢 低 | 沿用 G-003 沉淀 |
| 用户认知负担(还款 vs 记账混淆) | 🟡 中 | 主页「+」菜单分两栏「记账 / 还款」,UI 区分文案 |

---

## 🔍 验证矩阵

| 场景 | 命令 / 操作 | 预期 |
|---|---|---|
| migration 不破坏数据 | `flutter test test/data/db/migration_v4_test.dart` | PASS |
| TransactionType enum | `flutter test test/data/db/transaction_dao_test.dart` | 全绿 |
| 还款流 DAO | `flutter test test/features/repayment/` | 10+ 用例全绿 |
| 信用卡卡片增强 widget | `flutter test test/features/account/` | 卡片渲染测试 |
| 主页 iPhone 端到端 | 真机 3 场景手验 | PASS |
| CI iOS build | GitHub Actions Build iOS .ipa #X | GREEN |

---

## 📅 时间切片(7 天)

- **Day 18 (08-01)**:Schema migration v4 + TransactionType 加 repayment + DAO 测试 + 主页「+」菜单加「还款」入口(仅 1 文件)— 用户先做 S02 真机手验,签字后 CONTROL_TOWER 改 S03 写集
- **Day 19 (08-02)**:还款流 DAO(transferRepayment 事务方法)+ 单元测试 + integration test
- **Day 20 (08-03)**:还款流 UI(repayment_sheet.dart 3 步骤 + Riverpod provider)
- **Day 21 (08-04)**:信用卡账户卡片增强(account_card.dart 显示账单日/还款日/距离 X 天)
- **Day 22 (08-05)**:集成测试 + polish(主页菜单区分「记账 / 还款」)
- **Day 23 (08-06)**:真机手验 3+ 场景
- **Day 24 (08-07)**:Stage 3 ROA 收尾 + CONTROL_TOWER 更新

---

## 🔄 交接(Handoff)

### Stage 2 → Stage 3 交付物(S02 ACCEPTED 后)

- ✅ Drift schema v3 + 6 种账户类型 + 信用卡字段
- ✅ 多账户选择器
- ✅ 5 个 S02 ADR(0015 / 0017 / 0018 / 0019 / 0020)
- ✅ 227/227 测试 + analyze 0
- 🔄 ROA 待签(D18 早上用户真机手验后)

### Stage 3 准备

- ✅ ADR-0021 范围已确定(最小 MVP)
- ⏳ 用户授权 ACTIVE(待 S02 ACCEPTED 后拍板"开干")

### Stage 4 准备(结束 Stage 3 后)

- 账本分类汇总
- 月度预算管理
- 多账本切换

---

## 📝 备注

### 用户视角的成功标准

**非技术语言描述**:
- "我能从储蓄账户往信用卡还款,记账上看到'还款'"
- "信用卡卡片告诉我下个月几号要还多少钱"
- "还款后信用卡可用额度增加,储蓄账户余额减少"

### 技术视角的成功标准

- Drift schema v4 支持 TransactionType=repayment
- 还款流 DAO 用事务保证账户余额一致
- 信用卡卡片显示「距离还款日 X 天」基于 dueDay 字段计算

---

## 🗣️ Day 18 开工话术

> **Day 18 (2026-08-01) Stage 3 Day 1 — Schema migration v4 + 还款流入口**
> 工时预算:6 小时

### 必读清单(前 3 分钟)

1. `CLAUDE.md`
2. `docs/CONTROL_TOWER.md`(S03 写集刚 ACTIVE,S02 = ACCEPTED)
3. `docs/daily/2026-08-01.md`(今天创建)
4. `docs/stages/S03-credit-card-repayment.md`(本文件)
5. `docs/adr/0021-stage3-credit-card-scope.md`(范围决策)

### 状态对齐

- S02 = ✅ ACCEPTED(D18 早上真机手验 4 场景签字后)
- S03 = 🔄 ACTIVE(D18 签字后派生)
- 测试基线:227/227(S02 终态)
- ADR 最大编号:0021(新决策用 0022+)

### 今日目标(D18 — S03 Day 1 + S02 收尾)

**上午(S02 收尾):**

1. 用户真机手验 4 场景(沿用 D16 daily §「真机手验脚本」)
2. 回报后我立刻:
   - 填 ROA §用户签字 段 `✅ ACCEPTED`
   - 改 CONTROL_TOWER(S02 = ACCEPTED + §3 授权边界改 S03 + §4 Stage 3 ROA 行预创建)
   - 5 个 S02 ADR §「验证」section checkbox 补勾
   - commit + push

**下午(S03 Day 1 开工):**

1. ✅ **Schema migration v3 → v4** — TransactionType enum 加 `repayment` 值
2. ✅ **transaction_dao.dart 加 `transferRepayment()` 事务方法**(先写接口签名,Day 19 实施细节)
3. ✅ **主页「+」菜单加「还款」入口**(仅当存在 ≥1 信用卡账户时显示)
4. ✅ **migrate_v4_test.dart** 断言:旧 transaction.type='expense'/'income' 不变,新 type='repayment' 可写
5. ✅ 测试 ≥ 5(S03 起步)
6. ✅ D18 daily 写完 + commit + push

### 写集(均在 S03 §📂 允许文件)

```
lib/
├── data/db/
│   ├── app_database.dart              (改:schemaVersion 4 + onUpgrade v3→v4)
│   ├── tables/transactions.dart       (改:TransactionType 加 repayment)
│   └── daos/transaction_dao.dart     (改:+ transferRepayment 签名)
├── features/home/
│   └── presentation/home_page.dart   (改:主页「+」菜单加「还款」入口)

test/
└── data/db/migration_v4_test.dart    (新:旧数据 + 新 repayment 类型断言)

docs/daily/2026-08-01.md              (新:D18 daily)
```

### 不动(CLAUDE.md §11 保护)

- `product-design-v4.html` / `pubspec.yaml`(0 新依赖)/ `Info.plist` / `.github/workflows/*` / `.gitignore`

### 写代码前 8 检查(CLAUDE.md §4)

| # | 检查 | 备注 |
|---|---|---|
| 1 | write-set 包含目标? | ✅ 上表已列 |
| 2 | git worktree 干净? | D17 commit `8cfb8ac` 已 push,只剩 `.ai-work/` 未跟踪 |
| 3 | 涉及哪个 ADR? | ADR-0021(范围)+ ADR-0017(textEnum 模式参考)|
| 4 | 测试覆盖率目标? | 227 → 232+(Day 18 起步) |
| 5 | 用了占位符 / TODO? | 不需要 — 写代码 + 测试都是设计内 |
| 6 | 文件名符合规范? | `lib/data/db/tables/transactions.dart` 等已存在 / `migration_v4_test.dart` 新建 |
| 7 | 内部链接目标存在? | `docs/adr/0021-stage3-credit-card-scope.md`(本 Stage 新建)|
| 8 | commit 信息规范? | Conventional Commits,例:`feat(s03): Stage 3 Day 18 schema migration v4 + 还款流入口 + 5 tests` |

### 用户拍板 2 决策

| 决策 | 推荐 | 落地 |
|---|---|---|
| ① 还款流事务方法命名 | **A. `transferRepayment(fromAccountId, toAccountId, amountCents, note)`**(语义清晰) | transaction_dao.dart 加方法签名;Day 19 实施 |
| ② 主页「+」菜单 UI 区分 | **A. 分两栏(记账 / 还款)下拉**(简单) | home_page.dart 改 FloatingActionButton 或加 PopupMenuButton |

### 验收

- [ ] S02 真机手验 4 场景全过 + ROA 签字 + CONTROL_TOWER 派生 ACCEPTED
- [ ] schemaVersion 4 + TransactionType 加 repayment
- [ ] transaction_dao.transferRepayment 签名 + 单元测试骨架
- [ ] 主页「+」菜单有「还款」入口(条件渲染)
- [ ] migration_v4_test.dart 全过
- [ ] analyze 0 + test 232+ 全绿
- [ ] D18 daily 写完 + commit + push + status 干净

### 下一步(D19 — S03 Day 2)

- transaction_dao.transferRepayment 实施(transaction {} 事务)
- 单元测试覆盖成功路径 + 失败回滚
- integration test 第一个用例

---

**创建**:2026-07-31(D17 收尾时)
**授权者**:用户(待 S02 ACCEPTED 后批准)
**有效期**:2026-08-01 ~ 2026-08-07(7 天)
**base_sha**:S02 ACCEPTED 后的 main(预计 D18 签字后)
