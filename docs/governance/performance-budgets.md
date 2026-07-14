# 性能预算

> 状态：`GOVERNANCE`
> 创建：2026-07-14
> 适用范围：所有性能相关指标

---

## 🎯 核心指标（v1.0 MVP 必须达成）

| 指标 | 目标 | 测量方法 |
|---|---|---|
| 冷启动时间 | ≤ 2 秒 | 从点击图标到首页可交互 |
| 主页加载时间 | ≤ 1 秒 | 从首页可见到列表可滚动 |
| 页面切换 | ≤ 300ms | 点击到新页面可交互 |
| 滚动帧率 | ≥ 55 FPS | Xcode Instruments / Flutter DevTools |
| 内存占用 | ≤ 150 MB | 空闲时 |
| 包大小（.ipa） | ≤ 30 MB | 构建后大小 |
| 数据库查询 | ≤ 100ms | 简单查询 |
| 数据库查询（复杂） | ≤ 500ms | 统计/聚合查询 |
| 振动反馈 | ≤ 50ms | 操作触发到振动 |
| 动画时长 | 250-800ms | 弹层 / 攒攒 |

---

## 🚀 启动性能

### 冷启动 ≤ 2 秒分解

| 阶段 | 目标 |
|---|---|
| iOS 启动 App | 0-300ms（系统） |
| Flutter 引擎初始化 | 300-1000ms |
| 首屏渲染 | 1000-1500ms |
| 数据加载完成 | 1500-2000ms |

### 优化手段

- [ ] 首屏只加载必要数据（lazy load 其余）
- [ ] 主数据库查询并行（Future.wait）
- [ ] 图片懒加载（cached_network_image）
- [ ] 不在 main() 里做 IO
- [ ] 拆分 isolate 处理重活

---

## 📜 滚动性能

### ≥ 55 FPS 要求

- 列表用 `ListView.builder`（不是 ListView）
- `const` 构造所有不变 Widget
- 避免在 build 里做计算
- 用 `AutomaticKeepAliveClientMixin` 保持列表状态
- 复杂 Widget 用 `RepaintBoundary` 隔离重绘

### 反例

```dart
// ❌ 差（每次 build 都创建新对象）
ListView(
  children: transactions.map((t) {
    return TransactionTile(t, onTap: () => print(t.id));  // ❌ 闭包
  }).toList(),
)

// ✅ 好
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, i) {
    final tx = transactions[i];
    return TransactionTile(tx, key: ValueKey(tx.id));  // ✅ key
  },
)
```

---

## 💾 数据库性能

### 查询预算

| 查询类型 | 目标 |
|---|---|
| 单条查询 | ≤ 50ms |
| 列表（< 1000 条） | ≤ 100ms |
| 列表（< 10000 条） | ≤ 300ms |
| 聚合查询 | ≤ 500ms |

### 必须索引的字段

```sql
-- transactions 表
CREATE INDEX idx_transactions_date ON transactions(occurred_at);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);

-- accounts 表
CREATE INDEX idx_accounts_type ON accounts(type);

-- credit_cards 表
CREATE INDEX idx_credit_cards_due_date ON credit_cards(repayment_due_date);
```

### N+1 查询禁止

```dart
// ❌ 差（N+1）
for (final tx in transactions) {
  final category = await categoryDao.findById(tx.categoryId);
  // ...
}

// ✅ 好（JOIN 一次拿全部）
final txWithCategory = await transactionDao.findAllWithCategory();
```

---

## 📦 包大小

### 目标

- `.ipa` 文件 ≤ 30 MB
- `.app` bundle ≤ 25 MB

### 优化

- [ ] 用 `flutter build ios --release --split-debug-info`
- [ ] 移除未用资源（图片、字体）
- [ ] 压缩图片（WebP/AVIF）
- [ ] 启用 R8 / ProGuard

### 检查命令

```bash
# 查看 .ipa 大小
ls -lh build/ios/iphoneos/Runner.ipa

# 分析 .app 内容
du -sh build/ios/iphoneos/Runner.app/*
```

---

## 💾 内存

### 目标

- 空闲时：≤ 100 MB
- 加载时峰值：≤ 200 MB
- 长使用后：≤ 150 MB

### 常见内存泄漏

- 未取消的 Stream 订阅
- 未关闭的 Isolate
- 全局静态集合无限增长
- 大图片未释放

### 检测

- Xcode Instruments → Allocations
- Flutter DevTools → Memory

---

## 🌐 网络

### 目标（v1.0 无网络，但预留）

- API 响应：≤ 1 秒（p95）
- 重试：最多 3 次，指数退避
- 超时：10 秒

### 优化

- [ ] HTTP 缓存
- [ ] 请求合并
- [ ] 离线模式（v1.0 必须）

---

## 🔋 电量

### 目标

- 后台 1 小时：≤ 1% 电量
- 正常使用 1 小时：≤ 10% 电量

### 优化

- 不在后台跑任务（v1.0 几乎不需要）
- 振动反馈 < 100ms
- 动画不要无限循环

---

## 📊 性能监控

### Flutter DevTools

```bash
flutter run --profile  # profile 模式（带性能信息）
```

打开 DevTools：
- Performance → Timeline
- Memory → Allocation
- Network → 请求

### 真机测试

v1.0 必测：

- [ ] iPhone SE（第 3 代）- 老设备
- [ ] iPhone 15 - 标准
- [ ] iPhone 15 Pro Max - 大屏

### 性能测试用例（Stage 8）

```dart
// test/performance/scrolling_test.dart
testWidgets('列表滚动 1000 项保持 55 FPS', (tester) async {
  final transactions = List.generate(1000, (i) => Transaction.test());
  await tester.pumpWidget(app);
  
  await tester.fling(
    find.byType(ListView),
    Offset(0, -500),
    1000,
  );
  await tester.pumpAndSettle();
  
  // 验证无掉帧
  expect(tester.takeException(), isNull);
});
```

---

## 📌 性能检查清单（每个 Stage 完成）

```
□ flutter analyze 0 issues
□ 滚动测试 ≥ 55 FPS
□ 数据库查询 ≤ 100ms（用 EXPLAIN QUERY PLAN）
□ 启动 ≤ 2 秒（真机测试）
□ .ipa ≤ 30 MB
□ 内存 ≤ 150 MB（真机 Xcode Instruments）
□ 无内存泄漏（DevTools）
```

---

## 🚨 性能不达标处理

```
1. 性能测试发现不达标
   ↓
2. 用 DevTools 找瓶颈
   ↓
3. 修复（如加索引、加 const、Lazy load）
   ↓
4. 重新测
   ↓
5. 不达标 → 写 ADR 说明 + 决策（接受 / 推迟 / 重构）
```

性能不达标**不能** OWNER_ACCEPTANCE。

---

**最后更新**：2026-07-14 · 创建