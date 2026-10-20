import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';
import '../threed/scene_data.dart';
import '../threed/scene_view.dart';
import '../threed/scenes/farm_scene.dart';
import '../widgets/alerts.dart';
import '../widgets/charts.dart';
import '../widgets/glass.dart';
import '../widgets/layout.dart';
import '../widgets/sheets.dart';
import '../widgets/states.dart';
import '../widgets/trust.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen(
      {super.key, required this.onOpenTwin, required this.onOpenAlerts});

  final VoidCallback onOpenTwin;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final firstName = (controller.user?.name ?? '')
            .trim()
            .split(RegExp(r'\s+'))
            .firstOrNull ??
        'Farmer';

    return PagePadding(
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
                title: '${greeting()}, $firstName',
                subtitle:
                    '${prettyDate(DateTime.now())} · ${controller.selectedZone?.name ?? 'field'} command deck',
              ),
              const SizedBox(height: 14),
              if (controller.offline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OfflineBanner(
                    cachedAt: controller.cachedAt,
                    retrying: controller.refreshing,
                    onRetry: controller.refresh,
                  ),
                )
              else if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InlineNotice(
                    message: controller.error!,
                    color: TfColors.amber,
                    icon: Icons.timeline_rounded,
                    action: TextButton(
                      onPressed: controller.refresh,
                      style:
                          TextButton.styleFrom(foregroundColor: TfColors.amber),
                      child: const Text('Retry',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              if (controller.loading && !controller.hasData)
                const _OverviewSkeleton()
              else ...[
                _DashboardGrid(
                  controller: controller,
                  onOpenTwin: onOpenTwin,
                  onOpenAlerts: onOpenAlerts,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({
    required this.controller,
    required this.onOpenTwin,
    required this.onOpenAlerts,
  });

  final AppController controller;
  final VoidCallback onOpenTwin;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final heroHeight =
            wide ? 404.0 : (constraints.maxWidth < 480 ? 300.0 : 340.0);
        final scene = _SceneHero(
            controller: controller, height: heroHeight, onOpenTwin: onOpenTwin);
        final advisory = _AdvisoryPanel(controller: controller);
        final energy = _EnergyPanel(controller: controller);
        final stats = _StatsGrid(controller: controller, columns: wide ? 4 : 2);
        final charts = _Charts(controller: controller, stack: !wide);
        final bottom = _BottomPanels(
            controller: controller,
            onOpenAlerts: onOpenAlerts,
            onOpenTwin: onOpenTwin);

        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        scene,
                        const SizedBox(height: 16),
                        stats,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 352,
                    child: Column(
                      children: [
                        advisory,
                        const SizedBox(height: 16),
                        energy,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              charts,
              const SizedBox(height: 22),
              bottom,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            scene,
            const SizedBox(height: 14),
            advisory,
            const SizedBox(height: 16),
            stats,
            const SizedBox(height: 16),
            energy,
            const SizedBox(height: 22),
            charts,
            const SizedBox(height: 22),
            bottom,
          ],
        );
      },
    );
  }
}

class _SceneHero extends StatelessWidget {
  const _SceneHero({
    required this.controller,
    required this.height,
    required this.onOpenTwin,
  });

  final AppController controller;
  final double height;
  final VoidCallback onOpenTwin;

  @override
  Widget build(BuildContext context) {
    final zone = controller.selectedZone;
    final recommendation = controller.status.recommendation;
    final trust = controller.status.trust;
    final wide = MediaQuery.sizeOf(context).width >= TfBreakpoints.mobile;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TfRadius.xl),
        border: Border.all(color: TfColors.lineStrong),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 44, offset: Offset(0, 22))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TfRadius.xl - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CinematicScene(
              builder: buildFarmScene,
              telemetry: sceneTelemetryFrom(controller),
              autoRotate: controller.autoRotate,
              reducedMotion: controller.reducedMotion,
              highQuality: controller.highQuality,
              showLabels: wide,
              compactLabels: true,
              initialYaw: 0.62,
              initialPitch: 0.35,
              initialDistance: 16.5,
              onHotspotTap: (hotspot) => showHotspotSheet(context, hotspot),
              semanticLabel:
                  'Live 3D digital twin of ${zone?.displayName ?? 'your farm'}',
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TfColors.ink.withValues(alpha: 0.78),
                      Colors.transparent,
                      Colors.transparent,
                      TfColors.ink.withValues(alpha: 0.88),
                    ],
                    stops: const [0, 0.25, 0.56, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 15,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Kicker('Live digital twin',
                              dotColor: TfColors.mint),
                          const SizedBox(height: 5),
                          Text(
                            '${zone?.farm ?? 'TrustFarm'} · ${zone?.name ?? 'Zone'}'
                            '${zone != null && zone.crop.isNotEmpty ? ' · ${zone.crop}' : ''}',
                            style: TfType.body(11,
                                color: TfColors.textDim,
                                weight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (wide)
                      TrustBadge(
                          level: trust.level,
                          score: trust.score,
                          compact: true),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recommendation.advice,
                            style: TfType.title(wide ? 19 : 17)
                                .copyWith(height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: controller.offline
                                      ? TfColors.amber
                                      : TfColors.mint,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (controller.offline
                                              ? TfColors.amber
                                              : TfColors.mint)
                                          .withValues(alpha: 0.7),
                                      blurRadius: 7,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.offline
                                      ? 'Showing last known state'
                                      : '${formatSoil(controller.status.reading?.soilAverage)} soil · '
                                          '${formatPercent(controller.status.reading?.battSoc)} battery · '
                                          '${timeAgo(controller.lastUpdated)}',
                                  style: TfType.body(9.5,
                                      color: TfColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TfButton(
                    label: 'Explore',
                    icon: Icons.open_in_full_rounded,
                    secondary: true,
                    onPressed: onOpenTwin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryPanel extends StatelessWidget {
  const _AdvisoryPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final recommendation = controller.status.recommendation;
    final trust = controller.status.trust;
    final color = trustColor(trust.level);
    final irrigate = recommendation.irrigate;
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      radius: TfRadius.lg,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF122B25), Color(0xFF0A1717)],
      ),
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Kicker('Today’s advisory')),
              StatusPill(
                label: irrigate ? 'IRRIGATE' : 'HOLD',
                color: irrigate ? TfColors.amber : TfColors.green,
                icon: irrigate
                    ? Icons.water_drop_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TrustRing(
                score: trust.score,
                level: trust.level,
                size: 116,
                strokeWidth: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trust.score == null ? '—' : '${trust.score!.round()}',
                      style: TfType.display(31, color: color),
                    ),
                    Text('TRUST', style: TfType.label(size: 6.5)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrustBadge(
                        level: trust.level, score: trust.score, compact: true),
                    const SizedBox(height: 10),
                    Text(
                      recommendation.advice,
                      style: TfType.title(18).copyWith(height: 1.28),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recommendation.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              recommendation.reason,
              style: TfType.body(11, color: TfColors.textMuted)
                  .copyWith(height: 1.55),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: TfColors.line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _MiniFact(
                      label: 'Need', value: needLabel(recommendation.need))),
              Expanded(
                  child: _MiniFact(
                      label: 'Forecast soil',
                      value: formatSoil(recommendation.forecastSoil))),
              Expanded(
                child: _MiniFact(
                  label: 'Energy',
                  value:
                      controller.status.energy.irrigationOk ? 'Ready' : 'Held',
                  color: controller.status.energy.irrigationOk
                      ? TfColors.mint
                      : TfColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showTrustReport(context),
              icon: const Icon(Icons.shield_outlined, size: 15),
              label: const Text('Why this advice?',
                  style:
                      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: TfColors.mint,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TfType.label(size: 6.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TfType.mono(12, color: color ?? TfColors.text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EnergyPanel extends StatelessWidget {
  const _EnergyPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final reading = controller.status.reading;
    final energy = controller.status.energy;
    final gen = reading?.genW ?? 0;
    final load = reading?.loadW ?? 0;
    final peak = math.max(1.0, math.max(gen, load));
    final modeColor = energy.mode.toUpperCase() == 'PROTECT'
        ? TfColors.amber
        : energy.mode.toUpperCase() == 'CHARGING'
            ? TfColors.mint
            : TfColors.cyan;
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Kicker('Farm energy', dotColor: TfColors.gold)),
              StatusPill(
                  label: energyModeLabel(energy.mode).toUpperCase(),
                  color: modeColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  formatPower(energy.surplusW),
                  style: TfType.display(27).copyWith(height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('surplus',
                    style: TfType.body(10, color: TfColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _EnergyBar(
              label: 'Generation',
              value: formatPower(gen),
              fraction: gen / peak,
              color: TfColors.gold),
          const SizedBox(height: 9),
          _EnergyBar(
              label: 'Farm load',
              value: formatPower(load),
              fraction: load / peak,
              color: TfColors.cyan),
          const SizedBox(height: 9),
          _EnergyBar(
            label: 'Battery',
            value: formatPercent(reading?.battSoc),
            fraction: ((reading?.battSoc ?? 0) / 100).clamp(0.0, 1.0),
            color: TfColors.mint,
          ),
          const SizedBox(height: 12),
          Text(
            energy.message,
            style: TfType.body(10.5, color: TfColors.textMuted)
                .copyWith(height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.settings_remote_outlined,
                  size: 12, color: TfColors.textMuted),
              const SizedBox(width: 5),
              Text('Monitored · manual control',
                  style: TfType.body(9, color: TfColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  const _EnergyBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: TfType.body(10, color: TfColors.textMuted))),
            Text(value, style: TfType.mono(10.5, color: TfColors.textDim)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Positioned.fill(
                    child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.05))),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                  duration: motionDuration(
                      context, const Duration(milliseconds: 700)),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: animated,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          boxShadow: [
                            BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.controller, required this.columns});

  final AppController controller;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final readings = controller.readings;
    final metrics = <_Metric>[
      _Metric(
        label: 'Soil moisture',
        value: controller.status.reading?.soilAverage,
        suffix: '%',
        decimals: 1,
        delta: _delta(readings.map((r) => r.soilAverage).toList()),
        values: readings.map((r) => r.soilAverage).toList(),
        color: TfColors.mint,
        icon: Icons.water_drop_outlined,
        deltaSuffix: ' pts',
      ),
      _Metric(
        label: 'Battery',
        value: controller.status.reading?.battSoc,
        suffix: '%',
        decimals: 0,
        delta: _delta(readings.map((r) => r.battSoc).toList()),
        values: readings.map((r) => r.battSoc).toList(),
        color: TfColors.cyan,
        icon: Icons.battery_charging_full_rounded,
        deltaSuffix: '%',
      ),
      _Metric(
        label: 'Generation',
        value: controller.status.reading?.genW,
        suffix: ' W',
        decimals: 0,
        delta: _delta(readings.map((r) => r.genW).toList()),
        values: readings.map((r) => r.genW).toList(),
        color: TfColors.gold,
        icon: Icons.wb_sunny_outlined,
        deltaSuffix: ' W',
      ),
      _Metric(
        label: 'Irrigation flow',
        value: controller.status.reading?.flow,
        suffix: ' L/m',
        decimals: 1,
        delta: _delta(readings.map((r) => r.flow).toList()),
        values: readings.map((r) => r.flow).toList(),
        color: TfColors.mintDeep,
        icon: Icons.water_drop_rounded,
        deltaSuffix: ' L/m',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }

  double? _delta(List<double?> values) {
    final visible = values.whereType<double>().toList();
    if (visible.length < 2) return null;
    return visible.last - visible.first;
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.decimals,
    required this.values,
    required this.color,
    required this.icon,
    this.delta,
    this.deltaSuffix = '',
  });

  final String label;
  final double? value;
  final String suffix;
  final int decimals;
  final List<double?> values;
  final Color color;
  final IconData icon;
  final double? delta;
  final String deltaSuffix;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final delta = metric.delta;
    final deltaColor = delta == null || delta.abs() < 0.01
        ? TfColors.textMuted
        : delta > 0
            ? TfColors.mint
            : TfColors.amber;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      radius: TfRadius.md,
      onTap: () => ShellScope.maybeOf(context)?.navigate(2),
      semanticLabel:
          '${metric.label}: ${metric.value ?? 'no data'}. Open analytics.',
      child: SizedBox(
        height: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.label.toUpperCase(),
                    style: TfType.label(size: 7.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(metric.icon,
                    size: 14, color: metric.color.withValues(alpha: 0.8)),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedNumber(
                    value: metric.value,
                    decimals: metric.decimals,
                    style: TfType.display(27).copyWith(height: 1),
                  ),
                  Text(metric.suffix,
                      style: TfType.body(10.5, color: TfColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  delta == null || delta.abs() < 0.01
                      ? Icons.remove_rounded
                      : delta > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                  size: 11,
                  color: deltaColor,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    delta == null
                        ? 'awaiting history'
                        : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(metric.decimals)}${metric.deltaSuffix} in window',
                    style: TfType.body(8.5, color: deltaColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Sparkline(values: metric.values, color: metric.color, height: 26),
          ],
        ),
      ),
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.controller, required this.stack});

  final AppController controller;
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final readings = controller.readings;
    final soil = [
      ChartSeries(
          label: 'Soil probe 1',
          color: TfColors.mint,
          values: readings.map((r) => r.soil1).toList()),
      ChartSeries(
          label: 'Soil probe 2',
          color: TfColors.cyan,
          values: readings.map((r) => r.soil2).toList()),
    ];
    final energy = [
      ChartSeries(
          label: 'Generation',
          color: TfColors.gold,
          values: readings.map((r) => r.genW).toList()),
      ChartSeries(
          label: 'Farm load',
          color: TfColors.cyan,
          values: readings.map((r) => r.loadW).toList()),
    ];

    final soilPanel = _ChartPanel(
      title: 'Soil moisture',
      kicker: 'Field history',
      subtitle: 'Last ${rangeLabel(controller.rangeHours)} · both probes',
      legend: soil,
      chart: TrendChart(
          series: soil,
          readings: readings,
          ySuffix: '%',
          decimals: 1,
          height: 158),
    );
    final energyPanel = _ChartPanel(
      title: 'Energy balance',
      kicker: 'Power history',
      subtitle: 'Generation against farm load',
      legend: energy,
      chart: TrendChart(
          series: energy,
          readings: readings,
          ySuffix: ' W',
          decimals: 0,
          height: 158),
    );

    if (stack) {
      return Column(
        children: [soilPanel, const SizedBox(height: 14), energyPanel],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: soilPanel),
        const SizedBox(width: 14),
        Expanded(child: energyPanel),
      ],
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.kicker,
    required this.subtitle,
    required this.legend,
    required this.chart,
  });

  final String title;
  final String kicker;
  final String subtitle;
  final List<ChartSeries> legend;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
              title: title, subtitle: subtitle, kicker: kicker.toUpperCase()),
          const SizedBox(height: 10),
          ChartLegend(series: legend),
          const SizedBox(height: 10),
          chart,
        ],
      ),
    );
  }
}

class _BottomPanels extends StatelessWidget {
  const _BottomPanels({
    required this.controller,
    required this.onOpenAlerts,
    required this.onOpenTwin,
  });

  final AppController controller;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenTwin;

  @override
  Widget build(BuildContext context) {
    final trust = controller.status.trust;
    final recent = controller.alerts.take(4).toList();
    final trustPanel = GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: 'Signal trust',
            subtitle: 'Every reading is verified before advice',
            kicker: 'INTEGRITY',
            trailing: TrustBadge(
                level: trust.level, score: trust.score, compact: true),
          ),
          const SizedBox(height: 16),
          TrustTimeline(points: controller.trustHistory),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 13, color: trustColor(trust.level)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trust.flags.isEmpty
                      ? 'All checks passed on the latest sample.'
                      : '${trust.flags.length} check${trust.flags.length == 1 ? '' : 's'} flagged — advice is gated.',
                  style: TfType.body(10.5, color: TfColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => showTrustReport(context),
                style: TextButton.styleFrom(
                  foregroundColor: TfColors.mint,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                child:
                    const Text('Open report', style: TextStyle(fontSize: 10.5)),
              ),
            ],
          ),
        ],
      ),
    );

    final alertsPanel = GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: 'Recent alerts',
            subtitle: recent.isEmpty
                ? 'No faults reported'
                : '${controller.alerts.length} on the server',
            kicker: 'ATTENTION',
            trailing: TextButton(
              onPressed: onOpenAlerts,
              style: TextButton.styleFrom(
                foregroundColor: TfColors.mint,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              child: const Text('View all', style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            _NoAlerts(onOpenTwin: onOpenTwin)
          else
            for (var i = 0; i < recent.length; i++) ...[
              AlertTile(
                alert: recent[i],
                zoneName: _zoneName(controller, recent[i]),
                compact: true,
                onTap: () => showAlertDetail(context, recent[i]),
              ),
              if (i != recent.length - 1) const SizedBox(height: 7),
            ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [alertsPanel, const SizedBox(height: 14), trustPanel],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: trustPanel),
            const SizedBox(width: 14),
            Expanded(flex: 4, child: alertsPanel),
          ],
        );
      },
    );
  }

  String _zoneName(AppController controller, AlertInfo alert) {
    for (final zone in controller.zones) {
      if (zone.id == alert.zoneId) return zone.name;
    }
    return alert.zoneId == null ? 'Farm-wide' : 'Zone ${alert.zoneId}';
  }
}

class _NoAlerts extends StatelessWidget {
  const _NoAlerts({required this.onOpenTwin});

  final VoidCallback onOpenTwin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TfColors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(TfRadius.md),
        border: Border.all(color: TfColors.green.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 19, color: TfColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No open faults. The twin is stable.',
              style: TfType.body(11.5, color: TfColors.textDim),
            ),
          ),
          TextButton(
            onPressed: onOpenTwin,
            style: TextButton.styleFrom(
              foregroundColor: TfColors.mint,
              minimumSize: const Size(0, 30),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Inspect', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: wide ? 404 : 300, radius: TfRadius.xl),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 150, radius: TfRadius.lg)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 150, radius: TfRadius.lg)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: ShimmerBox(height: 130, radius: TfRadius.md)),
                ],
              ],
            ),
            const SizedBox(height: 18),
            ShimmerBox(height: 210, radius: TfRadius.lg),
          ],
        );
      },
    );
  }
}
