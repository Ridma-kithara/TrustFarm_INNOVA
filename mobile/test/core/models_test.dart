import 'package:flutter_test/flutter_test.dart';
import 'package:trustfarm_mobile/core/models.dart';

void main() {
  group('ZoneStatus parsing', () {
    final payload = {
      'reading': {
        'ts': '2026-05-01T10:00:00Z',
        'soil1': 41.2,
        'soil2': 38.8,
        'temp': 28.4,
        'hum': 64,
        'rain': 0,
        'flow': 1.2,
        'batt_v': 12.7,
        'batt_soc': 76,
        'gen_w': 85,
        'load_w': 30,
      },
      'trust': {
        'level': 'Amber',
        'score': 65,
        'flags': [
          {'code': 'MISMATCH', 'message': 'Sensors disagree by 16.0'},
          'legacy string flag',
        ],
      },
      'recommendation': {
        'need': 'medium',
        'forecast_soil': 35.4,
        'irrigate': true,
        'advice': 'Irrigate for 20 minutes',
        'reason': 'Forecast drops below the comfort band',
      },
      'energy': {
        'mode': 'CHARGING',
        'irrigation_ok': true,
        'surplus_w': 55,
        'message': 'Surplus available, battery charging',
      },
    };

    test('reads every nested section', () {
      final status = ZoneStatus.fromJson(payload);
      expect(status.reading?.soil1, 41.2);
      expect(status.reading?.battSoc, 76);
      expect(status.reading?.soilAverage, closeTo(40.0, 0.001));
      expect(status.trust.level, 'Amber');
      expect(status.trust.score, 65);
      expect(status.trust.flags, hasLength(2));
      expect(status.trust.flags.first.code, 'MISMATCH');
      expect(status.trust.flags.last.message, 'legacy string flag');
      expect(status.recommendation.irrigate, isTrue);
      expect(status.recommendation.forecastSoil, 35.4);
      expect(status.energy.mode, 'CHARGING');
      expect(status.energy.surplusW, 55);
    });

    test('missing sections fall back to safe defaults', () {
      final status = ZoneStatus.fromJson(const {});
      expect(status.reading, isNull);
      expect(status.trust.hasData, isFalse);
      expect(status.recommendation.advice, isNotEmpty);
      expect(status.energy.mode, 'UNKNOWN');
      expect(status.energy.irrigationOk, isFalse);
    });
  });

  test('UserProfile initials handle names and emails', () {
    const byName = UserProfile(
        id: 1, email: 'k@p.lk', name: 'Nimal Perera', role: 'farmer');
    const byEmail =
        UserProfile(id: 1, email: 'oshini@farm.lk', name: '', role: 'officer');
    expect(byName.initials, 'NP');
    expect(byEmail.initials, 'OF');
  });

  test('AlertInfo lowercases severity and tracks acknowledgement', () {
    final alert = AlertInfo.fromJson(const {
      'id': 9,
      'zone_id': 2,
      'severity': 'Critical',
      'message': 'No data from zone 2',
      'acknowledged': true,
    });
    expect(alert.severity, 'critical');
    expect(alert.acknowledged, isTrue);
    expect(alert.zoneId, 2);
  });
}
