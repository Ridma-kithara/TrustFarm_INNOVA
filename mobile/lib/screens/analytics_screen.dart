import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';
import '../widgets/charts.dart';
import '../widgets/glass.dart';
import '../widgets/layout.dart';
import '../widgets/states.dart';
import '../widgets/trust.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return PagePadding(
      maxWidth: 1500,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        color: TfColors.mint,
        backgroundColor: TfColors.surfaceHigh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: pageBottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Field analytics',
                subtitle:
                    'Sensor history · ${controller.selectedZone?.name ?? 'zone'}',
              ),
              const SizedBox(height: 14),
              _RangeChips(controller: controller),
              if (controller.offline) ...[
                const SizedBox(height: 12),
                OfflineBanner(
                  cachedAt: controller.cachedAt,
                  retrying: controller.refreshing,
                  onRetry: controller.refresh,
                ),
              ],
              if (controller.refreshing) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    minHeight: 2,
                    color: TfColors.mint,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (controller.loading && !controller.hasData)
                const _AnalyticsSkeleton()
              else if (controller.error != null && controller.readings.isEmpty)
                SizedBox(
                  height: 320,
                  child: ErrorState(
                      message: controller.error!, onRetry: controller.refresh),
                )
              else
                _AnalyticsBody(
                    controller: controller, range: controller.rangeHours),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.controller});

  final AppController controller;

  static const options = [6, 12, 24, 72, 168];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 15, color: TfColors.textMuted),
          const SizedBox(width: 9),
          for (final hours in options) ...[
            _RangeChip(
              label: rangeLabel(hours),
              selected: controller.rangeHours == hours,
              onTap: () => controller.setRange(hours),
            ),
            const SizedBox(width: 7),
          ],
          const SizedBox(width: 3),
          if (controller.readings.isNotEmpty)
            Text(
              '${controller.readings.length} samples',
              style: TfType.body(10, color: TfColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Show $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: motionDuration(context, TfMotion.fast),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? TfColors.mint.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(TfRadius.pill),
            border: Border.all(
                color: selected
                    ? TfColors.mint.withValues(alpha: 0.4)
                    : TfColors.line),
          ),
          child: Text(
            label,
            style: TfType.body(
              11,
              color: selected ? TfColors.mint : TfColors.textMuted,
              weight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.controller, required this.range});

  final AppController controller;
  final int range;

  @override
  Widget build(BuildContext context) {
    final readings = controller.readings;
    final sampled = _sample(readings);
    final soil = [
      ChartSeries(
          label: 'Probe 1',
          color: TfColors.mint,
          values: sampled.map((r) => r.soil1).toList()),
      ChartSeries(
          label: 'Probe 2',
          color: TfColors.cyan,
          values: sampled.map((r) => r.soil2).toList()),
    ];
    final energy = [
      ChartSeries(
          label: 'Generation',
          color: TfColors.gold,
          values: sampled.map((r) => r.genW).toList()),
      ChartSeries(
          label: 'Load',
          color: TfColors.cyan,
          values: sampled.map((r) => r.loadW).toList()),
    ];
    final battery = [
      ChartSeries(
          label: 'State of charge',
          color: TfColors.mint,
          values: sampled.map((r) => r.battSoc).toList()),
    ];

    final soilAvg = _mean(readings.map((r) => r.soilAverage));
    final soilMin = _min(readings.map((r) => r.soilAverage));
    final soilMax = _max(readings.map((r) => r.soilAverage));
    final battAvg = _mean(readings.map((r) => r.battSoc));
    final genAvg = _mean(readings.map((r) => r.genW));
    final peakGen = _max(readings.map((r) => r.genW));
    final rainSum = readings.fold<double>(0, (sum, r) => sum + (r.rain ?? 0));
    final tempValues = sampled.map((r) => r.temp).toList();

    final soilPanel = _Panel(
      kicker: 'WATER',
      title: 'Soil moisture',
      subtitle: 'Both probes · last ${rangeLabel(range)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactRow(facts: [
            _Fact('Average', formatSoil(soilAvg), TfColors.mint),
            _Fact('Lowest', formatSoil(soilMin)),
            _Fact('Highest', formatSoil(soilMax)),
            _Fact(
                'Forecast',
                formatSoil(controller.status.recommendation.forecastSoil),
                TfColors.cyan),
          ]),
          const SizedBox(height: 12),
          ChartLegend(series: soil),
          const SizedBox(height: 10),
          TrendChart(
              series: soil,
              readings: sampled,
              ySuffix: '%',
              decimals: 1,
              height: 210),
        ],
      ),
    );

    final energyPanel = _Panel(
      kicker: 'ENERGY',
      title: 'Power balance',
      subtitle: 'Generation, load and battery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RadialGauge(
                value: controller.status.reading?.battSoc,
                label: 'SOC',
                color: TfColors.mint,
                size: 92,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InlineValue(
                        label: 'Generation avg',
                        value: formatPower(genAvg),
                        color: TfColors.gold),
                    const SizedBox(height: 8),
                    _InlineValue(
                        label: 'Peak generation',
                        value: formatPower(peakGen),
                        color: TfColors.gold),
                    const SizedBox(height: 8),
                    _InlineValue(
                      label: 'Energy mode',
                      value: energyModeLabel(controller.status.energy.mode),
                      color: TfColors.cyan,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChartLegend(series: energy),
          const SizedBox(height: 8),
          TrendChart(
              series: energy,
              readings: sampled,
              ySuffix: ' W',
              decimals: 0,
              height: 150),
        ],
      ),
    );

    final batteryPanel = _Panel(
      kicker: 'STORAGE',
      title: 'Battery reserve',
      subtitle: 'State of charge across the window',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactRow(facts: [
            _Fact('Average', formatPercent(battAvg), TfColors.mint),
            _Fact('Latest', formatPercent(controller.status.reading?.battSoc),
                TfColors.cyan),
            _Fact(
                'Voltage',
                controller.status.reading?.battV == null
                    ? '—'
                    : '${controller.status.reading!.battV!.toStringAsFixed(1)} V'),
            _Fact('Surplus', formatPower(controller.status.energy.surplusW),
                TfColors.gold),
          ]),
          const SizedBox(height: 10),
          TrendChart(
            series: battery,
            readings: sampled,
            ySuffix: '%',
            decimals: 0,
            minY: 0,
            maxY: 100,
            height: 138,
          ),
        ],
      ),
    );

    final trustPanel = _Panel(
      kicker: 'INTEGRITY',
      title: 'Trust timeline',
      subtitle:
          'Server-scored history · ${controller.trustHistory.length} checks',
      trailing: TrustBadge(
        level: controller.status.trust.level,
        score: controller.status.trust.score,
        compact: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrustTimeline(points: controller.trustHistory, height: 62),
          const SizedBox(height: 14),
          TrustExplainer(trust: controller.status.trust),
          const SizedBox(height: 12),
          Text(
            'Scores combine freshness, range, stuck/jump detection, sensor agreement, rain response '
            'and a learned anomaly model. Amber and Red levels gate irrigation advice.',
            style: TfType.body(10.5, color: TfColors.textMuted)
                .copyWith(height: 1.55),
          ),
        ],
      ),
    );

    final environmentPanel = _Panel(
      kicker: 'FIELD',
      title: 'Environment',
      subtitle: 'Air, rain and water movement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactRow(facts: [
            _Fact('Temperature', formatTemp(controller.status.reading?.temp),
                TfColors.gold),
            _Fact('Humidity', formatPercent(controller.status.reading?.hum),
                TfColors.cyan),
            _Fact('Rain in window', '${rainSum.toStringAsFixed(1)} mm',
                TfColors.cyan),
            _Fact(
              'Flow',
              controller.status.reading?.flow == null
                  ? '—'
                  : '${controller.status.reading!.flow!.toStringAsFixed(1)} L/m',
              TfColors.mint,
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: Text('Temperature history',
                      style: TfType.body(10.5, color: TfColors.textMuted))),
              Text(
                controller.status.reading?.temp == null
                    ? '—'
                    : '${controller.status.reading!.temp!.toStringAsFixed(1)}°C now',
                style: TfType.mono(11, color: TfColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Sparkline(values: tempValues, color: TfColors.gold, height: 54),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(TfRadius.sm),
              border: Border.all(color: TfColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    size: 14, color: TfColors.cyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.status.recommendation.reason.isEmpty
                        ? 'Irrigation advice appears when a trusted forecast is available.'
                        : controller.status.recommendation.reason,
                    style: TfType.body(10.5, color: TfColors.textMuted)
                        .copyWith(height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              soilPanel,
              const SizedBox(height: 14),
              energyPanel,
              const SizedBox(height: 14),
              batteryPanel,
              const SizedBox(height: 14),
              environmentPanel,
              const SizedBox(height: 14),
              trustPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  soilPanel,
                  const SizedBox(height: 14),
                  environmentPanel,
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  energyPanel,
                  const SizedBox(height: 14),
                  batteryPanel,
                  const SizedBox(height: 14),
                  trustPanel,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Reading> _sample(List<Reading> input) {
    if (input.length <= 300) return input;
    final step = input.length / 300;
    return [
      for (var i = 0; i < 299; i++) input[(i * step).floor()],
      input.last,
    ];
  }

  double? _mean(Iterable<double?> values) {
    final visible = values.whereType<double>().toList();
    if (visible.isEmpty) return null;
    return visible.reduce((a, b) => a + b) / visible.length;
  }

  double? _min(Iterable<double?> values) {
    final visible = values.whereType<double>().toList();
    if (visible.isEmpty) return null;
    return visible.reduce(math.min);
  }

  double? _max(Iterable<double?> values) {
    final visible = values.whereType<double>().toList();
    if (visible.isEmpty) return null;
    return visible.reduce(math.max);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
              title: title,
              subtitle: subtitle,
              kicker: kicker,
              trailing: trailing),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value, [this.color]);

  final String label;
  final String value;
  final Color? color;
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 2 : facts.length;
        final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final fact in facts)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fact.label.toUpperCase(),
                        style: TfType.label(size: 6.8)),
                    const SizedBox(height: 4),
                    Text(
                      fact.value,
                      style:
                          TfType.mono(13, color: fact.color ?? TfColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InlineValue extends StatelessWidget {
  const _InlineValue(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Expanded(
            child: Text(label,
                style: TfType.body(10.5, color: TfColors.textMuted))),
        Text(value, style: TfType.mono(10.5, color: TfColors.textDim)),
      ],
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerBox(height: 58, radius: TfRadius.pill),
        const SizedBox(height: 18),
        ShimmerBox(height: 330, radius: TfRadius.lg),
        const SizedBox(height: 14),
        ShimmerBox(height: 330, radius: TfRadius.lg),
      ],
    );
  }
}
