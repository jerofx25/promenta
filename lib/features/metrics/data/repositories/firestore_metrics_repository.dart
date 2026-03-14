import '../../domain/entities/capacity_type.dart';
import '../../domain/entities/fitness_metric_record.dart';
import '../../domain/repositories/metrics_repository.dart';
import '../datasources/firestore_metrics_datasource.dart';

/// Implementación del repositorio de métricas con Firestore.
class FirestoreMetricsRepository implements MetricsRepository {
  FirestoreMetricsRepository(this._dataSource);

  final FirestoreMetricsDataSource _dataSource;

  @override
  Future<String> save(FitnessMetricRecord record) {
    return _dataSource.create(record);
  }

  @override
  Future<void> update(String id, FitnessMetricRecord record) {
    return _dataSource.update(id, record);
  }

  @override
  Future<void> delete(String id) {
    return _dataSource.delete(id);
  }

  @override
  Future<List<FitnessMetricRecord>> getUserMetrics(
    String userId, {
    CapacityType? capacityType,
    int? limit,
  }) async {
    final models = await _dataSource.getUserMetrics(
      userId,
      capacityType: capacityType,
      limit: limit,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FitnessMetricRecord>> getHistoryByExercise(
    String userId,
    String exerciseKey,
  ) async {
    final models = await _dataSource.getHistoryByExercise(userId, exerciseKey);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<FitnessMetricRecord>> getLatestByCapacityTypes(
    String userId,
    List<CapacityType> capacityTypes,
  ) async {
    final models = await _dataSource.getLatestByCapacityTypes(
      userId,
      capacityTypes,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
