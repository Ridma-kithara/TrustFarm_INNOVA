/// Plain data models that mirror the FastAPI responses exactly.
/// Parsing is defensive: a field the backend has not produced yet must never
/// crash the UI.
library;

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? asDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round(),
            isUtc: true)
        .toLocal();
  }
  return null;
}

String asText(dynamic value, {String fallback = ''}) =>
    value is String ? value : fallback;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.farmId,
  });

  final int id;
  final String email;
  final String name;
  final String role;
  final int? farmId;

  String get initials {
    final source = name.trim().isNotEmpty ? name : email;
    final parts =
        source.split(RegExp(r'[\s.@_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'TF';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: asInt(json['id']) ?? 0,
        email: asText(json['email']),
        name: asText(json['name'], fallback: asText(json['email'])),
        role: asText(json['role'], fallback: 'farmer'),
        farmId: asInt(json['farm_id']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'farm_id': farmId,
      };
}

class ZoneInfo {
  const ZoneInfo({
    required this.id,
    required this.name,
    required this.farmId,
    required this.farm,
    required this.crop,
  });

  final int id;
  final String name;
  final int farmId;
  final String farm;
  final String crop;

  String get displayName => farm.isEmpty ? name : '$farm · $name';

  factory ZoneInfo.fromJson(Map<String, dynamic> json) => ZoneInfo(
        id: asInt(json['id']) ?? 0,
        name: asText(json['name'], fallback: 'Zone'),
        farmId: asInt(json['farm_id']) ?? 0,
        farm: asText(json['farm']),
        crop: asText(json['crop']),
      );
}

class Reading {
  const Reading({
    this.ts,
    this.soil1,
    this.soil2,
    this.temp,
    this.hum,
    this.rain,
    this.flow,
    this.battV,
    this.battSoc,
    this.genW,
    this.loadW,
  });

  final DateTime? ts;
  final double? soil1;
  final double? soil2;
  final double? temp;
  final double? hum;
  final double? rain;
  final double? flow;
  final double? battV;
  final double? battSoc;
  final double? genW;
  final double? loadW;

  double? get soilAverage {
    if (soil1 == null && soil2 == null) return null;
    if (soil1 == null) return soil2;
    if (soil2 == null) return soil1;
    return (soil1! + soil2!) / 2;
  }

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        ts: asDate(json['ts']),
        soil1: asDouble(json['soil1']),
        soil2: asDouble(json['soil2']),
        temp: asDouble(json['temp']),
        hum: asDouble(json['hum']),
        rain: asDouble(json['rain']),
        flow: asDouble(json['flow']),
        battV: asDouble(json['batt_v']),
        battSoc: asDouble(json['batt_soc']),
        genW: asDouble(json['gen_w']),
        loadW: asDouble(json['load_w']),
      );
}

class TrustFlag {
  const TrustFlag({required this.code, required this.message});

  final String code;
  final String message;

  factory TrustFlag.fromJson(dynamic json) {
    if (json is String) return TrustFlag(code: 'FLAG', message: json);
    if (json is Map) {
      return TrustFlag(
        code: asText(json['code'], fallback: 'FLAG'),
        message: asText(json['message'], fallback: 'Sensor check required'),
      );
    }
    return const TrustFlag(code: 'FLAG', message: 'Sensor check required');
  }
}

class TrustInfo {
  const TrustInfo({
    this.ts,
    this.level = 'Unknown',
    this.score,
    this.flags = const [],
  });

  final DateTime? ts;
  final String level;
  final double? score;
  final List<TrustFlag> flags;

  bool get hasData => level.toLowerCase() != 'unknown';

  factory TrustInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TrustInfo();
    final rawFlags = json['flags'];
    return TrustInfo(
      ts: asDate(json['ts']),
      level: asText(json['level'], fallback: 'Unknown'),
      score: asDouble(json['score']),
      flags: rawFlags is List
          ? rawFlags.map(TrustFlag.fromJson).toList()
          : const [],
    );
  }
}

class Recommendation {
  const Recommendation({
    this.ts,
    this.need,
    this.forecastSoil,
    this.irrigate = false,
    this.advice = 'Waiting for data…',
    this.reason = '',
  });

  final DateTime? ts;
  final String? need;
  final double? forecastSoil;
  final bool irrigate;
  final String advice;
  final String reason;

  factory Recommendation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Recommendation();
    return Recommendation(
      ts: asDate(json['ts']),
      need: json['need'] is String ? json['need'] as String : null,
      forecastSoil: asDouble(json['forecast_soil']),
      irrigate: json['irrigate'] == true,
      advice: asText(json['advice'], fallback: 'Waiting for data…'),
      reason: asText(json['reason']),
    );
  }
}

class EnergyInfo {
  const EnergyInfo({
    this.mode = 'UNKNOWN',
    this.irrigationOk = false,
    this.surplusW = 0,
    this.message = 'Energy data unavailable',
  });

  final String mode;
  final bool irrigationOk;
  final double surplusW;
  final String message;

  factory EnergyInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EnergyInfo();
    return EnergyInfo(
      mode: asText(json['mode'], fallback: 'UNKNOWN'),
      irrigationOk: json['irrigation_ok'] == true,
      surplusW: asDouble(json['surplus_w']) ?? 0,
      message: asText(json['message'], fallback: 'Energy data unavailable'),
    );
  }
}

class ZoneStatus {
  const ZoneStatus({
    this.reading,
    this.trust = const TrustInfo(),
    this.recommendation = const Recommendation(),
    this.energy = const EnergyInfo(),
  });

  final Reading? reading;
  final TrustInfo trust;
  final Recommendation recommendation;
  final EnergyInfo energy;

  factory ZoneStatus.fromJson(Map<String, dynamic> json) {
    final reading = json['reading'];
    return ZoneStatus(
      reading:
          reading is Map<String, dynamic> ? Reading.fromJson(reading) : null,
      trust: TrustInfo.fromJson(json['trust'] is Map<String, dynamic>
          ? json['trust'] as Map<String, dynamic>
          : null),
      recommendation: Recommendation.fromJson(
        json['recommendation'] is Map<String, dynamic>
            ? json['recommendation'] as Map<String, dynamic>
            : null,
      ),
      energy: EnergyInfo.fromJson(json['energy'] is Map<String, dynamic>
          ? json['energy'] as Map<String, dynamic>
          : null),
    );
  }
}

class TrustPoint {
  const TrustPoint({this.ts, this.level = 'Unknown', this.score = 0});

  final DateTime? ts;
  final String level;
  final double score;

  factory TrustPoint.fromJson(Map<String, dynamic> json) => TrustPoint(
        ts: asDate(json['ts']),
        level: asText(json['level'], fallback: 'Unknown'),
        score: asDouble(json['score']) ?? 0,
      );
}

class AlertInfo {
  const AlertInfo({
    required this.id,
    required this.severity,
    required this.message,
    this.zoneId,
    this.ts,
    this.acknowledged = false,
  });

  final int id;
  final int? zoneId;
  final DateTime? ts;
  final String severity;
  final String message;
  final bool acknowledged;

  factory AlertInfo.fromJson(Map<String, dynamic> json) => AlertInfo(
        id: asInt(json['id']) ?? 0,
        zoneId: asInt(json['zone_id']),
        ts: asDate(json['ts']),
        severity: asText(json['severity'], fallback: 'info').toLowerCase(),
        message: asText(json['message'], fallback: 'System alert'),
        acknowledged: json['acknowledged'] == true,
      );
}

class Fetched<T> {
  const Fetched({required this.data, this.offline = false, this.cachedAt});

  final T data;
  final bool offline;
  final DateTime? cachedAt;
}

extension FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
