import '../entities/exercise.dart';

abstract class ExerciseRepository {
  Future<List<Exercise>> fetchExercises();

  Future<void> saveExercises(List<Exercise> exercises);

  Future<List<ExerciseProgress>> fetchProgress();

  Future<void> saveProgress(List<ExerciseProgress> progress);
}

