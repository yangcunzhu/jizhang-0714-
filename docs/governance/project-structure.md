# 项目结构规范

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：Flutter 项目代码组织

---

## 🎯 设计原则

- **Feature-based**：按功能模块组织（不是按类型）
- **Clean Architecture 变体**：data → domain → presentation 三层
- **依赖方向**：presentation → domain ← data
- **每个 Feature 独立**：可独立测试、独立修改

---

## 📁 完整目录结构

```
E:\jizhang-0714\
├── docs/                          ← 文档（已在 docs/README.md）
│
├── product-design-v4.html         ← v4 方案（不在 git 中修改）
│
├── README.md                      ← 项目说明
├── CHANGELOG.md                   ← 版本变更日志
├── pubspec.yaml                   ← 依赖配置
├── pubspec.lock                   ← 锁定版本（必须 commit）
├── analysis_options.yaml          ← lint 配置
├── .gitignore
├── .gitattributes
│
├── lib/                           ← 应用代码
│   ├── main.dart                  ← 入口
│   ├── app.dart                   ← App 根 Widget
│   │
│   ├── core/                      ← 跨功能共享
│   │   ├── theme/                 ← 主题（颜色、字体、间距）
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_theme.dart
│   │   ├── utils/                 ← 工具
│   │   │   ├── logger.dart
│   │   │   ├── date_utils.dart
│   │   │   └── currency_utils.dart
│   │   ├── extensions/            ← 扩展方法
│   │   │   ├── string_extensions.dart
│   │   │   └── datetime_extensions.dart
│   │   ├── constants/             ← 常量
│   │   │   ├── app_constants.dart
│   │   │   └── storage_keys.dart
│   │   └── widgets/               ← 通用 Widget
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       └── loading_indicator.dart
│   │
│   ├── data/                      ← 数据层
│   │   ├── database/              ← Drift 数据库
│   │   │   ├── app_database.dart
│   │   │   ├── tables/            ← 表定义
│   │   │   │   ├── transactions.dart
│   │   │   │   ├── categories.dart
│   │   │   │   ├── accounts.dart
│   │   │   │   └── ...
│   │   │   ├── daos/              ← 数据访问对象
│   │   │   │   ├── transaction_dao.dart
│   │   │   │   └── ...
│   │   │   └── migrations/        ← 数据库迁移
│   │   │       ├── v1_to_v2.dart
│   │   │       └── ...
│   │   ├── models/                ← 数据模型
│   │   │   ├── transaction.dart
│   │   │   ├── category.dart
│   │   │   └── ...
│   │   ├── repositories/          ← 仓储实现
│   │   │   ├── transaction_repository.dart
│   │   │   └── ...
│   │   └── services/              ← 外部服务
│   │       ├── storage_service.dart  （Stage 6）
│   │       ├── biometric_service.dart （Stage 6）
│   │       └── llm_service.dart    （Stage 7）
│   │
│   ├── domain/                    ← 领域层（业务规则）
│   │   ├── entities/              ← 实体（业务对象）
│   │   │   ├── transaction.dart
│   │   │   └── ...
│   │   ├── repositories/          ← 仓储接口
│   │   │   └── transaction_repository.dart
│   │   ├── services/              ← 领域服务
│   │   │   ├── audit_service.dart
│   │   │   ├── budget_service.dart
│   │   │   └── ...
│   │   └── value_objects/         ← 值对象
│   │       ├── money.dart
│   │       └── date_range.dart
│   │
│   ├── presentation/              ← 表现层
│   │   ├── providers/             ← Riverpod providers
│   │   │   ├── transaction_provider.dart
│   │   │   └── ...
│   │   ├── routing/               ← 路由
│   │   │   ├── app_router.dart
│   │   │   └── routes.dart
│   │   └── pages/                 ← 页面
│   │       ├── home_page.dart
│   │       └── ...
│   │
│   └── features/                  ← 功能模块（feature-based）
│       ├── record/                ← 记账（S01）
│       │   ├── data/
│       │   │   ├── transaction_dao.dart
│       │   │   └── ...
│       │   ├── domain/
│       │   │   └── ...
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── record_page.dart
│       │       ├── widgets/
│       │       │   ├── amount_input.dart
│       │       │   ├── category_grid.dart
│       │       │   └── account_selector.dart
│       │       └── providers/
│       │           └── record_provider.dart
│       │
│       ├── categories/            ← 分类（S02）
│       ├── accounts/              ← 账户（S02）
│       ├── credit_cards/          ← 信用卡（S03）
│       ├── books/                 ← 账本（S04）
│       ├── budget/                ← 预算（S04）
│       ├── dashboard/             ← 仪表盘（S05）
│       ├── storage/               ← 存储（S06）
│       └── zan_zan/               ← 攒攒（S07）
│
├── ios/                           ← iOS 平台代码
│   └── Runner/
│       ├── AppDelegate.swift
│       ├── ocr_processor.swift    ← Vision API（S07）
│       ├── notification_handler.swift
│       └── ...
│
├── test/                          ← 测试
│   ├── unit/                      ← 单元测试
│   │   ├── data/
│   │   ├── domain/
│   │   └── core/
│   ├── widget/                    ← Widget 测试
│   │   └── features/
│   └── integration/               ← 集成测试
│       └── ...
│
├── assets/                        ← 静态资源
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── lottie/                    ← 攒攒动画
│
├── scripts/                       ← 工具脚本
│   ├── generate_assets.dart
│   └── seed_data.dart
│
└── tools/                         ← 开发工具
    └── ...
```

---

## 📂 Feature 模块内部结构

每个 feature（如 `record/`）内部统一结构：

```
features/record/
├── data/                  ← 该 feature 的数据访问
│   └── ...
├── domain/                ← 该 feature 的业务逻辑
│   ├── entities/
│   ├── repositories/
│   └── services/
├── presentation/          ← 该 feature 的 UI
│   ├── pages/
│   ├── widgets/
│   └── providers/
└── tests/                 ← 该 feature 的测试
    └── ...
```

---

## 🔄 三层依赖规则

```
presentation ─→ domain ←── data
```

- ✅ presentation 依赖 domain（用 interface）
- ✅ data 实现 domain 的 interface
- ❌ domain 不能依赖 presentation 或 data
- ❌ data 不能依赖 presentation

### 示例

```dart
// domain/repositories/transaction_repository.dart（接口）
abstract class TransactionRepository {
  Future<Transaction> create(Transaction tx);
  Future<List<Transaction>> findAll({DateTimeRange? range});
}

// data/repositories/transaction_repository_impl.dart（实现）
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;
  TransactionRepositoryImpl(this._dao);
  
  @override
  Future<Transaction> create(Transaction tx) async {
    await _dao.insert(tx);
    return tx;
  }
  
  @override
  Future<List<Transaction>> findAll({DateTimeRange? range}) async {
    return _dao.query(range: range);
  }
}

// presentation/providers/record_provider.dart（使用）
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  // Riverpod 注入实现
  return ref.read(transactionRepositoryImplProvider);
});
```

---

## 📐 命名约定

### 文件

| 类型 | 规则 | 示例 |
|---|---|---|
| 表定义 | snake_case + _table | `transactions_table.dart` |
| DAO | snake_case + _dao | `transaction_dao.dart` |
| Repository 接口 | I 前缀（可选） | `transaction_repository.dart` |
| Repository 实现 | Impl 后缀 | `transaction_repository_impl.dart` |
| Service | snake_case + _service | `storage_service.dart` |
| Provider | snake_case + _provider | `record_provider.dart` |
| Widget | pascal_case | `AmountInput` |
| Page | pascal_case + Page | `RecordPage` |
| Test | _test.dart 后缀 | `transaction_repository_test.dart` |

### 目录

- snake_case 全小写：`features/credit_cards/`
- 避免缩写：`features/transaction_categories/` 而非 `txn_cat/`

---

## 🚫 反模式

### ❌ 不要按类型组织

```
lib/
├── models/        ← 所有 model 放一起
├── widgets/       ← 所有 widget 放一起
├── pages/         ← 所有 page 放一起
└── services/      ← 所有 service 放一起
```

**为什么差**：改一个 feature 要改 5 个目录，跨 feature 改不动

### ✅ 按 feature 组织

```
lib/features/record/
├── data/
├── domain/
└── presentation/
```

**为什么好**：一个 feature 集中，删/改/移植都方便

---

### ❌ 不要 God Object

```
class AppManager {
  // 1000 行
  // 包含数据库、网络、UI、状态...
}
```

### ✅ 单一职责

```
class TransactionRepository { /* 只管 transaction CRUD */ }
class StorageService { /* 只管存储 */ }
class AuthService { /* 只管认证 */ }
```

---

## 📦 跨 Feature 共享

需要共享时 → 放到 `lib/core/`，**不要**互相 import features。

```dart
// ❌ 差
import 'package:jizhang_app/features/categories/models/category.dart';
import 'package:jizhang_app/features/accounts/models/account.dart';

// ✅ 好（共享的放 core/）
import 'package:jizhang_app/domain/entities/category.dart';  // 多个 feature 共享
import 'package:jizhang_app/domain/entities/account.dart';
```

---

## 🧪 测试目录

```
test/
├── unit/              ← 测试纯函数、service、repository
│   ├── data/
│   ├── domain/
│   └── core/
├── widget/            ← 测试 Widget 渲染
│   └── features/
├── integration/       ← 测试端到端流程
│   └── ...
└── fixtures/          ← 测试数据
    └── transactions.json
```

---

## 🔧 工具与检查

每次 commit 前：

```bash
# 检查目录结构是否合理
find lib -name "*.dart" | wc -l

# 检查依赖方向（手动）
# domain/ 不应该 import data/ 或 presentation/

# Lint
flutter analyze
```

---

## 📌 约定一致性

- 新建文件 → 按本规范命名
- 新建 feature → 复制 `lib/features/record/` 结构
- 跨 feature 共享 → 提升到 `lib/core/`
- 违反规范 → 督察审计时报告

---

**最后更新**：2026-07-14 · 创建
**对应 ADR**：0002-project-structure