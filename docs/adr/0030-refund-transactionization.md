# ADR-0030:退款 transaction 化设计(基于咔皮图 4 退款详情弹层)

> 状态:**ACCEPTED**
> 日期:2026-08-06(D23 治理收尾,基于咔皮图 4 退款详情弹层)
> Stage:**S03 ACTIVE → 准备 D24+ 代码实施**
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0026 §9 退款按钮自审盲点** + **ADR-0022 §1 余额联动** + **产品设计 v4 §P0-05 退款按钮**

---

## 背景

ADR-0026 §9 自审盲点:**「退款」按钮语义**(A:撤销最近一笔 / B:余额清零 / C:单笔 reverse transaction / D:其他)— 当时不确定,留「决策前,建议用户先用咔皮点一次『退款』,告诉我行为,我再补 ADR」。

D23 用户补咔皮图 4(7/18 22:33 截图)给出**确切答案**:**「退款」= 单笔 reverse transaction,生成新「退款」交易,保留原交易**。

**咔皮图 4 退款详情弹层**:
- 顶部:「退款详情」半屏弹层
- 字段 4 个:
  - **退款金额** ¥8.96(自动填入原交易金额,不可改)
  - **退款账户** 180 支付宝(默认原付款账户)
  - **退款时间** 2026.07.18 22:22(用户选)
  - **备注** 请输入退款备注(可选)
- 「确认」按钮(蓝色)
- 底部:原交易详情(餐饮-做饭食材 / 实付金额 -¥8.96 / 账单日期 / 所属账本 / 付款账户)

**业务语义**:
- 保留原交易(餐饮 -¥8.96,2026-07-17 22:48)
- 新增一笔「退款」交易(收入 +¥8.96,2026-07-18 22:22,原账户 180 支付宝,备注「退款」)
- 账户 180 支付宝 余额 += ¥8.96(原扣回)
- 主页交易列表:看到 2 笔(原 -¥8.96 + 退款 +¥8.96),可识别为「对账」
- 统计:`-¥8.96 + ¥8.96 = 0`,本月实际支出抵消(原记账误 + 退款抵消)

---

## 决策

### 决策 1:新增 TransactionType.refund 枚举值

```dart
// lib/data/db/tables/categories.dart(D26 加)
enum TransactionType {
  expense,
  income,
  transfer,    // D21
  repayment,   // D19
  lend,        // D22
  borrow,      // D22
  refund,      // 🆕 D26(2026-08-09 用户拍板 Q2=B 触发:v1.0 支持
              //   expense/repayment/lend/borrow 全退款,原 v4 §P0-05
              //   "v1.0 只支持 expense"声明已对齐,详 ADR-0037 §v4 对齐)
}

// textEnum 兼容,旧数据零影响
```

**WHY 新增枚举值 vs 复用 income**:
- 「退款」是**关联交易**(原 transactionId 引用),不是普通收入
- 统计时 `refund` 单独聚合(不计入「收入」),但可计入「收支净额」
- 下游 S05 净资产 / S07 异常检测 区分「真收入」vs「退款抵消」

### 决策 2:transactions 表加 2 字段

```dart
// lib/data/db/tables/transactions.dart(D24+ 加)
class Transactions extends Table {
  // ... 已有字段

  // 退款 transaction 专用
  IntColumn get originalTransactionId => integer().nullable()();
  // 关联交易,refund 记录必填(nullable 兜底 v7 旧数据 NULL)
  //
  // WHY 不加 .references(Transactions, #id):drift codegen 在 nullable + 自引用 FK
  // 上有迁移陷阱(与 fromAccountId 现状一致,详 ADR-0028 §1.2)。FK 完整性由调用方
  // 保证:refundMoney DAO 写 refund 前 select 原 transaction 验证存在 + 类型合法。
  // 如未来需要 DB 层 FK 兜底,再走 schema v9 加约束。

  TextColumn get refundNote => text().nullable()();
  // 退款备注(图 4 「备注」字段)
}
```

### 决策 3:refundMoney DAO 设计(2026-08-09 修订:支持拆分金额退款)

```dart
// lib/data/db/daos/transaction_dao.dart(D26 加)
Future<int> refundMoney({
  required int originalTransactionId,    // 原交易 ID
  required int refundAccountId,          // 退款账户(图 4 「退款账户」)
  required int amountCents,              // 退款金额(图 4 「退款金额」,允许 <= original.amountCents)
  required DateTime refundTime,          // 退款时间(图 4 「退款时间」)
  String? refundNote,                    // 备注(图 4 「备注」)
}) async {
  return transaction(() async {
    // Step 1: 校验原交易
    final original = await (select(transactions)
      ..where((t) => t.id.equals(originalTransactionId)))
      .getSingleOrNull();
    if (original == null) throw StateError('原交易不存在: $originalTransactionId');
    if (original.type == TransactionType.refund) {
      throw StateError('不能对退款记录再退款(嵌套保护)');
    }
    if (original.type == TransactionType.income ||
        original.type == TransactionType.transfer) {
      throw StateError('只能对支出/还款/借贷 transaction 退款');
    }
    if (amountCents <= 0) {
      throw ArgumentError('退款金额必须 > 0(当前: $amountCents)');
    }
    if (amountCents > original.amountCents) {
      throw StateError(
        '单笔退款金额不能超过原交易金额(本次 ¥${_formatYuan(amountCents)},'
        '原 ¥${_formatYuan(original.amountCents)})',
      );
    }

    // Step 2: 累计已退金额检查(多次拆分退款保护:sum <= original)
    final refundedSum = await _sumRefundedAmount(originalTransactionId);
    if (refundedSum + amountCents > original.amountCents) {
      throw StateError(
        '累计退款金额超限(原 ¥${_formatYuan(original.amountCents)},'
        '已退 ¥${_formatYuan(refundedSum)},'
        '本次 ¥${_formatYuan(amountCents)})',
      );
    }

    // Step 3: 更新账户余额(原账户扣回 = +amount,C6 fix 用 refundTime 不 now)
    await _updateAccountBalance(refundAccountId, amountCents);
    // 语义:支出原 -amount,这次退款 +amount = 净值 0(单笔完整退款)
    // 拆分退款:原 -¥10,退 ¥3 = 净值 -¥7

    // Step 4: 写 refund transaction(直接 into,不走 insertTransaction,因为类型 refund
    // 已在 switch 抛 ArgumentError)
    return await into(transactions).insert(
      TransactionsCompanion.insert(
        accountId: refundAccountId,
        categoryId: await _getOrCreateRefundCategoryId(),
        type: TransactionType.refund,
        amountCents: amountCents,
        occurredAt: Value(refundTime),  // C6 fix:用 refundTime 非 now
        originalTransactionId: Value(originalTransactionId),
        refundNote: Value(refundNote ?? '退款'),
        note: Value('退款:${original.note ?? ''} ¥${_formatYuan(amountCents)}'),
      ),
    );
  });
}

/// 查原交易累计已退金额(refund sum,2026-08-09 加,支持拆分退款显示 + UI 禁用判断)。
Future<int> _sumRefundedAmount(int originalTransactionId) async {
  final query = select(transactions)
    ..where((t) => t.originalTransactionId.equals(originalTransactionId));
  final rows = await query.get();
  return rows.fold<int>(0, (sum, t) => sum + t.amountCents);
}

/// 查原交易是否被退过(公开 API,UI 详情页用于禁用编辑/删除/退款按钮)。
/// 返回:0 = 未退过;>0 = 已退总额(分)。
Future<int> getRefundedAmount(int originalTransactionId) async {
  return _sumRefundedAmount(originalTransactionId);
}
```

### 决策 4:refund 分类自动 seed(2026-08-09 修订:双字段查找 + sortOrder=99)

```dart
// lib/data/db/daos/transaction_dao.dart
Future<int> _getOrCreateRefundCategoryId() async {
  final all = await db.categoryDao.getAll();
  // M4 修复:按 name + type 双字段查找,避免和用户自建的 "退款" expense 同名分类冲突
  final existing = all.where((c) =>
      c.name == '退款' && c.type == TransactionType.refund);
  if (existing.isNotEmpty) return existing.first.id;

  return await db.categoryDao.insertCategory(
    CategoriesCompanion.insert(
      name: '退款',
      iconName: '↩️',
      colorValue: 0xFF607D8B,  // 蓝灰色
      type: TransactionType.refund,
      // L4 修复:sortOrder = 99 放最后,与现有 9 个默认分类(0-9)不冲突
      sortOrder: const Value(99),
    ),
  );
}
```

### 决策 5:交易详情 UI 加「退款」按钮(交易详情页)

**触发位置**(图 19 交易详情页):
- 底部按钮:**「删除」+ 「退款」**(D22 已有删除,缺退款)
- 点击「退款」→ 弹「退款详情」半屏弹层(图 4)
- 弹层自动填 4 字段(原金额/原账户/当前时间/备注空)
- 「确认」→ 调 `refundMoney` DAO

### 决策 6:主页交易列表识别 refund

```dart
// lib/features/home/presentation/widgets/transaction_tile.dart
final isRefund = transaction.type == TransactionType.refund;
final tileColor = isRefund ? Colors.blueGrey.shade50 : null;
final iconOverlay = isRefund ? '↩️' : null;
```

**主页 UI 展示**:
- 金额前缀加「↩️」标识
- 颜色淡化(蓝灰)
- 弹详情时显示「关联交易」链接 → 跳原 transaction 详情

---

## 不可逆性(2026-08-09 修订)

| 项 | 永不变更 | 理由 |
|---|---|---|
| TransactionType.refund 枚举值 | ✅ | textEnum 兼容,旧数据零影响;下游统计/异常检测 区分 refund vs income |
| 关联交易 originalTransactionId 引用 | ✅ | 链式追踪,refund 嵌套保护(防止 refund 退款) |
| refund 分类自动 seed | ✅ | 用户透明(无感知),统一图标「↩️」+ 蓝灰色 |
| **退款金额允许 <= 原金额(支持拆分,2026-08-09 修订)** | ✅ | v1.0 多次独立 refund transaction(DAO 校验 sum <= original),无 schema bump;v1.1 考虑硬部分退款 + schema v9 加 refundedAmountCents/isFullyRefunded 字段,详 ADR-0037 |
| 退款账户默认 = 原付款账户 | ✅ | 99% 场景正确,用户可改(同账户) |
| 主页交易列表 refund 视觉差异化 | ✅ | 用户易识别(↩️ overlay + 蓝灰底色) |
| **DAO 拒绝 income/transfer/refund 退款(只允许 expense/repayment/lend/borrow,2026-08-09 修订)** | ✅ | 与 v4 §P0-05 字面对齐(Q2=B 拍板)|
| **DAO 累计超限保护(2026-08-09 修订)** | ✅ | sum(refunds where originalTransactionId=X) <= original.amountCents,防超额退款 |

---

## 后果

### 正面影响
- ✅ 退款按钮语义明确(咔皮对标,无需用户点咔皮确认)
- ✅ 退款可链式追踪(`originalTransactionId` 引用)
- ✅ 统计语义清晰(refund 抵消支出,本年支出净值正确)
- ✅ 主页交易列表易识别(图标 + 颜色)

### 负面影响 / 风险(2026-08-09 修订)
| 风险 | 等级 | 缓解 |
|---|---|---|
| refund 分类不计入「收入」统计,需要所有统计 DAO 过滤 | 🟡 中 | ADR-0022 §1 余额联动不动(余额已正确回滚),但 S05 净资产仪表盘 + S07 异常检测需明确:refund 计入「收支净额」但不计入「收入合计」 |
| **拆分退款 UX 复杂度(2026-08-09 修订)** | 🟢 低 | 多次独立 refund,主页 tile 显示「已退 ¥X / ¥Y」(DAO getRefundedAmount 累加 SUM),用户感受自然 |
| 退款后改原交易 | 🟢 低 | UI 禁用(交易详情页 + ActionSheet 详情页:DAO getRefundedAmount > 0 → 改/删/退全灰,2026-08-09 用户拍板 Q2=A 加 isRefunded 检测)|

### 衔接下游
- **S04 账本 & 预算**:refund 计入预算(按原交易分类的预算)
- **S05 净资产仪表盘**:refund 抵消原支出,**不**重复计入收入
- **S07 异常检测**:1 小时内同一分类多次退款 → 异常提示「频繁退款」

---

## 实施清单(D24+ 装机验后)

| # | 工作 | 范围 | 工作量 |
|---|---|---|---|
| 1 | schema v8 migration(加 TransactionType.refund + originalTransactionId + refundNote)| `app_database.dart` + 2 表 | 30 分钟 |
| 2 | refundMoney DAO + _getOrCreateRefundCategoryId | `transaction_dao.dart` | 2 小时 |
| 3 | 交易详情页加「退款」按钮(底部) | `transaction_detail_page.dart`(新建) | 1 小时 |
| 4 | 退款详情弹层(图 4 复刻) | `refund_sheet.dart`(新建) | 2 小时 |
| 5 | 主页交易 tile refund 视觉差异化 | `transaction_tile.dart` | 1 小时 |
| 6 | 单元测试 8(DAO 3 类场景 × 1 边界 + 嵌套保护) + widget 测试 4 | 测试 | 2 小时 |
| 7 | ADR-0030 自审 + 真机验 2 场景(支出退款 / 信用卡还款退款)| 收尾 | 1 小时 |
| **总计** | | | **~10 小时(2 天)** |

---

## 不做(本期 v1.0)

| 功能 | 何时 | 备注 |
|---|---|---|
| 部分退款(¥10 退 ¥5) | v1.1 评估 | 本期金额必须 == 原 |
| 批量退款(多笔同账户) | v1.1 | 本期单笔单次 |
| 退款理由模板(质量问题/尺码不对/不想要了) | v1.1 | 本期只 1 个备注字段 |
| 退款流程通知(原账户推送) | v1.1(本地通知) | ADR-0021 不引通知 |

---

## 验证

- [ ] flutter analyze 0 issues
- [ ] flutter test 314 + 8(DAO) + 4(widget) 全绿
- [ ] schema v8 migration_v8_test 3 用例 PASS(refund type + originalTransactionId + refundNote)
- [ ] refundMoney 3 类场景(正常/嵌套退款拒绝/金额不匹配拒绝)PASS
- [ ] 交易详情页 widget 4 测试 PASS
- [ ] iPhone 真机手验 2 场景:餐饮 -¥8.96 退款 → 账户 +¥8.96,主页显示 ↩️ 标识
- [ ] 旧 S03 数据零丢失(schema v8 兜底)

---

## 关联

- **CLAUDE.md 铁律 1**(极致体验)— 退款按钮语义明确
- **CLAUDE.md 铁律 8**(简化≠边界)— 退款 4 字段完整
- **ADR-0026 §9 退款按钮自审盲点**(2026-08-03 留 → 本 ADR 关闭)
- **ADR-0022 §1 余额联动**(refund 反向更新)
- **ADR-0028** §5 后续 P0(退款 transaction 化)
- **咔皮图 4**(7/18 22:33 退款详情弹层,真源)
- **咔皮图 19**(7/18 22:28 交易详情页,「删除+退款」双按钮)
- **产品设计 v4 §P0-05** 信用卡管理 + 退款

---

**最后更新**:2026-08-06
**生效日期**:用户拍板后立刻
**下次复审**:D24+ 实施 + 装机验时
