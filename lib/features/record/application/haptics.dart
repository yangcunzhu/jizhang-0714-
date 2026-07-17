import 'package:vibration/vibration.dart';

/// 触觉反馈公共入口(Day 8 抽出)。
///
/// WHY: 原本 `recordFormProvider.submit()` 内联 Vibration.vibrate(50) — 难测
/// 难统一。现在两档语义清晰:
///   - [light] (50ms):输入确认(点分类、点数字)
///   - [heavy] (100ms):成功完成(保存成功、删除成功、退款成功)
///
/// fire-and-forget + 吞错:
///   - 模拟器无振动器 → Vibration.hasVibrator() 返回 false,直接跳过
///   - iPhone 静音模式 → 短振仍触发,长振可能被系统忽略,不影响业务
///   - 不阻塞主流程(返回 `Future<void>` 但调用方一般不 await)
class Haptics {
  Haptics._();

  static const _lightMs = 50;
  static const _heavyMs = 100;

  static Future<void> light() => _vibrate(_lightMs);
  static Future<void> heavy() => _vibrate(_heavyMs);

  static Future<void> _vibrate(int durationMs) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: durationMs);
      }
    } catch (_) {
      // 振动失败不阻断业务;真机静默,模拟器抛异常都吞掉
    }
  }
}