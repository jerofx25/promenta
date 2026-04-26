import 'dart:async';

import 'package:IAEntrenar/features/meals/application/daily_meal_plan_state.dart';
import 'package:IAEntrenar/features/meals/domain/daily_meal_input.dart';
import 'package:IAEntrenar/features/meals/infrastructure/local_llm_meal_plan_service.dart';
import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:IAEntrenar/services/apple_health_service.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyMealPlanCubit extends Cubit<DailyMealPlanState> {
  DailyMealPlanCubit({LocalLlmMealPlanService? service})
      : _service = service ?? LocalLlmMealPlanService(),
        super(const DailyMealPlanState.initial());

  final LocalLlmMealPlanService _service;
  StreamSubscription? _downloadSub;

  Future<void> generate({
    required UserProfile profile,
    required WorkupDay? selectedWorkout,
    DateTime? now,
  }) async {
    emit(state.copyWith(
      status: DailyMealPlanStatus.downloadingModel,
      error: null,
      downloadProgress: 0,
    ));

    try {
      await _ensureModelDownloaded();
      if (isClosed) return;

      emit(state.copyWith(
        status: DailyMealPlanStatus.generating,
        error: null,
        downloadProgress: null,
      ));

      final health = await _collectVerifiedAppleHealthData();
      final recovery = await _computeStressAndRecovery(health);
      final input = DailyMealInput.from(
        now: now ?? DateTime.now(),
        profile: profile,
        health: health,
        recovery: recovery,
        selectedWorkout: selectedWorkout,
      );

      final plan = await _service.generateDailyMealPlan(input);
      if (!isClosed) {
        emit(state.copyWith(status: DailyMealPlanStatus.ready, plan: plan));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: DailyMealPlanStatus.error,
          error: e.toString(),
        ));
      }
    }
  }

  Future<void> _ensureModelDownloaded() async {
    await _downloadSub?.cancel();
    _downloadSub = null;

    final completer = Completer<void>();
    _downloadSub = _service.downloadModelInBackground().listen(
      (progress) {
        if (isClosed) return;
        final percent = progress.percent;
        if (percent == null) return;
        emit(state.copyWith(
          status: DailyMealPlanStatus.downloadingModel,
          downloadProgress: percent,
        ));
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    await completer.future;
  }

  Future<VerifiedAppleHealthData?> _collectVerifiedAppleHealthData() async {
    if (!AppleHealthService.isSupported) return null;

    try {
      final health = AppleHealthService();
      final granted = await health.requestPermissions();
      if (!granted) return null;

      final steps = _validInt(
        await health.getTodaySteps(),
        min: 1,
        max: 100000,
      );
      final activeCalories = _validInt(
        (await health.getTodayActiveCalories())?.round(),
        min: 1,
        max: 5000,
      );
      final exerciseMinutes = _validInt(
        await health.getTodayExerciseMinutes(),
        min: 1,
        max: 1440,
      );
      final hrvMs = _validDouble(
        await health.getLastHRV(),
        min: 1,
        max: 300,
      );
      final sleepLastNightHours = _validDouble(
        await health.getSleepLastNightHours(),
        min: 0.5,
        max: 16,
      );

      final verified = VerifiedAppleHealthData(
        steps: steps,
        activeCalories: activeCalories,
        exerciseMinutes: exerciseMinutes,
        hrvMs: hrvMs,
        sleepLastNightHours: sleepLastNightHours,
      );
      return verified.isEmpty ? null : verified;
    } catch (_) {
      return null;
    }
  }

  Future<DailyMealRecoveryMetrics?> _computeStressAndRecovery(
    VerifiedAppleHealthData? data,
  ) async {
    if (data == null) return null;
    final sleep = data.sleepLastNightHours;
    final hrv = data.hrvMs;
    if (sleep == null || hrv == null) return null;

    final prefs = await SharedPreferences.getInstance();
    const alpha = 0.12;
    final previousBaselineHrv = prefs.getDouble('baseline_hrv_ms');
    final previousBaselineSleep = prefs.getDouble('baseline_sleep_h');

    final baselineHrv = _ewmaUpdate(
      prefs: prefs,
      key: 'baseline_hrv_ms',
      value: hrv,
      alpha: alpha,
    );
    _ewmaUpdate(
      prefs: prefs,
      key: 'baseline_sleep_h',
      value: sleep,
      alpha: alpha,
    );

    // La pantalla de progreso marca la primera baseline como ejemplo; aqui
    // evitamos enviarla a la IA hasta tener una referencia real previa.
    if (previousBaselineHrv == null || previousBaselineSleep == null) {
      return null;
    }

    final minutes = (data.exerciseMinutes ?? 0).toDouble();
    final calories = (data.activeCalories ?? 0).toDouble();
    final steps = (data.steps ?? 0).toDouble();
    final sleepScore = _clamp01(_mapLinear(sleep, 5, 8));
    final hrvRatio = baselineHrv <= 0 ? 0.0 : hrv / baselineHrv;
    final hrvScore = _clamp01((hrvRatio - 0.70) / (1.20 - 0.70));
    final load = (0.45 * _clamp01(minutes / 60)) +
        (0.35 * _clamp01(calories / 600)) +
        (0.20 * _clamp01(steps / 10000));

    final recovery =
        (100 * ((0.48 * sleepScore) + (0.42 * hrvScore) + (0.10 * (1 - load))))
            .clamp(0.0, 100.0)
            .toDouble();
    final stress = (100 *
            ((0.50 * (1 - sleepScore)) +
                (0.35 * (1 - hrvScore)) +
                (0.15 * load)))
        .clamp(0.0, 100.0)
        .toDouble();

    return DailyMealRecoveryMetrics(stress: stress, recovery: recovery);
  }

  int? _validInt(int? value, {required int min, required int max}) {
    if (value == null || value < min || value > max) return null;
    return value;
  }

  double? _validDouble(double? value,
      {required double min, required double max}) {
    if (value == null || value < min || value > max) return null;
    return value;
  }

  double _ewmaUpdate({
    required SharedPreferences prefs,
    required String key,
    required double value,
    required double alpha,
  }) {
    final previous = prefs.getDouble(key);
    final next =
        previous == null ? value : (alpha * value + (1 - alpha) * previous);
    prefs.setDouble(key, next);
    return next;
  }

  double _mapLinear(double value, double min, double max) {
    if (max <= min) return 0;
    return (value - min) / (max - min);
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);

  void reset() {
    emit(const DailyMealPlanState.initial());
  }

  @override
  Future<void> close() async {
    await _downloadSub?.cancel();
    _downloadSub = null;
    await _service.dispose();
    return super.close();
  }
}
