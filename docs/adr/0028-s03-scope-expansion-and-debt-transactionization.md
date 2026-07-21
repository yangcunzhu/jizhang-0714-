# ADR-0028:S03 范围扩写追溯 + 借贷业务流程独立化 + pubspec.yaml §11 例外授权

> 状态:**已接受**
> 日期:2026-08-06(D23 装机验前治理收尾)
> Stage:**S03-credit-card-repayment**(D23 装机验前,治理文档同步)
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0021**(被超越 — S03 最小 MVP → 实际 14 项)/ **ADR-0022**(余额联动策略不变,扩展为 5 类 transaction)/ **ADR-0024**(被超越 → 借贷 transaction 化)/ **ADR-0026 §6 §8 §10 §12.1 §12.3 §14**(内部不一致修正)/ **CLAUDE.md §11**(pubspec 例外授权)/ **CLAUDE.md 铁律 9**(v4 §3.1 引用)

---

## §1 背景

### 1.1 治理缺失

D21(ce11073,2026-08-04)+ D22(6888552,2026-08-05)在 S03 ACTIVE 期间**实际完成了 ADR-0021「最小 MVP」范围之外的 11 项功能**,但**未走任何治理流程**(无 Decision Request、无 ADR 修订、S03 §In Scope 未更新)。

触发场景:用户 2026-08-05 真机手验反馈 3 个问题后,大副在 D22 daily(2026-08-05.md)§「妥协 / 显式简化」**主动声明**了这一治理漏洞,要求本会话(2026-08-06)收尾。

### 1.2 D18-D22 实际做了什么(vs 原计划)

| Day | commit | 计划范围 | 实际范围 | 偏差 |
|---|---|---|---|---|
| **D18** | (2026-08-01,S02 签字) | schema migration v4 + TransactionType 加 repayment | 同计划 | — |
| **D19** | (2026-08-02) | 还款流 DAO(transferRepayment)+ ADR-0022/0023 | + ADR-0022(余额策略)+ ADR-0023(build_info) | 多 2 个 ADR |
| **D20** | `401e7ce` `ec2d83c` `8c3f21a` (2026-08-03) | 还款流 UI + 主页「+」入口 | + ADR-0024(6 种账户定位)+ ADR-0025(v1.1 backlog)+ ADR-0026(咔皮 13 张截图完整产品设计)+ schema v5(installment_period)+ 主页提醒卡片 + transaction_tile 期数徽章 + 4 收款类型还款 + 网贷期数 | **超出计划 6 项** |
| **D21** | `ce11073` (2026-08-04) | 信用卡卡片增强 | **彻底重做**:5 大类 × 23 子类 schema v6 + transferMoney DAO + 主页「+」改 5 入口聚合菜单(记一笔/转账/还款/借出/借入)+ AccountCategory/AccountSubType 双枚举 + 4 toggle | **完全偏离原计划**(D21 daily 称"超前,补齐 §3.1 咔皮对标核心")|
| **D22** | `6888552` (2026-08-05) | (无计划,D21 完成后顺延)| **真机 3 问题修复**:借出/入独立全屏(LendRecordPage/BorrowRecordPage)+ 日期 picker 中文 locale(pubspec 加 flutter_localizations)+ 转账下拉去过滤 + schema v7 migration(fromAccountId/toAccountId/counterpartyName/startDate)+ lendMoney/borrowMoney DAO + TransactionType lend/borrow | **完全新增**(非原计划内)|

**累计**:**D18-D22 实际完成 14 项功能**,远超 ADR-0021 声明的 3 项最小 MVP。

### 1.3 借贷决策矛盾(§1 关键)

| 时间 | 来源 | 借贷语义 | 与代码一致性 |
|---|---|---|---|
| 2026-08-03 ADR-0026 初版 | `965a4ad` | 借贷作为 transaction 类型(§12.3)+ 账户子类型借出/借入改为 transactionType 枚举 lend/borrow | — |
| 2026-08-03 ADR-0026 修订 | `f9a4881` | **借贷作为独立账户 subType=lend/borrow**(修正误判),有完整 6 字段(图 25/26) | 代码已按"独立账户"实现 subType 字段 |
| 2026-08-04 D21 实施 | `ce11073` | schema v6 accounts 表加 subType=lendOut/borrowIn(独立账户) | ✅ 代码一致 |
| 2026-08-05 D22 真机验后 | `6888552` | **真机截图 261-264 显示咔皮的「借出/借入」是独立全屏记账页,不是账户 CRUD**。大副修订 schema v7 + 新增 lendMoney/borrowMoney DAO + LendRecordPage/BorrowRecordPage 全屏 widget + TransactionType lend/borrow | ✅ 代码与咔皮对齐 |
| 2026-08-06 用户校准 | (本会话)| **借贷作为独立业务流程(transaction 化主导 + subType 字段保留落库占位 + UI 不暴露借贷账户入口)** | ✅ 与 D22 代码 + 咔皮对标 三方对齐 |

**根因**:ADR-0026 修订版(f9a4881)「借贷作为独立账户」是**基于截图文字描述的猜测**,未点击实际咔皮 UI 验证。D22 真机手验后,咔皮截图 261-264 显示借贷是**记账按钮**而非"添加借贷账户"。

**不可逆性**:D22 已实施,代码不可回退到「独立账户」模型(下游计算已基于 transaction)。

---

## §2 决策

### 决策 1:借贷作为独立业务流程(transaction 化)

#### 1.1 借贷业务流程独立(用户视角)

| 维度 | 设计 |
|---|---|
| **FAB 入口** | 主页「+」聚合菜单第 4 / 第 5 项:「📤 借出」/「📥 借入」(D21 决策)|
| **界面形式** | **独立全屏记账页面**(LendRecordPage / BorrowRecordPage),**不**走 AccountEditSheet 预选借贷 subType |
| **业务流程** | 用户填金额 + 选扣款/入款账户 + 起始时间(必填,语义「该时间之前的记录不计入余额统计」)+ 备注 → 落库为 transaction(type=lend/borrow) |
| **UI 不暴露** | 用户**不能**主动建借贷账户(AccountEditSheet 不提供借贷 subType 入口,首页「+ 添加账户」也不含借贷)|

#### 1.2 schema / DAO / 数据层(技术视角)

| 维度 | 设计 | 不可逆性 |
|---|---|---|
| **schema v7** | `transactions` 表加 `fromAccountId` / `toAccountId` / `counterpartyName` / `startDate`(4 列,migration v6→v7) | ✅ 不可逆(S07+ 统计依赖)|
| **TransactionType 枚举** | 加 `lend` / `borrow`(textEnum 兼容)| ✅ 不可逆(下游统计依赖字符串)|
| **DAO** | `lendMoney(fromAccountId, counterpartyName, amountCents, startDate, note)` + `borrowMoney(toAccountId, counterpartyName, amountCents, startDate, note)` — 事务原子,借贷分类自动 seed | ✅ 不可逆(已有 11 个测试覆盖)|
| **subType=lendOut/borrowIn** | **schema 字段保留**(AccountCategory.loan + AccountSubType.lendOut/borrowIn)用于 schema 一致性,UI 不暴露 | ⚠️ 占位字段,后续 D24+ 可选删除(详 §5 后续) |
| **TransactionTile 显示** | transfer 用中性色 + ⇄ 前缀(D21);lend/borrow 暂沿用 transfer 显示模式(D22 未单独做 tile,D24+ 评估) | 🟡 显示一致性可后续优化 |

#### 1.3 与咔皮对标

咔皮截图 #25-26 显示借贷是**记账按钮**(顶部黄框起始余额/起始欠款 + 起始时间 + 借款人姓名 + 扣款/入款账户 + 3 toggle),D22 实施的 LendRecordPage/BorrowRecordPage 完整对标。咔皮本身**无「添加借贷账户」入口**。

#### 1.4 不做(避免再次偏离)

| 不做 | 理由 |
|---|---|
| ❌ 借贷 subType 字段删除(D24 评估) | subType 字段保留落库 = schema 复杂度浪费,但删除需 schema v8 migration + 历史数据迁移,**风险大于收益**,留 ADR-0029 backlog |
| ❌ 借贷账户余额汇总(按 loan 大类 SUM) | 借贷不存在账户,无法汇总;净资产通过 transaction 表过滤 type=lend/borrow 计算(详 ADR-0026 §6/§8 修订)|
| ❌ 借贷 transaction 退款按钮 | ADR-0026 §9 退款按钮语义未确认(待用户点咔皮一次),借贷退款同信用卡退款待 ADR-0030 |

### 决策 2:S03 范围扩写(ADR-0021 部分被超越)

#### 2.1 S03 范围声明(D18-D22 实际 14 项)

| # | 工作 | commit / Day | 状态 |
|---|---|---|---|
| 1 | schema migration v3 → v4(TransactionType 加 repayment) | D18 (2026-08-01) | ✅ |
| 2 | 还款流 DAO(`transferRepayment`)+ ADR-0022 | D19 (2026-08-02) | ✅ |
| 3 | 还款流 UI(repayment_sheet + 主页「+」入口) | D20 (2026-08-03) | ✅ |
| 4 | ADR-0024(6 种账户定位)+ ADR-0026(咔皮对标完整)+ ADR-0025(v1.1 backlog) | D20 (2026-08-03) | ✅ |
| 5 | schema migration v4 → v5(installment_period 列)| D20 (2026-08-03) | ✅ |
| 6 | 还款弹层 4 收款类型扩展 + 网贷期数下拉 | D20 (2026-08-03) | ✅ |
| 7 | 主页「距离还款日 X 天」提醒卡片 + transaction_tile 期数徽章 | D20 (2026-08-03) | ✅ |
| 8 | schema migration v5 → v6(5 大类 × 23 子类 + 9 列)| D21 (2026-08-04) | ✅ |
| 9 | AccountCategory/AccountSubType 双枚举 + 4 toggle(特别关注 / 默认收账 / 默认支出)| D21 (2026-08-04) | ✅ |
| 10 | 转账流(transferMoney DAO + transfer_sheet + 主页菜单)| D21 (2026-08-04) | ✅ |
| 11 | 主页「+」聚合菜单改 5 入口(记一笔/转账/还款/借出/借入)| D21 (2026-08-04) | ✅ |
| 12 | schema migration v6 → v7(借贷 transaction 化 4 列)+ TransactionType lend/borrow | D22 (2026-08-05) | ✅ |
| 13 | lendMoney/borrowMoney DAO + LendRecordPage/BorrowRecordPage 全屏记账 | D22 (2026-08-05) | ✅ |
| 14 | 日期 picker 中文 locale(pubspec +flutter_localizations)+ 转账下拉去过滤 | D22 (2026-08-05) | ✅ |
| **(测试基线)** | 232 → **314/314 全绿** | D18→D22 | ✅ |

#### 2.2 ADR-0021 超越声明

- **ADR-0021 状态**:**PARTIALLY_SUPERSEDED**(部分被超越)
- **保留部分**:TransactionType 加 repayment 值、主页「+」还款入口位置(AppBar.actions → D21 决策改 FAB「+」聚合菜单)
- **超越部分**:范围从「3 项最小 MVP」扩为「14 项 D18-D22 实际」(本 ADR §2.1)
- **不撤销**:ADR-0021 §不可逆性中"0 新依赖"决策仍有效(被 §3 决策 3 局部修正)

#### 2.3 ADR-0026 §14 实施清单状态

| # | 工作 | 状态 |
|---|---|---|
| 1 | schema v6 migration | ✅ D21 |
| 2 | schema v7 migration | ✅ D22 |
| 3 | ledgers 表 + ledgerProvider | ⏳ S04 范围(独立 Stage)|
| 4 | 添加账户弹层 5 大类 × 子类 | ✅ D21 |
| 5 | 信用账户字段扩展 | ✅ D21 |
| 6 | 编辑账户 4 toggle | ✅ D21 |
| 7 | 转账流程 | ✅ D21 |
| 8 | 主页底部 3 入口 → 5 入口聚合菜单(超 ADR-0026 计划)| ✅ D21 |
| 9 | 记账弹层加转账 tab | ⏳ D22 未做(转账走独立 transfer_sheet)+ D24+ 评估 |
| 10 | 账户详情 + 余额变动明细 2 tab | ⏳ D22 简化项 #3,优先级 P1(D23+ 装机验后)|
| 11 | 资产页拆分(资产 ¥X / 负债 ¥Y)| ⏳ 优先级 P1(D23+ 装机验后)|
| 12-13 | 14 个新测试 + ROA | 🟡 部分完成(实际 +26 D21 + 11 D22 = 37 测试),ROA 待 D23 装机验后 |

### 决策 3:pubspec.yaml §11 例外授权

#### 3.1 背景

CLAUDE.md §11 规定"AI 不得修改 `pubspec.yaml`"(核心配置文件保护),ADR-0021 §不可逆性「0 新依赖」明确禁止 flutter_local_notifications / workmanager 等。

D22(2026-08-05)为修复真机日期 picker 英文 bug(咔皮截图 244),修改 `pubspec.yaml` 加 `flutter_localizations` + `intl: 0.20.2`,**严格说违反 §11**。

#### 3.2 例外授权(追溯)

| 项 | 内容 |
|---|---|
| **授权时间** | 2026-08-05(用户口头授权"你来定,A+ 标准",D22 daily §「妥协 / 显式简化」#3 显式声明)|
| **授权内容** | pubspec.yaml 加 `flutter_localizations: { sdk: flutter }` + `intl: 0.20.2`(锁版本,沿用 ADR-0012 模式)|
| **本 ADR 追溯** | 用户 2026-08-06 在本会话校准借贷语义时**一并追溯授权**(A+ 质量 + 稳定性原则 > 治理流程)|
| **必要性论证** | iOS 系统日期 picker(`showDatePicker`)需 `flutter_localizations` delegates 才能本地化为中文;`intl 0.20.2` 是 Flutter SDK 内置 version,**0 第三方依赖风险** |
| **后续 ADR-0021「0 新依赖」例外清单** | 1. `flutter_localizations`(本 ADR §3.2)+ 2. 后续如需 `flutter_local_notifications` / `workmanager` 走单独 ADR(不动 §11 主体)|

#### 3.3 pubspec.yaml 改动清单(D22)

```yaml
# diff (2026-08-05, ce11073 → 6888552)
dependencies:
  flutter:
    sdk: flutter
+ flutter_localizations:
+   sdk: flutter
+ intl: 0.20.2

flutter:
+ generate: true  # intl 需要
```

**未引入**:`flutter_local_notifications` / `workmanager` / 任何第三方支付 / 金融 API(沿用 ADR-0021 §不可逆性)。

#### 3.4 main.dart 同步改动(D22)

```dart
// lib/main.dart(D22 加)
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // ...
)
```

`_pickDate` 显式 `locale: Locale('zh','CN')`(account_edit_sheet.dart L5 修)。

---

## §3 后果

### 3.1 正面影响

| 项 | 收益 |
|---|---|
| 借贷业务流程独立化(transaction 化)| 咔皮对标完整,代码与 §1.3 三方对齐 |
| S03 范围扩写追溯 | D21/D22 14 项实施显式记录,后续 Stage 不重复 |
| pubspec 例外授权 | iOS 中文日期 picker 修复,A+ 体验闭环 |

### 3.2 负面影响 / 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| ADR-0021「0 新依赖」被 §3 局部突破 | 🟡 中 | 本 ADR §3.2 显式授权 + 例外清单管理,后续新依赖走单独 ADR |
| 借贷 subType=lendOut/borrowIn 字段保留 = 死代码 | 🟢 低 | D24+ 评估是否 schema v8 删除(详 §5 后续)|
| ADR-0026 §12.1 修订版「借贷作为独立账户」与代码不一致 | 🟡 中 | 本 ADR §1.3 + §2.1 显式记录矛盾;P1-3/4 修订 ADR-0026 §12.1/§6/§8 |
| 治理漏洞(无 DR 流程)| 🟡 中 | 写 CLAUDE.md 铁律 13(本 ADR 草拟建议):「D+1 daily 必须包含 §治理自审,检查是否有超 ADR 范围实施」,等用户拍板 |

### 3.3 衔接下游(必同步清单)

| 文档 | 同步内容 | 见 P1 任务 |
|---|---|---|
| `docs/CONTROL_TOWER.md` | 全重写:§1 ACTIVE D18-22 + §3 授权边界补 D21/D22 + §4 测试基线 314 + §7 ADR 列表 +0028 + §8 W4 进度条 | P0-2 |
| `docs/adr/0026-kapi-product-design.md` | §6/§8 净资产公式删借贷 SUM 项 + §12.1 表格借贷行注「transaction 化」 + §12.3 决策表补 lend/borrow 流程说明 + §1 主页设计加注 D21「5 入口聚合菜单」 | P1-3 / P1-4 / P3-13 |
| `docs/adr/0022-balance-auto-update-strategy.md` | §1/§3 表格扩到 5 类 transaction(expense/income/transfer/lend/borrow)| P1-5 |
| `docs/adr/0024-account-types-product-design.md` | §实施清单加注「作废 — D21/D22 已迁移 lendMoney/borrowMoney + transferMoney」 | P1-6 |
| `docs/stages/S03-credit-card-repayment.md` | §In Scope 改 D18-D22 实际 14 项 + §时间切片 7 天→5 天 | P1-7 |
| `docs/PLAN.md` | §S02 #5 改「5 大类 × 23 子类」+ §S03 加 D21/D22 实际条目 | P1-8 |
| `docs/ROADMAP.md` | P0-04 改「5 大类 × 23 子类」 | P1-9 |
| `docs/daily/2026-08-04.md` | commit 填 `ce11073` + 测试基线 303 | P2-10 |
| `docs/daily/2026-08-05.md` | commit 填 `6888552` + 测试基线 314 + §显式简化合并 | P2-10/11 |
| `docs/governance/scripts.md` | 加注「本文件是话术库(Standard Phrases),不是 Stage Lifecycle Scripts」 | P3-12 |

---

## §4 不可逆性

| 项 | 永不变更 | 理由 |
|---|---|---|
| 借贷 transaction 化(transactional model,非独立账户) | ✅ | D22 已实施,11 测试覆盖;回退 = 删 11 测试 + 重写 schema v7 migration + 重写 LendRecordPage/BorrowRecordPage,成本极高 |
| `TransactionType` 枚举加值 `lend` / `borrow` | ✅ | textEnum 兼容,S07+ 异常检测 / S04 月度统计依赖字符串匹配 |
| `flutter_localizations` 依赖 | ✅(可卸但需替代)| iOS 系统中文日期 picker 必需;替代方案 = 自写中文日期 widget(成本 > 收益)|
| `intl: 0.20.2` 版本锁定 | ✅ | 沿用 ADR-0012 锁版本模式 |
| schema v7(fromAccountId/toAccountId/counterpartyName/startDate)| ✅ | lendMoney/borrowMoney DAO 依赖 |
| schema v6(subType/brandName/isPinned/isDefaultIncomeAccount/isDefaultExpenseAccount/initialDebtCents/startDate/dueDate/counterpartyName)| ✅ | D21 已实施,277 测试覆盖 |
| ADR-0021 §不可逆性保留 | ✅(部分超越)| 「0 新依赖」局部突破(本 ADR §3.2);「TransactionType 加 repayment」「还款 transaction 引用『还款』分类」「还款事务原子化」保留 |
| ADR-0026 借贷决策最终走向 | ✅ | 本 ADR §2.1 决策 1 = SSOT,ADR-0026 §12.1 修订版被超越 |

---

## §5 后续评估(D23+ 装机验后,基于 A+ 完整性)

| 优先级 | 项 | 决策需求 | 理由 |
|---|---|---|---|
| **P0** | 借贷 subType 字段删除(可选 schema v8) | 需用户拍板(是否值得为 schema 简洁付出 migration 成本)| subType=lendOut/borrowIn 字段保留 = 死代码,但删除 = schema v8 migration + 历史数据迁移 + 11 测试改写 |
| **P0** | ADR-0026 §9 退款按钮语义确认 | **需用户点咔皮一次**确认行为(A/B 二选一)| transaction_dao 需新增 `reverseLastTransaction` 方法 |
| **P1** | LendRecordPage / BorrowRecordPage widget 测试 | 无 | D22 简化项,DAO 已覆盖,补 widget test 完整化 |
| **P1** | §14 实施清单 #10 账户详情 + 余额变动明细 2 tab | 无 | 咔皮截图 #9,S05 净资产前置 |
| **P1** | §14 实施清单 #11 资产页拆分 | 无 | 咔皮截图 #6,S05 前置 |
| **P2** | §14 实施清单 #9 记账弹层加转账 tab | 用户决策(D22 走独立 transfer_sheet 是否保留)| UX 简化 vs 完整 |
| **P2** | §14 实施清单 #3 + §12.4 账本表 | S04 独立 Stage | 咔皮截图 #1(右上角账本切换) |
| **P2** | CLAUDE.md 铁律 13(治理自审)| 用户决策 | 本 ADR §3.2 风险缓解 |

---

## §6 验证

### 6.1 本 ADR 接受后必做(治理同步)

- [ ] P0-1 ADR-0028 写完 ✅(本文件)
- [ ] P0-2 CONTROL_TOWER 全重写
- [ ] P1-3 ADR-0026 §12.1 + §12.3 注「借贷已 transaction 化」
- [ ] P1-4 ADR-0026 §6/§8 净资产公式删借贷 SUM 项
- [ ] P1-5 ADR-0022 §1/§3 表格扩 5 类 transaction
- [ ] P1-6 ADR-0024 §实施清单注「作废」
- [ ] P1-7 S03 §In Scope + §时间切片
- [ ] P1-8 PLAN.md §S02/§S03
- [ ] P1-9 ROADMAP.md P0-04
- [ ] P2-10 daily/2026-08-04 + 2026-08-05 commit SHA
- [ ] P2-11 显式简化清单合并入 CONTROL_TOWER §5
- [ ] P3-12 scripts.md 注
- [ ] P3-13 ADR-0026 §1 主页设计加注 D21

### 6.2 深度审计(本 ADR 接受后)

- [ ] docs/audit/2026-08-06-doc-and-code.md 产出
- [ ] ADR-0028 ↔ 9 个文档 ↔ 代码 三方一致性
- [ ] grep "<<<<<<" docs/ 无冲突标记
- [ ] grep ".tmp\|debug_\|test_*.dart" 无残留(除 test/ 目录)
- [ ] git status 干净(只 .ai-work/ 可能残留,本会话结束删)
- [ ] flutter analyze 0 issues(虽然不动代码,跑一次确认)
- [ ] flutter test 314/314 全绿

### 6.3 D23+ 装机验(S03 ROA)

- [ ] D22 3 项修复真机手验(借出/入独立全屏 + 日期 picker 中文 + 转账下拉全账户)
- [ ] 真机验通过 → S03 ROA 签字 → CONTROL_TOWER 派生 ACCEPTED

---

## §7 关联

- **CLAUDE.md 铁律 7**(产品设计先行)— D22 借贷业务流程修复基于真机手验反馈 ✅
- **CLAUDE.md 铁律 8**(简化≠边界)— D22 借贷业务流程独立化保持 3 类场景边界(正常 / 异常余额不足 / 边界 amount≤0)✅
- **CLAUDE.md 铁律 9**(v4 §3.1 必查)— 本 ADR §1.3 借贷对标咔皮截图 #25-26 ✅
- **CLAUDE.md 铁律 10**(完成日期机制)— commit message 标完成日期(D21/D22)✅
- **CLAUDE.md 铁律 11**(启动前列要点)— 本 ADR §6.1 13 项验证清单 ✅
- **CLAUDE.md 铁律 12**(Stage 收尾自审)— D22 daily §妥协 / 显式简化 + 本 ADR §3.2 风险表 ✅
- **CLAUDE.md §11**(pubspec 保护)— 本 ADR §3 例外授权追溯 ✅
- **ADR-0021**(S03 范围 — 被超越 PARTIALLY_SUPERSEDED)
- **ADR-0022**(余额联动策略 — 扩展为 5 类 transaction)
- **ADR-0023**(build_info 版本管理 — D19 实施)
- **ADR-0024**(6 种账户定位 — 被超越,§实施清单注「作废」)
- **ADR-0025**(v1.1 backlog — 保留)
- **ADR-0026**(咔皮对标完整 — §6/§8/§12.1/§12.3 修订)
- **ADR-0027**(攒钱计划模块 — S07 范围,本 ADR 不涉及)
- **product-design-v4.html §3.1**(咔皮对标 — 借贷截图 #25-26 + 主页截图 #1)
- **product-design-v4.html §52.7**(看板 — D21/D22 已 ✅,本 ADR 同步)
- **lib/data/db/tables/accounts.dart**(AccountSubType.lendOut/borrowIn 字段保留,本 ADR §2.1 决策 1 占位)
- **lib/data/db/tables/transactions.dart**(TransactionType.lend/borrow + fromAccountId/toAccountId/counterpartyName/startDate 4 列)
- **lib/features/lend/presentation/lend_record_page.dart** + **lib/features/borrow/presentation/borrow_record_page.dart**(全屏记账 widget)
- **lib/data/db/daos/transaction_dao.dart**(transferMoney / lendMoney / borrowMoney 3 个 DAO)
- **pubspec.yaml**(flutter_localizations + intl 0.20.2,本 ADR §3 授权)

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻(本会话)
**下次复审**:D23 装机验后(S03 ROA 时)+ §5 后续项决策时
