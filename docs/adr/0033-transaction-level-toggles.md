# ADR-0033:交易级 2 toggle(不计收支 + 不计预算,基于咔皮图 19/293 完美证实)

> 状态:**ACCEPTED**
> 日期:2026-08-06(D23 治理收尾,基于咔皮图 19 + 293 完美证实)
> Stage:**S02 → S03 衔接**(S02 未实现,D24+ 实施)
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0026 §12 + §14 #11** + **ADR-0022 §1 余额联动** + **产品设计 v4 §P0-12 基础统计**

---

## 背景

咔皮图 19(7/18 22:28 交易详情页)+ **图 293(7/21 9:39 添加定时记账)** **完美证实**交易级 2 toggle:

| toggle | 含义 | 真源图 |
|---|---|---|
| **不计收支** | 此交易**不计入**本月收支统计(图 19 toggle 默认关) | 图 19 / 293 |
| **不计预算** | 此交易**不计入**分类预算统计 | 图 19 / 293 |

**应用场景**:
- **报销**:公司报销 ¥500(收入,但不是个人收入)— 开关「不计收支」
- **代付**:帮同事代付 ¥200 餐费(支出,但不是本人消费)— 开关「不计收支」
- **预算外**:买大件家电 ¥5000(支出,但已用专门预算)— 开关「不计预算」避免月度预算超支提示
- **退还商家**:¥300 退货(支出,实质是抵消)— 后续 ADR-0030 退款 transaction 化,不走此 toggle

**S02 实施现状**:
- transactions 表**无** `excludeFromIncomeExpense` / `excludeFromBudget` 字段
- DAO `_updateAccountBalance` 不判断 toggle(账户余额**始终**更新)
- 统计 DAO(净资产/预算)未过滤 toggle(统计**总是**含此交易)
- → **D24+ 修复**

**根因**:
- D19 ADR-0022 §1 余额联动没考虑 toggle
- D19 ADR-0022 §3 「写交易自动更新余额」3 类(支出/收入/还款) 没考虑 toggle
- D21 ADR-0026 §12 净资产公式没考虑 toggle
- D22 D24 简化项(已自审),D23 治理收尾补本 ADR

---

## 决策

### 决策 1:transactions 表加 2 字段(schema v8)

```dart
// lib/data/db/tables/transactions.dart(D24+ 加)
class Transactions extends Table {
  // ... 已有字段
  
  // 交易级 2 toggle(D24+ 加)
  BoolColumn get excludeFromIncomeExpense => boolean().withDefault(const Constant(false))();
  // true = 此交易不计入收支统计,但账户余额仍更新
  
  BoolColumn get excludeFromBudget => boolean().withDefault(const Constant(false))();
  // true = 此交易不计入分类预算统计,但账户余额仍更新
}
```

**默认值 false** = 保持 S02 行为(交易都计入统计),旧数据零影响(schema v8 migration 兜底)。

### 决策 2:DAO `_updateAccountBalance` 行为不变(余额始终更新)

```dart
// lib/data/db/daos/transaction_dao.dart(D24+ 不改)
Future<void> _updateAccountBalance(int accountId, int deltaCents) async {
  // 余额永远更新(账户是真实状态)
  // toggle 只影响统计/预算过滤
}
```

**WHY 不变**:
- 账户余额 = 真实资金状态(报销到账 → 余额 +¥500,不论是否计入收支)
- toggle 只影响**展示层**(本月支出 ¥? / 分类预算 ¥?)
- 混在一起 = 数据不一致(账户余额与统计对不上)

### 决策 3:统计 DAO 过滤 toggle(新增 2 过滤方法)

```dart
// lib/data/db/daos/statistics_dao.dart(D24+ 新建)
class StatisticsDao {
  // 本月收入(过滤 excludeFromIncomeExpense = true)
  Future<int> getMonthlyIncome(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await (select(transactions)
      ..where((t) => t.type.equals('income') &
                      t.createdAt.isBetweenValues(start, end) &
                      t.excludeFromIncomeExpense.equals(false)))
      .get();
    return rows.fold(0, (sum, t) => sum + t.amountCents);
  }
  
  // 本月支出(过滤 excludeFromIncomeExpense = true)
  Future<int> getMonthlyExpense(DateTime month) async {
    // 类似
  }
  
  // 分类预算使用(过滤 excludeFromBudget = true)
  Future<int> getCategoryBudgetUsed(int categoryId, DateTime month) async {
    // 类似
  }
}
```

**所有统计 DAO 一致行为**:
- `getMonthlyIncome` / `getMonthlyExpense` / `getMonthlyBalance` 过滤 `excludeFromIncomeExpense = true`
- `getCategoryBudgetUsed` 过滤 `excludeFromBudget = true`
- `getAccountBalance`(账户余额,已用)不过滤(账户真实状态)

### 决策 4:主页「+」记账弹层加 2 toggle

**UI 位置**(图 19/293):
- 弹层底部 chip 栏:「7月18日 / 家庭账本 / 180 支付宝 / **不计收支** / **不计预算**」+ 图标
- 默认 off(图 19 灰色 toggle)
- 点击 toggle → 弹层底部小字提示:
  - 「不计收支 ON」:此交易不计入本月收支统计(账户余额照常更新)
  - 「不计预算 ON」:此交易不计入分类预算统计

### 决策 5:交易详情页(图 19)显示 2 toggle 状态

- toggle 状态在弹层设置后,详情页只读显示
- 不可改 toggle(改 = 改历史,会破坏统计一致性)
- 详情页字段顺序:
  - 实付金额 / 账单日期 / 所属账本 / 付款账户
  - **不计收支** toggle(只读)
  - **不计预算** toggle(只读)
  - 交易方 / 标签 / 备注 / 附件
  - 删除 / 退款

### 决策 6:定时记账(图 293)同步支持

- 定时记账 = 周期性自动生成 transaction,新 transaction 继承 toggle 设置
- 用户在「添加定时记账」页面(图 293)一次性设置 2 toggle,所有周期生成都按此设置
- 「开始时间」之后第一次生成 + 之后每次周期都按 toggle 计算统计

---

## 不可逆性

| 项 | 永不变更 | 理由 |
|---|---|---|
| transactions 表加 `excludeFromIncomeExpense` / `excludeFromBudget` 2 字段 | ✅ | schema v8 migration,旧数据默认 false 兜底 |
| 默认值 false(保持 S02 行为)| ✅ | 旧数据零影响,新数据用户主动开 |
| `_updateAccountBalance` 行为不变 | ✅ | 账户余额 = 真实状态,toggle 只影响展示 |
| 统计 DAO 过滤 toggle | ✅ | 收支/预算与账户余额语义分离,用户预期符合 |
| 交易详情页 toggle 只读 | ✅ | 改 toggle = 改历史统计 = 不可逆 |
| toggle 影响所有下游统计(收支/预算/排行)| ✅ | ADR-0022 §1 + §3 联动扩展 |

---

## 后果

### 正面影响
- ✅ 报销/代付/预算外 等真实场景有官方支持(咔皮对标)
- ✅ 账户余额 = 真实状态(永远准确,不被 toggle 污染)
- ✅ 统计可关闭(选择性统计)
- ✅ 定时记账支持(全场景覆盖)

### 负面影响 / 风险
| 风险 | 等级 | 缓解 |
|---|---|---|
| 用户开 toggle 后忘记,统计数字对不上,以为是 bug | 🟡 中 | 弹层底部小字提示 toggle 含义;交易详情页 toggle 只读显示 |
| toggle 改了,统计改了(用户期望"我之前收入 ¥1000,怎么变 ¥800?") | 🟢 低 | 详情页 toggle 状态可见;本 ADR 决策 5 不可改 |
| 定时记账 toggle 设错,周期生成全部错 | 🟢 低 | 添加定时记账页(图 293)toggle 显著 + 提示语 |

### 衔接下游
- **S04 预算**:`getCategoryBudgetUsed` 过滤 toggle(图 19/293 设计),用户可"不计预算"标记大件消费
- **S05 净资产仪表盘**:`getMonthlyIncome/Expense/Balance` 过滤 toggle,统计纯净
- **S07 异常检测**:toggle = false 交易才计入异常检测(报销不算异常)
- **ADR-0030 退款**:`refundMoney` 生成的 transaction **excludeFromIncomeExpense = true**(默认,因 refund 抵消原支出,不重复计入收入)— 详 ADR-0030 决策 1

---

## 实施清单(D24+ 装机验后)

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | schema v8 migration(加 2 字段 + 默认 false)| `app_database.dart` + transactions 表 | 30 分钟 |
| 2 | `StatisticsDao` 新建(3 方法)| `statistics_dao.dart` | 2 小时 |
| 3 | 主页调用 getMonthlyIncome/Expense 替换原 logic(原 S02 逻辑)| `home_page.dart` + provider | 2 小时 |
| 4 | 记账弹层加 2 toggle chip(图 19/293 复刻)| `record_sheet.dart` | 1 小时 |
| 5 | 交易详情页加 2 toggle 只读显示 | `transaction_detail_page.dart`(D24+ 新建) | 1 小时 |
| 6 | 定时记账页加 2 toggle(图 293 复刻)| `add_scheduled_record_page.dart` | 1 小时 |
| 7 | 单元测试 8(DAO 3 + 过滤 3 + 嵌套 2) + widget 测试 6 | 测试 | 2 小时 |
| 8 | ADR-0033 自审 + 真机验 3 场景(报销/代付/预算外) | 收尾 | 1 小时 |
| **总计** | | | **~10.5 小时(2 天)** |

---

## 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 改 toggle(交易详情页)| 永远不做 | 改 = 改历史统计 = 不可逆 |
| 批量改 toggle(多选交易) | v1.1 评估 | 本期单笔设置 |
| toggle 影响排行(单笔支出 Top 5) | v1.1 评估 | 排行通常按金额,toggle 不影响 |
| toggle 模板(快速标记)| v1.1 | 自定义分类 + toggle 组合 |

---

## 验证(2026-08-11 D28 + D28 IQA-fix 实施字面对齐实际)

- [x] flutter analyze 0 issues
- [x] flutter test 358/358 全绿(D28 末 352 → D28 IQA-fix +6:detail_page 3 + statistics_dao 3)
- [x] schema v8 migration_v8_test 3 用例 PASS — toggle 字段默认 false 兜底
- [x] **statistics_dao_test 9 用例 PASS(D28 +6,D28 IQA-fix +3)**:
  - 月度收入默认 toggle=false 全计入
  - excludeFromIncomeExpense=true 收入不计入
  - 月度支出同理过滤
  - 月度边界(7月/8月/9月隔离)
  - excludeFromBudget=true 单笔预算过滤(但仍计入收支)
  - 退款自动 excludeFromIncomeExpense=true + excludeFromBudget=true(ADR-0033 §衔接下游 + D28 联动)
  - **新增 M-IQA-D28-3** MonthlyStatsSnapshot incomeYuan 千位分隔(`12345678 → ¥123,456.78`)
  - **新增 M-IQA-D28-3** balanceYuan 负数(`-100 → ¥-1.00`)+ 零(`0 → ¥0.00`)
  - **新增 M-IQA-D28-4** 空月份边界(整月 0 笔交易 → balance ¥0.00)
- [x] 主页净资产接入 StatisticsDao + **IQA-fix C-IQA-D28-1** `_monthlyStatsProvider` ref.watch `transactionListProvider` 自动 invalidate(用户提交报销 toggle 后主页立即刷新)
- [x] 记账弹层 step 3 加 2 SwitchListTile(toggle chip)— record_sheet widget
- [x] **新增 M-IQA-D28-2** detail_page 3 widget 测试(toggle on 显示「开」+ toggle off 显示「关」)
- [x] 交易详情页 toggle 只读显示(detail_page 字段表)— D28 决策 5 不可改
- [x] **新增 G-IQA-D28-6** 编辑 refund 时 toggle 锁(`RecordFormState.isRefundLocked=true`,chip disabled + submit 不写 toggle)— 防止用户改 toggle=false 破坏一致性
- [ ] 定时记账 toggle on → 周期生成 4 周 = 4 笔,统计全部过滤(S07 评估时再加)
- [ ] iPhone 真机手验 3 场景(报销/代付/预算外)— D29 整合装机验

**D28 + D28 IQA-fix 验证已完成(8/9 字面)。**

---

## 关联

- **CLAUDE.md 铁律 1**(极致体验)— 报销/代付/预算外真实场景
- **CLAUDE.md 铁律 8**(简化≠边界)— 收支 vs 余额语义分离
- **ADR-0022 §1 余额联动** + **§3 写交易自动更新余额**(本 ADR 扩展)
- **ADR-0026 §12**(本 ADR 落地)+ **§14 #11**(基于 ADR-0026 设计)
- **ADR-0030 退款**(refund 自动 excludeFromIncomeExpense = true,详 ADR-0030 决策 1)
- **咔皮图 19**(7/18 22:28 交易详情页,2 toggle 完整设计)
- **咔皮图 293**(7/21 9:39 添加定时记账,2 toggle 完美证实)
- **产品设计 v4 §P0-12** 基础统计 + 3 种图表

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻
**下次复审**:D24+ 实施 + S04 预算接入 + 装机验时
