# 测试策略

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有代码测试

---

## 🎯 测试原则

1. **测试金字塔**：70% 单元 / 20% Widget / 10% 集成
2. **关键模块 100% 覆盖**：金额计算、信用卡还款、预算执行、数据加密
3. **TDD 默认**：复杂逻辑先写测试再写实现
4. **测试不撒谎**：测试通过 = 功能真的对，不是只跑过

---

## 📊 测试覆盖率目标

| 模块 | 目标覆盖率 |
|---|---|
| `lib/domain/`（业务规则） | **100%** |
| `lib/data/repositories/` | **≥ 90%** |
| `lib/data/services/`（核心服务） | **≥ 90%** |
| `lib/features/*/domain/` | **≥ 90%** |
| `lib/features/*/data/` | **≥ 80%** |
| `lib/presentation/`（UI） | **≥ 60%** |
| `lib/core/`（工具） | **≥ 70%** |
| **整体** | **≥ 80%** |

---

## 🧪 测试类型

### 1. 单元测试（Unit Test）

测试纯函数、Service、Repository。

```dart
// test/unit/domain/services/budget_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/domain/services/budget_service.dart';

void main() {
  group('BudgetService', () {
    late BudgetService service;
    
    setUp(() {
      service = BudgetService();
    });
    
    test('计算剩余预算 - 正常情况', () {
      final result = service.calculateRemaining(
        totalBudget: 5000.0,
        spent: 2000.0,
      );
      expect(result, 3000.0);
    });
    
    test('计算剩余预算 - 超支返回 0', () {
      final result = service.calculateRemaining(
        totalBudget: 5000.0,
        spent: 6000.0,
      );
      expect(result, 0.0);
    });
    
    test('计算剩余预算 - 边界 0', () {
      final result = service.calculateRemaining(totalBudget: 0, spent: 0);
      expect(result, 0.0);
    });
  });
}
```

**何时写**：
- ✅ 业务规则
- ✅ 计算逻辑
- ✅ 数据转换
- ✅ 验证逻辑
- ❌ 不写 UI 测试

---

### 2. Widget 测试（Widget Test）

测试 Widget 渲染和交互。

```dart
// test/widget/features/record/amount_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/features/record/presentation/widgets/amount_input.dart';

void main() {
  testWidgets('AmountInput 显示初始值', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AmountInput(initial: 100.0)),
      ),
    );
    
    expect(find.text('100'), findsOneWidget);
  });
  
  testWidgets('AmountInput 输入数字后触发回调', (tester) async {
    double? receivedAmount;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountInput(
            initial: 0,
            onChanged: (v) => receivedAmount = v,
          ),
        ),
      ),
    );
    
    await tester.enterText(find.byType(TextField), '250');
    expect(receivedAmount, 250.0);
  });
}
```

**何时写**：
- ✅ 复杂 Widget（AmountInput, CategoryGrid）
- ✅ 关键交互流程
- ❌ 简单 Widget（Text, Icon）不写

---

### 3. 集成测试（Integration Test）— 概念

跨多个组件、验证真实数据流的测试。Stage 1 范围：复用在 `lib/data/repositories/` 与 `lib/features/*/data/` 层的代码（DAO + 内存 SQLite + Provider），不依赖 Widget 树。

> **E2E 真 Flutter engine 的规范见 §4。** §3 只描述模块级集成（不启动真 app）。

```dart
// test/data/repositories/transaction_repository_test.dart
// 示例：DAO + 内存 SQLite 联合测试(不是 E2E)
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => await db.close());

  test('insertTransaction 后 getById 拿回', () async {
    final cat = await db.categoryDao.getAll();
    final acc = await db.accountDao.getDefault();
    final id = await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        amountCents: 1234,
        type: TransactionType.expense,
        categoryId: cat.first.id,
        accountId: acc!.id,
      ),
    );
    final fetched = await db.transactionDao.getById(id);
    expect(fetched?.amountCents, 1234);
  });
}
```

**何时写**：
- ✅ 跨 DAO / Repository 交互(如记账流程 = categoryDao + accountDao + transactionDao)
- ✅ Provider + Drift 集成(如 transactionListProvider 监听 watchAll)
- ❌ 不写 UI(E2E 写,见 §4)

---

### 4. E2E 集成测试（Integration Test — ADR-0014 真 Flutter engine）

**关键差异**：与 widget test 不同，E2E 启动整个 Flutter app（`app.main()`），在 iOS 模拟器或真机上跑真 Flutter engine + 真 SQLite 文件 + 真 Plugin Channel。

```dart
// integration_test/e2e_record_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整记账流程', (tester) async {
    await tester.pumpWidget(const MyApp()); // 真 app 启动
    await tester.tap(find.byType(FloatingActionButton));
    // ... 真键盘 / 真 SQLite / 真字体
  });
}
```

**E2E 文件组织**：
```
integration_test/
├── _helpers/
│   ├── test_harness.dart    # 共享 boot / 操作
│   └── selectors.dart       # 语义化 finder
├── e2e_record_flow_test.dart
├── e2e_persistence_test.dart
└── e2e_emoji_render_test.dart
```

**跑 E2E**：
```bash
# macOS 开发机
xcrun simctl boot "iPhone 15"
flutter test integration_test/ -d "iPhone 15"

# 真机（需 macOS）
flutter test integration_test/ -d <device-id>
```

**何时写**（ADR-0014 每 Stage 至少 1 个）：
- ✅ 完整用户旅程：记账 → 列表 → 修改 → 删除
- ✅ 真 SQLite 持久化（文件而非内存）
- ✅ 字体渲染（emoji / Apple Color Emoji）
- ✅ Plugin Channel 真触发（振动 / SQLCipher / AI 推理）
- ✅ App 生命周期（pause + resume 数据持久性）

**Widget 加 Key 规范**（Day 8 起强制）：
```dart
// ✅ 语义清晰,可直接 find.byKey
FloatingActionButton(
  key: const Key('record-fab'),
  onPressed: () => showRecordSheet(context),
)

// E2E:
await tester.tap(find.byKey(const Key('record-fab')));
```

**反模式**：
- ❌ 在 E2E 中复用 widget test 的 `UncontrolledProviderScope overrideWithValue`（E2E 跑真 app）
- ❌ 测试细节如 `pump(Duration(milliseconds: 100))` 而不是 `pumpAndSettle()`（impeller 渲染等待时机不一致）
- ❌ 一个 E2E 测多个独立流程（隔离失败,失败时无法定位）

---

## 🔴 必测场景

### 金额计算

```dart
test('金额四舍五入到 2 位小数', () {});
test('金额为 0 不允许', () {});
test('金额为负数抛异常', () {});
test('金额超过上限抛异常', () {});
test('金额支持科学计数法', () {});  // 1e6 = 1000000
```

### 信用卡还款

```dart
test('还款金额 = 账单金额', () {});
test('部分还款正确', () {});
test('还款后可用额度更新', () {});
test('逾期还款标记', () {});
```

### 预算

```dart
test('预算 80% 触发警告', () {});
test('预算 95% 触发严重警告', () {});
test('预算 100% 触发超支', () {});
test('日预算 = 剩余预算 / 剩余天数', () {});
test('日预算考虑已用', () {});
```

### 数据加密（Stage 6）

```dart
test('数据库文件是加密的', () {});
test('错误密钥无法打开', () {});
test('密钥从 Keychain 读取', () {});
test('迁移后数据完整', () {});
```

---

## 🔧 测试工具

### 必备

- `flutter_test`（官方）
- `mocktail`（mock 库，比 mockito 简单）
- `integration_test`（E2E 集成测试）

### 可选

- `bloc_test` / `riverpod_test`（状态测试）
- `golden_toolkit`（截图对比）
- `patrol`（高级集成测试）

---

## 📐 测试命名

```dart
// ✅ 好（描述行为）
test('createTransaction 金额为负数抛 InvalidAmountException', () {});

// ❌ 差（模糊）
test('test1', () {});
test('it works', () {});
```

格式：`{方法名} {条件} {预期结果}`

---

## 🎯 TDD 流程

复杂逻辑用 TDD：

```
1. Red:    写失败的测试
2. Green:  写最小实现让测试通过
3. Refactor: 重构（保持测试通过）
4. Repeat
```

### 示例

```dart
// Step 1: Red（测试失败）
test('还款后可用额度增加', () {
  final card = CreditCard(creditLimit: 10000, used: 5000);
  final updated = card.afterRepayment(2000);
  expect(updated.available, 7000);  // ❌ 失败（Card 还没有 afterRepayment）
});

// Step 2: Green（最小实现）
class CreditCard {
  final double creditLimit;
  final double used;
  CreditCard({required this.creditLimit, required this.used});
  
  CreditCard afterRepayment(double amount) {
    return CreditCard(
      creditLimit: creditLimit,
      used: used - amount,
    );
  }
}

// Step 3: Refactor（完善）
```

---

## 🚫 反模式

### ❌ 测试实现细节

```dart
// ❌ 差（测内部状态）
expect(provider.state.isLoading, true);

// ✅ 好（测行为）
expect(find.byType(CircularProgressIndicator), findsOneWidget);
```

### ❌ 脆弱的断言

```dart
// ❌ 差（依赖 UI 细节）
expect(find.text('¥100.00'), findsOneWidget);  // 一改样式就挂

// ✅ 好（测业务含义）
expect(find.textContaining('100'), findsOneWidget);
```

### ❌ 互相依赖的测试

```dart
// ❌ 差（测试 A 改了全局状态，影响测试 B）
test('A', () { globalState.x = 1; });
test('B', () { expect(globalState.x, 1); });  // 依赖 A

// ✅ 好（每个测试独立 setUp）
```

### ❌ 只测正常路径

```dart
// ❌ 差
test('保存成功', () {});

// ✅ 好（覆盖边界）
test('保存成功', () {});
test('保存失败（数据库错误）', () {});
test('保存时网络断开', () {});
test('保存时用户取消', () {});
```

---

## 🔍 测试检查清单（每个 Task 完工）

```
□ 新代码有对应测试
□ 边界条件覆盖（0、null、空、最大、最小）
□ 错误路径覆盖
□ 测试命名清晰（行为描述）
□ 不依赖其他测试
□ 不测实现细节
□ flutter test 通过
□ flutter analyze 0 issues
□ 关键 Stage 加 E2E(ADR-0014)
```

---

## 📊 覆盖率查看

```bash
# 生成覆盖率报告
flutter test --coverage

# 用 lcov 查看
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html  # Windows
```

**CI 集成**（Stage 8）：

```yaml
- name: Test with coverage
  run: |
    flutter test --coverage
    # 检查覆盖率达标
    if [ $(jq '.coverage' coverage/coverage.json) -lt 80 ]; then
      echo "覆盖率不足 80%"; exit 1;
    fi
```

---

## 📌 测试纪律

- 大副写代码时**同时写测试**
- 关键模块**必须 TDD**
- 督察审计时**检查测试覆盖率**
- 覆盖率不达标 → 不能 OWNER_ACCEPTANCE

---

**最后更新**：2026-07-14 · 创建
**对应 ADR**：0003-test-strategy