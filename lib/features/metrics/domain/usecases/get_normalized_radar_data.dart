import '../entities/capacity_type.dart';
import '../entities/fitness_metric_record.dart';
import '../entities/metric_unit.dart';
import '../repositories/metrics_repository.dart';

/// Radar consistente:
/// - Preferimos un "ejercicio representante" por capacidad.
/// - Normalizamos a 0–[maxRadarValue] contra tu MEJOR marca histórica de ese eje.
/// - Si la métrica es por tiempo (segundos), menor es mejor.
const Map<CapacityType, ({String key, String name})> _representativeByCapacity =
    {
  CapacityType.strength: (key: 'back_squat', name: 'Back Squat'),
  CapacityType.endurance: (key: 'push_ups', name: 'Push Ups'),
  CapacityType.speed: (key: 'run_100m', name: 'Run 100m'),
  CapacityType.mobility: (key: 'mobility_test', name: 'Mobility Test'),
  CapacityType.cardio: (key: 'row_2k', name: 'Row 2k'),
};

bool _lowerIsBetterByUnit(MetricUnit unit) => unit == MetricUnit.seconds;

/// Obtiene los últimos registros por capacidad, los normaliza y devuelve
/// Map<displayName, value> en escala 0–[maxRadarValue] para el radar.
class GetNormalizedRadarData {
  GetNormalizedRadarData(this._repository);

  final MetricsRepository _repository;

  /// [maxRadarValue] típicamente 10.0 para el radar.
  Future<Map<String, double>> call(
    String userId, {
    double maxRadarValue = 10.0,
    List<CapacityType>? capacityTypes,
  }) async {
    final types = capacityTypes ?? CapacityType.values;
    final latestByType =
        await _repository.getLatestByCapacityTypes(userId, types);

    final result = <String, double>{};
    for (final type in types) {
      final displayName = type.displayName;
      final rep = _representativeByCapacity[type];

      FitnessMetricRecord? latestRep;
      FitnessMetricRecord? latestFallback;
      for (final r in latestByType) {
        if (r.capacityType == type) {
          latestFallback = r;
          break;
        }
      }

      // 1) Intentar usar representante (si hay registros).
      if (rep != null) {
        final history = await _repository.getHistoryByExercise(userId, rep.key);
        final repHistory =
            history.where((e) => e.capacityType == type).toList();
        if (repHistory.isNotEmpty) {
          // `getHistoryByExercise` viene ordenado desc por recordedAt.
          latestRep = repHistory.first;

          final best = _bestValue(repHistory, latestRep.unit);
          final normalized = _normalizeAgainstBest(
            latest: latestRep.value,
            best: best,
            lowerIsBetter: _lowerIsBetterByUnit(latestRep.unit),
          );
          result[displayName] = normalized * maxRadarValue;
          continue;
        }
      }

      // 2) Fallback: último registro de esa capacidad (cualquier ejercicio),
      // normalizado contra su mejor histórico para ese MISMO exerciseKey.
      if (latestFallback == null) {
        result[displayName] = 0.0;
        continue;
      }

      final fallbackHistory = await _repository.getHistoryByExercise(
        userId,
        latestFallback.exerciseKey,
      );
      final sameType =
          fallbackHistory.where((e) => e.capacityType == type).toList();
      final best =
          sameType.isEmpty ? null : _bestValue(sameType, latestFallback.unit);
      final normalized = _normalizeAgainstBest(
        latest: latestFallback.value,
        best: best,
        lowerIsBetter: _lowerIsBetterByUnit(latestFallback.unit),
      );
      result[displayName] = normalized * maxRadarValue;
    }
    return result;
  }
}

double? _bestValue(List<FitnessMetricRecord> history, MetricUnit unit) {
  if (history.isEmpty) return null;
  if (_lowerIsBetterByUnit(unit)) {
    double best = history.first.value;
    for (final r in history) {
      if (r.value > 0 && r.value < best) best = r.value;
    }
    return best;
  }
  double best = history.first.value;
  for (final r in history) {
    if (r.value > best) best = r.value;
  }
  return best;
}

double _normalizeAgainstBest({
  required double latest,
  required double? best,
  required bool lowerIsBetter,
}) {
  if (best == null || best <= 0 || latest <= 0) return 0.0;
  if (lowerIsBetter) {
    // Menor tiempo es mejor: best/minTime => 1.0. Si latest es peor (mayor), baja.
    final ratio = (best / latest).clamp(0.0, 1.0);
    return ratio;
  }
  final ratio = (latest / best).clamp(0.0, 1.0);
  return ratio;
}
