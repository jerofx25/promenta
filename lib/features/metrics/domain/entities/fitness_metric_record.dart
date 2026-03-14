import 'capacity_type.dart';
import 'metric_unit.dart';

/// Registro de una métrica física (RM, repeticiones, tiempo, score).
/// Entidad de dominio; sin detalles de Firestore.
class FitnessMetricRecord {
  const FitnessMetricRecord({
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

  FitnessMetricRecord copyWith({
    String? id,
    String? userId,
    CapacityType? capacityType,
    String? exerciseKey,
    String? exerciseDisplayName,
    double? value,
    MetricUnit? unit,
    String? sourceUnit,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FitnessMetricRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      capacityType: capacityType ?? this.capacityType,
      exerciseKey: exerciseKey ?? this.exerciseKey,
      exerciseDisplayName: exerciseDisplayName ?? this.exerciseDisplayName,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      sourceUnit: sourceUnit ?? this.sourceUnit,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
