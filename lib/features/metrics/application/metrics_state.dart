import 'package:equatable/equatable.dart';

import '../domain/entities/fitness_metric_record.dart';

/// Estado del Cubit de métricas.
class MetricsState extends Equatable {
  const MetricsState({
    this.metrics = const [],
    this.radarData = const {},
    this.isLoading = false,
    this.radarLoading = false,
    this.error,
    this.saveSuccess = false,
  });

  final List<FitnessMetricRecord> metrics;
  final Map<String, double> radarData;
  final bool isLoading;
  final bool radarLoading;
  final String? error;
  final bool saveSuccess;

  MetricsState copyWith({
    List<FitnessMetricRecord>? metrics,
    Map<String, double>? radarData,
    bool? isLoading,
    bool? radarLoading,
    String? error,
    bool? saveSuccess,
  }) {
    return MetricsState(
      metrics: metrics ?? this.metrics,
      radarData: radarData ?? this.radarData,
      isLoading: isLoading ?? this.isLoading,
      radarLoading: radarLoading ?? this.radarLoading,
      error: error,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }

  @override
  List<Object?> get props => [metrics, radarData, isLoading, radarLoading, error, saveSuccess];
}
