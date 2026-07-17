# ADR-0021:Stage 3 信用卡 & 还款范围决策(最小 MVP)

> 状态:**已接受**
> 日期:2026-07-31(D17 收尾时)
> Stage:**S03-credit-card-repayment**(Day 18-24,2026-08-01 ~ 2026-08-07)
> 作者:Claude(执行)+ 用户(决策)

---

## 背景

Stage 2(S02)已实现信用卡账户 CRUD + 字段(creditLimit / billingDay / dueDay),但**还款流缺失**:
- 用户不能用 App 执行「从储蓄账户 → 信用卡账户」的还款
- 信用卡账户卡片不显示还款日,用户必须自己记住
- 信用卡消费后,看不到「下个月该还多少」

产品方案(`product-design-v4.html` §P0-05)要求:
- 信用卡账单日 / 还款日本地通知(flutter_local_notifications)
- 信用卡还款流(从储蓄账户 → 信用卡账户)
- 还款记录作为特殊 transaction

由此引出 2 个不可逆决策:

1. **S03 范围**:MVP vs MVP+通知
2. **是否引 flutter_local_notifications**(CLAUDE.md §2「不引入新依赖 — 除非现有方案无法实现」)

---

## 决策

### 1. S03 范围 = **最小 MVP**(还款流 + 卡片增强)

**包含**:

1. **Schema migration v3 → v4** — TransactionType enum 加 `repayment` 值(textEnum 自动处理)
2. **还款流 UI** — 「从储蓄账户 → 信用卡账户」转账交互
   - 主页「+」菜单加「还款」入口(仅当存在 ≥1 信用卡账户时显示)
   - 还款弹层 3 步骤:选储蓄账户 → 输入金额 → 选信用卡账户 → 备注(可选)→ 保存
   - 落地:生成 1 条 type=repayment 的 transaction(语义 = 储蓄账户扣款 + 信用卡账户增加可用额度)
3. **信用卡账户卡片增强** — 显示账单日 / 还款日 / 「距离还款日 X 天」

**排除**:

- ❌ flutter_local_notifications 本地通知(**违反 CLAUDE.md §2「不引入新依赖」**)
- ❌ 信用卡账单生成(自动抓取 / 手动输入)
- ❌ 自动还款(扣款日自动转账)
- ❌ 多币种
- ❌ 信用评分 / 最低还款额

### 2. flutter_local_notifications = **不引**

**WHY**:

- CLAUDE.md §2「不引入新依赖 — 除非现有方案无法实现」
- 通知功能可由「信用卡卡片显示距离还款日 X 天」替代(用户主动看 App)
- 引入新包 = 增加 CI 卡死风险 + iOS 18 兼容性问题(flutter_local_notifications 在 iOS 18 有多个待修 issue)
- S03 7 天时间紧(2026-08-07 收尾),引入新依赖会增加 1-2 天调研成本
- S04+ 如确实需要通知,可单独开 ADR 评估(届时 flutter_local_notifications 可能已稳定)

**替代方案**:在主页 AppBar 加「还款提醒」图标,点进去显示「3 天后还招行信用卡 ¥1500」主动提醒。

---

## 后果

### 正面影响

- ✅ 0 新依赖 — 风险可控
- ✅ 还款闭环完整,信用卡账户「有用」起来
- ✅ 7 天计划可达成(D18-D24)
- ✅ 卡片增强让用户主动跟踪还款日,避免忘记
- ✅ 与 S02 6 种账户类型扩展一脉相承

### 负面影响 / 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| 还款流事务失败导致账户余额不一致 | 🟡 中 | 用 `transaction {}` 包裹;集成测试覆盖失败回滚 |
| 信用卡「距离还款日 X 天」跨月计算错误 | 🟡 中 | 单测覆盖 1/15/28/31 + 跨月边界 |
| TransactionType 加 repayment 破坏历史行 | 🟢 低 | textEnum 兼容性已验证(ADR-0017 模式) |
| 用户错过还款日(无通知) | 🟡 中 | 主页 AppBar「还款提醒」图标主动呈现 |
| iOS 18 兼容性问题(无新依赖) | 🟢 低 | 沿用现有 CI 链,无新风险面 |

### 衔接下游

- **Stage 4(账本 & 预算)**:基于 transaction type='repayment' 可统计月度还款总额
- **Stage 5(净资产 & 仪表盘)**:还款 transaction 影响储蓄账户余额,但不影响信用卡账户余额(已用信用额度)
- **Stage 6(存储 & 快照)**:Drift 加密不变(沿用 S06 计划)

---

## 不可逆性

- **TransactionType enum 加值 `repayment`**:DB schema 列名变更极难回退,只能再 migration v5 补救;**枚举名 `repayment` 必须永不变更**(S04+ 月度还款总额统计依赖字符串匹配)
- **0 新依赖决策**:S04+ 如需通知需开新 ADR 评估,不能直接引入
- **主页「还款」按钮位置 = AppBar.actions**(沿用分类模板按钮模式):后续新功能按 AppBar.actions 模式,不在 FAB 加新按钮(避免 UX 分裂)
- **还款 transaction 语义**:type=repayment 的金额方向(储蓄账户负 / 信用卡账户正)固定,下游计算依赖
- **还款 transaction categoryId 引用「还款」分类**:S03 新增一个默认分类(name='还款', icon='💳', type=expense),repayment transaction 引用它(保持 categoryId NOT NULL 约束,避免改 schema)

---

## 验证

- [ ] flutter analyze 0 错误
- [ ] flutter test 全绿(227 + S03 新增 ≥ 25 = 252+)
- [ ] migration_v4_test.dart 断言:旧 transaction.type='expense'/'income' 不变 + 新 type='repayment' 可写 + v3→v4 升级路径
- [ ] transaction_dao.transferRepayment 单元测试(成功路径 + 失败回滚 + 余额不足边界)
- [ ] account_card 信用卡字段 widget 测试(显示 + 「距离还款日 X 天」跨月计算)
- [ ] 集成测试覆盖还款全链路
- [ ] Build iOS .ipa CI 绿
- [ ] Day 23 真机手验 3+ 场景

---

## 关联

- ADR-0015:Stage 2 写集(本决策在 S02 基础上扩展)
- ADR-0017:AccountType enum + textEnum 模式(本决策的 TransactionType 沿用同一模式)
- ADR-0012:依赖锁定(本决策维持 0 新依赖)
- ADR-0013:emoji 优先(沿用)
- `lib/data/db/tables/transactions.dart`:TransactionType 定义位置
- `lib/data/db/daos/transaction_dao.dart`:transferRepayment 实施位置
- `lib/features/account/presentation/widgets/account_card.dart`:信用卡卡片增强位置
- `docs/stages/S03-credit-card-repayment.md`:Stage 3 主文档
- `CLAUDE.md §2:不引入新依赖 — 除非现有方案无法实现`

---

**最后更新**:2026-07-31(D17 收尾拍板)
**生效日期**:S03 ACTIVE 后(S02 ACCEPTED 后的 D18)
**下次复审**:S03 ROA 时(如发现还款流不够用,再开 ADR 评估通知)
