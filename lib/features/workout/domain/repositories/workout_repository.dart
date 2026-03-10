import '../entities/workout.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> fetchWorkouts();

  Future<void> saveWorkouts(List<Workout> workouts);
}

