import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';
import '../threed/renderer.dart';
import 'trust.dart';

Future<void> showHotspotSheet(BuildContext context, Hotspot3D hotspot) {
  final controller = AppScope.read(context);
  final status = controller.status;
  final reading = status.reading;
  final trust = status.trust;
  final recommendation = status.recommendation;
  final energy = status.energy;

  late final String eyebrow;
  late final IconData icon;
  late final Color color;
  late final List<SheetMetric> metrics;
  late final String note;
  Widget? extra;

  switch (hotspot.id) {
    case 'node':
      eyebrow = 'EDGE SENSOR';
      icon = Icons.memory_rounded;
      color = trustColor(trust.level);
      metrics = [
        SheetMetric('Trust level', trust.hasData ? trust.level : 'Unknown',
            color: color),
        SheetMetric('Trust score',
            trust.score == null ? '—' : '${trust.score!.round()}/100'),
        SheetMetric('Last reading', timeAgo(reading?.ts)),
        SheetMetric(
            'Connection', controller.offline ? 'Last known state' : 'Live'),
        SheetMetric('Air temperature', formatTemp(reading?.temp)),
        SheetMetric('Humidity', formatPercent(reading?.hum)),
      ];
      note = trust.flags.isEmpty
          ? 'All basic, cross-sensor and anomaly checks passed on the latest sample.'
          : 'Trust flags are active, so advice is being gated until the sensors recover.';
      extra = TrustExplainer(trust: trust);
      break;
    case 'energy':
      eyebrow = 'WASTE-TO-ENERGY';
      icon = Icons.bolt_rounded;
      color = TfColors.gold;
      metrics = [
        SheetMetric('Generation', formatPower(reading?.genW)),
        SheetMetric('Farm load', formatPower(reading?.loadW)),
        SheetMetric('Surplus', formatPower(energy.surplusW)),
        SheetMetric('Energy mode', energyModeLabel(energy.mode)),
        SheetMetric('Biogas source', 'Digester'),
        SheetMetric(
            'Irrigation power', energy.irrigationOk ? 'Allowed' : 'Held back'),
      ];
      note = '${energy.message} The digester is monitored on the digital twin; '
          'gas flow and generator controls stay manual.';
      break;
    case 'battery':
      eyebrow = 'STORAGE';
      icon = Icons.battery_charging_full_rounded;
      color = TfColors.mint;
      metrics = [
        SheetMetric('State of charge', formatPercent(reading?.battSoc),
            color: TfColors.mint),
        SheetMetric(
            'Battery voltage',
            reading?.battV == null
                ? '—'
                : '${reading!.battV!.toStringAsFixed(1)} V'),
        SheetMetric('Current load', formatPower(reading?.loadW)),
        SheetMetric('Energy mode', energyModeLabel(energy.mode)),
        SheetMetric('Surplus', formatPower(energy.surplusW)),
        SheetMetric(
            'Irrigation allowed', energy.irrigationOk ? 'Yes' : 'Not now'),
      ];
      note =
          '${energy.message} Deep-discharge protection is applied by the energy controller, '
          'not by this app.';
      break;
    case 'irrigation':
      eyebrow = 'IRRIGATION DECISION';
      icon = Icons.water_drop_rounded;
      color = TfColors.cyan;
      metrics = [
        SheetMetric('Recommendation',
            recommendation.irrigate ? 'Irrigate now' : 'Hold irrigation',
            color: recommendation.irrigate ? TfColors.amber : TfColors.green),
        SheetMetric('Need', needLabel(recommendation.need)),
        SheetMetric('Forecast soil', formatSoil(recommendation.forecastSoil)),
        SheetMetric(
            'Flow',
            reading?.flow == null
                ? '—'
                : '${reading!.flow!.toStringAsFixed(1)} L/min'),
        SheetMetric('Energy permission',
            energy.irrigationOk ? 'Available' : 'Unavailable'),
        SheetMetric(
            'Rain (latest)',
            reading?.rain == null
                ? '—'
                : '${reading!.rain!.toStringAsFixed(1)} mm'),
      ];
      note = recommendation.reason.isEmpty
          ? 'TrustFarm advises; the farmer decides. This app does not switch the pump.'
          : '${recommendation.reason} TrustFarm advises; the farmer decides. This app does not switch the pump.';
      break;
    default:
      eyebrow = 'FIELD SIGNAL';
      icon = Icons.sensors_rounded;
      color = hotspot.color;
      metrics = [
        SheetMetric('Latest value', hotspot.value),
        SheetMetric('Soil moisture', formatSoil(reading?.soilAverage)),
        SheetMetric('Forecast soil', formatSoil(recommendation.forecastSoil)),
        SheetMetric('Updated', timeAgo(controller.lastUpdated)),
      ];
      note =
          'Values are refreshed from the Farm API every ${controller.refreshSeconds <= 0 ? 'manual' : '${controller.refreshSeconds} seconds'}.';
  }

  return _showSheet(
    context: context,
    eyebrow: eyebrow,
    title: hotspot.title,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hotspot.id == 'node')
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TrustBadge(level: trust.level, score: trust.score),
          ),
        _MetricGrid(metrics: metrics),
        if (extra != null) ...[
          const SizedBox(height: 14),
          extra,
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(TfRadius.sm),
            border: Border.all(color: TfColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: TfColors.textMuted),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(note,
                      style: TfType.body(11.5, color: TfColors.textMuted))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Updated ${timeAgo(controller.lastUpdated)} · zone ${controller.selectedZone?.name ?? '—'}',
          style: TfType.body(10.5, color: TfColors.textMuted),
        ),
      ],
    ),
  );
}

Future<void> showTrustReport(BuildContext context) {
  final controller = AppScope.read(context);
  final trust = controller.status.trust;
  final recommendation = controller.status.recommendation;
  final color = trustColor(trust.level);
  return _showSheet(
    context: context,
    eyebrow: 'TRUST ENGINE',
    title: 'Why this advice?',
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(Icons.verified_user_rounded, color: color, size: 20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TrustRing(
              score: trust.score,
              level: trust.level,
              size: 118,
              strokeWidth: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trust.score == null ? '—' : '${trust.score!.round()}',
                    style: TfType.display(29, color: color),
                  ),
                  Text('OUT OF 100', style: TfType.label(size: 6.5)),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrustBadge(
                      level: trust.level, score: trust.score, compact: true),
                  const SizedBox(height: 10),
                  Text(
                    trust.level.toLowerCase() == 'green'
                        ? 'Sensor data is coherent. Advice is allowed.'
                        : trust.level.toLowerCase() == 'amber'
                            ? 'Some checks failed. Treat the advice with caution.'
                            : 'Trust is too low. Irrigation guidance is paused.',
                    style: TfType.body(12.5, color: TfColors.textDim)
                        .copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MetricGrid(metrics: [
          SheetMetric('Irrigation need', needLabel(recommendation.need)),
          SheetMetric('Forecast soil', formatSoil(recommendation.forecastSoil)),
          SheetMetric('Decision', recommendation.irrigate ? 'Irrigate' : 'Hold',
              color: recommendation.irrigate ? TfColors.amber : TfColors.green),
          SheetMetric(
              'Trust checks',
              trust.flags.isEmpty
                  ? 'All passed'
                  : '${trust.flags.length} flagged'),
        ]),
        const SizedBox(height: 16),
        Text('SENSOR CHECKS', style: TfType.label(size: 8.5)),
        const SizedBox(height: 9),
        TrustExplainer(trust: trust),
        const SizedBox(height: 14),
        Text(recommendation.advice, style: TfType.title(16)),
        if (recommendation.reason.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(recommendation.reason,
              style: TfType.body(12, color: TfColors.textMuted)
                  .copyWith(height: 1.55)),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(TfRadius.sm),
            border: Border.all(color: TfColors.line),
          ),
          child: Text(
            'Scoring: 100 minus the penalty of every failed check. Green ≥ 80, Amber ≥ 50, '
            'Red below 50. Checks cover freshness, range, stuck/jumping values, sensor agreement, '
            'rain response and a learned anomaly score.',
            style: TfType.body(11, color: TfColors.textMuted)
                .copyWith(height: 1.55),
          ),
        ),
      ],
    ),
  );
}

Future<void> showAlertDetail(BuildContext context, AlertInfo alert) {
  final controller = AppScope.read(context);
  final zone =
      controller.zones.where((zone) => zone.id == alert.zoneId).firstOrNull;
  final color = alert.severity == 'critical' || alert.severity == 'high'
      ? TfColors.red
      : alert.severity == 'warning' || alert.severity == 'medium'
          ? TfColors.amber
          : TfColors.cyan;
  return _showSheet(
    context: context,
    eyebrow: 'FARM ALERT',
    title: alert.severity == 'info' ? 'Field notice' : 'Field alert',
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(
        alert.severity == 'info'
            ? Icons.info_outline_rounded
            : Icons.warning_amber_rounded,
        color: color,
        size: 21,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlertSeverityBadge(severity: alert.severity),
        const SizedBox(height: 14),
        Text(alert.message, style: TfType.title(17).copyWith(height: 1.35)),
        const SizedBox(height: 16),
        _MetricGrid(metrics: [
          SheetMetric(
              'Zone',
              zone?.displayName ??
                  (alert.zoneId == null
                      ? 'Farm-wide'
                      : 'Zone ${alert.zoneId}')),
          SheetMetric('Raised', formatDateTime(alert.ts)),
          SheetMetric('Age', timeAgo(alert.ts)),
          SheetMetric(
              'Server state', alert.acknowledged ? 'Acknowledged' : 'Open'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(TfRadius.sm),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            alert.acknowledged
                ? 'This alert has been acknowledged by the farm team. The reading, trust status and '
                    'recommendation on the dashboard remain the live source of truth.'
                : 'This alert is still open on the server. Acknowledge it through the farm operator '
                    'console; this mobile build is read-only for alerts to preserve the existing API contract.',
            style: TfType.body(11.5, color: TfColors.textDim)
                .copyWith(height: 1.55),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 14, color: TfColors.textMuted),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'New critical alerts also surface as an in-app banner while TrustFarm is open.',
                style: TfType.body(10.5, color: TfColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> showAboutSheet(BuildContext context) {
  return _showSheet(
    context: context,
    eyebrow: 'ICBT INNOVA 2026',
    title: 'Trusted water, powered by the farm',
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5CF0AF), Color(0xFF179567)]),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.eco_rounded, color: TfColors.ink, size: 21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TrustFarm verifies every sensor reading before an AI recommends irrigation, then powers '
          'the decision with on-farm waste-to-energy. The experience you are holding is the '
          'mobile command deck for that loop.',
          style:
              TfType.body(13, color: TfColors.textDim).copyWith(height: 1.65),
        ),
        const SizedBox(height: 18),
        const _Bullet(
          icon: Icons.shield_outlined,
          title: 'Trust-gated advice',
          body:
              'Green / Amber / Red checks run on freshness, range, sensor agreement, rain response and anomalies.',
        ),
        const _Bullet(
          icon: Icons.view_in_ar_outlined,
          title: 'Real-time 3D twin',
          body:
              'A procedurally modelled farm — no external models — rendered with Flutter’s Canvas for parity on Android, iOS and web.',
        ),
        const _Bullet(
          icon: Icons.bolt_rounded,
          title: 'Energy-aware irrigation',
          body:
              'Solar, battery, generator and biogas telemetry explain whether irrigation has energy available.',
        ),
        const _Bullet(
          icon: Icons.public_rounded,
          title: 'SDG 2 · 6 · 13',
          body:
              'Better yields, responsible water use and climate-smart energy decisions.',
        ),
        const SizedBox(height: 16),
        Text('HONEST LIMITS', style: TfType.label(size: 8.5)),
        const SizedBox(height: 8),
        Text(
          'This build does not switch pumps, acknowledge alerts on the server or send push '
          'notifications. History is cached for offline viewing. The 3D twin is an illustrative '
          'digital model driven by live telemetry, not a survey-grade reconstruction.',
          style: TfType.body(11.5, color: TfColors.textMuted)
              .copyWith(height: 1.6),
        ),
        const SizedBox(height: 18),
        Text('TrustFarm v1.0.0 · Silent Force · Flutter',
            style: TfType.label(size: 8)),
      ],
    ),
  );
}

class SheetMetric {
  const SheetMetric(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<SheetMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: TfColors.surfaceHigh.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(TfRadius.sm),
                    border: Border.all(color: TfColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label.toUpperCase(),
                        style: TfType.label(size: 7.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        metric.value,
                        style: TfType.mono(14,
                            color: metric.color ?? TfColors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: TfColors.mint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: TfColors.mint.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: 14, color: TfColors.mint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TfType.body(12.5,
                        color: TfColors.text, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: TfType.body(11, color: TfColors.textMuted)
                        .copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSheet({
  required BuildContext context,
  required String eyebrow,
  required String title,
  required Widget leading,
  required Widget child,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    constraints: const BoxConstraints(maxWidth: 620),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xF50A1615),
            borderRadius: BorderRadius.circular(TfRadius.xl),
            border: Border.all(color: TfColors.lineStrong),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 50,
                  offset: Offset(0, 22))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eyebrow, style: TfType.label(size: 8)),
                                const SizedBox(height: 3),
                                Text(title, style: TfType.headline(22)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded,
                                size: 19, color: TfColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
