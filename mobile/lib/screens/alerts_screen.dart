import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/models.dart';
import '../widgets/alerts.dart';
import '../widgets/glass.dart';
import '../widgets/layout.dart';
import '../widgets/sheets.dart';
import '../widgets/states.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _search = TextEditingController();
  String _filter = 'all';
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final counts = _Counts(controller.alerts);
    final filtered = _filtered(controller.alerts);
    final wide = width >= TfBreakpoints.mobile;

    return PagePadding(
      maxWidth: 1180,
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
              const PageHeader(
                title: 'Faults & notices',
                subtitle: 'Server alerts · newest first',
              ),
              const SizedBox(height: 14),
              if (controller.offline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OfflineBanner(
                    cachedAt: controller.cachedAt,
                    retrying: controller.refreshing,
                    onRetry: controller.refresh,
                  ),
                ),
              GlassPanel(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    _SummaryValue(
                        label: 'Critical',
                        value: counts.critical,
                        color: TfColors.red),
                    _SummaryDivider(),
                    _SummaryValue(
                        label: 'Warnings',
                        value: counts.warning,
                        color: TfColors.amber),
                    _SummaryDivider(),
                    _SummaryValue(
                        label: 'Notices',
                        value: counts.info,
                        color: TfColors.cyan),
                    _SummaryDivider(),
                    _SummaryValue(
                      label: 'Ack’d',
                      value:
                          controller.alerts.where((a) => a.acknowledged).length,
                      color: TfColors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  children: [
                    SizedBox(width: 300, child: _searchField()),
                    const SizedBox(width: 14),
                    Expanded(child: _filters(counts)),
                  ],
                )
              else ...[
                _searchField(),
                const SizedBox(height: 10),
                _filters(counts),
              ],
              const SizedBox(height: 16),
              if (controller.alerts.isEmpty)
                EmptyState(
                  icon: Icons.verified_rounded,
                  title: controller.offline
                      ? 'No cached alerts'
                      : 'No alerts reported',
                  message: controller.offline
                      ? 'The last known state has no alerts for this zone.'
                      : 'The farm server has not raised any faults. Sensors and energy systems look calm.',
                  action: TfButton(
                      label: 'Refresh now',
                      icon: Icons.refresh_rounded,
                      secondary: true,
                      onPressed: controller.refresh),
                )
              else if (filtered.isEmpty)
                EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Nothing matches',
                  message: 'Try another severity or clear the search.',
                  action: TfButton(
                    label: 'Clear filters',
                    secondary: true,
                    onPressed: () {
                      _search.clear();
                      setState(() {
                        _query = '';
                        _filter = 'all';
                      });
                    },
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${filtered.length} ${filtered.length == 1 ? 'alert' : 'alerts'}',
                          style: TfType.body(11, color: TfColors.textMuted),
                        ),
                        const Spacer(),
                        Text('Newest first', style: TfType.label(size: 7.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < filtered.length; i++) ...[
                      AlertTile(
                        alert: filtered[i],
                        zoneName: _zoneName(controller, filtered[i]),
                        onTap: () => showAlertDetail(context, filtered[i]),
                      ),
                      if (i != filtered.length - 1) const SizedBox(height: 9),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              const InlineNotice(
                message:
                    'Alerts are read-only in this build. Acknowledgements happen in the farm '
                    'operator console; new critical alerts appear as an in-app banner while TrustFarm is open.',
                icon: Icons.notifications_paused_outlined,
                color: TfColors.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      style: TfType.body(12.5, color: TfColors.text),
      decoration: InputDecoration(
        hintText: 'Search alerts',
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded, size: 16),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _filters(_Counts counts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: counts.total,
            selected: _filter == 'all',
            color: TfColors.mint,
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Critical',
            count: counts.critical,
            selected: _filter == 'critical',
            color: TfColors.red,
            onTap: () => setState(() => _filter = 'critical'),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Warnings',
            count: counts.warning,
            selected: _filter == 'warning',
            color: TfColors.amber,
            onTap: () => setState(() => _filter = 'warning'),
          ),
          const SizedBox(width: 7),
          _FilterChip(
            label: 'Notices',
            count: counts.info,
            selected: _filter == 'info',
            color: TfColors.cyan,
            onTap: () => setState(() => _filter = 'info'),
          ),
        ],
      ),
    );
  }

  List<AlertInfo> _filtered(List<AlertInfo> alerts) {
    return alerts.where((alert) {
      final matchesSeverity = switch (_filter) {
        'critical' => alert.severity == 'critical' || alert.severity == 'high',
        'warning' => alert.severity == 'warning' || alert.severity == 'medium',
        'info' => alert.severity != 'critical' &&
            alert.severity != 'high' &&
            alert.severity != 'warning' &&
            alert.severity != 'medium',
        _ => true,
      };
      if (!matchesSeverity) return false;
      if (_query.isEmpty) return true;
      return alert.message.toLowerCase().contains(_query);
    }).toList();
  }

  String _zoneName(AppController controller, AlertInfo alert) {
    for (final zone in controller.zones) {
      if (zone.id == alert.zoneId) return zone.name;
    }
    return alert.zoneId == null ? 'Farm-wide' : 'Zone ${alert.zoneId}';
  }
}

class _Counts {
  _Counts(List<AlertInfo> alerts) {
    for (final alert in alerts) {
      switch (alert.severity) {
        case 'critical':
        case 'high':
          critical++;
          break;
        case 'warning':
        case 'medium':
          warning++;
          break;
        default:
          info++;
          break;
      }
    }
  }

  int critical = 0;
  int warning = 0;
  int info = 0;

  int get total => critical + warning + info;
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: TfType.label(size: 6.8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$value',
              style: TfType.mono(20,
                  color: value > 0 ? color : TfColors.textMuted)),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: TfColors.line,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label alerts, $count',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: motionDuration(context, TfMotion.fast),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(TfRadius.pill),
            border: Border.all(
                color: selected ? color.withValues(alpha: 0.4) : TfColors.line),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TfType.body(
                  10.5,
                  color: selected ? color : TfColors.textMuted,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$count',
                    style: TfType.mono(8.5,
                        color: selected ? color : TfColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
