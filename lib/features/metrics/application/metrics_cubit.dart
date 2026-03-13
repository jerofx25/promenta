import 'package:bloc/bloc.dart';

import '../domain/entities/capacity_type.dart';
import '../domain/entities/fitness_metric_record.dart';
import '../domain/entities/metric_unit.dart';
import '../domain/repositories/metrics_repository.dart';
import '../domain/usecases/calculate_rm_percentages.dart';
import '../domain/usecases/convert_weight_unit.dart';
import '../domain/usecases/get_normalized_radar_data.dart';
import '../domain/usecases/get_user_metrics.dart';
import '../domain/usecases/save_metric.dart';
import 'metrics_state.dart';

/// Cubit de métricas: listado, radar, guardar. Recibe userId desde la UI.
class MetricsCubit extends Cubit<MetricsState> {
  MetricsCubit({
    required MetricsRepository repository,
  })  : _saveMetric = SaveMetric(repository),
        _getUserMetrics = GetUserMetrics(repository),
        _getNormalizedRadarData = GetNormalizedRadarData(repository),
        _calculateRmPercentages = CalculateRmPercentages(),
        _convertWeightUnit = ConvertWeightUnit(),
        super(const MetricsState());

  final SaveMetric _saveMetric;
  final GetUserMetrics _getUserMetrics;
  final GetNormalizedRadarData _getNormalizedRadarData;
  final CalculateRmPercentages _calculateRmPercentages;
  final ConvertWeightUnit _convertWeightUnit;

  /// Carga métricas del usuario para listado / histórico.
  Future<void> loadUserMetrics(String userId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final list = await _getUserMetrics(userId, limit: 200);
      emit(state.copyWith(metrics: list, isLoading: false, error: null));
    } catch (e, st) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Carga datos normalizados para el radar (FitnessTrackerScreen).
  Future<void> loadRadarData(String userId) async {
    emit(state.copyWith(radarLoading: true));
    try {
      final data = await _getNormalizedRadarData(userId);
      emit(state.copyWith(radarData: data, radarLoading: false));
    } catch (e) {
      emit(state.copyWith(
        radarData: {},
        radarLoading: false,
      ));
    }
  }

  /// Guarda una métrica (desde RM Calculator o formulario).
  /// [exerciseKey] debe ser estable, ej: back_squat, push_ups, run_5k.
  Future<void> saveMetric({
    required String userId,
    required CapacityType capacityType,
    required String exerciseKey,
    required String exerciseDisplayName,
    required double value,
    required MetricUnit unit,
    DateTime? recordedAt,
  }) async {
    emit(state.copyWith(error: null, saveSuccess: false));
    try {
      await _saveMetric(
        userId: userId,
        capacityType: capacityType,
        exerciseKey: exerciseKey,
        exerciseDisplayName: exerciseDisplayName,
        value: value,
        unit: unit,
        recordedAt: recordedAt,
      );
      emit(state.copyWith(saveSuccess: true));
      await loadUserMetrics(userId);
      await loadRadarData(userId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Tabla de porcentajes de RM (10%–100%). [rmKg] en kg.
  List<RMPercentageEntry> getRmPercentages(double rmKg, {int step = 5}) {
    return _calculateRmPercentages(rmKg: rmKg, step: step);
  }

  /// Convierte peso entre kg y lb.
  double convertWeight({
    required double value,
    required MetricUnit fromUnit,
    required MetricUnit toUnit,
  }) {
    return _convertWeightUnit(
      value: value,
      fromUnit: fromUnit,
      toUnit: toUnit,
    );
  }

  /// Limpia error y flag de éxito (para que la UI no muestre mensaje duplicado).
  void clearErrorAndSuccess() {
    emit(state.copyWith(error: null, saveSuccess: false));
  }
}
