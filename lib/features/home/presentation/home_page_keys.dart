import 'package:flutter/material.dart';

/// 主页 FAB 的 GlobalKey — Day 9 攒攒动画的全局发射点。
///
/// WHY 单独文件:
///   - ConfettiBurst.fire 需要 GlobalKey 才能在 widget tree 外 findRenderObject
///   - ActionSheet 在 home 上下文 fire 动画时也需要同一发射点(让"删除/退款成功"
///     动画也回到 FAB 位置,视觉一致)
///   - 跨 home_page / transaction_actions_sheet 共享,放独立文件避免循环依赖
///
/// 单一发射点而不是每笔交易一个 key:
///   - 主页 ListView.builder 每行 GlobalKey 需缓存 + 清理,易内存泄漏
///   - 视觉上 FAB 是用户的"入口",所有成功动画回到入口形成闭环
final GlobalKey recordFabKey = GlobalKey(debugLabel: 'record-fab');