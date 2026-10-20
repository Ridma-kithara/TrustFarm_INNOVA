import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import 'glass.dart';
import 'trust.dart';

abstract final class TfBreakpoints {
  static const mobile = 760.0;
  static const wide = 1180.0;
}

/// Bottom padding that clears the floating navigation bar and any system
/// gesture inset. Desktop layouts sit beside a rail, so they use [plain].
double pageBottomInset(
  BuildContext context, {
  double nav = 108,
  double plain = 34,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= TfBreakpoints.mobile) return plain;
  return nav + MediaQuery.paddingOf(context).bottom;
}

class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child, this.maxWidth = 1440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final media = MediaQuery.of(context);
    final horizontal = width >= TfBreakpoints.wide
        ? 40.0
        : width >= TfBreakpoints.mobile
            ? 28.0
            : 18.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal + media.padding.left,
            12 + media.padding.top,
            horizontal + media.padding.right,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions = const [],
    this.showZone = true,
    this.showTrust = true,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showZone;
  final bool showTrust;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < TfBreakpoints.mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: TfType.label(size: 8.5, color: TfColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: TfType.headline(compact ? 26 : 30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            for (final action in actions) ...[const SizedBox(width: 8), action],
            if (compact) ...[
              const SizedBox(width: 6),
              TfIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh farm data',
                active: controller.refreshing,
                onPressed: controller.loading || controller.refreshing
                    ? null
                    : () => controller.refresh(),
                size: 38,
              ),
            ],
            const SizedBox(width: 8),
            _AccountButton(
              initials: controller.user?.initials ?? 'TF',
              onTap: () => _openProfile(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (showZone)
              Expanded(
                  child: ZoneChip(controller: controller, compact: compact)),
            if (showZone && showTrust) const SizedBox(width: 10),
            if (showTrust && !compact)
              TrustBadge(
                level: controller.status.trust.level,
                score: controller.status.trust.score,
                compact: true,
              ),
            if (!compact) const Spacer(),
            if (compact && showTrust)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TrustBadge(
                    level: controller.status.trust.level,
                    score: controller.status.trust.score,
                    compact: true,
                    short: true,
                  ),
                ),
              ),
            if (!compact) ...[
              RelativeTimestamp(time: controller.lastUpdated),
              const SizedBox(width: 10),
              TfIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh farm data',
                active: controller.refreshing,
                onPressed: controller.loading || controller.refreshing
                    ? null
                    : () => controller.refresh(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _openProfile(BuildContext context) {
    ShellScope.maybeOf(context)?.navigate(4);
  }
}

/// Lets any header or card ask the shell to switch tabs without a dependency
/// on the concrete shell widget.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.navigate, required super.child});

  final ValueChanged<int> navigate;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class ZoneChip extends StatelessWidget {
  const ZoneChip({super.key, required this.controller, this.compact = false});

  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final zone = controller.selectedZone;
    final label = zone == null
        ? 'No zone assigned'
        : compact
            ? zone.name
            : zone.displayName;
    return Semantics(
      button: controller.zones.length > 1,
      label: 'Select zone. Current zone ${zone?.displayName ?? 'none'}',
      child: MouseRegion(
        cursor: controller.zones.length > 1
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: controller.zones.length > 1
              ? () => showZonePicker(context, controller)
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 11 : 13, vertical: 9),
            decoration: BoxDecoration(
              color: TfColors.surfaceHigh.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(TfRadius.pill),
              border: Border.all(color: TfColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grass_rounded, size: 15, color: TfColors.mint),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TfType.body(12,
                        color: TfColors.textDim, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!compact && zone != null && zone.crop.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 12, color: TfColors.line),
                  const SizedBox(width: 8),
                  Text(
                    zone.crop.toUpperCase(),
                    style: TfType.label(size: 7.5, color: TfColors.textMuted),
                  ),
                ],
                if (controller.zones.length > 1) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: TfColors.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile and settings',
      child: Semantics(
        button: true,
        label: 'Open profile and settings',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A4C40), Color(0xFF182D27)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: TfColors.mint.withValues(alpha: 0.3)),
            ),
            child: Center(
              child:
                  Text(initials, style: TfType.mono(13, color: TfColors.mint)),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showZonePicker(
    BuildContext context, AppController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SheetFrame(
        title: 'Choose a zone',
        subtitle: 'Live data is scoped to one zone at a time.',
        child: Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: controller.zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final zone = controller.zones[index];
              final selected = zone.id == controller.selectedZoneId;
              return GlassPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                radius: TfRadius.md,
                color: selected ? TfColors.mint.withValues(alpha: 0.08) : null,
                borderColor:
                    selected ? TfColors.mint.withValues(alpha: 0.4) : null,
                onTap: () {
                  Navigator.of(context).pop();
                  controller.selectZone(zone.id);
                },
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TfColors.mint
                            .withValues(alpha: selected ? 0.16 : 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.landscape_rounded,
                        size: 16,
                        color: selected ? TfColors.mint : TfColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(zone.displayName, style: TfType.title(14)),
                          const SizedBox(height: 3),
                          Text(
                            '${zone.crop.isEmpty ? 'Mixed crop' : zone.crop} · zone ${zone.id}',
                            style: TfType.body(10.5, color: TfColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: TfColors.mint),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xF20A1615),
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
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(title, style: TfType.headline(21)),
            const SizedBox(height: 5),
            Text(subtitle, style: TfType.body(12, color: TfColors.textMuted)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String prettyDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String shortTime(DateTime? time) => formatClock(time);
