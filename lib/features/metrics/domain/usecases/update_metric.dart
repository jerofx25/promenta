import '../entities/fitness_metric_record.dart';
import '../repositories/metrics_repository.dart';

/// Actualiza un registro existente.
class UpdateMetric {
  UpdateMetric(this._repository);

  final MetricsRepository _repository;

  Future<void> call(FitnessMetricRecord record) {
    if (record.id.isEmpty) {
      throw ArgumentError('Se necesita id para actualizar');
    }
    return _repository.update(record.id, record);
  }
}
