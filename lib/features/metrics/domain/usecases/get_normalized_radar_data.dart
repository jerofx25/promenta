import '../entities/capacity_type.dart';
import '../entities/fitness_metric_record.dart';
import '../repositories/metrics_repository.dart';

/// Escalas por capacidad para normalizar a 0–[maxValue].
/// Valores por encima del max se clampan.
const Map<CapacityType, double> _defaultMaxByCapacity = {
  CapacityType.strength: 200.0,   // kg
  CapacityType.endurance: 100.0,  // reps o equivalente
  CapacityType.speed: 20.0,      // segundos (menor = mejor, se invierte)
  CapacityType.mobility: 10.0,   // score
  CapacityType.cardio: 600.0,    // segundos (ej. 10 min row)
};

/// Para speed, "mejor" = menor tiempo; normalizamos invirtiendo.
bool _lowerIsBetter(CapacityType type) => type == CapacityType.speed;

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
    final latest = await _repository.getLatestByCapacityTypes(userId, types);

    final result = <String, double>{};
    for (final type in types) {
      FitnessMetricRecord? record;
      for (final r in latest) {
        if (r.capacityType == type) {
          record = r;
          break;
        }
      }
      final displayName = type.displayName;
      if (record == null) {
        result[displayName] = 0.0;
        continue;
      }
      final maxScale = _defaultMaxByCapacity[type] ?? 100.0;
      double normalized = record.value / maxScale;
      if (normalized > 1.0) normalized = 1.0;
      if (_lowerIsBetter(type)) {
        normalized = 1.0 - normalized;
      }
      result[displayName] = normalized * maxRadarValue;
    }
    return result;
  }
}
