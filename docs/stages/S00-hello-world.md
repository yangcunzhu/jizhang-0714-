# Stage 0: 环境验证 + Hello World

> stage_id: **S00-hello-world**
> stage_kind: `IMPLEMENT`
> 风险等级: **M**（中等，关键路径验证）
> 审议方式: `SELF_CHECK`
> 授权状态: ⏳ **DRAFT → READY**（待用户授权）
> 计划工期: 3 天（Day 1-3）
> 计划工时: ~30 小时

---

## 🎯 Goal

**跑通完整的 0 成本开发链路**：Windows 11 → VS Code → GitHub → GitHub Actions（macOS runner）→ .ipa → AltStore → iPhone 真机

**用户结果**：在 iPhone 上看到 "Hello 审计官" 应用图标，点击启动看到欢迎界面，证明整套 0 成本方案可行。

---

## 📋 Context

### 已批准决策
- ADR-0001：Flutter 技术栈
- PLAN.md：W1 (S00) 工时 ~30h
- 用户时间：每天 12-16 小时，平均 13h
- 部署方案：GitHub Actions + AltStore

### 当前状态
- Windows 11 开发机已就绪
- Apple ID：用户待确认是否专门注册
- 旧电脑：用户待确认是否准备好常开
- GitHub 账户：用户待创建

### 关键依赖
- Flutter SDK 3.24+
- Dart 3.5+
- Git
- VS Code + Flutter 插件
- GitHub 账户
- Apple ID（用于 AltStore）
- iPhone + Lightning/USB-C 数据线

---

## 🚧 In Scope

### 必须完成
1. ✅ 安装 Flutter SDK（Windows）
2. ✅ 安装 VS Code + Flutter/Dart 插件
3. ✅ 配置 Git（用户名、邮箱）
4. ✅ 创建 GitHub 私有仓库 `jizhang-app`
5. ✅ `flutter create` 生成 Hello World 项目
6. ✅ 项目结构按 PLAN.md § 36 章节规划
7. ✅ 提交到 GitHub
8. ✅ 配置 GitHub Actions workflow（macOS runner）
9. ✅ 配置 Apple 证书 + Provisioning Profile
10. ✅ Workflow 跑通（产出 .ipa）
11. ✅ 下载 .ipa + AltStore 安装到 iPhone
12. ✅ 真机启动 + 显示 "Hello 审计官"
13. ✅ 配置 AltServer（家里旧电脑常开）

### 不做（明确排除）
- ❌ 写任何业务代码
- ❌ 数据库初始化
- ❌ 任何 UI 设计
- ❌ iOS 原生桥接
- ❌ 单元测试（Hello World 项目不需要）

---

## 🚫 Out of Scope

- S01 及以后的所有功能
- Android 平台
- 性能优化
- 国际化

---

## 📂 允许文件（write-set）

```
E:\jizhang-0714\
├── README.md                    （新建）
├── .gitignore                   （新建）
├── pubspec.yaml                 （flutter create 生成）
├── lib/                         （flutter create 生成）
│   └── main.dart                （修改为显示 Hello 审计官）
├── ios/                         （flutter create 生成）
│   └── Runner/
│       ├── Info.plist           （修改应用名）
│       └── ...
├── android/                     （flutter create 生成，不上传）
├── .github/
│   └── workflows/
│       └── build-ios.yml        （新建）
├── docs/
│   └── daily/
│       └── 2026-07-15.md        （新建）
└── ...
```

**禁止写入**：
- ❌ `E:\jizhang-0714\product-design-v4.html`（产品方案，未授权不可改）
- ❌ `E:\jizhang-0714\docs\PLAN.md`（主计划，未授权不可改）
- ❌ `E:\jizhang-0714\docs\ROADMAP.md`（同上）

---

## 🎯 Done When

### 功能验收
- [ ] iPhone 真机启动 App，显示 "Hello 审计官" 文字
- [ ] App 图标可见
- [ ] 点击图标能正常启动
- [ ] GitHub Actions workflow 跑通（绿勾）
- [ ] 产出 .ipa 文件可下载
- [ ] AltStore 成功安装到 iPhone

### 技术验收
- [ ] `flutter doctor` 0 警告
- [ ] `flutter analyze` 通过
- [ ] `flutter test` 默认测试通过
- [ ] Git 提交历史清晰
- [ ] .gitignore 配置正确（不含 build/、.dart_tool/）

### 文档验收
- [ ] daily/2026-07-15.md 完成（Day 1）
- [ ] daily/2026-07-16.md 完成（Day 2）
- [ ] daily/2026-07-17.md 完成（Day 3）
- [ ] CONTROL_TOWER 更新到 Stage 0 DONE
- [ ] S00 Stage 结束卡完成

---

## ⚠️ 风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| Flutter SDK 下载慢/失败 | 🟡 中 | 用清华镜像（FLUTTER_STORAGE_BASE_URL） |
| GitHub Actions macOS runner 排队 | 🟢 低 | 等待或换时间触发 |
| Apple 证书导入失败 | 🟡 中 | 详细步骤在 daily 文件，按步骤操作 |
| AltStore 配对失败 | 🟡 中 | 重启 AltServer + 重新配对 |
| iPhone 不信任证书 | 🟢 低 | 设置 → 通用 → VPN 与设备管理 → 信任 |
| 网络问题（GitHub / Apple） | 🟡 中 | 备用网络（如手机热点） |

---

## 🔍 验证矩阵

| 场景 | 命令/操作 | 预期 |
|---|---|---|
| Flutter 安装 | `flutter --version` | 3.24+ |
| 环境检查 | `flutter doctor` | 0 警告 |
| 项目创建 | `flutter create .` | 成功 |
| 本地运行 | `flutter run -d chrome` | Web 启动 Hello World |
| 代码分析 | `flutter analyze` | 0 错误 |
| 单元测试 | `flutter test` | PASS |
| Git 提交 | `git log --oneline` | 清晰历史 |
| GitHub Actions | 仓库 Actions tab | 绿勾 |
| iPhone 安装 | AltStore My Apps | 显示已安装 |

---

## 📅 时间切片（3 天）

### Day 1 (2026-07-15) - 环境搭建
- 09:00-10:00 安装 Flutter SDK + 配置 PATH
- 10:00-11:00 安装 VS Code + 插件
- 11:00-12:00 Git 配置 + GitHub 仓库
- 13:00-14:00 `flutter create` + 项目结构整理
- 14:00-16:00 修改 main.dart 为 Hello 审计官
- 16:00-17:00 flutter analyze + flutter test
- 18:00-19:00 提交到 GitHub
- 19:00-22:00 编写 GitHub Actions workflow
- **当日产出**: GitHub 仓库 + 可运行的 Hello World

### Day 2 (2026-07-16) - Actions 配置
- 09:00-12:00 GitHub Actions macOS runner 配置
- 13:00-15:00 Apple 证书生成 + 导入（Base64 编码）
- 15:00-17:00 Provisioning Profile 下载 + 编码
- 18:00-20:00 测试 workflow（触发 build）
- 20:00-22:00 下载 .ipa artifact 验证
- **当日产出**: 可下载的 .ipa 文件

### Day 3 (2026-07-17) - AltStore 部署
- 09:00-11:00 AltServer 安装（家里旧电脑）
- 11:00-13:00 iPhone USB 连接 + AltStore 配对
- 13:00-15:00 通过 AltStore 安装 .ipa
- 15:00-17:00 真机启动 + 截图验证
- 17:00-18:00 AltServer 续签机制配置
- 18:00-22:00 编写 Stage 0 结束卡 + 复盘
- **当日产出**: iPhone 上能启动的 Hello 审计官

---

## 🔄 交接（Handoff）

### Stage 0 → Stage 1 的交付物
- 完整可运行的 Flutter 项目（GitHub 仓库）
- GitHub Actions 流水线（自动编 .ipa）
- AltStore 安装链路（家里旧电脑常开）
- 用户验收：iPhone 看到 Hello 审计官

### Stage 1 准备
- 用户必须给出 Apple ID 凭证（在加密环境）
- 用户确认家里旧电脑已配置
- 用户准备 iPhone 数据线

### 文档同步
- [ ] CONTROL_TOWER 更新：S00 → DONE，S01 → ACTIVE
- [ ] daily/2026-07-17.md 写结束卡
- [ ] 创建 stages/S01-manual-record.md 授权包络
- [ ] 创建 daily/2026-07-18.md Day 4 计划

---

## 📝 备注

### 用户视角的成功标准
**非技术语言描述**：
- "我能在 iPhone 上看到一个新 App 叫 '审计官'"
- "点开能看到欢迎界面"
- "整个过程没花一分钱"
- "不需要 Mac 电脑"

### 技术视角的成功标准
- Flutter 项目结构符合 Clean Architecture
- GitHub Actions 流水线稳定（成功率 > 95%）
- .ipa 文件 < 30 MB
- AltStore 7 天自动续签机制跑通

---

**创建**：2026-07-14
**授权者**：用户（待批准）
**有效期**：2026-07-15 ~ 2026-07-17（3 天）
**base_sha**：待首次 git commit
