import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/local_exercise_datasource.dart';

class LocalExerciseRepository implements ExerciseRepository {
  LocalExerciseRepository(this._dataSource);

  final LocalExerciseDataSource _dataSource;

  @override
  Future<List<Exercise>> fetchExercises() {
    return _dataSource.loadExercises();
  }

  @override
  Future<void> saveExercises(List<Exercise> exercises) {
    return _dataSource.saveExercises(exercises);
  }

  @override
  Future<List<ExerciseProgress>> fetchProgress() {
    return _dataSource.loadProgress();
  }

  @override
  Future<void> saveProgress(List<ExerciseProgress> progress) {
    return _dataSource.saveProgress(progress);
  }
}

