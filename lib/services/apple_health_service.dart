import 'dart:io';

import 'package:health/health.dart';

/// Servicio para leer datos de Apple Health (iOS) y Health Connect (Android).
/// Requiere en iOS: HealthKit capability en Xcode y permisos en Info.plist.
class AppleHealthService {
  final Health _health = Health();

  bool _configured = false;

  Future<void> init() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Tipos que pedimos leer (pasos, calorías, ejercicio, frecuencia cardiaca, sueño).
  static List<HealthDataType> get _readTypes => [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME,
        HealthDataType.HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_IN_BED,
      ];

  static List<HealthDataAccess> get _readPermissions =>
      List.filled(_readTypes.length, HealthDataAccess.READ);

  Future<bool> requestPermissions() async {
    await init();
    return _health.requestAuthorization(_readTypes, permissions: _readPermissions);
  }

  static double? _numericFromPoint(HealthDataPoint point) {
    final v = point.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return null;
  }

  /// Pasos de hoy (desde medianoche).
  Future<int?> getTodaySteps() async {
    await init();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    // Para evitar duplicados entre iPhone y Apple Watch, la mejor forma
    // es usar la función nativa de HealthKit para pasos totales.
    return _health.getTotalStepsInInterval(midnight, now);
  }

  /// Calorías activas de hoy (kcal).
  Future<double?> getTodayActiveCalories() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final list = await _health.getHealthDataFromTypes(
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: midnight,
      endTime: now,
    );
    if (list.isEmpty) return null;
    double sum = 0;
    for (final point in list) {
      final v = _numericFromPoint(point);
      if (v != null) sum += v;
    }
    return sum;
  }

  /// Minutos de ejercicio de hoy (Apple: "move time" / ejercicio).
  Future<int?> getTodayExerciseMinutes() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final list = await _health.getHealthDataFromTypes(
      types: [HealthDataType.EXERCISE_TIME],
      startTime: midnight,
      endTime: now,
    );
    if (list.isEmpty) return null;
    double sum = 0;
    for (final point in list) {
      final v = _numericFromPoint(point);
      if (v != null) sum += v;
    }
    return sum.round();
  }

  /// Frecuencia cardiaca últimas 24 h (último valor para mostrar).
  Future<List<HealthDataPoint>> getHeartRateLast24h() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    return _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE],
      startTime: yesterday,
      endTime: now,
    );
  }

  /// HRV (variabilidad cardíaca) últimas 24 h; último valor en ms.
  Future<double?> getLastHRV() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    final list = await _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
      startTime: yesterday,
      endTime: now,
    );
    if (list.isEmpty) return null;
    final last = list.last;
    return _numericFromPoint(last);
  }

  /// Sueño última noche (tipos de fase de sueño); duración total en horas.
  Future<double?> getSleepLastNightHours() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    final list = await _health.getHealthDataFromTypes(
      types: [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_IN_BED,
      ],
      startTime: yesterday,
      endTime: now,
    );
    if (list.isEmpty) return null;
    double totalMinutes = 0;
    final seen = <String>{};
    for (final point in list) {
      final end = point.dateTo;
      final key = '${point.dateFrom.millisecondsSinceEpoch}-${end.millisecondsSinceEpoch}';
      if (seen.contains(key)) continue;
      seen.add(key);
      totalMinutes += end.difference(point.dateFrom).inMinutes.toDouble();
    }
    return totalMinutes / 60.0;
  }

  /// Carga todos los datos de hoy para la pantalla de fitness.
  /// Devuelve null si no hay permiso o no se puede leer (ej. en escritorio).
  Future<AppleHealthData?> fetchTodayData() async {
    try {
      final granted = await requestPermissions();
      if (!granted) return null;

      final steps = await getTodaySteps();
      final calories = await getTodayActiveCalories();
      final exerciseMinutes = await getTodayExerciseMinutes();
      final heartRateList = await getHeartRateLast24h();
      final hrv = await getLastHRV();
      final sleepHours = await getSleepLastNightHours();

      double? lastHeartRate;
      if (heartRateList.isNotEmpty) {
        lastHeartRate = _numericFromPoint(heartRateList.last);
      }

      return AppleHealthData(
        steps: steps ?? 0,
        activeCalories: calories != null ? calories.round() : 0,
        exerciseMinutes: exerciseMinutes ?? 0,
        lastHeartRate: lastHeartRate,
        hrvMs: hrv,
        sleepLastNightHours: sleepHours,
      );
    } catch (_) {
      return null;
    }
  }

  /// Comprueba si la plataforma soporta Health (iOS o Android con Health Connect).
  static bool get isSupported => Platform.isIOS || Platform.isAndroid;
}

/// DTO con los datos de salud leídos para la pantalla de fitness.
class AppleHealthData {
  const AppleHealthData({
    this.steps,
    this.activeCalories,
    this.exerciseMinutes,
    this.lastHeartRate,
    this.hrvMs,
    this.sleepLastNightHours,
  });

  final int? steps;
  final int? activeCalories;
  final int? exerciseMinutes;
  final double? lastHeartRate;
  final double? hrvMs;
  final double? sleepLastNightHours;
}
