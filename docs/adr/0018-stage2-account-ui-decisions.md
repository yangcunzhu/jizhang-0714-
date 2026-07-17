# ADR-0018:Stage 2 账户管理 UI 设计决策

## 状态
已接受 — Day 12(2026-07-19)

## 背景

Stage 2 Day 12 实施账户 CRUD UI(主页入口 + 弹层 + 6 种类型卡片)前,3 个 UI 决策需要固定,否则实现路径发散:

1. **编辑弹层形式**:bottom sheet vs full page
2. **账户管理页布局**:list vs grid
3. **emoji 头像样式**:透明背景 vs 主题色背景

## 决策

### 1. 编辑弹层 = `showModalBottomSheet`

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => AccountEditSheet(...),
);
```

WHY:
- 与 `record_sheet` / `transaction_actions_sheet` 风格一致(均 modal bottom sheet)
- 账户字段数 ≤ 6(类型 + 名称 + 可选信用卡 3 字段 + 余额/状态),空间够用
- 保存后 dismiss 回调干净 — `Navigator.pop(context, true)`,父级 await 即可

### 2. 账户管理页 = `ListView` 单列

```dart
ListView(children: [
  for (final acc in accounts) AccountCard(...),
])
```

WHY:
- 信息密度高 — 一行卡片可显示余额 + 信用卡专项字段(额度/账单日/还款日)
- 沿用 `home_page._TransactionList` 视觉风格(也是 ListView)
- 用户扫一眼能看到所有账户 + 关键信息

### 3. emoji 头像 = 类型 emoji + 透明背景

```dart
Text(account.type.emoji, style: TextStyle(fontSize: 18))
```

WHY:
- 沿用 ADR-0013 emoji 优先(无 Material Icons 干扰)
- 跟 `account_picker.dart` 现有 `_AccountCard` 一致 — 不引入视觉风格差异
- 透明背景降低视觉重量,适合多账户列表

## 字段动态显示(默认决策,不需用户拍板)

- 信用卡类型(`type = creditCard`)才显示:creditLimit / billingDay / dueDay 三个字段
- 其他类型:这三个字段隐藏
- 切换类型时:无需动画(AnimatedSwitcher)— 简单直接显隐,切换是低频操作

## 余额显示(默认决策)

- 显示在卡片:隐私是用户决策,iOS App 不强制隐藏
- Stage 5 净资产计算依赖此字段

## 后果

### 正面影响

- UI 与现有 3 个 modal sheet 风格统一(record_sheet / transaction_actions_sheet / account_edit_sheet)
- 列表 + emoji 透明背景降低视觉噪声
- 信用卡专项字段在卡片内即可见,无需跳详情

### 负面影响 / 风险

- 6 个账户类型 emoji 各异,需要 `AccountType.emoji` getter 已定义(ADR-0017 完成)
- 弹层高度需根据类型动态计算(isScrollControlled + DraggableScrollableSheet?)

### 风险缓解

- 弹层用 `isScrollControlled: true` + 内容自适应高度,避免键盘弹出挤压
- 切换类型后字段立刻消失/出现,用 conditional widget 而非 AnimatedSwitcher

## 不可逆性

- 弹层形式确定后,后续新建 sheet 都按这个模式
- 列表 vs 网格确定后,主页交易列表也维持一致

## 关联

- ADR-0013:emoji 优先(本决策继续沿用)
- ADR-0017:AccountType enum + emoji getter(本决策消费)
- ADR-0015:Stage 2 写集(本决策在写集内)
- `lib/features/record/presentation/record_sheet.dart`:弹层风格参考
- `lib/features/home/presentation/widgets/transaction_actions_sheet.dart`:弹层风格参考
- `lib/features/record/presentation/widgets/account_picker.dart`:emoji 透明背景参考

## 验证

- [x] `flutter analyze` 0 错误
- [x] `flutter test` 全绿(Day 11 93 + Day 12 新增 ≥20)
- [x] Day 16 真机手验 3+ 场景(创建/编辑/删除账户)(D18 签字后补勾)