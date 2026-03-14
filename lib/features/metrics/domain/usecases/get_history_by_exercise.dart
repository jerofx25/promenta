import '../entities/fitness_metric_record.dart';
import '../repositories/metrics_repository.dart';

/// Histórico de un ejercicio para gráficas de evolución.
class GetHistoryByExercise {
  GetHistoryByExercise(this._repository);

  final MetricsRepository _repository;

  Future<List<FitnessMetricRecord>> call(String userId, String exerciseKey) {
    return _repository.getHistoryByExercise(userId, exerciseKey);
  }
}
