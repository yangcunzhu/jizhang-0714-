# ADR-0016: Stage 7+ 智能记账功能规划(咔皮对比)

> 状态:**已接受**(规划性,非阻塞)
> 日期:2026-07-17(Day 11 拍板)
> Stage:**Stage 7+**(v1.1+ 路线,Day 11+ 暂不实施)
> 作者:Claude(执行)+ 用户(决策)
> 触发:用户分享咔皮 App 截图,问"我们方案里有没有这些功能"

---

## 背景

Stage 1 ACCEPTED 后(2026-07-17 真机 3 场景全过),用户分享**咔皮** App 的两张截图,展示其"自动记账"+"语音记账"两大功能 + 4 种 iOS 触发方式。

咔皮截图核心功能:
1. **自动记账**(支付成功后自动识别并记账)— 走"咔皮-自动记账"快捷指令 + 4 种触发方式
2. **语音记账**("Hey Siri, 停车 30")— 走 Siri Shortcuts

iOS 触发方式(图二):
- ① 辅助触控(小白点)— 单点/轻点两下/长按
- ② 轻敲手机背面(iOS 14+ Back Tap)
- ③ 操作按钮(iPhone 15 Pro+ Action Button)
- ④ 控制中心(添加专属指令)

用户问题:**"我们的方案里有没有这些功能?"**

---

## 现状对比

| 功能 | 咔皮截图 | 我们方案 `product-design-v4.html` | 优先级 | 计划 Stage |
|---|---|---|---|---|
| 支付通知自动监听 → 自动记账 | ✅ | ❌ **iOS 没有原生 API**(Android 有 NotificationListenerService) | - | - |
| 语音记账 "Hey Siri,停车 30" | ✅ | ✅ P1-02 Siri Shortcuts | P1(低) | Stage 7+ |
| 截图 OCR → 自动识别 | ✅ | ✅ P1-01 OCR + P1-03 截图自动触发 | P1(低) | Stage 7+ |
| 4 种 iOS 触发方式 | ✅ | ✅ 通过 `flutter_siri_shortcuts` 集成 Shortcuts framework | P1(低) | Stage 7+ |
| 定时记账(房租/订阅/工资) | ✅ | ✅ P1-10 周期自动记账 | P1(低) | Stage 7+ |
| 攒攒语音反馈(TTS) | ✅ | ✅ P2-05 攒攒语音 | P2(最低) | v2.0 |
| **数据源标记** schema | ✅ | ✅ transactions.source 已预留 `'manual'/'ocr'/'siri'/'scheduled'` | - | Stage 1 ✅ |

---

## 决策

### Stage 2-6 不动 — 智能记账全部留到 Stage 7+

**WHY 不在 Stage 2 加**:
1. Stage 2 主线 = 数据模型扩展 + 自定义 UI(ADR-0015 已定)
2. 智能记账需要 iOS 系统权限 + 新依赖(`flutter_siri_shortcuts` / OCR / LLM),会扩大 scope
3. CLAUDE.md §3.4 决策原则:**质量优先 > 稳定优先 > 简单优先** — Stage 2 聚焦做透"自定义",智能功能 Stage 7+ 再加

### Stage 7+ 必须实现(P1 优先级 5 项)

| 编号 | 功能 | 实施路径 |
|---|---|---|
| **S7-01** | Siri Shortcuts 集成 | `flutter_siri_shortcuts: ^1.0+` + iOS Shortcuts framework |
| **S7-02** | iOS 4 种触发方式 | iOS Shortcuts framework 自带(辅助触控/背面/操作按钮/控制中心都可注册 Shortcut) |
| **S7-03** | OCR 截图识别 | iOS Vision API 原生(免费本地) |
| **S7-04** | 定时记账 | `flutter_local_notifications` + WorkManager(iOS) / BackgroundFetch |
| **S7-05** | 数据源标记 UI | 主页交易列表显示 `source` icon(✍️ manual / 📷 OCR / 🎙️ Siri / ⏰ scheduled) |

### Stage 7+ 可选实现(P2 优先级,留到 v2.0)

| 编号 | 功能 | 实施路径 |
|---|---|---|
| S7-06 | 攒攒语音反馈(TTS) | iOS AVSpeechSynthesizer |
| S7-07 | LLM 自动归类(规则引擎 + LLM 校验) | OpenAI / Claude API |
| S7-08 | PDF 月报 | `pdf` 包 + fl_chart |
| S7-09 | CSV 导入(从咔皮迁移) | `csv` 包 + 字段映射 |
| S7-10 | RPG 等级系统 | Flutter 自定义动画 + 状态机 |

---

## iOS vs Android 关键差异

### 自动记账(支付通知监听)

| 平台 | 方案 | 难度 |
|---|---|---|
| Android | `NotificationListenerService` 原生 API | ⭐ 易 |
| iOS | **无原生 API**,只能间接实现 | ⭐⭐⭐ 难 |

**iOS 间接方案**:
- **方案 A — Shortcuts Automation**:用户在 iPhone"快捷指令"App 建一条"收到微信支付通知 → 自动截图 → 调用我们 App OCR 入口"。**用户必须手动设置**,App 不能主动监听。
- **方案 B — Watch App / Live Activity**:Apple Watch 监测支付 → 推到 iPhone,App 接收(需用户装 Watch App)。
- **方案 C — 手动截图 OCR**:用户截图支付成功页 → 自动 Shortcut 触发 → App OCR + 弹确认(我们的 P1-03 路线)。

**推荐方案 C**(最稳定 + 用户主动可控),咔皮 Android 版用方案 A 直达,iOS 走方案 C。

### iOS Shortcuts framework 集成边界

**Apple 政策**:
- ✅ App 可以**注册** Shortcut(让用户在系统 Shortcuts App 里看到)
- ✅ 用户在 Shortcuts App 里**手动添加**到 4 种触发方式
- ❌ App **不能强制**绑定到辅助触控 / 背面 / 操作按钮(必须在 Shortcuts App 完成)

**这意味着我们的"语音记账" + "4 触发方式" = Stage 7+ 实施时,需要写好 Shortcut 注册逻辑,然后在 README / 设置页告诉用户"3 步去 Shortcuts App 添加"。

---

## Stage 2 衔接(写到这里就好,Stage 7 再展开)

Stage 2 已经预留的衔接点:
- ✅ `transactions.source` 字段(Stage 1 已 commit,Stage 7+ 直接用)
- ✅ `accounts.type` 字段(Stage 2 加,信用卡/花呗等为 Stage 3 还款铺路)
- ✅ Riverpod state(Stage 7+ 接 LLM 客户端不用重构)

**Stage 2 内不需要为 Stage 7 做任何额外工作**。

---

## 风险与决策

| 风险 | 等级 | 缓解 |
|---|---|---|
| iOS Shortcuts 集成政策变化 | 🟢 低 | 用 flutter_siri_shortcuts 主流包,跨 Apple 政策变化兼容 |
| OCR 准确率 < 90% | 🟡 中 | 用户确认弹窗兜底(不自动记账,需用户点确认) |
| LLM 调用成本失控 | 🟡 中 | 本地规则引擎优先,LLM 仅在规则不命中时回退 |
| 用户认知:"咔皮能做自动记账,我们为什么不能" | 🟡 中 | 在 README + 设置页明确说明 iOS 限制 + 截图 OCR 替代方案 |

---

## 关键参考

- `product-design-v4.html` §2.10 P0-04 / §3.20 OCR + Siri
- ADR-0015 Stage 2 写集(分类 CRUD + 多账户,不包含智能记账)
- ADR-0007(待写)Stage 7 苹果匠角色 / Siri 集成细节
- 咔皮截图:用户 `E:\0717-shenjiguanxuqiu\` 下 2 张

---

**最后更新**:2026-07-17
**生效日期**:Stage 7 开工时(预计 v1.1+)
**下次复审**:Stage 7 ROA 时