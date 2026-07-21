# ADR-0037:部分退款设计(v1.1 评估 — schema v9 + refundedAmount 字段)

> 状态:**DRAFT**(2026-08-09 由 D26 治理 Q3=B + Q4=α2 决策触发)
> 日期:2026-08-09(D26 实施期间,Day 2/5)
> Stage:**S03 ACTIVE → 留 v1.1 实施**
> 作者:Claude(执行)+ 用户(决策)
> 关联:**ADR-0030 §不可逆性第 5 条 修订**(2026-08-09)+ **v4 §P0-05 修订**(2026-08-09)+ **D26 用户拍板 Q3=B + Q4=α2**

---

## 背景

D26 用户拍板决策:
- **Q3 = B**:RefundSheet 退款金额字段**可改**(原 ADR-0030 字面要求只读)
- **Q4 = α2**:**多次完整退款** 模式 — 不动 schema,DAO 允许 `amount <= original`,多次独立 refund transaction 累加

D26 实施期间发现的设计缺口:**用户其实想要"硬部分退款"**(同 transaction 累计显示已退多少 / 还剩多少),但 α2 模式只能"多次独立完整退款",UX 上无法直观显示「已退 ¥3 / ¥10」这种累加 UI。

ADR-0030 当前实现支持 α2(多次独立 refund + SUM 查已退总额),但缺:
- schema 字段 `refundedAmountCents`(原交易已退累计金额)
- schema 字段 `isFullyRefunded`(原交易是否已全额退款)
- UI:主页 tile 显示「已退 ¥X / ¥Y」进度条 / 详情页显示退款历史

本 ADR 留 **v1.1 实施**,D26 不动 schema v8(避免 S04 启动时间影响)。

---

## 决策

### 决策 1:硬部分退款 = 单 transaction 累计(2026-08-09 用户拍板 α2 升级版)

```dart
// lib/data/db/tables/transactions.dart(v9 加)
IntColumn get refundedAmountCents => integer().nullable()();
// 原交易已退累计金额(分)。nullable 让 v8 旧数据 NULL = 未退过。
// 写入规则:每次 refundMoney 成功 → update original.refundedAmountCents += amount

BoolColumn get isFullyRefunded => boolean().withDefault(const Constant(false))();
// 原交易是否已全额退款(SUM >= originalAmountCents 时触发 true)
// UI 用作:主页 tile 显示「已退 ¥X / ¥Y · 已全额」标签

BoolColumn get hasPartialRefund => boolean().withDefault(const Constant(false))();
// 原交易是否被部分退款过(0 < SUM < originalAmountCents)
```

### 决策 2:DAO 累计校验改为原子化 update(取代 v8 SUM 查询)

```dart
// lib/data/db/daos/transaction_dao.dart(D26+ 升级)
return transaction(() async {
  // ... 校验
  
  // 读原交易最新状态(refundedAmountCents)
  final currentRefunded = original.refundedAmountCents ?? 0;
  if (currentRefunded + amountCents > original.amountCents) {
    throw StateError('累计退款金额超限 ...');
  }
  
  // 写 refund transaction
  final refundId = await into(transactions).insert(...);
  
  // 更新原交易累加字段(原子)
  await update(transactions).replace(original.copyWith(
    refundedAmountCents: Value(currentRefunded + amountCents),
    isFullyRefunded: Value(currentRefunded + amountCents == original.amountCents),
    hasPartialRefund: const Value(true),
    updatedAt: DateTime.now(),
  ));
  
  return refundId;
});
```

### 决策 3:UI 显示硬部分退款进度

```dart
// lib/features/home/presentation/widgets/transaction_tile.dart(v9 加)
if (transaction.hasPartialRefund && !transaction.isFullyRefunded) {
  // 主页 tile trailing 改为:「已退 ¥3 / ¥10」+ 进度条
  trailing: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text('已退 ¥X / ¥Y', ...),
      LinearProgressIndicator(
        value: transaction.refundedAmountCents! / transaction.amountCents,
        color: Colors.blueGrey,
        backgroundColor: Colors.blueGrey.shade50,
      ),
    ],
  ),
} else if (transaction.isFullyRefunded) {
  // 全额退款:显示「已全额退款」徽章
  trailing: Text('已全额退款', ...),
}
```

---

## 不可逆性(本 ADR 自身)

| 项 | 永不变更 | 理由 |
|---|---|---|
| schema v9 加 refundedAmountCents/isFullyRefunded/hasPartialRefund | ✅ | 单 transaction 字段,跨 S04 预算 / S05 净资产报表 / S07 异常检测,下游统一消费 |
| DAO 改原子化 update(取代 SUM 查询) | ✅ | 性能:避免每次 refundMoney 全表 SUM |
| UI 进度条 / 全额徽章 | ✅ | 用户识别度高,可视化 |

---

## 后果(2026-08-09 当前状态)

### D26(本期 v1.0)— 走 α2
- ✅ ADR-0030 §不可逆性第 5 条已修订(支持拆分金额)
- ✅ DAO 走 SUM 查询(_sumRefundedAmount)
- ✅ 主页 tile 显示「已退 ¥X / ¥Y」通过 SUM 查表(SUM 多次 refund)
- ❌ 主页 tile 进度条暂不实现(等 v1.1)
- ❌ 详情页累计 UI 暂不实现(等 v1.1)

### 负面影响(本期)
- 多次退款时主页 tile 不直观显示「已退百分比」(用户只看 X / Y 数字,没进度条)— v1.1 解决

---

## 决策翻转历史

| 日期 | 决策 | WHY |
|---|---|---|
| 2026-08-06 | ADR-0030 写"金额必须 == 原" | v1.0 简化,避免部分退款复杂度 |
| 2026-08-09 | 用户拍板 Q3=B(可改)+ Q4=α2(多次完整退款) | 现实部分退款场景必须支持,但 v1.0 走"多次独立 refund"避免 schema bump |
| 2026-08-09 | 本 ADR 立 DRAFT | v1.1 升级"硬部分退款" + schema v9 + UI 进度条 |

---

## 未来 v1.1 评估(IQA-fix M8 2026-08-09 修订:无 §实施清单)

> ⚠️ **DRAFT 状态不应写实施清单**(CLAUDE.md 治理纪律 — DRAFT = 背景 + 决策 + 不做)。
> 本节改名为"§未来 v1.1 评估",作为 v1.1 启动时的入口备忘,**不**是 v1.1 实施计划。
>
> v1.1 真要实施时,把状态改 ACCEPTED + 复制本节到 §实施清单 + 写 Day v1.1.X daily。

### 范围备忘(5 项)

| # | 工作 | 范围 | 估计工作量 |
|---|---|---|---|
| 1 | schema v9 migration(3 字段:refundedAmountCents/isFullyRefunded/hasPartialRefund)| app_database + transactions 表 | 30 分钟 |
| 2 | DAO 改原子化 update(取代 SUM)+ ADR-0030 §决策 3 修订 | transaction_dao | 1 小时 |
| 3 | 主页 tile 显示退款进度条 / 全额徽章 | transaction_tile | 1 小时 |
| 4 | 详情页加「退款历史」tab(v9 字段读)| transaction_detail_page | 1.5 小时 |
| 5 | 单元测试 + widget 测试 + 装机验 | test | 1.5 小时 |
| **总计** | | | **~5.5 小时(1 天)** |

### IQA-fix M1 关联(2026-08-09)

D26 已在 v1.0 加内存缓存 `_refundedSumCache` 缓解 N+1 + 全表扫,但**仅临时**——
v1.1 加 schema v9 + refundedAmountCents 字段后,DAO 改原子化 update 单 transaction 字段
读,无 SUM 查询(性能彻底解决)。

**触发 v1.1 评估条件**:S07 攒攒智能记账触发几万笔交易,内存缓存命中率下降导致
查询变慢时,或用户主观感受"交易列表卡" → 启动 v1.1 实施。

---

## 关联

- **ADR-0030**(2026-08-06 ACCEPTED + 2026-08-09 §不可逆性 / §决策 3 / §决策 4 修订)— 本 ADR 是 v1.1 升级
- **v4 §P0-05**(2026-08-09 修订)— SSOT 已对齐
- **CLAUDE.md 铁律 9**(v4 是 SSOT,ADR 只能补充)— 本 ADR 补充 ADR-0030 不覆盖 v4
- **CLAUDE.md 铁律 6**(推翻 ADR 必须新 ADR 替换)— D26 用户拍板 Q3=B 触发本 ADR
- **D26 Q3/Q4 拍板会话**(2026-08-09)

---

**最后更新**:2026-08-09
**生效日期**:D26 主体实施拍板后(v1.0 沿用 ADR-0030 修订版,α2 模式)
**下次复审**:v1.1 启动时
