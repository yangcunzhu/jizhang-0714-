# 编码规范

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有 Dart / Flutter / Swift 代码

---

## 🎯 总原则

1. **可读性优先**：代码是写给人看的，顺便让机器执行
2. **简单优先**：能简单的不要复杂，能用标准库的不要自己造
3. **测试驱动**：复杂逻辑必须 TDD
4. **零注释**（除非 WHY 不明显）
5. **强类型**：禁止 `dynamic`，禁止 `as` 强转（除非必要）

---

## 📐 文件组织

### 文件命名

| 类型 | 规则 | 示例 |
|---|---|---|
| Dart 文件 | snake_case | `transaction_repository.dart` |
| Dart 类 | PascalCase | `TransactionRepository` |
| Dart 文件夹 | snake_case | `lib/features/record/` |
| Swift 文件 | PascalCase | `OCRProcessor.swift` |
| 测试文件 | `_test.dart` 后缀 | `transaction_repository_test.dart` |

### 每个文件 ≤ 300 行

超过 300 行 → 拆分为多个文件

### 每个函数 ≤ 50 行

超过 50 行 → 拆分为多个函数

---

## 🎨 命名规范

### 类

```dart
// ✅ 好
class TransactionRepository {}      // 名词
class TransactionCreateService {}  // 动词 + 名词

// ❌ 差
class Transaction {}                // 太泛
class DoTransaction {}             // 动词开头
class trx_repo {}                  // 缩写
```

### 变量

```dart
// ✅ 好
final amount = 100.0;
final transactionList = <Transaction>[];
final isLoading = false;

// ❌ 差
final a = 100.0;
final tmp = <Transaction>[];
final flag = false;
```

### 函数

```dart
// ✅ 好（动词开头）
Future<Transaction> createTransaction(Transaction tx) async {}
Future<void> saveAmount(double amount) async {}
bool isValidAmount(String text) {}

// ❌ 差
Future<Transaction> transaction(Transaction tx) async {}
Future<void> amount(double amount) async {}
```

### 常量

```dart
// ✅ 好
const maxAmount = 1000000.0;
const defaultCategoryIcon = '🍔';

// ❌ 差
const MAX_AMOUNT = 1000000.0;  // 不要 SCREAMING_SNAKE_CASE
const default_category_icon = '🍔';  // 不要 snake_case
```

---

## 🧬 类型系统

### 强制

- ✅ 所有函数明确返回类型（禁止 `dynamic`）
- ✅ 所有 public 类成员明确类型
- ✅ 优先使用 `final` 而非 `var`
- ✅ 优先使用 `const` 构造

### 禁止

- ❌ `dynamic`（除非第三方 API 必须）
- ❌ `as` 强转（用 `is` + 类型守卫）
- ❌ `!` 非空断言（除非 100% 确定）
- ❌ `print()`（用 logger）
- ❌ `// ignore: ...`（除非必要 + 注释说明）

### 类型守卫示例

```dart
// ✅ 好
if (value is String) {
  return value.toUpperCase();
}

// ❌ 差
return (value as String).toUpperCase();  // 可能 crash
```

---

## 🎯 函数设计

### 单一职责

一个函数只做一件事。

```dart
// ✅ 好
Future<Transaction> createTransaction(Transaction tx) async {
  await _validate(tx);
  await _save(tx);
  return tx;
}

// ❌ 差（一个函数做了 5 件事）
Future<Transaction> createTransaction(Transaction tx) async {
  // validate + save + notify + log + cache + ...
}
```

### 避免深嵌套

最多 3 层 `{}`。

```dart
// ✅ 好（early return）
if (!isValid) return null;
if (!hasPermission) return null;
return doWork();

// ❌ 差（深嵌套）
if (isValid) {
  if (hasPermission) {
    return doWork();
  }
}
```

### 函数参数

最多 4 个参数。超过 → 用对象封装。

```dart
// ✅ 好
class CreateTransactionParams {
  final double amount;
  final String categoryId;
  final String accountId;
  final DateTime occurredAt;
  final String? note;
  CreateTransactionParams({...});
}
createTransaction(params);

// ❌ 差
createTransaction(amount, categoryId, accountId, occurredAt, note, ...);
```

---

## 🧪 测试规范

### 必须测试

- ✅ 所有 public 类的方法
- ✅ 所有业务逻辑
- ✅ 所有边界条件（0、null、空、最大、最小）
- ✅ 所有错误处理路径

### 测试命名

```dart
// ✅ 好
test('createTransaction 保存到数据库', () {});
test('createTransaction 金额为负数抛异常', () {});
test('createTransaction 分类不存在抛异常', () {});

// ❌ 差
test('test1', () {});
test('it works', () {});
```

### 测试结构（AAA）

```dart
test('createTransaction 保存成功', () async {
  // Arrange（准备）
  final repo = TransactionRepository(db);
  final tx = Transaction.test();
  
  // Act（执行）
  await repo.create(tx);
  
  // Assert（断言）
  final saved = await repo.findById(tx.id);
  expect(saved, isNotNull);
  expect(saved!.amount, tx.amount);
});
```

---

## 🚨 错误处理

### 禁止吞掉错误

```dart
// ❌ 差
try {
  await saveData();
} catch (e) {
  // 啥都不做
}

// ✅ 好
try {
  await saveData();
} on SpecificException catch (e) {
  logger.e('保存失败', error: e);
  rethrow;
}
```

### 自定义异常

```dart
// ✅ 好（明确异常类型）
class TransactionNotFoundException implements Exception {
  final String id;
  TransactionNotFoundException(this.id);
  @override
  String toString() => 'Transaction $id not found';
}

// 调用方能精确 catch
try {
  await repo.findById(id);
} on TransactionNotFoundException catch (e) {
  showNotFoundError(e.id);
}
```

---

## 📝 注释规范

### 何时写注释

只有当 WHY 不明显时才写：

```dart
// ✅ 好（解释 WHY）
// SQLCipher 要求密钥长度至少 32 字节
final dbKey = generateKey(length: 32);

// ✅ 好（解释 WHY）
// 用 Isolate 避免阻塞 UI（OCR 大图像会卡 1-2s）
await Isolate.run(() => processImage(image));

// ❌ 差（解释 WHAT，代码已经说清楚了）
// 设置用户名为 "John"
final userName = 'John';

// ❌ 差（无意义）
// TODO: 优化
// FIXME: 有 bug
```

### 禁止

- ❌ 解释 WHAT 的注释（代码自解释）
- ❌ emoji 注释（除了 TODO 标记）
- ❌ 注释掉的代码（直接删除）
- ❌ 大段 docstring（除非 public API）

---

## 📦 Import 规范

### 顺序

1. Dart SDK
2. Flutter SDK
3. 第三方 package
4. 项目内 import

每组之间空一行。

```dart
// ✅ 好
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jizhang_app/data/models/transaction.dart';
import 'package:jizhang_app/core/utils/logger.dart';
```

### 禁止

- ❌ `import 'package:jizhang_app/...';` 与 `import '../...';` 混用
- ❌ 未使用的 import（lint 会警告）
- ❌ `part` / `part of`（用 lib/ 子目录组织）

---

## 🎨 Widget 规范（Flutter）

### 拆分 Widget

每个 Widget 只负责一个职责。

```dart
// ✅ 好
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(),
      body: HomeBody(),
      bottomNavigationBar: HomeBottomNav(),
    );
  }
}

// ❌ 差（一个 Widget 几百行）
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: Column(
        children: [
          // 100 行
        ],
      ),
    );
  }
}
```

### const 构造

所有不需要 rebuild 的 Widget 用 `const`：

```dart
// ✅ 好
const Text('Hello')
const SizedBox(height: 16)
const Icon(Icons.add)

// ❌ 差（每次 build 都创建新对象）
Text('Hello')
SizedBox(height: 16)
```

---

## ⚡ 性能规范

### 列表性能

```dart
// ✅ 好（ListView.builder 懒加载）
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, i) => TransactionTile(transactions[i]),
)

// ❌ 差（一次性构建所有）
ListView(
  children: transactions.map((t) => TransactionTile(t)).toList(),
)
```

### 避免重复构建

```dart
// ✅ 好（提取 const）
const _kAmountStyle = TextStyle(fontSize: 32);
Text('¥100', style: _kAmountStyle);

// ❌ 差（每次 build 重建 TextStyle）
Text('¥100', style: TextStyle(fontSize: 32));
```

---

## 🔧 工具与验证

### 提交前必跑

```bash
flutter analyze      # 0 issues
flutter test         # All passed
dart format --set-exit-if-changed lib/ test/
```

### 配置

`analysis_options.yaml`：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    # 视为错误而非警告
    invalid_assignment: error
    missing_return: error
    dead_code: error

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
    avoid_print: true
    require_trailing_commas: true
    unawaited_futures: true
```

---

## 📌 违规处理

- 大副代码违反规范 → 大副自己修复
- 督察审计时检查编码规范 → 列入审计报告
- 反复违规 → 写 ADR 改进流程

---

**最后更新**：2026-07-14 · 创建