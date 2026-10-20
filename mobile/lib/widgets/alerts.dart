import 'package:flutter/material.dart';

import '../core/design.dart';
import '../core/formatters.dart';
import '../core/models.dart';
import 'glass.dart';
import 'trust.dart';

Color alertColor(String severity) {
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

IconData alertIcon(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
    case 'high':
      return Icons.warning_amber_rounded;
    case 'warning':
    case 'medium':
      return Icons.error_outline_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.zoneName,
    required this.onTap,
    this.compact = false,
  });

  final AlertInfo alert;
  final String zoneName;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.severity);
    return GlassPanel(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 13 : 15, vertical: compact ? 11 : 13),
      radius: TfRadius.md,
      color: color.withValues(alpha: 0.035),
      borderColor: color.withValues(alpha: 0.14),
      onTap: onTap,
      semanticLabel: '${alert.severity} alert: ${alert.message}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(alertIcon(alert.severity),
                size: compact ? 14 : 16, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: TfType.body(compact ? 11.5 : 12.5,
                          color: TfColors.text, weight: FontWeight.w500)
                      .copyWith(height: 1.45),
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        zoneName,
                        style: TfType.body(9.5, color: TfColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                            color: TfColors.textMuted, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(timeAgo(alert.ts),
                        style: TfType.body(9.5, color: TfColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AlertSeverityBadge(severity: alert.severity),
                if (alert.acknowledged) ...[
                  const SizedBox(height: 5),
                  Text('ACK',
                      style:
                          TfType.label(size: 6.5, color: TfColors.textMuted)),
                ],
              ],
            ),
          ] else if (!alert.acknowledged && alert.severity != 'info') ...[
            const SizedBox(width: 5),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 5)
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
