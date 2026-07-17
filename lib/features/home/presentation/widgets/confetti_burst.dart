import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 攒攒反馈动画 — 极简光点(Stage 1 Day 9 基础版)。
///
/// 设计:6 个主题色光点从 origin 向 6 方向扩散 + 渐隐 + 微缩。
/// - 持续 500ms(easeOutCubic)
/// - 半径扩散 60-100 px
/// - 半径缩 30% 让光点有"散开感"
/// - 不引第三方,纯 CustomPainter
///
/// 触发:记账成功 / 退款成功 / 删除成功后调用 [ConfettiBurst.fire]。
///
/// WHY 走 Overlay:
///   - 不污染主页 widget tree(动画完成后 OverlayEntry 自动 remove)
///   - 动画不参与主页 rebuild,不影响 transactionListProvider 的实时刷新
///   - 跨 Navigator 路由也能 fire(在 ActionSheet 内 fire,画在主页上)
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.origin,
    required this.color,
    this.onComplete,
  });

  /// 全局坐标(origin 在屏幕坐标系中的位置)。
  final Offset origin;

  /// 光点颜色(默认从主题色取)。
  final Color color;

  /// 动画结束回调(通常用来移除 OverlayEntry)。
  final VoidCallback? onComplete;

  /// 在指定 anchor 位置触发一次 burst。
  ///
  /// [originKey] 是触发源 Widget 的 GlobalKey(如 record-fab / txn-action-delete)，
  /// 动画从该 Widget 中心点发射。
  /// [color] 可选,默认用主题 primary 色。
  ///
  /// 找不到 originKey 对应的 RenderBox 时静默返回(常见情况:Widget 已被 dispose)。
  static void fire(
    BuildContext context, {
    required GlobalKey originKey,
    Color? color,
  }) {
    final renderBox =
        originKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final origin = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: ConfettiBurst(
            origin: origin,
            color: resolvedColor,
            onComplete: () {
              if (entry.mounted) entry.remove();
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    // 6 个粒子均匀分布 + 随机抖动,避免机械感
    _particles = List.generate(6, (i) {
      final baseAngle = (i / 6) * 2 * math.pi;
      final jitter = (rng.nextDouble() - 0.5) * 0.6; // ±0.3 弧度 ≈ ±17°
      return _Particle(
        angle: baseAngle + jitter,
        distance: 60 + rng.nextDouble() * 40, // 60-100 px
        size: 4 + rng.nextDouble() * 4, // 4-8 px 半径
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BurstPainter(
          origin: widget.origin,
          color: widget.color,
          particles: _particles,
          progress: _controller,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
  });

  final double angle;
  final double distance;
  final double size;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.origin,
    required this.color,
    required this.particles,
    required this.progress,
  }) : super(repaint: progress);

  final Offset origin;
  final Color color;
  final List<_Particle> particles;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t >= 1.0) return;

    // easeOutCubic: 1 - (1 - t)^3 → 起步快,收尾慢
    final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();
    // 透明度线性递减
    final opacity = 1.0 - t;
    // 半径略微收缩(从 1.0 → 0.7),强化"散开"感
    final radiusScale = 1.0 - 0.3 * t;

    final paint = Paint()..color = color.withValues(alpha: opacity);

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.distance * eased;
      final dy = math.sin(p.angle) * p.distance * eased;
      final center = origin + Offset(dx, dy);
      canvas.drawCircle(center, p.size * radiusScale, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => false;
}