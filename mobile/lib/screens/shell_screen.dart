import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/design.dart';
import '../core/models.dart';
import '../widgets/background.dart';
import '../widgets/layout.dart';
import '../widgets/nav.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'overview_screen.dart';
import 'profile_screen.dart';
import 'twin_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= TfBreakpoints.mobile;
    final extendedRail = width >= TfBreakpoints.wide;
    final alertCount = _unacknowledgedCritical(controller.alerts);
    final pages = <Widget>[
      OverviewScreen(onOpenTwin: () => _goTo(1), onOpenAlerts: () => _goTo(3)),
      const TwinScreen(),
      const AnalyticsScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    final content = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < pages.length; i++)
          TickerMode(
            enabled: i == _index,
            child: pages[i],
          ),
      ],
    );

    final body = desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TfSideRail(
                index: _index,
                onChanged: _goTo,
                alertCount: alertCount,
                extended: extendedRail,
                online: !controller.offline && controller.serverReachable,
              ),
              Expanded(child: content),
            ],
          )
        : Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TfBottomBar(
                    index: _index, onChanged: _goTo, alertCount: alertCount),
              ),
            ],
          );

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: ShellScope(
            navigate: _goTo,
            child: Stack(
              children: [
                Positioned.fill(child: body),
                if (controller.pendingAlert != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Center(
                          child: _CriticalAlertBanner(
                            alert: controller.pendingAlert!,
                            onReview: () {
                              controller.dismissPendingAlert();
                              _goTo(3);
                            },
                            onDismiss: controller.dismissPendingAlert,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _unacknowledgedCritical(List<AlertInfo> alerts) {
    return alerts
        .where((alert) =>
            !alert.acknowledged &&
            (alert.severity == 'critical' || alert.severity == 'high'))
        .length;
  }
}

class _CriticalAlertBanner extends StatelessWidget {
  const _CriticalAlertBanner({
    required this.alert,
    required this.onReview,
    required this.onDismiss,
  });

  final AlertInfo alert;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: const Color(0xF5140C0D),
          borderRadius: BorderRadius.circular(TfRadius.md),
          border: Border.all(color: TfColors.red.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 12)),
            BoxShadow(
                color: TfColors.red.withValues(alpha: 0.18), blurRadius: 30),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TfColors.red.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: TfColors.red.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 17, color: TfColors.red),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('NEW CRITICAL ALERT',
                      style: TfType.label(size: 7.5, color: TfColors.red)),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    style: TfType.body(11.5,
                        color: TfColors.text, weight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onReview,
              style: TextButton.styleFrom(
                foregroundColor: TfColors.red,
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('Review',
                  style:
                      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: TfColors.textMuted),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
