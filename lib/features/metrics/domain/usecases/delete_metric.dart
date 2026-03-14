import '../repositories/metrics_repository.dart';

/// Elimina un registro de métrica por id.
class DeleteMetric {
  DeleteMetric(this._repository);

  final MetricsRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
