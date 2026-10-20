import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

enum SessionPhase { booting, signedOut, signedIn }

/// Single source of truth for the app. It keeps the existing REST contract
/// (zones / status / readings / trust-history / alerts) and adds the settings
/// that make the experience feel personal without changing server behaviour.
class AppController extends ChangeNotifier {
  AppController({required this.api});

  final TrustFarmApi api;

  static const _kAutoRotate = 'tf:autoRotate';
  static const _kReducedMotion = 'tf:reducedMotion';
  static const _kRefreshSeconds = 'tf:refreshSeconds';
  static const _kRangeHours = 'tf:rangeHours';
  static const _kHighQuality = 'tf:highQuality';
  static const _kLastSeenAlert = 'tf:lastSeenAlert';

  SessionPhase phase = SessionPhase.booting;
  UserProfile? user;

  List<ZoneInfo> zones = const [];
  int? selectedZoneId;
  ZoneStatus status = const ZoneStatus();
  List<Reading> readings = const [];
  List<TrustPoint> trustHistory = const [];
  List<AlertInfo> alerts = const [];

  int rangeHours = 24;
  bool loading = false;
  bool refreshing = false;
  bool offline = false;
  bool serverReachable = true;
  String? error;
  DateTime? cachedAt;
  DateTime? lastUpdated;

  bool autoRotate = true;
  bool reducedMotion = false;
  bool highQuality = true;
  int refreshSeconds = 20;

  int? lastSeenAlertId;
  AlertInfo? pendingAlert;

  Timer? _poller;
  AppLifecycleListener? _lifecycle;
  bool _started = false;
  Future<void>? _inFlight;

  ZoneInfo? get selectedZone {
    for (final zone in zones) {
      if (zone.id == selectedZoneId) return zone;
    }
    return zones.isEmpty ? null : zones.first;
  }

  bool get hasData => status.reading != null || status.trust.hasData;
  bool get isReady => phase == SessionPhase.signedIn;

  Future<void> boot() async {
    if (_started) return;
    _started = true;
    await _loadSettings();

    try {
      final restored = await api.restoreSession();
      if (restored != null) {
        user = restored;
        phase = SessionPhase.signedIn;
        _startLifecycle();
        notifyListeners();
        await refresh(showSpinner: true);
      } else {
        phase = SessionPhase.signedOut;
        notifyListeners();
      }
    } catch (_) {
      phase = SessionPhase.signedOut;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (email.trim().isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Enter a valid email address.';
    }
    if (password.isEmpty) return 'Enter your password.';

    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await api.login(email, password);
      phase = SessionPhase.signedIn;
      loading = false;
      lastSeenAlertId = null;
      _startLifecycle();
      notifyListeners();
      await refresh(showSpinner: true);
      return null;
    } on ApiFailure catch (failure) {
      loading = false;
      notifyListeners();
      return failure.message;
    } catch (_) {
      loading = false;
      notifyListeners();
      return 'Something went wrong while signing in. Please try again.';
    }
  }

  Future<void> signOut() async {
    _poller?.cancel();
    _poller = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    await api.logout();
    user = null;
    phase = SessionPhase.signedOut;
    zones = const [];
    selectedZoneId = null;
    status = const ZoneStatus();
    readings = const [];
    trustHistory = const [];
    alerts = const [];
    error = null;
    offline = false;
    cachedAt = null;
    lastUpdated = null;
    pendingAlert = null;
    _started = false;
    notifyListeners();
  }

  Future<void> refresh({bool showSpinner = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final future = _refresh(showSpinner: showSpinner);
    _inFlight = future.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> _refresh({required bool showSpinner}) async {
    if (phase != SessionPhase.signedIn) return;
    if (showSpinner || !hasData) {
      loading = true;
    } else {
      refreshing = true;
    }
    error = null;
    notifyListeners();

    try {
      final zoneResult = await api.zones();
      zones = zoneResult.data;
      if (zones.isNotEmpty) {
        final validSelection = zones.any((zone) => zone.id == selectedZoneId);
        selectedZoneId = validSelection ? selectedZoneId : zones.first.id;
      } else {
        selectedZoneId = null;
      }

      var anyOffline = zoneResult.offline;
      DateTime? newestCache = zoneResult.cachedAt;

      if (selectedZoneId != null) {
        final id = selectedZoneId!;
        final results = await Future.wait<Object>([
          api.zoneStatus(id),
          api.readings(id, hours: rangeHours),
          api.trustHistory(id, hours: rangeHours),
          api.alerts(),
        ]);

        final statusResult = results[0] as Fetched<ZoneStatus>;
        final readingResult = results[1] as Fetched<List<Reading>>;
        final trustResult = results[2] as Fetched<List<TrustPoint>>;
        final alertResult = results[3] as Fetched<List<AlertInfo>>;

        status = statusResult.data;
        readings = readingResult.data;
        trustHistory = trustResult.data;
        alerts = _sortedAlerts(alertResult.data);

        anyOffline = anyOffline ||
            statusResult.offline ||
            readingResult.offline ||
            trustResult.offline ||
            alertResult.offline;
        newestCache = statusResult.cachedAt ?? newestCache;

        _handleNewCriticalAlert();
      }

      offline = anyOffline;
      cachedAt = newestCache;
      lastUpdated = DateTime.now();
      serverReachable = !anyOffline;
      error = null;
    } on UnauthorizedFailure {
      await signOut();
      return;
    } on ApiFailure catch (failure) {
      error = failure.message;
      serverReachable = false;
      offline = cachedAt != null;
    } catch (_) {
      error = 'Unable to refresh farm data. Please try again.';
      serverReachable = false;
    } finally {
      loading = false;
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> selectZone(int id) async {
    if (id == selectedZoneId) return;
    selectedZoneId = id;
    status = const ZoneStatus();
    readings = const [];
    trustHistory = const [];
    notifyListeners();
    await refresh(showSpinner: true);
  }

  Future<void> setRange(int hours) async {
    if (hours == rangeHours) return;
    rangeHours = hours;
    await _saveInt(_kRangeHours, hours);
    notifyListeners();
    await refresh();
  }

  void setAutoRotate(bool value) {
    autoRotate = value;
    _saveBool(_kAutoRotate, value);
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    reducedMotion = value;
    _saveBool(_kReducedMotion, value);
    notifyListeners();
  }

  void setHighQuality(bool value) {
    highQuality = value;
    _saveBool(_kHighQuality, value);
    notifyListeners();
  }

  void setRefreshSeconds(int seconds) {
    refreshSeconds = seconds;
    _saveInt(_kRefreshSeconds, seconds);
    _schedulePolling();
    notifyListeners();
  }

  Future<void> clearCache() async {
    await api.clearCache();
    notifyListeners();
  }

  void dismissPendingAlert() {
    final alert = pendingAlert;
    if (alert != null) {
      lastSeenAlertId = alert.id;
      _saveInt(_kLastSeenAlert, alert.id);
    }
    pendingAlert = null;
    notifyListeners();
  }

  List<AlertInfo> _sortedAlerts(List<AlertInfo> input) {
    final copy = [...input];
    copy.sort((a, b) {
      final aTime = a.ts?.millisecondsSinceEpoch ?? 0;
      final bTime = b.ts?.millisecondsSinceEpoch ?? 0;
      final byTime = bTime.compareTo(aTime);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
    return copy;
  }

  void _handleNewCriticalAlert() {
    if (alerts.isEmpty) return;
    final highestId =
        alerts.fold<int>(0, (max, alert) => alert.id > max ? alert.id : max);
    if (lastSeenAlertId == null) {
      lastSeenAlertId = highestId;
      _saveInt(_kLastSeenAlert, highestId);
      return;
    }
    final newestCritical = alerts
        .where((alert) => alert.id > lastSeenAlertId! && _isCritical(alert))
        .firstOrNull;
    if (newestCritical != null) {
      pendingAlert = newestCritical;
    }
  }

  bool _isCritical(AlertInfo alert) =>
      alert.severity == 'critical' || alert.severity == 'high';

  void _startLifecycle() {
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (phase == SessionPhase.signedIn) {
          refresh();
          _schedulePolling();
        }
      },
      onPause: () {
        _poller?.cancel();
        _poller = null;
      },
    );
    _schedulePolling();
  }

  void _schedulePolling() {
    _poller?.cancel();
    _poller = null;
    if (phase != SessionPhase.signedIn || refreshSeconds <= 0) return;
    _poller = Timer.periodic(Duration(seconds: refreshSeconds), (_) {
      refresh();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    autoRotate = prefs.getBool(_kAutoRotate) ?? true;
    reducedMotion = prefs.getBool(_kReducedMotion) ?? false;
    highQuality = prefs.getBool(_kHighQuality) ?? true;
    refreshSeconds = prefs.getInt(_kRefreshSeconds) ?? 20;
    rangeHours = prefs.getInt(_kRangeHours) ?? 24;
    lastSeenAlertId = prefs.getInt(_kLastSeenAlert);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _lifecycle?.dispose();
    api.dispose();
    super.dispose();
  }
}
