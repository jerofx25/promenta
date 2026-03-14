import '../entities/capacity_type.dart';
import '../entities/fitness_metric_record.dart';
import '../entities/metric_unit.dart';
import '../repositories/metrics_repository.dart';

/// Guarda una métrica: valida, convierte unidades si aplica (lb→kg) y persiste.
class SaveMetric {
  SaveMetric(this._repository);

  final MetricsRepository _repository;

  static const double _lbToKg = 0.453592;

  /// [value] y [unit] son los introducidos por el usuario.
  /// Si [unit] es lb y capacityType es strength, se convierte a kg antes de guardar.
  Future<String> call({
    required String userId,
    required CapacityType capacityType,
    required String exerciseKey,
    required String exerciseDisplayName,
    required double value,
    required MetricUnit unit,
    DateTime? recordedAt,
  }) async {
    if (value <= 0) {
      throw ArgumentError('El valor debe ser mayor que 0');
    }

    final now = DateTime.now();
    final recorded = recordedAt ?? now;

    double canonicalValue = value;
    String? sourceUnit;
    MetricUnit canonicalUnit = unit;

    if (capacityType == CapacityType.strength && unit.isWeight) {
      if (unit == MetricUnit.lb) {
        canonicalValue = value * _lbToKg;
        sourceUnit = MetricUnit.lb.firestoreValue;
        canonicalUnit = MetricUnit.kg;
      }
    }
    // Tiempos: guardar en segundos (canónico)
    if (capacityType == CapacityType.speed || capacityType == CapacityType.cardio) {
      if (unit == MetricUnit.minutes) {
        canonicalValue = value * 60;
        sourceUnit = MetricUnit.minutes.firestoreValue;
        canonicalUnit = MetricUnit.seconds;
      } else if (unit == MetricUnit.hours) {
        canonicalValue = value * 3600;
        sourceUnit = MetricUnit.hours.firestoreValue;
        canonicalUnit = MetricUnit.seconds;
      }
    }
                           
    final record = FitnessMetricRecord(
      id: '', // El repo/data asignará id al crear
      userId: userId,
      capacityType: capacityType,
      exerciseKey: exerciseKey,
      exerciseDisplayName: exerciseDisplayName,
      value: canonicalValue,
      unit: canonicalUnit,
      sourceUnit: sourceUnit,
      recordedAt: recorded,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.save(record);
  }
}
