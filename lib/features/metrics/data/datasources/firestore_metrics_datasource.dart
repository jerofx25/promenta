import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fitness_metric_record_model.dart';
import '../../domain/entities/capacity_type.dart';
import '../../domain/entities/fitness_metric_record.dart';

/// Origen de datos Firestore para métricas. Responsable de queries y escrituras.
class FirestoreMetricsDataSource {
  FirestoreMetricsDataSource([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FitnessMetricRecordModel.collection);

  /// Crea documento y devuelve el id.
  Future<String> create(FitnessMetricRecord record) async {
    final map = FitnessMetricRecordModel.toFirestoreFromEntity(record);
    final ref = await _col.add(map);
    return ref.id;
  }

  Future<void> update(String id, FitnessMetricRecord record) async {
    final map = FitnessMetricRecordModel.toFirestoreFromEntity(record);
    map['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _col.doc(id).update(map);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// Lista por userId, opcional capacityType y limit.
  Future<List<FitnessMetricRecordModel>> getUserMetrics(
    String userId, {
    CapacityType? capacityType,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> q = _col
        .where('userId', isEqualTo: userId)
        .orderBy('recordedAt', descending: true);
    if (capacityType != null) {
      q = q.where('capacityType', isEqualTo: capacityType.firestoreValue);
    }
    if (limit != null) {
      q = q.limit(limit);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => FitnessMetricRecordModel.fromFirestore(d))
        .whereType<FitnessMetricRecordModel>()
        .toList();
  }

  /// Histórico por ejercicio (mismo exerciseKey).
  Future<List<FitnessMetricRecordModel>> getHistoryByExercise(
    String userId,
    String exerciseKey,
  ) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('exerciseKey', isEqualTo: exerciseKey)
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => FitnessMetricRecordModel.fromFirestore(d))
        .whereType<FitnessMetricRecordModel>()
        .toList();
  }

  /// Último registro por cada tipo en [capacityTypes].
  Future<List<FitnessMetricRecordModel>> getLatestByCapacityTypes(
    String userId,
    List<CapacityType> capacityTypes,
  ) async {
    final futures = capacityTypes.map((type) async {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('capacityType', isEqualTo: type.firestoreValue)
          .orderBy('recordedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return FitnessMetricRecordModel.fromFirestore(snap.docs.first);
    });
    final results = await Future.wait(futures);
    return results.whereType<FitnessMetricRecordModel>().toList();
  }
}
