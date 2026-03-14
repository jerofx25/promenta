import '../entities/capacity_type.dart';
import '../entities/fitness_metric_record.dart';
import '../repositories/metrics_repository.dart';

/// Obtiene métricas del usuario para listado/histórico.
class GetUserMetrics {
  GetUserMetrics(this._repository);

  final MetricsRepository _repository;

  Future<List<FitnessMetricRecord>> call(
    String userId, {
    CapacityType? capacityType,
    int? limit,
  }) {
    return _repository.getUserMetrics(
      userId,
      capacityType: capacityType,
      limit: limit,
    );
  }
}
