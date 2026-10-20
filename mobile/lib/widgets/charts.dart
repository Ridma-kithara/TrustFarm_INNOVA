import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';

class ChartSeries {
  const ChartSeries(
      {required this.label, required this.color, required this.values});

  final String label;
  final Color color;
  final List<double?> values;
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.readings,
    this.height = 190,
    this.ySuffix = '',
    this.decimals = 0,
    this.minY,
    this.maxY,
    this.fillFirst = true,
  });

  final List<ChartSeries> series;
  final List<Reading> readings;
  final double height;
  final String ySuffix;
  final int decimals;
  final double? minY;
  final double? maxY;
  final bool fillFirst;

  @override
  Widget build(BuildContext context) {
    final visible =
        series.where((s) => s.values.any((v) => v != null)).toList();
    if (visible.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No readings in this window',
              style: TfType.body(12, color: TfColors.textMuted)),
        ),
      );
    }

    final allValues = <double>[
      for (final s in visible)
        for (final value in s.values)
          if (value != null) value,
    ];
    var low = minY ?? allValues.reduce(math.min);
    var high = maxY ?? allValues.reduce(math.max);
    if (high - low < 1) {
      high += 1;
      low -= 1;
    }
    final pad = (high - low) * 0.12;
    low = low - pad;
    high = high + pad;

    final lineBars = <LineChartBarData>[];
    for (var index = 0; index < visible.length; index++) {
      final item = visible[index];
      final spots = <FlSpot>[];
      for (var i = 0; i < item.values.length; i++) {
        final value = item.values[i];
        if (value != null) spots.add(FlSpot(i.toDouble(), value));
      }
      if (spots.isEmpty) continue;
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.24,
          preventCurveOverShooting: true,
          color: item.color,
          barWidth: 2.1,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          shadow:
              Shadow(color: item.color.withValues(alpha: 0.35), blurRadius: 8),
          belowBarData: BarAreaData(
            show: fillFirst && index == 0,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                item.color.withValues(alpha: 0.22),
                item.color.withValues(alpha: 0)
              ],
            ),
          ),
        ),
      );
    }

    final labelCount = math.max(2, math.min(4, readings.length));
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, readings.length - 1).toDouble(),
          minY: low,
          maxY: high,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (high - low) / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: (high - low) / 3,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${value.round()}$ySuffix',
                    style: TfType.body(9, color: TfColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: readings.length <= 1
                    ? 1
                    : (readings.length - 1) / (labelCount - 1),
                getTitlesWidget: (value, meta) {
                  final index = value.round().clamp(0, readings.length - 1);
                  final time = readings[index].ts;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatClock(time),
                      style: TfType.body(8.5, color: TfColors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => const Color(0xF20B1718),
              tooltipBorder: BorderSide(color: TfColors.lineStrong),
              tooltipRoundedRadius: 10,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${visible[spot.barIndex].label}  ${spot.y.toStringAsFixed(decimals)}$ySuffix',
                      TfType.body(10.5,
                          color: visible[spot.barIndex].color,
                          weight: FontWeight.w600),
                    ),
                ];
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) => [
              for (final _ in spotIndexes)
                TouchedSpotIndicatorData(
                  FlLine(
                      color: barData.color!.withValues(alpha: 0.4),
                      strokeWidth: 1),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: bar.color ?? TfColors.mint,
                      strokeWidth: 0,
                    ),
                  ),
                ),
            ],
            handleBuiltInTouches: true,
          ),
          lineBarsData: lineBars,
        ),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.series});

  final List<ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final item in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                        color: item.color.withValues(alpha: 0.5), blurRadius: 5)
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(item.label,
                  style: TfType.body(10, color: TfColors.textMuted)),
            ],
          ),
      ],
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 38,
  });

  final List<double?> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child:
          CustomPaint(painter: _SparklinePainter(values: values, color: color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final visible = <double>[];
    for (final value in values) {
      if (value != null) visible.add(value);
    }
    if (visible.length < 2) return;
    final low = visible.reduce(math.min);
    final high = visible.reduce(math.max);
    final span = (high - low).abs() < 0.01 ? 1.0 : high - low;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      final x = size.width * (i / (values.length - 1));
      final y = size.height -
          ((value - low) / span) * size.height * 0.82 -
          size.height * 0.09;
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25),
    );
    canvas.drawCircle(points.last, 2.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class TrustTimeline extends StatefulWidget {
  const TrustTimeline({super.key, required this.points, this.height = 54});

  final List<TrustPoint> points;
  final double height;

  @override
  State<TrustTimeline> createState() => _TrustTimelineState();
}

class _TrustTimelineState extends State<TrustTimeline> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('No trust history yet',
              style: TfType.body(11, color: TfColors.textMuted)),
        ),
      );
    }
    final selected = _selected == null
        ? null
        : widget.points[_selected!.clamp(0, widget.points.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final index = (details.localPosition.dx /
                          constraints.maxWidth *
                          widget.points.length)
                      .floor()
                      .clamp(0, widget.points.length - 1);
                  setState(() => _selected = index);
                },
                child: CustomPaint(
                  painter: _TimelinePainter(
                      points: widget.points, selected: _selected),
                  size: Size(constraints.maxWidth, widget.height),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                selected == null
                    ? 'Tap the timeline to inspect a moment'
                    : '${formatDateTime(selected.ts)} · ${selected.level} · ${selected.score.round()}/100',
                style: TfType.body(10.5,
                    color: selected == null
                        ? TfColors.textMuted
                        : trustColor(selected.level)),
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: () => setState(() => _selected = null),
                child: Text('clear',
                    style: TfType.body(10.5, color: TfColors.textMuted)),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({required this.points, required this.selected});

  final List<TrustPoint> points;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final width = size.width;
    final segmentWidth = width / points.length;
    final rect = Rect.fromLTWH(0, 8, width, size.height - 22);
    final radius = Radius.circular(rect.height / 2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));
    for (var i = 0; i < points.length; i++) {
      final color = trustColor(points[i].level);
      final left = rect.left + segmentWidth * i;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)],
        ).createShader(
            Rect.fromLTWH(left, rect.top, segmentWidth + 1, rect.height));
      canvas.drawRect(
          Rect.fromLTWH(left, rect.top, segmentWidth + 0.6, rect.height),
          paint);
    }
    canvas.restore();

    if (selected != null) {
      final x = rect.left + segmentWidth * (selected! + 0.5);
      canvas.drawLine(
        Offset(x, rect.top - 3),
        Offset(x, rect.bottom + 3),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        Offset(x, rect.bottom + 5),
        2.4,
        Paint()..color = trustColor(points[selected!].level),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.selected != selected;
}

class RadialGauge extends StatelessWidget {
  const RadialGauge({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.size = 96,
    this.min = 0,
    this.max = 100,
  });

  final double? value;
  final String label;
  final Color color;
  final double size;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final progress =
        value == null ? 0.0 : ((value! - min) / (max - min)).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: motionDuration(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(progress: animated, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value == null ? '—' : '${value!.round()}%',
                    style: TfType.mono(18),
                  ),
                  Text(label,
                      style: TfType.label(size: 8, color: TfColors.textMuted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
