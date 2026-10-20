import '../core/app_state.dart';
import '../core/design.dart';
import '../core/formatters.dart';
import 'renderer.dart';
import 'vector.dart';

SceneTelemetry sceneTelemetryFrom(AppController controller) {
  final reading = controller.status.reading;
  final trust = controller.status.trust;
  final recommendation = controller.status.recommendation;
  final energy = controller.status.energy;
  return SceneTelemetry(
    soil: reading?.soilAverage ?? 0,
    soil1: reading?.soil1,
    soil2: reading?.soil2,
    forecastSoil: recommendation.forecastSoil,
    battSoc: reading?.battSoc ?? 0,
    genW: reading?.genW ?? 0,
    loadW: reading?.loadW ?? 0,
    temp: reading?.temp ?? 0,
    hum: reading?.hum ?? 0,
    rain: reading?.rain ?? 0,
    flow: reading?.flow ?? 0,
    trustLevel: trust.level,
    trustScore: trust.score ?? 0,
    energyMode: energy.mode,
    advice: recommendation.advice,
    irrigate: recommendation.irrigate,
    online: !controller.offline && controller.serverReachable,
  );
}

List<Hotspot3D> twinHotspots(AppController controller) {
  final reading = controller.status.reading;
  final trust = controller.status.trust;
  final recommendation = controller.status.recommendation;
  final energy = controller.status.energy;
  return [
    Hotspot3D(
      id: 'node',
      position: const Vec3(0, 0, 0),
      title: 'ESP32 node',
      value: trust.hasData
          ? '${trust.level} · ${trust.score?.round() ?? 0}/100 trust'
          : 'Waiting for readings',
      color: trustColor(trust.level),
    ),
    Hotspot3D(
      id: 'energy',
      position: const Vec3(0, 0, 0),
      title: 'Waste-to-energy',
      value: '${formatPower(reading?.genW)} · ${energyModeLabel(energy.mode)}',
      color: TfColors.gold,
    ),
    Hotspot3D(
      id: 'battery',
      position: const Vec3(0, 0, 0),
      title: 'Battery storage',
      value:
          '${formatPercent(reading?.battSoc)} · ${formatPower(reading?.loadW)} load',
      color: TfColors.mint,
    ),
    Hotspot3D(
      id: 'irrigation',
      position: const Vec3(0, 0, 0),
      title: 'Irrigation line',
      value: (reading?.flow ?? 0) > 0.1
          ? 'Flowing ${reading!.flow!.toStringAsFixed(1)} L/min'
          : recommendation.advice,
      color: TfColors.cyan,
    ),
  ];
}
