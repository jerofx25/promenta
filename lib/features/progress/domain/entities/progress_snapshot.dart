class DailyActivity {
  final int caloriesBurned;
  final int steps;
  final int distanceKm;
  final int activeMinutes;

  const DailyActivity({
    required this.caloriesBurned,
    required this.steps,
    required this.distanceKm,
    required this.activeMinutes,
  });
}

class ProgressSnapshot {
  final DailyActivity today;
  final List<double> weeklyWorkoutHours;
  final List<double> heartRateBpm;

  const ProgressSnapshot({
    required this.today,
    required this.weeklyWorkoutHours,
    required this.heartRateBpm,
  });
}

