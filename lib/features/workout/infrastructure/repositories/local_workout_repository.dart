import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/local_workout_datasource.dart';

class LocalWorkoutRepository implements WorkoutRepository {
  LocalWorkoutRepository(this._dataSource);

  final LocalWorkoutDataSource _dataSource;

  @override
  Future<List<Workout>> fetchWorkouts() {
    return _dataSource.loadWorkouts();
  }

  @override
  Future<void> saveWorkouts(List<Workout> workouts) {
    return _dataSource.saveWorkouts(workouts);
  }
}

