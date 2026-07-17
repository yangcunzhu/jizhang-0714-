# ADR-0017:Stage 2 账户 Schema v2 + AccountType enum 取值策略

## 状态
已接受 — Day 11(2026-07-18)

## 背景

Stage 1 (S01) 简化为单一"现金"账户(accounts 表只 4 字段:id / name / balanceCents / createdAt)。
Stage 2 (S02) 需支持 6 种账户类型 + 信用卡专属字段,主页 Step 3 改为多账户选择器。

由此引出三个不可逆决策:

1. **AccountType 怎么存**(中文 / 英文 / 双语)
2. **Schema 怎么演进**(增量 ALTER / 删表重建 / 新表平迁)
3. **新字段可空性**(信用卡 3 字段对非信用卡账户的语义)

## 决策

### 1. AccountType enum:值英文存,中文显示

```dart
enum AccountType { cash, savings, creditCard, huabei, onlineLoan, investment }
```

- DB 列 `TextColumn type = textEnum<AccountType>().withDefault(const Constant('cash'))()`
- UI 显示走 enum 实例的 `displayName`/`emoji` getter(中文 + 类型 emoji 头像)
- 模仿项目已有 `TransactionType`(categories.dart 第 6 行),用 Drift 内置 `textEnum<>()` 而非 `intEnum<>()`

WHY:
- i18n 安全 — 存英文,改中文文案不动数据库
- 未来在中间插新值(如 `transfer`)不破坏历史行映射(不用 index)
- 与 `TransactionType` 一致,降低认知负担

### 2. Schema migration 走"增量 ALTER TABLE"

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await _seedDefaults();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(accounts, accounts.type);
      await m.addColumn(accounts, accounts.includeInNetWorth);
      await m.addColumn(accounts, accounts.creditLimit);
      await m.addColumn(accounts, accounts.billingDay);
      await m.addColumn(accounts, accounts.dueDay);
    }
  },
  beforeOpen: ...,
);

@override
int get schemaVersion => 2;
```

WHY:
- 写增量的 INSERT/UPDATE 历史交易行的外键完整保留(transactions.accountId 不被破坏)
- 已有 Stage 1 行自动填默认值('cash'),无需回填 SQL
- `addColumn` 是 Drift 官方推荐迁移 API,语义清晰
- 排除"删表重建"破坏数据;"新表平迁"复杂度高、收益低

### 3. 新字段可空性

| 字段 | 类型 | 可空 | 默认 | 说明 |
|---|---|---|---|---|
| `type` | TextColumn(textEnum) | NO | `'cash'` | 已有 row 自动归类 |
| `includeInNetWorth` | BoolColumn | NO | `true` | 理财类账户可改 false |
| `creditLimit` | IntColumn | YES | NULL | 仅 creditCard 类型有意义 |
| `billingDay` | IntColumn | YES | NULL | 仅 creditCard 类型有意义(1-31) |
| `dueDay` | IntColumn | YES | NULL | 仅 creditCard 类型有意义(1-31) |

WHY:
- NOT NULL + DEFAULT:'cash' / true,Stage 1 已存在的"现金"账户自动获合法值
- 信用卡 3 字段 nullable:花呗 / 网贷 / 储蓄 / 现金 / 理财都没有"账单日"概念,NULL 是语义正确而非缺失

## 后果

### 正面影响

- 主页可列出 6 种账户,Step 3 真正可切换
- 信用卡账户可填额度 + 账单/还款日(为 Stage 3 还款流打基础)
- 会计科目扩展无需 DB 重建

### 负面影响 / 风险

- `withDefault(Constant('cash'))` + textEnum 的组合需 Drift 2.34.4+ 支持 — 已通过 ADR-0012 锁定
- 信用卡 3 字段 NULL 时 UI 不会显示 — 需 Day 12 UI 区分处理(按 enum 字段)
- type 字段以 enum.name 字符串存,数据库迁移需保留字符串兼容性

### 风险缓解

- **测试覆盖**:Day 11 必须写 `migration_v2_test.dart`,从 v1 schema 升到 v2 后断言
  - 1 条已有账户,`type='cash'`,`includeInNetWorth=true`,后 3 字段 NULL
- **真机手验**:Day 16 (07-23) 真机验升级路径

## 不可逆性

- DB schema 列名变更极难回退,只有"再 migration v3"能补救
- enum 名称定义必须永不变更(只增不改)
- 一旦下游代码依赖 `AccountType.name`,换表示需要数据迁移

## 验证

- [x] `flutter analyze` 0 错误
- [x] `flutter test` 全绿(80+ 用例含 migration ≥5)
- [x] 真实升级路径自动化测试(v1 schema → v2 迁移后断言)
- [x] Build iOS .ipa CI 绿
- [x] Day 16 真机 3 场景手验覆盖升级路径(D18 签字后补勾)

## 关联

- ADR-0012:依赖锁定(drift_dev 2.34.4)
- ADR-0013:emoji 优先(`emoji` getter 用 emoji 字符)
- ADR-0015:Stage 2 写集(本文是写集第 1 项"Schema migration v2"的实施细节)
- `lib/data/db/tables/categories.dart`:TransactionType.textEnum<>() 范式
- `docs/stages/S02-classification-accounts.md`:Stage 2 主文档
- `docs/daily/2026-07-25.md`:Day 11 开工话术(写"日期: 2026-07-18")
