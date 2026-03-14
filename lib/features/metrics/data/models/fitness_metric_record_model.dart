import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/capacity_type.dart';
import '../../domain/entities/fitness_metric_record.dart';
import '../../domain/entities/metric_unit.dart';

/// Modelo de datos para Firestore. Mapea entre entidad de dominio y documentos.
class FitnessMetricRecordModel {
  const FitnessMetricRecordModel({
    required this.id,
    required this.userId,
    required this.capacityType,
    required this.exerciseKey,
    required this.exerciseDisplayName,
    required this.value,
    required this.unit,
    this.sourceUnit,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  final String id;
  final String userId;
  final CapacityType capacityType;
  final String exerciseKey;
  final String exerciseDisplayName;
  final double value;
  final MetricUnit unit;
  final String? sourceUnit;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  static const String _collection = 'user_metrics';

  static String get collection => _collection;

  /// Desde documento de Firestore (id del documento + data).
  static FitnessMetricRecordModel? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) return null;
    final capacityType = CapacityType.fromFirestore(data['capacityType'] as String?);
    final unit = MetricUnit.fromFirestore(data['unit'] as String?);
    if (capacityType == null || unit == null) return null;

    final recordedAt = _parseTimestamp(data['recordedAt']);
    final createdAt = _parseTimestamp(data['createdAt']);
    final updatedAt = _parseTimestamp(data['updatedAt']);
    if (recordedAt == null || createdAt == null || updatedAt == null) return null;

    return FitnessMetricRecordModel(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      capacityType: capacityType,
      exerciseKey: data['exerciseKey'] as String? ?? '',
      exerciseDisplayName: data['exerciseDisplayName'] as String? ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      unit: unit,
      sourceUnit: data['sourceUnit'] as String?,
      recordedAt: recordedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Convierte a entidad de dominio.
  FitnessMetricRecord toEntity() {
    return FitnessMetricRecord(
      id: id,
      userId: userId,
      capacityType: capacityType,
      exerciseKey: exerciseKey,
      exerciseDisplayName: exerciseDisplayName,
      value: value,
      unit: unit,
      sourceUnit: sourceUnit,
      recordedAt: recordedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  /// Para crear documento (sin id); id lo asigna Firestore.
  Map<String, dynamic> toFirestore() {
    return _toMap(
      userId: userId,
      capacityType: capacityType,
      exerciseKey: exerciseKey,
      exerciseDisplayName: exerciseDisplayName,
      value: value,
      unit: unit,
      sourceUnit: sourceUnit,
      recordedAt: recordedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  /// Desde entidad de dominio (crear nuevo registro).
  static Map<String, dynamic> toFirestoreFromEntity(FitnessMetricRecord record) {
    return _toMap(
      userId: record.userId,
      capacityType: record.capacityType,
      exerciseKey: record.exerciseKey,
      exerciseDisplayName: record.exerciseDisplayName,
      value: record.value,
      unit: record.unit,
      sourceUnit: record.sourceUnit,
      recordedAt: record.recordedAt,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      metadata: record.metadata,
    );
  }

  static Map<String, dynamic> _toMap({
    required String userId,
    required CapacityType capacityType,
    required String exerciseKey,
    required String exerciseDisplayName,
    required double value,
    required MetricUnit unit,
    String? sourceUnit,
    required DateTime recordedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'userId': userId,
      'capacityType': capacityType.firestoreValue,
      'exerciseKey': exerciseKey,
      'exerciseDisplayName': exerciseDisplayName,
      'value': value,
      'unit': unit.firestoreValue,
      if (sourceUnit != null) 'sourceUnit': sourceUnit,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Para update (updatedAt se actualiza en el repo).
  Map<String, dynamic> toFirestoreUpdate({
    required DateTime updatedAt,
    String? exerciseDisplayName,
    double? value,
    MetricUnit? unit,
    String? sourceUnit,
    DateTime? recordedAt,
    Map<String, dynamic>? metadata,
  }) {
    final map = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    if (exerciseDisplayName != null) map['exerciseDisplayName'] = exerciseDisplayName;
    if (value != null) map['value'] = value;
    if (unit != null) map['unit'] = unit.firestoreValue;
    if (sourceUnit != null) map['sourceUnit'] = sourceUnit;
    if (recordedAt != null) map['recordedAt'] = Timestamp.fromDate(recordedAt);
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }
}
