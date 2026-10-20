import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import '../threed/renderer.dart';
import '../threed/scene_data.dart';
import '../threed/scene_view.dart';
import '../threed/scenes/farm_scene.dart';
import '../widgets/glass.dart';
import '../widgets/layout.dart';
import '../widgets/sheets.dart';
import '../widgets/trust.dart';

class TwinScreen extends StatefulWidget {
  const TwinScreen({super.key});

  @override
  State<TwinScreen> createState() => _TwinScreenState();
}

class _TwinScreenState extends State<TwinScreen> {
  int _cameraEpoch = 0;
  bool _labels = true;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1030;
    final mobile = width < TfBreakpoints.mobile;

    return PagePadding(
      maxWidth: 1600,
      child: Padding(
        padding: EdgeInsets.only(
            bottom: mobile ? pageBottomInset(context, nav: 98, plain: 16) : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Digital twin',
              subtitle:
                  '${controller.selectedZone?.farm ?? 'TrustFarm'} · live 3D model',
              actions: mobile
                  ? const []
                  : [
                      TfIconButton(
                        icon: _labels
                            ? Icons.label_outline_rounded
                            : Icons.label_off_outlined,
                        tooltip: _labels
                            ? 'Hide hotspot labels'
                            : 'Show hotspot labels',
                        active: _labels,
                        onPressed: () => setState(() => _labels = !_labels),
                        size: 38,
                      ),
                      TfIconButton(
                        icon: controller.autoRotate
                            ? Icons.motion_photos_on_rounded
                            : Icons.motion_photos_off_rounded,
                        tooltip: controller.autoRotate
                            ? 'Pause auto-rotation'
                            : 'Resume auto-rotation',
                        active: controller.autoRotate,
                        onPressed: () =>
                            controller.setAutoRotate(!controller.autoRotate),
                        size: 38,
                      ),
                      TfIconButton(
                        icon: Icons.center_focus_strong_rounded,
                        tooltip: 'Recenter camera',
                        onPressed: () => setState(() => _cameraEpoch++),
                        size: 38,
                      ),
                    ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: _stage(context, controller,
                          wide: wide, mobile: mobile)),
                  if (wide) ...[
                    const SizedBox(width: 14),
                    SizedBox(
                        width: 330,
                        child: _TwinSidePanel(controller: controller)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, AppController controller,
      {required bool wide, required bool mobile}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TfRadius.xl),
        border: Border.all(color: TfColors.lineStrong),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 22))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TfRadius.xl - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CinematicScene(
              key: ValueKey(_cameraEpoch),
              builder: buildFarmScene,
              telemetry: sceneTelemetryFrom(controller),
              autoRotate: controller.autoRotate,
              reducedMotion: controller.reducedMotion,
              highQuality: controller.highQuality,
              showLabels: _labels,
              compactLabels: !wide,
              initialYaw: 0.62,
              initialPitch: wide ? 0.32 : 0.5,
              initialDistance: wide ? 16 : 16.5,
              onHotspotTap: (hotspot) => showHotspotSheet(context, hotspot),
              semanticLabel:
                  'Interactive 3D farm twin. Drag to orbit, pinch or scroll to zoom. '
                  'Tap a hotspot for details.',
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TfColors.ink.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.transparent,
                      TfColors.ink.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.2, 0.72, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  _LivePill(online: !controller.offline),
                  const Spacer(),
                  if (mobile)
                    Row(
                      children: [
                        TfIconButton(
                          icon: _labels
                              ? Icons.label_outline_rounded
                              : Icons.label_off_outlined,
                          tooltip: _labels ? 'Hide markers' : 'Show markers',
                          active: _labels,
                          onPressed: () => setState(() => _labels = !_labels),
                          size: 36,
                        ),
                        const SizedBox(width: 7),
                        TfIconButton(
                          icon: controller.autoRotate
                              ? Icons.motion_photos_on_rounded
                              : Icons.motion_photos_off_rounded,
                          tooltip: controller.autoRotate
                              ? 'Pause rotation'
                              : 'Resume rotation',
                          active: controller.autoRotate,
                          onPressed: () =>
                              controller.setAutoRotate(!controller.autoRotate),
                          size: 36,
                        ),
                        const SizedBox(width: 7),
                        TfIconButton(
                          icon: Icons.center_focus_strong_rounded,
                          tooltip: 'Recenter',
                          onPressed: () => setState(() => _cameraEpoch++),
                          size: 36,
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xB30A1615),
                        borderRadius: BorderRadius.circular(TfRadius.pill),
                        border: Border.all(color: TfColors.line),
                      ),
                      child: Text(
                        'DRAG TO ORBIT · SCROLL TO ZOOM',
                        style: TfType.label(size: 7, color: TfColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
            if (!wide)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _MobileReadouts(
                  controller: controller,
                  onOpenList: () => _showHotspots(context, controller),
                ),
              ),
            if (wide)
              Positioned(
                left: 18,
                bottom: 16,
                child: IgnorePointer(
                  child: Text(
                    'TAP A HOTSPOT FOR LIVE DETAILS',
                    style: TfType.label(
                        size: 7,
                        color: TfColors.textMuted.withValues(alpha: 0.8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHotspots(
      BuildContext context, AppController controller) async {
    final hotspots = twinHotspots(controller);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xF50A1615),
            borderRadius: BorderRadius.circular(TfRadius.xl),
            border: Border.all(color: TfColors.lineStrong),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text('Twin hotspots', style: TfType.headline(21)),
              const SizedBox(height: 4),
              Text('Tap a system to inspect its live values.',
                  style: TfType.body(11.5, color: TfColors.textMuted)),
              const SizedBox(height: 14),
              for (final hotspot in hotspots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    radius: TfRadius.md,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      showHotspotSheet(context, hotspot);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hotspot.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: hotspot.color.withValues(alpha: 0.24)),
                          ),
                          child: Icon(_hotspotIcon(hotspot.id),
                              size: 15, color: hotspot.color),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hotspot.title,
                                  style: TfType.body(12.5,
                                      color: TfColors.text,
                                      weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                hotspot.value,
                                style: TfType.body(10.5,
                                    color: TfColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 17, color: TfColors.textMuted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _hotspotIcon(String id) {
    switch (id) {
      case 'node':
        return Icons.memory_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      case 'irrigation':
        return Icons.water_drop_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? TfColors.green : TfColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xB30A1615),
        borderRadius: BorderRadius.circular(TfRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetaballDot(color: color, size: 6),
          const SizedBox(width: 7),
          Text(
            online ? 'LIVE MODEL' : 'LAST KNOWN STATE',
            style: TfType.label(size: 7.5, color: color),
          ),
        ],
      ),
    );
  }
}

class _MobileReadouts extends StatelessWidget {
  const _MobileReadouts({required this.controller, required this.onOpenList});

  final AppController controller;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final reading = controller.status.reading;
    final items = [
      _Readout('Soil', formatSoil(reading?.soilAverage), TfColors.mint),
      _Readout('Battery', formatPercent(reading?.battSoc), TfColors.cyan),
      _Readout('Gen', formatPower(reading?.genW), TfColors.gold),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0xE60A1615),
        borderRadius: BorderRadius.circular(TfRadius.lg),
        border: Border.all(color: TfColors.lineStrong),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(items[i].label.toUpperCase(),
                      style: TfType.label(size: 6.5)),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(items[i].value,
                        style: TfType.mono(13, color: items[i].color)),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              Container(width: 1, height: 24, color: TfColors.line),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenList,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: TfColors.mint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(TfRadius.pill),
                border:
                    Border.all(color: TfColors.mint.withValues(alpha: 0.28)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Details',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: TfColors.mint)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: TfColors.mint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Readout {
  const _Readout(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _TwinSidePanel extends StatelessWidget {
  const _TwinSidePanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final trust = controller.status.trust;
    final recommendation = controller.status.recommendation;
    final energy = controller.status.energy;
    final hotspots = twinHotspots(controller);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      blur: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Live telemetry'),
            const SizedBox(height: 14),
            Row(
              children: [
                TrustRing(
                  score: trust.score,
                  level: trust.level,
                  size: 88,
                  strokeWidth: 7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trust.score == null ? '—' : '${trust.score!.round()}',
                        style:
                            TfType.display(24, color: trustColor(trust.level)),
                      ),
                      Text('TRUST', style: TfType.label(size: 6)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrustBadge(
                          level: trust.level,
                          score: trust.score,
                          compact: true),
                      const SizedBox(height: 8),
                      Text(
                        needLabel(recommendation.need),
                        style: TfType.body(11, color: TfColors.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeAgo(controller.lastUpdated),
                        style: TfType.body(10, color: TfColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: TfColors.line),
            const SizedBox(height: 12),
            Text('SYSTEMS', style: TfType.label(size: 8)),
            const SizedBox(height: 6),
            for (final hotspot in hotspots)
              _SystemRow(
                  hotspot: hotspot,
                  onTap: () => showHotspotSheet(context, hotspot)),
            const SizedBox(height: 12),
            Container(height: 1, color: TfColors.line),
            const SizedBox(height: 14),
            Text('TODAY', style: TfType.label(size: 8)),
            const SizedBox(height: 7),
            Text(
              recommendation.advice,
              style: TfType.title(16).copyWith(height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (recommendation.reason.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                recommendation.reason,
                style: TfType.body(10.5, color: TfColors.textMuted)
                    .copyWith(height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: TfColors.gold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${energyModeLabel(energy.mode)} · ${formatPower(energy.surplusW)} surplus',
                    style: TfType.body(10, color: TfColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Procedural model · rendered in Flutter',
              style: TfType.body(9,
                  color: TfColors.textMuted.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  const _SystemRow({required this.hotspot, required this.onTap});

  final Hotspot3D hotspot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TfRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: hotspot.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: hotspot.color.withValues(alpha: 0.6),
                      blurRadius: 7)
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotspot.title,
                      style: TfType.body(11.5,
                          color: TfColors.text, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    hotspot.value,
                    style: TfType.body(9.5, color: TfColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded,
                size: 13, color: TfColors.textMuted),
          ],
        ),
      ),
    );
  }
}
