import '../../domain/entities/progress_snapshot.dart';

class LocalProgressDataSource {
  Future<ProgressSnapshot> loadProgress() async {
    // Datos locales de ejemplo, hoy hardcodeados pero encapsulados
    // para poder sustituir por datos reales (API, wearables, etc.).
    const today = DailyActivity(
      caloriesBurned: 685,
      steps: 8754,
      distanceKm: 5,
      activeMinutes: 62,
    );

    const weeklyWorkoutHours = <double>[3, 4, 1, 2, 5, 2, 3];

    const heartRateBpm = <double>[72, 74, 95, 120, 110, 89, 75, 70];

    return const ProgressSnapshot(
      today: today,
      weeklyWorkoutHours: weeklyWorkoutHours,
      heartRateBpm: heartRateBpm,
    );
  }
}

