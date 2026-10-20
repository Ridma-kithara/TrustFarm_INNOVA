import 'package:flutter/material.dart';

import '../core/design.dart';

class TfDestination {
  const TfDestination(
      {required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const tfDestinations = [
  TfDestination(
      label: 'Overview',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded),
  TfDestination(
      label: 'Digital twin',
      icon: Icons.view_in_ar_outlined,
      activeIcon: Icons.view_in_ar_rounded),
  TfDestination(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded),
  TfDestination(
      label: 'Alerts',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded),
  TfDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded),
];

class TfBottomBar extends StatelessWidget {
  const TfBottomBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.alertCount,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xF20A1615),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TfColors.lineStrong),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                offset: Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < tfDestinations.length; i++)
              Expanded(
                child: _BottomItem(
                  destination: tfDestinations[i],
                  selected: i == index,
                  badge: i == 3 ? alertCount : 0,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final TfDestination destination;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: motionDuration(context, TfMotion.base),
          curve: TfMotion.curve,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? TfColors.mint.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? destination.activeIcon : destination.icon,
                    size: 20,
                    color: selected ? TfColors.mint : TfColors.textMuted,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: TfColors.red,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                                color: TfColors.red.withValues(alpha: 0.5),
                                blurRadius: 6)
                          ],
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  style: TfType.body(
                    9,
                    color: selected ? TfColors.mint : TfColors.textMuted,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TfSideRail extends StatelessWidget {
  const TfSideRail({
    super.key,
    required this.index,
    required this.onChanged,
    required this.alertCount,
    required this.extended,
    required this.online,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int alertCount;
  final bool extended;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: motionDuration(context, TfMotion.base),
      width: extended ? 232 : 84,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      padding:
          EdgeInsets.symmetric(horizontal: extended ? 14 : 10, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xB30A1615),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: TfColors.line),
      ),
      child: Column(
        children: [
          _RailBrand(extended: extended),
          const SizedBox(height: 30),
          for (var i = 0; i < tfDestinations.length; i++) ...[
            _RailItem(
              destination: tfDestinations[i],
              selected: i == index,
              badge: i == 3 ? alertCount : 0,
              extended: extended,
              onTap: () => onChanged(i),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          if (extended) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TfColors.surfaceHigh.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(TfRadius.md),
                border: Border.all(color: TfColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: online ? TfColors.green : TfColors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (online ? TfColors.green : TfColors.amber)
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        online ? 'Field online' : 'Last known state',
                        style: TfType.body(10.5,
                            color: TfColors.textDim, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trust before advice',
                    style: TfType.body(9, color: TfColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: online ? TfColors.green : TfColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              if (extended) ...[
                const SizedBox(width: 7),
                Text('v1.0 · INNOVA 2026', style: TfType.label(size: 7.5)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          extended ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5CF0AF), Color(0xFF179567)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: TfColors.mint.withValues(alpha: 0.26), blurRadius: 22)
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: TfColors.ink, size: 22),
        ),
        if (extended) ...[
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TrustFarm',
                  style: TfType.title(17).copyWith(letterSpacing: -0.4)),
              Text('SMARTCROP AI',
                  style: TfType.label(size: 6.5, color: TfColors.mint)),
            ],
          ),
        ],
      ],
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.badge,
    required this.extended,
    required this.onTap,
  });

  final TfDestination destination;
  final bool selected;
  final int badge;
  final bool extended;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? TfColors.mint : TfColors.textMuted;
    final item = Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: motionDuration(context, TfMotion.fast),
            padding: EdgeInsets.symmetric(
                horizontal: widget.extended ? 13 : 0, vertical: 12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? TfColors.mint.withValues(alpha: 0.1)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.selected
                    ? TfColors.mint.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.selected
                          ? widget.destination.activeIcon
                          : widget.destination.icon,
                      size: 20,
                      color: color,
                    ),
                    if (widget.badge > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: TfColors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                if (widget.extended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.destination.label,
                      style: TfType.body(
                        12.5,
                        color: widget.selected
                            ? TfColors.text
                            : TfColors.textMuted,
                        weight:
                            widget.selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TfColors.mint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: TfColors.mint.withValues(alpha: 0.7),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return widget.extended
        ? item
        : Tooltip(message: widget.destination.label, child: item);
  }
}
