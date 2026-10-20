import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';
import 'glass.dart';

class TrustBadge extends StatelessWidget {
  const TrustBadge(
      {super.key,
      required this.level,
      this.score,
      this.compact = false,
      this.short = false});

  final String level;
  final double? score;
  final bool compact;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final color = trustColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 13, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 18)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 9)
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            '${short ? 'TRUST' : 'DATA TRUST'} · ${level.toUpperCase()}',
            style: TfType.label(color: color, size: compact ? 9 : 9.5),
          ),
          if (score != null) ...[
            const SizedBox(width: 7),
            Text(
              '${score!.round()}',
              style: TfType.mono(compact ? 11 : 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class TrustRing extends StatelessWidget {
  const TrustRing({
    super.key,
    required this.score,
    required this.level,
    this.size = 178,
    this.strokeWidth = 10,
    this.child,
  });

  final double? score;
  final String level;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = trustColor(level);
    final target = ((score ?? 0) / 100).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: motionDuration(context, const Duration(milliseconds: 1100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _TrustRingPainter(
                progress: value, color: color, strokeWidth: strokeWidth),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  const _TrustRingPainter(
      {required this.progress, required this.color, required this.strokeWidth});

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.055),
    );

    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 6
      ..color = color.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.45),
          color,
          Colors.white.withValues(alpha: 0.9)
        ],
        stops: const [0, 0.7, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

    final dotAngle = -math.pi / 2 + sweep;
    final dot =
        center + Offset(math.cos(dotAngle), math.sin(dotAngle)) * radius;
    canvas.drawCircle(
      dot,
      4.5,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawCircle(dot, 2.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrustRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class TrustExplainer extends StatelessWidget {
  const TrustExplainer({super.key, required this.trust});

  final TrustInfo trust;

  @override
  Widget build(BuildContext context) {
    final color = trustColor(trust.level);
    if (trust.flags.isEmpty) {
      return GlassPanel(
        padding: const EdgeInsets.all(TfSpace.md),
        radius: TfRadius.md,
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All sensor checks passed. Advice is safe to follow.',
                style: TfType.body(12.5, color: TfColors.textDim),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final flag in trust.flags.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(TfRadius.sm),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(flag.message,
                        style: TfType.body(12.5, color: TfColors.textDim)),
                  ),
                  const SizedBox(width: 6),
                  Text(flag.code, style: TfType.label(size: 8.5, color: color)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AlertSeverityBadge extends StatelessWidget {
  const AlertSeverityBadge({super.key, required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(severity.toUpperCase(),
          style: TfType.label(color: color, size: 8.5)),
    );
  }
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
    case 'high':
      return TfColors.red;
    case 'warning':
    case 'medium':
      return TfColors.amber;
    default:
      return TfColors.cyan;
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TfType.body(10.5, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class RelativeTimestamp extends StatelessWidget {
  const RelativeTimestamp(
      {super.key, required this.time, this.prefix = 'Updated'});

  final DateTime? time;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Text(
      time == null ? '$prefix —' : '$prefix ${timeAgo(time)}',
      style: TfType.body(11, color: TfColors.textMuted),
    );
  }
}
