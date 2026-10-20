String twoDigits(num value) => value.round().toString().padLeft(2, '0');

String formatReading(double? value, {int decimals = 0, String fallback = '—'}) {
  if (value == null || value.isNaN || value.isInfinite) return fallback;
  if (decimals == 0) return value.round().toString();
  return value.toStringAsFixed(decimals);
}

String formatSoil(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(1)}%';

String formatPower(double? value) => value == null ? '—' : '${value.round()} W';

String formatTemp(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(1)}°';

String formatPercent(double? value) =>
    value == null ? '—' : '${value.round()}%';

String formatClock(DateTime? time) {
  if (time == null) return '—';
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

String formatDateTime(DateTime? time) {
  if (time == null) return '—';
  return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')} '
      '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return 'unknown';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDateTime(time);
}

String compactNumber(num value) {
  if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.round().toString();
}

String rangeLabel(int hours) {
  if (hours == 6) return '6 hours';
  if (hours == 12) return '12 hours';
  if (hours == 24) return '24 hours';
  if (hours == 72) return '3 days';
  if (hours == 168) return '7 days';
  return '$hours hours';
}

String needLabel(String? need) {
  switch (need?.toLowerCase()) {
    case 'high':
      return 'High need';
    case 'medium':
      return 'Medium need';
    case 'low':
      return 'Low need';
    default:
      return 'Awaiting forecast';
  }
}

String energyModeLabel(String mode) {
  switch (mode.toUpperCase()) {
    case 'CHARGING':
      return 'Charging';
    case 'NORMAL':
      return 'Energy balanced';
    case 'CONSERVE':
      return 'Conserving';
    case 'PROTECT':
      return 'Protecting battery';
    default:
      return 'Unknown';
  }
}
