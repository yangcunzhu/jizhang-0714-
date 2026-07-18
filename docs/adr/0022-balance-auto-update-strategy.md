# ADR-0022:账户余额自动更新策略(S03 债务闭环关键)

> 状态:**已接受**
> 日期:2026-08-02(D19)
> Stage:**S03-credit-card-repayment**(Day 19,2026-08-02)
> 作者:Claude(执行)+ 用户(决策)
> 关联:ADR-0021(还款流范围)+ ADR-0017(账户 schema v2)

---

## 背景

S02 阶段(2026-07-25 ~ 2026-08-01)实现了账户 CRUD(增 / 改 / 删 / 查),但 **`transaction_dao.insertTransaction` 写交易时不更新 `accounts.balanceCents` 字段**。导致用户真机手验(D18,2026-08-01)看到「现金账户余额永远 ¥0.00」,记账没反馈。

更严重的是,S03 信用卡还款流要执行「**从储蓄账户扣款 + 给信用卡账户增加可用额度**」操作。如果不更新余额,信用卡「距离还款日」卡片显示的「已用 vs 额度」永远不准,S05 净资产计算也会失效。

**根因**:`transaction_dao` 写交易时只 insert `transactions` 表,**没触碰 `accounts.balanceCents`**。S02 写集 ADR-0015 / 0017 / 0018 / 0019 / 0020 都**没明确**这个 DAO 联动逻辑,PLAN.md 第 6 项写「账户 CRUD + **余额管理**」但没细化。

---

## 决策

### 1. 余额语义统一为「正向记账余额」

| 账户类型 | `balanceCents` 含义 | UI 显示(待 S05 仪表盘落实) |
|---|---|---|
| 现金 💵 | 当前余额 | 「余额 ¥xxx」 |
| 储蓄 🏦 | 当前余额 | 「余额 ¥xxx」 |
| 信用卡 💳 | **已用额度**(0 = 没用)| 「已用 ¥xxx / 额度 ¥yyy,可用 ¥(creditLimit - balanceCents)」 |
| 花呗 🅰️ | 当前余额 | 「余额 ¥xxx」 |
| 网贷 🆘 | 当前余额 | 「余额 ¥xxx」 |
| 理财 📈 | 当前余额 | 「余额 ¥xxx」 |

**WHY 统一语义**:
- 单字段 `balanceCents` 不分裂(不引入 `usedCents` / `availableCents` 两个字段)
- 还款流逻辑简单:`储蓄.balanceCents -= 还款额`(钱少了)+ `信用卡.balanceCents -= 还款额`(已用减少)
- 所有账户类型走同一套 DAO 逻辑,代码统一

### 2. `_updateAccountBalance(accountId, deltaCents)` 私有方法(v2:D19 实施时调整)

```dart
Future<void> _updateAccountBalance(int accountId, int deltaCents) async {
  final account = await db.accountDao.getById(accountId);
  if (account == null) return; // silent skip(账户不存在 / 已删)
  final newBalance = account.balanceCents + deltaCents;
  // 允许变负(用户记账可能透支;信用卡已用额度极端情况下也可能为负)
  // 余额校验 **不在此处**,业务方法(如 transferRepayment)显式 check
  await db.accountDao.updateAccountById(
    AccountsCompanion(id: Value(accountId), balanceCents: Value(newBalance)),
  );
}
```

**WHY 调整(v1 → v2)**:
- v1 设计:负余额抛 StateError,事务回滚
- v1 问题:S02 既有测试 fixture 默认账户余额 = 0,任何支出交易都触发「余额不足」,破坏 31 个测试
- v2 设计:`_updateAccountBalance` 静默更新(silent skip on 账户不存在 / 允许负余额)
- 余额校验 **上移到业务方法**:`transferRepayment` 在调用 `_updateAccountBalance` 前显式 check,余额不足抛 StateError + 事务回滚
- 这符合「边界检查放在业务层,不放在底层 helper」的常见设计

**WHY 允许透支**:
- S02 用户首启默认账户余额 = 0,如果记账直接抛错,体验差
- 用户自己知道账户实际有多少钱(看银行 App),记账 App 不需要强制阻止透支
- 还款流(主动还款)是显式用户行为,有明确预期,余额不足必须拦截

### 3. 写交易自动更新余额(所有 6 种账户类型统一处理)

| 记账类型 | transaction.type | balanceCents 变化 |
|---|---|---|
| 支出 | expense | `账户.balanceCents -= amountCents` |
| 收入 | income | `账户.balanceCents += amountCents` |
| 还款 | repayment | `储蓄.balanceCents -= amountCents` + `信用卡.balanceCents -= amountCents` |

`insertTransaction` 内部根据 `entry.type.value` 自动判断 delta 方向,**不需要**调用方手动传 delta。

### 4. 还款事务(`transferRepayment`)完整语义

```dart
Future<int> transferRepayment({
  required int fromSavingsAccountId,
  required int toCreditCardAccountId,
  required int amountCents,
  String? note,
}) async {
  return transaction(() async {
    // Step 1: 校验(避免事务内失败回滚成本)
    final savings = await db.accountDao.getById(fromSavingsAccountId);
    final creditCard = await db.accountDao.getById(toCreditCardAccountId);
    if (savings == null) throw StateError('储蓄账户不存在');
    if (creditCard == null) throw StateError('信用卡账户不存在');
    if (creditCard.type != AccountType.creditCard) {
      throw StateError('目标账户不是信用卡类型');
    }
    if (savings.balanceCents < amountCents) {
      throw StateError('储蓄账户余额不足');
    }
    if (amountCents <= 0) {
      throw ArgumentError('还款金额必须 > 0');
    }

    // Step 2: 更新余额(储蓄 -amount,信用卡已用 -amount)
    await _updateAccountBalance(fromSavingsAccountId, -amountCents);
    await _updateAccountBalance(toCreditCardAccountId, -amountCents);

    // Step 3: 写 repayment transaction(语义记录,引用「还款」分类)
    final repaymentCategoryId = await _getOrCreateRepaymentCategoryId();
    return await insertTransaction(
      TransactionsCompanion.insert(
        accountId: fromSavingsAccountId,
        categoryId: repaymentCategoryId,
        type: TransactionType.repayment,
        amountCents: amountCents,
        note: Value(note ?? '还${creditCard.name}'),
      ),
    );
  });
}
```

**WHY 完整实施不留占位**:
- CLAUDE.md §铁律「不留万能函数」— Day 19 一次性写完整,不留「明天再加」的部分
- 还款 transaction 引用「还款」分类(`name='还款', icon='💳', type=expense`),保持 `categoryId NOT NULL` 约束(ADR-0021 §不可逆性)
- 储蓄账户余额不足 → 抛 `StateError` → 整个 transaction 回滚(余额 + transaction 都改回去)

### 5. 「还款」分类自动创建(免去手动 seed)

```dart
Future<int> _getOrCreateRepaymentCategoryId() async {
  // 找已有的「还款」分类
  final allCategories = await db.categoryDao.getAll();
  final existing = allCategories.where((c) => c.name == '还款');
  if (existing.isNotEmpty) return existing.first.id;

  // 没有则创建(首次还款时自动 seed)
  return await db.categoryDao.insertCategory(
    CategoriesCompanion.insert(
      name: '还款',
      iconName: '💳',
      colorValue: 0xFF7E57C2, // 紫色,与信用卡 emoji 一致
      type: TransactionType.expense,
      sortOrder: Value(10),
    ),
  );
}
```

**WHY**:
- 不用手动 seed 默认分类(S02 写集已收尾,新增 seed 需重跑 migration 测试)
- 用户首次还款时自动创建,后续还款复用同一分类
- 与 ADR-0019「分类 emoji + 中文命名」一致

---

## 不可逆性

| 项 | 不可变性 | 理由 |
|---|---|---|
| `balanceCents` 语义 = 「正向记账余额」 | 不可变更更 | S05 净资产仪表盘依赖此语义计算 |
| 信用卡 `balanceCents` = 已用额度 | 不可变更更 | UI 卡片显示 + 可用额度计算都依赖 |
| 还款 transaction 引用「还款」分类 | 必须保留 | categoryId NOT NULL 约束 + 流水统计依赖 |
| 还款语义「储蓄 -amount + 信用卡 -amount」| 永不变更 | 下游 S04 月度还款总额统计依赖 |
| 余额不足抛 `StateError` + 事务回滚 | 永不变更 | 用户预期 + 数据一致性 |

---

## 后果

### 正面影响

- ✅ 余额自动更新,用户记账后立刻看到变化(体验大幅提升)
- ✅ 信用卡「已用 vs 额度」卡片可显示准确数字
- ✅ S05 净资产仪表盘有可靠数据源
- ✅ 还款事务原子化,任意失败回滚(无脏数据)
- ✅ 代码统一(所有 6 种账户类型走同一套逻辑)

### 负面影响 / 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| 余额不足抛异常可能让用户混淆(已记账但没扣款) | 🟡 中 | 错误提示文案清晰「储蓄账户余额不足,请充值后再试」 |
| 信用卡 `balanceCents` 语义与普通账户不一致(普通账户是正余额,信用卡是已用) | 🟡 中 | ADR-0022 明确文档,UI 层做语义转换(后续 S05 落实)|
| `_updateAccountBalance` 每次写交易都要调用,可能有性能影响 | 🟢 低 | Drift 事务批量写,1 次 update ≈ 1ms,232 测试 5 秒内可跑完 |
| 「还款」分类自动创建可能与用户自定义分类冲突 | 🟢 低 | 用户自定义分类名不会用「还款」(语义不同)|

### 衔接下游

- **Stage 4(账本 & 预算)**:基于 `balanceCents` 计算账户结余 + 月度还款总额统计
- **Stage 5(净资产 & 仪表盘)**:基于 `includeInNetWorth` + `balanceCents` 计算净资产
- **Stage 6(存储 & 快照)**:Drift 加密不变(沿用 S06 计划)

---

## 验证

- [ ] flutter analyze 0 错误
- [ ] flutter test 全绿(232 + Day 19 新增 ≥ 5 = 237+)
- [ ] `_updateAccountBalance` 单测:正负方向正确、负余额抛异常、信用卡允许 0
- [ ] `transferRepayment` 单测:成功路径 + 失败回滚 + 边界(余额不足、信用卡不存在、储蓄账户不是储蓄类型)
- [ ] `insertTransaction` 联动测试:支出扣减 / 收入增加 / 还款两账户更新
- [ ] integration test:首个 bootContainer 用例覆盖还款全链路
- [ ] Build iOS .ipa CI 绿
- [ ] Day 22 真机手验 3+ 场景

---

## 关联

- ADR-0015:Stage 2 写集(背景)
- ADR-0017:AccountType enum + schema v2(本决策依赖账户字段定义)
- ADR-0021:S03 范围决策(还款流是本决策的实施场景)
- `lib/data/db/daos/transaction_dao.dart`:`_updateAccountBalance` + `transferRepayment` 实施位置
- `lib/data/db/daos/account_dao.dart`:`updateAccountById` 底层依赖
- `lib/data/db/tables/accounts.dart`:`balanceCents` 字段定义
- `lib/data/db/tables/categories.dart`:TransactionType.enum repayment(ADR-0021 加)
- `docs/stages/S03-credit-card-repayment.md`:Stage 3 主文档(Day 19 部分)

---

**最后更新**:2026-08-02(D19 拍板)
**生效日期**:S03 ACTIVE 后(D18)
**下次复审**:S03 ROA 时(如发现余额管理不够用,再开 ADR 评估)