import '../entities/capacity_type.dart';
import '../entities/fitness_metric_record.dart';

/// Contrato del repositorio de métricas (Firestore u otro backend).
abstract class MetricsRepository {
  /// Guarda un nuevo registro. Devuelve el id del documento creado.
  Future<String> save(FitnessMetricRecord record);

  /// Actualiza un registro existente por id.
  Future<void> update(String id, FitnessMetricRecord record);

  /// Elimina un registro por id.
  Future<void> delete(String id);

  /// Lista métricas del usuario, opcionalmente filtradas por tipo y con límite.
  Future<List<FitnessMetricRecord>> getUserMetrics(
    String userId, {
    CapacityType? capacityType,
    int? limit,
  });

  /// Histórico de un ejercicio (mismo exerciseKey), ordenado por recordedAt desc.
  Future<List<FitnessMetricRecord>> getHistoryByExercise(
    String userId,
    String exerciseKey,
  );

  /// Último registro por cada tipo de capacidad (para radar).
  Future<List<FitnessMetricRecord>> getLatestByCapacityTypes(
    String userId,
    List<CapacityType> capacityTypes,
  );
}
