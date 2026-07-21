# ADR-0029:借贷账户字段修补(D22 实施漏 6 字段)

> 状态:**ACCEPTED**
> 日期:2026-08-06(D23 治理收尾,基于咔皮图 8/13/14/26/280/281)
> Stage:**S03 ACTIVE → 准备 D24+ 代码修补**
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0028 §1.3 决策 1**(借贷业务流程独立化)+ **ADR-0026 §12.1**(5 大类账户模型)+ **ADR-0024 §实施清单**(D19 还款流原始设计)

---

## 背景

D21/D22 真机验后,基于咔皮截图 #25-26 实际 UI,大副修订借贷决策:
- **D22 实施**:lendMoney/borrowMoney DAO + LendRecordPage/BorrowRecordPage 全屏记账,11 测试覆盖
- **ADR-0028 §1.3 决策 1**:借贷作为**业务流程**(transaction 化),**非独立账户模型**;subType=lendOut/borrowIn 字段保留落库占位

咔皮图 8/13/14(7/18-7/21 截图)显示**借贷页面完整字段 = 8 账户字段 + 4 transaction 字段 + 3 toggle**,D22 实施**漏了 6 字段**:

| 字段 | 类型 | D22 实施 | 咔皮真源 |
|---|---|---|---|
| 起始余额(借出)/ 起始欠款(借入) | 账户 | ❌ 漏 | ✅ 图 8/13/14 黄框 |
| 起始时间(必填) | 账户 | ❌ 漏 | ✅ 图 8/13/14 「之前的记录不计入余额统计」提示 |
| 账户名称 | 账户 | ❌ 漏(没让用户填)| ✅ 图 8/13/14 「账户名称」行 |
| 借出日期(借出)/ 借入日期(借入) | transaction | ❌ 漏 | ✅ 图 8/14/280/281 |
| 收款日期(借出)/ 还款日期(借入) | transaction | ❌ 漏 | ✅ 图 8/14/280/281 |
| 计入总资产 / 特别关注 / 默认收支(3 toggle) | 账户 | ❌ 漏 | ✅ 图 8/13/14 |

**根因**:D22 大副只看了 2 张咔皮图(7/18 22:25-22:28 借出/借入简化版),**没看到完整字段设计**;D23 用户补咔皮-6 图 280/281(7/21 完整版)才发现 6 字段漏。

---

## 决策

### 决策 1:借贷作为「独立业务流程 + 借贷账户 subType 字段」

| 维度 | 设计 |
|---|---|
| **业务流程** | 用户路径 = 主页「+」→「📤 借出 / 📥 借入」→ **LendRecordPage / BorrowRecordPage 全屏记账**(D22 已实施) |
| **借贷账户 subType** | 保留 `lendOut / borrowIn` 字段落库(schema v6 已加),**仅供 v1.1 关联分析用**,**UI 不暴露**借贷账户 CRUD 入口 |
| **新事务** | D22 lendMoney/borrowMoney DAO **扩展 6 字段** + 写 transactions 表 + 同步更新 accounts 表「起始余额/起始时间/3 toggle」 |

### 决策 2:accounts 表借贷 subType 加 4 字段

```dart
// lib/data/db/tables/accounts.dart(D24+ 加)
class Accounts extends Table {
  // ... 已有字段
  
  // 借贷 subType(lendOut/borrowIn)专用
  RealColumn get initialLendBalanceCents => real().nullable()();
  // 借出 = 起始余额;借入 = 起始欠款
  // 不在 includeInNetWorth 公式里(详 ADR-0026 §6/§8 D22 修订)
  
  DateTimeColumn get initialTime => dateTime().nullable()();
  // 必填,提示"该时间之前的记录不计入余额统计"
  
  TextColumn get lendCounterpartyName => text().nullable()();
  // 借款/放款对手方姓名
  
  DateTimeColumn get lendDueDate => dateTime().nullable()();
  // 还款/收款截止日期
}
```

### 决策 3:transactions 表 lendMoney/borrowMoney 加 2 字段

```dart
// lib/data/db/tables/transactions.dart(D24+ 加)
class Transactions extends Table {
  // ... 已有字段
  
  // 借贷 transaction 专用(D22 漏)
  DateTimeColumn get lendStartDate => dateTime().nullable()();
  // 借出日期/借入日期
  
  DateTimeColumn get lendEndDate => dateTime().nullable()();
  // 收款日期/还款日期
}
```

### 决策 4:lendMoney / borrowMoney DAO 扩展

```dart
// lib/data/db/daos/transaction_dao.dart(D24+ 改)
Future<int> lendMoney({
  required int fromAccountId,        // 扣款账户
  required String counterpartyName,   // 借款人姓名(D22 已有)
  required int amountCents,
  required DateTime lendStartDate,    // 🆕 借出日期(必填)
  required DateTime lendEndDate,      // 🆕 收款日期(必填)
  required DateTime initialTime,      // 🆕 账户起始时间
  String? note,
  int? accountId,                    // 🆕 借贷账户 subType=lendOut(可选)
}) async { ... }

Future<int> borrowMoney({
  required int toAccountId,          // 入款账户
  required String counterpartyName,
  required int amountCents,
  required DateTime borrowStartDate,  // 🆕 借入日期
  required DateTime repayEndDate,     // 🆕 还款日期
  required DateTime initialTime,
  String? note,
  int? accountId,                    // 🆕 借贷账户 subType=borrowIn
}) async { ... }
```

### 决策 5:3 toggle 不入数据库,UI state

| toggle | 存储 | 原因 |
|---|---|---|
| 计入总资产 | 已有 `includeInNetWorth` 字段 | 通用账户字段,D21 已实施 |
| 设为特别关注账户 | 已有 `isPinned` 字段 | 通用账户字段,D21 已实施 |
| 设为默认收账/支出账户 | 已有 `isDefaultIncomeAccount` / `isDefaultExpenseAccount` | D21 已实施 |

**结论**:3 toggle **字段已存在**,**D22 实施时 UI 未显示**(LendRecordPage/BorrowRecordPage 漏),**D24+ 修复 UI 即可,无需 schema 变更**。

### 决策 6:subType=lendOut/borrowIn 借贷账户 CRUD UI 是否做?

| 选项 | 评 | 决定 |
|---|---|---|
| **A. 不做** | 用户不能主动建借贷账户,只通过 LendRecordPage/BorrowRecordPage 记账;subType 字段保留仅作分析 | ✅ **D24+ 推荐**(咔皮对标也是记账按钮,不是账户管理) |
| B. 做 | 用户主动建借贷账户(类似信用账户) | ❌ 偏离咔皮 |

---

## 不可逆性

| 项 | 永不变更 | 理由 |
|---|---|---|
| 借贷业务流程独立化(transaction 化) | ✅ | ADR-0028 §1.3 + §2.1 决策 1,不可回退 |
| accounts 表加 4 字段(initialLendBalanceCents/initialTime/lendCounterpartyName/lendDueDate) | ✅ | schema v8 migration,旧数据 nullable 兜底 |
| transactions 表加 2 字段(lendStartDate/lendEndDate) | ✅ | D22 已用 lendMoney/borrowMoney DAO,新字段 nullable |
| 3 toggle 复用 D21 已有 4 字段(includeInNetWorth/isPinned/isDefaultIncome/Expense) | ✅ | 字段已就位,UI 修复即可 |
| 借贷账户 CRUD UI 不做(选项 A) | ✅ | 咔皮对标 |

---

## 后果

### 正面影响
- ✅ 借贷字段完整(8 账户 + 4 transaction + 3 toggle 复用)
- ✅ 起始时间提示「之前的记录不计入余额统计」语义保留
- ✅ LendRecordPage/BorrowRecordPage UI 修 6 字段(无 schema 风险)

### 负面影响 / 风险
| 风险 | 等级 | 缓解 |
|---|---|---|
| schema v8 migration 风险 | 🟢 低 | 4 字段全部 nullable,默认值 NULL,旧数据零影响 |
| LendRecordPage UI 改动测试 | 🟡 中 | 补 widget test(详 ADR-0028 §5 P1 简化项) |
| 3 toggle 数据已存在但 UI 未显示 | 🟢 低 | 纯 UI 修复,无 schema 风险 |

### 衔接下游
- **S05 净资产仪表盘**:不计入借贷账户余额(沿用 ADR-0026 §6/§8 D22 修订)
- **S07 异常检测**:可基于 lendEndDate 到期检测「应收未收」异常
- **S04 账本 & 预算**:借贷不计入预算

---

## 实施清单(D24+ 装机验后)

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | schema v8 migration(accounts 加 4 字段 + transactions 加 2 字段)| `app_database.dart` + 2 表 | 30 分钟 |
| 2 | lendMoney/borrowMoney DAO 扩展 6 字段 + 业务逻辑 | `transaction_dao.dart` | 2 小时 |
| 3 | LendRecordPage UI 加 6 字段(起始余额/起始时间/账户名称/3 toggle/借出日期/收款日期)| `lend_record_page.dart` | 2 小时 |
| 4 | BorrowRecordPage UI 加 6 字段(起始欠款/起始时间/账户名称/3 toggle/借入日期/还款日期)| `borrow_record_page.dart` | 2 小时 |
| 5 | 单元测试 11 + widget 测试 8(每页 4) | 测试 | 2 小时 |
| 6 | ADR-0029 自审 + 真机验 2 场景 | 收尾 | 1 小时 |
| **总计** | | | **~10 小时(2 天)** |

---

## 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 借贷账户 CRUD UI(选项 B) | v1.1 评估 | 咔皮对标是记账按钮,非账户管理 |
| 借贷 transaction 退款 | 跟随 ADR-0030(退款 transaction 化) | 整体退款设计 |
| 借贷子分类 | v1.1 | 收入/支出 16 分类已够用,借贷不细分 |

---

## 验证

- [ ] flutter analyze 0 issues
- [ ] flutter test 314 + 11(DAO) + 8(widget) 全绿
- [ ] schema v8 migration_v8_test 3 用例 PASS
- [ ] lendMoney/borrowMoney 3 类场景(正常/异常余额不足/边界)PASS
- [ ] LendRecordPage / BorrowRecordPage widget test 4 用例 PASS
- [ ] iPhone 真机手验 2 场景:借出/入 全字段保存 + 起始时间提示
- [ ] 旧 S03 数据零丢失(schema v8 兜底)

---

## 关联

- **CLAUDE.md 铁律 1**(极致体验)— 补全借贷 6 字段=用户视角完整
- **CLAUDE.md 铁律 8**(简化≠边界)— D22 漏 6 字段=违反边界完整
- **ADR-0028** §1.3 决策 1 借贷业务流程独立化 + §5 后续 P0
- **ADR-0024** §实施清单(原始 D19 设计漏借贷字段)
- **ADR-0026** §10 5 大类账户模型 + §12.1 借贷决策修订
- **咔皮图 8/13/14/26/280/281**(7/18-7/21 完整借出/入页面)
- **产品设计 v4 §3.1** 借贷对标 + §P0-08 账本切换前置

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻
**下次复审**:S03 装机验后 + D24+ 实施时
