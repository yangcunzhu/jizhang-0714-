# 《审计官》项目级 CLAUDE

> 版本：v1.0 · 创建：2026-07-14 · 维护者：Claude（执行）+ 用户（决策）
> 本文件是 AI 进入本项目的**第一必读文件**，相当于"宪法"
> 全局 CLAUDE.md：`C:\Users\Administrator\.claude\CLAUDE.md`（v2.1）

---

## 0. 优先级（最高规则）

> **项目级 CLAUDE.md > 全局 CLAUDE.md**
> 未在本文件覆盖的全局规则，全部继承并适用。
> 冲突时，以本文件为准；本文件未规定但全局有的规则，按全局执行。

---

## 1. 项目速览（30 秒读懂）

| 维度 | 内容 |
|---|---|
| **是什么** | iOS 自用记账 App《审计官》 |
| **技术栈** | Flutter 3.24+ / Riverpod 2.5+ / Drift 2.20+ / SQLCipher 4.5+ |
| **部署路线** | AltStore + GitHub Actions（0 成本，不交 $99/年）|
| **目标** | 8 周 / 56 天完成 v1.0 MVP（20 项 P0） |
| **协作模式** | 单人 + AI（你决策 / 我执行 + 主动汇报） |
| **起点日期** | 2026-07-15（Stage 0 / Day 1） |

**真源文件**（冲突时以这些为准）：
1. `product-design-v4.html` — 产品功能
2. `docs/PLAN.md` — 实施计划
3. `docs/ROADMAP.md` — 路线图
4. `docs/CONTROL_TOWER.md` — 当前状态（**派生**，不手填）
5. 代码 + 运行证据

---

## 2. 必读清单（每次新会话**前 3 分钟**必读）

进入本项目的**每个新会话**（无论原因），按此顺序读：

1. ⭐ `CLAUDE.md`（本文件）
2. ⭐ `docs/CONTROL_TOWER.md`（当前状态：哪个 Stage / 阻塞 / 决策）
3. ⭐ `docs/daily/$(date +%Y-%m-%d).md`（今天做什么）
4. `docs/context-management.md`（上下文管理 / 防幻觉）
5. `MEMORY.md`（在 `C:\Users\Administrator\.claude\projects\E--jizhang-0714\memory\`）

**跳过这些 = 幻觉风险 + 不合规风险。**

---

## 3. AI 必须遵守的 6 条铁律（违反 = 拒绝继续）

### 🔴 铁律 1：write-set 授权包络
**未经授权的文件 = 不能写。**

- 每个 Stage 有 `docs/stages/S{N}-*.md`，里面有 write-set
- 写任何代码/文档前，**先查 write-set** 是否包含目标路径
- 不在 write-set 内的文件 → 拒绝写，或开 Decision Request 申请

### 🔴 铁律 9(2026-08-03 增)：v4 是 SSOT,ADR 只能补充,开工前必查 v4
**(用户问题倒逼出来的规则 — 我之前做偏根因 1:没强制护栏,光看 CLAUDE.md 不够,要"机制"不是"道德")。**

- **`product-design-v4.html` 是单一可信源(SSOT)**,所有产品决策以 v4 为准
- **ADR 只能"补充 / 更新" v4,不能"覆盖" v4**(覆盖要先更新 v4)
- 每个 ADR §关联 必须引用 v4 章节 + 标"补充 / 覆盖 / 更新"
- **每个 Stage 开工前必查**(CLAUDE.md §4 强制):
  1. Read `product-design-v4.html` §3(咔皮对标)+ §4(功能)+ §52(路线图)
  2. Read 相关 `docs/adr/00XX-*.md`(上一轮决策)
  3. **明确本次决策与 v4 关系**:一致 / 补充 / 更新
  4. 一致 → 直接写代码;补充 → ADR 引用 v4 章节;更新 → 先改 v4,再写 ADR

- **每 1-2 周跑偏检查**:Read v4 §3.1 + 当前代码 + ADR,做 diff,确认未偏离
- **沟通机制**:用户给新截图 / 新需求 → 我**先**更新 v4(必要时),**再**写 ADR,不再让 ADR 跑前面

### 🔴 铁律 7(2026-08-02 增)：产品设计先行,PM 视角开工
**(用户问题倒逼出来的规则 — 我之前没主动遵守 CLAUDE.md §1 「极致体验 / 顶级品质 / 行家认可」)。**

### 🔴 铁律 10(2026-08-03 增)：完成日期机制,文档对账
**(用户每天 18 小时加班倒逼出来的规则 — 我之前文档标计划时间,实际节奏不匹配)。**

- **用户时间 vs 模型时间**:用户每天 18 小时加班,模型做得快,v4 计划时间 ≠ 实际完成时间
- **commit message 标「完成日期」**:
  ```
  feat(s03): D19 还款流 DAO + 余额自动更新(完成 2026-08-03,vs v4 计划:超前 1 周)
  ```
- **daily 标实际进度**:不写「计划完成时间 vs 实际」对比(混淆),只写「今天做了什么 / 累计 vs v4 计划差 X 周」
- **v4 §52.7 看板每周五晚更新**(从 ⏳ 改 ✅,或加新任务)
- **ADR 不再新写**(除非真做新功能);已经写的标完成日
- **v4 = SSOT**(铁律 9),所有文档时间以 v4 实际完成时间为准,不是计划时间

- 每个 Stage 开工前,先出**产品设计文档**(PM 视角),含:
  - 产品定位(这个功能解决什么问题)
  - 用户旅程(用户从打开 App 到完成任务的步骤)
  - **3 类场景**:正常 / 异常 / 边界(例:还款流:储蓄够 / 储蓄不够 / amount=0)
  - **产品差异化**:同类型不同产品(如花呗 vs 网贷 vs 信用卡)必须单独设计,不允许「一刀切」

- 用户拍板后才开始写代码,不允许「先写代码后想产品」。

- 「MVP 简化」可以,但必须在 ADR 里**显式列出**哪些场景简化了、为什么、什么时候补。

### 🔴 铁律 8(2026-08-02 增)：简化「功能」≠ 简化「边界」
**(用户问题倒逼出来的规则 — 我之前混淆了这两件事,导致边界场景缺失)。**

- 简化功能可以(例:还款提醒改卡片显示距离 X 天)。
- 但**每种账户类型必须单独设计产品逻辑**:
  - 现金 / 储蓄:基本余额管理
  - 信用卡:额度 + 账单日 + 还款日 + 还款流
  - 花呗:类似信用卡,但**花呗分期**特殊
  - 网贷:类似信用卡 + **期数管理**
  - 理财:概念抽象,需 PM 明确(基金?股票?P2P?)
- 不允许用「现金逻辑」套其他类型。

### 🔴 铁律 2：SSOT 不可手填
**SSOT = Single Source of Truth。**

- `CONTROL_TOWER.md` 第 3 行明确标 `DERIVED / DO NOT EDIT / NOT_SSOT`
- 改 PLAN/ROADMAP/CONTROL_TOWER 前必须读 ADR-0001 ~ 0003 等已接受决策
- 派生数据自动算，不准手填

### 🔴 铁律 3：变更前先审计
**不知道现状前不准动手。**

- 改代码前 `git status` 看 worktree 干净
- 改规则前 `git log` 看决策历史
- 改前必读相关 ADR + 最近 3 个 commit

### 🔴 铁律 4：失败即停 + 升级
**遇到错误 / 矛盾 / 不确定，必须停下：**

- 1 步可修复 → 修
- 2 步以上 / 影响 Stage 边界 / 涉及用户偏好 → **写 Decision Request**（`templates/decision-request-template.md`）阻塞等待
- 不准"先做了再说"，不准"假装没看到"

### 🔴 铁律 5：禁止临时文件污染
**所有临时文件必须放 `.ai-work/`**（全局 CLAUDE.md 规则）

- `.ai-work/` 不存在则创建
- 任务完成**必须删除** `.ai-work/`
- 根目录 / lib/ / docs/ 下禁止出现 `.tmp` `debug_*` `test_*.dart` 等残留

### 🔴 铁律 6：每日收尾必须 git 提交
**当日代码必须 commit。**

- 遵循 `templates/commit-message-template.md`（Conventional Commits）
- commit 前 `git status` 检查无残留
- commit 后 `git log --oneline -1` 确认成功

---

## 4. AI 必做的 8 个检查（每个动作前自检）

每个 Task 开始前 / 每段代码生成前 / 每个文档写入前，**默念**这 8 个检查：

| # | 检查 | 怎么做 |
|---|---|---|
| 1 | write-set 包含目标？ | 读 Stage 文档 |
| 2 | git worktree 干净？ | `git status` |
| 3 | 涉及哪个 ADR？ | 列出并读 |
| 4 | 测试覆盖率目标清楚？ | `lib/domain/` 100% / `data/` ≥ 90% / 整体 ≥ 80% |
| 5 | 用了占位符 / TODO？ | 设计内可以，泄漏不行 |
| 6 | 文件名符合规范？ | `S{N}-*` / `{4位}-*` / `YYYY-MM-DD` / `*-template` |
| 7 | 内部链接目标存在？ | 不引用没创建的文件 |
| 8 | commit 信息规范？ | Conventional Commits |

**任意一项不通过 → 停下修复再继续。**

---

## 5. AI 绝不能做的事（10 条禁区）

1. ❌ 不读 `CONTROL_TOWER.md` 就动手改代码
2. ❌ 不读 write-set 就写文件
3. ❌ 不查 ADR 就改架构
4. ❌ 不跑测试就 commit
5. ❌ 不通过用户授权就跳过 Stage
6. ❌ 不用占位符就写真实个人数据（手机号 / 卡号 / 家人称呼 / 真实金额）
7. ❌ 不写 Decision Request 就擅自扩大 Stage 范围
8. ❌ 把临时文件 / 测试代码 / debug 代码 commit 到主分支
9. ❌ 在代码 / commit 信息 / 文档里暴露密钥 / Apple ID / GitHub Token
10. ❌ "改完就说完成" — 必须验证（build / test / analyze 三件套至少 2 个通过）

---

## 6. 与全局 CLAUDE.md 的关系（冲突表）

### 6.1 全局规则在本项目**全部适用**（无需声明）

- 决策优先级（极致体验 / 顶级品质 / 务实挑战 / 行家认可 / 效率）
- 语言规范（中文 + 代码标识符英文）
- 10 条禁止行为（不改范围外 / 不加无用抽象 / 不引入新依赖 等）
- 通用规则（先审计再动手 / 精准手术 / 目标驱动 / 简单优先）
- 质量保障（不验证不算完成 / 自验证清单 / 测试要求）
- 项目管理（核心配置保护 / 临时文件隔离 / 变更追踪）
- 安全合规（数据安全 / 输入验证 / 权限控制）
- 子智能体管理（防卡死 / 终止条件 / 失败即停）
- 架构决策记录（ADR）
- 技术债务管理

### 6.2 全局规则在本项目**部分覆盖 / 调整**

| 全局规则 | 在本项目的应用 |
|---|---|
| 不写注释（代码内） | ✅ **代码内适用**；❌ 治理 / ADR / 产品文档**不受限**（需 emoji + WHY 说明）|
| HTML First | ✅ **已合规**：`product-design-v4.html` / `collaboration-architecture.html` |
| 子智能体优先 | ✅ **启用**，但本项目有 6 角色专门模型（见 `docs/governance/roles.md`）|
| 严格测试 | ✅ **强化**：本项目 ADR-0003 要求关键模块 100% 覆盖 |
| 函数 ≤ 50 行 / 文件 ≤ 300 行 | ⚠️ **代码内适用**；复杂 Flutter UI widget 允许 ≤ 100 行（需代码注释说明，已确认放宽）|
| ADR 编号格式 | ✅ 4 位序号（0001, 0002, 0003...）|
| git 提交规范 | ✅ Conventional Commits，见 `templates/commit-message-template.md` |
| `.ai-work/` 临时文件 | ✅ **强制**；任务完成必删 |

### 6.3 全局规则在本项目**显式豁免**

- **禁止 emoji**（全局隐含） → 本项目治理 / ADR / 产品文档**可用**（✅ 已大量使用，视为风格而非装饰）
- **不在 .md 写大段叙述** → 本项目治理文档详细叙述是设计内（用户决策参考需要）
- **每个回答 3 行以内** → 本项目审计 / 报告 / 复杂问题允许长答案

### 6.4 本项目**独有**的规则（全局没有）

| 规则 | 说明 | 见 |
|---|---|---|
| write-set 授权包络 | 每个 Stage 有明确写入白名单 | `docs/stages/S{N}-*.md` |
| SSOT 纪律 | PLAN/ROADMAP/CONTROL_TOWER 优先级 + 派生规则 | 本文件 §1 + `CONTROL_TOWER.md` |
| 占位符还原 | 文档中真名/真金额必须用占位符 | 本文件 §5 第 6 条 |
| Stage 生命周期 | DRAFT→READY→AUTHORIZED→ACTIVE→VALIDATING→ROA→ACCEPTED | `docs/governance/scripts.md` |
| 检查池审计 | 每个 Stage ROA 必跑 | `docs/templates/audit-report-template.md` |
| 6 角色协作 | 指挥官/大副/架构师/苹果匠/攒攒师/督察 | `docs/governance/roles.md` |

---

## 7. 长期稳定性机制（防 AI 跑偏）

8 周 56 天 = 长周期项目，单靠"提醒"不够。需要**结构性保障**：

### 7.1 SSOT 纪律
- 所有决策有真源，冲突时查真源
- 派生文档（CONTROL_TOWER）不手填
- 修改任何 SSOT 必须先写 ADR

### 7.2 Stage 边界 + write-set
- 每个 Stage 有明确范围（≤ 1 周）
- 范围外的事不在这 Stage 做（开新 Stage 或写 DR）
- 防止"慢慢扩大"侵蚀纪律

### 7.3 检查池（Stage ROA 必跑）
- 每个 Stage 收尾：lint / test / analyze / audit 4 件套
- 不通过 = 不能进入下一 Stage
- 详见 `templates/audit-report-template.md`

### 7.4 ADR 决策记录
- 重大技术决策必须写 ADR
- ADR 一旦接受，code 必须遵守
- 推翻 ADR 必须新 ADR 替换

### 7.5 每日工作日志
- 每天 `docs/daily/YYYY-MM-DD.md` 必填
- 含：今天做了什么 / 没做什么 / 明天做什么 / 阻塞 / 决策请求
- 不写 = 当日没干活（纪律要求）

### 7.6 上下文管理 4 层防御
详见 `docs/context-management.md`：
- Layer 1：SSOT + 文件持久化
- Layer 2：记忆系统（MEMORY.md）
- Layer 3：检查池（自动审计）
- Layer 4：Stage 边界（隔离）

### 7.7 失败即停 + 升级
- 卡住 ≤ 5 分钟：自查修复
- 卡住 5-15 分钟：查 error-catalog.md
- 卡住 > 15 分钟：**停下来问用户**，不准猜

### 7.8 重启策略
会话切换时（用户说"继续"/"接着做"/"开始新对话"）：
1. 读本文件 §2 必读清单（5 个文件）
2. 读当前 daily
3. 读 `CONTROL_TOWER.md` 决策表
4. 问用户 1 句话："现在到哪了？"
5. 不准假设上下文连续

---

## 8. 协作架构速查（6 角色 / 3 会话 / 6 模式）

| 角色 | 身份 | 何时启用 |
|---|---|---|
| **指挥官** 👑 | 用户（你） | 全程，最终决策 |
| **大副** ⚙️ | 我（Claude 主对话） | 全程执行 + 协调 |
| **架构师** 🏛️ | Stage 6+ 启用 | Drift schema / 模块边界 |
| **苹果匠** 🍎 | Stage 1+ 启用 | Swift/Pigeon/原生 API |
| **攒攒师** 🤖 | Stage 7+ 启用 | LLM prompt / 异常检测 |
| **督察** 🔍⚖️ | Stage ROA 启用 | 代码审计 / 找 BUG |

详细见 `docs/governance/roles.md` + `docs/collaboration-architecture.html`

---

## 9. 关键技术决策（不可重新讨论）

| 决策 | 内容 | 见 |
|---|---|---|
| 技术栈 | Flutter + Riverpod + Drift + SQLCipher | ADR-0001 |
| 项目结构 | Feature-based Clean Architecture | ADR-0002 |
| 测试策略 | 70/20/10 金字塔 + 关键模块 100% | ADR-0003 |
| 部署路线 | AltStore + GitHub Actions（0 成本）| ROADMAP.md |
| iOS 最低版本 | iOS 16+ | product-design-v4.html |
| 数据加密 | SQLCipher + Keychain | ADR-0001 + Stage 6 |
| 离线优先 | 本地数据库为主，无网络同步 | product-design-v4.html |

**重新讨论任一项必须先开 ADR 替换原决策。**

---

## 10. 文件组织（AI 写入位置速查）

| 类型 | 位置 | 命名 |
|---|---|---|
| 代码 | `lib/` | `feature_type/name.dart` |
| 测试 | `test/` | `*_test.dart`（与 lib 镜像）|
| Widget 测试 | `test/widget/` | `feature_widget_test.dart` |
| 集成测试 | `test/integration/` | `user_journey_test.dart` |
| 文档 | `docs/` | 见各子目录规则 |
| 临时文件 | `.ai-work/` | 任务结束删 |
| 配置文件 | 项目根 | 不要乱改（见 §11）|
| 密钥 | 不进 git | 用 GitHub Secrets / Keychain |

---

## 11. 禁止修改的配置文件

参考全局 CLAUDE.md"核心配置文件保护"，本项目额外保护：

```
package.json / pubspec.yaml        # 依赖锁版本
ios/Runner/Info.plist              # iOS 配置（影响发布）
.github/workflows/*.yml            # CI 配置（影响发布）
docs/CONTROL_TOWER.md              # 派生，不手填
product-design-v4.html             # 产品真源（已脱敏）
.github/CODEOWNERS                 # 权限
.gitignore
```

**修改任何一项前必须**：
1. 备份原文件
2. 写 Decision Request 解释原因
3. 用户明确同意

---

## 12. 紧急情况处理

### 情况 A：AI 不按要求做
1. 用户立即说"停"
2. AI 立即停手
3. 读 `CONTROL_TOWER.md` 看当前进度
4. 列出"我刚才做了什么" + "下一步应该做什么"
5. 用户决策：继续 / 回滚 / 改方案

### 情况 B：AI 暴露隐私信息
1. 立即删除 + git revert
2. 用户审查 git log
3. 写 Decision Request 改进流程
4. 如已推送 GitHub，标记为私密 repo / 联系 GitHub Support

### 情况 C：build / test 失败
1. 读错误信息（不准猜）
2. 查 `docs/governance/error-catalog.md`
3. 仍未解决 → 写 DR 问用户

### 情况 D：用户判断"AI 跑偏了"
1. 信任用户判断（用户是 Owner）
2. 立即停手 + 读上下文
3. 列出当前状态让用户核对
4. 按用户指示调整

---

## 13. 与其他文件的关系

| 文件 | 与本文件的关系 |
|---|---|
| `MEMORY.md` | 本文件的项目级摘要，自动加载 |
| `docs/README.md` | 文档目录索引，新人导航 |
| `docs/CONTROL_TOWER.md` | 当前状态真源（派生）|
| `docs/PLAN.md` | 实施计划真源 |
| `docs/governance/` | 详细规范（本文件是入口，详细看这）|
| `docs/adr/` | 决策记录（不可逆）|
| `docs/templates/` | 创建新文件时复制 |
| `docs/daily/` | 每日工作日志 |

---

## 14. 文档版本与维护

- **当前版本**：v1.0（2026-07-14）
- **维护者**：Claude（执行）+ 用户（决策）
- **变更方式**：本文件变更必须写 ADR（**CLAUDE-XXX** 编号），不允许静默修改
- **下次复审**：Stage 0 完成时（2026-07-17 之后）

---

## 15. 一句话总结

> **进入本项目，先读本文件 + CONTROL_TOWER + 今天 daily；不读不动手；不写不在 write-set 的文件；不通过 ROA 不进下一 Stage；卡住就问，不准猜；失败即停；每日 commit。**

---

**最后更新**：2026-07-14 · 创建 v1.0
**下次更新**：Stage 0 ROA 后补充实战经验
