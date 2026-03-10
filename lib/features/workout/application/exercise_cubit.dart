import 'package:bloc/bloc.dart';

import '../domain/entities/exercise.dart';
import '../domain/repositories/exercise_repository.dart';
import 'exercise_state.dart';

class ExerciseCubit extends Cubit<ExerciseState> {
  ExerciseCubit({required ExerciseRepository exerciseRepository})
      : _exerciseRepository = exerciseRepository,
        super(const ExerciseState.initial());

  final ExerciseRepository _exerciseRepository;

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final exercises = await _exerciseRepository.fetchExercises();
      final progress = await _exerciseRepository.fetchProgress();

      emit(
        state.copyWith(
          isLoading: false,
          exercises: exercises,
          progress: progress,
          selectedExercise:
              exercises.isNotEmpty ? exercises.first : state.selectedExercise,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void selectExercise(String id) {
    final exercise = state.exercises.firstWhere(
      (e) => e.id == id,
      orElse: () => state.exercises.first,
    );
    emit(state.copyWith(selectedExercise: exercise));
  }

  Future<void> addExercise(String name, double maxWeight) async {
    final newExercise = Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      maxWeight: maxWeight,
      date: DateTime.now(),
    );
    final updatedExercises = [...state.exercises, newExercise];

    final newProgress = ExerciseProgress(
      exerciseId: newExercise.id,
      weight: maxWeight,
      date: DateTime.now(),
    );
    final updatedProgress = [...state.progress, newProgress];

    await _exerciseRepository.saveExercises(updatedExercises);
    await _exerciseRepository.saveProgress(updatedProgress);

    emit(
      state.copyWith(
        exercises: updatedExercises,
        progress: updatedProgress,
        selectedExercise: newExercise,
      ),
    );
  }

  Future<void> updateExercise(
    String id,
    String name,
    double maxWeight,
  ) async {
    final updatedExercises = state.exercises.map((e) {
      if (e.id == id) {
        return e.copyWith(
          name: name,
          maxWeight: maxWeight,
          date: DateTime.now(),
        );
      }
      return e;
    }).toList();

    final newProgress = ExerciseProgress(
      exerciseId: id,
      weight: maxWeight,
      date: DateTime.now(),
    );
    final updatedProgress = [...state.progress, newProgress];

    await _exerciseRepository.saveExercises(updatedExercises);
    await _exerciseRepository.saveProgress(updatedProgress);

    final selected =
        state.selectedExercise?.id == id ? updatedExercises.firstWhere((e) => e.id == id) : state.selectedExercise;

    emit(
      state.copyWith(
        exercises: updatedExercises,
        progress: updatedProgress,
        selectedExercise: selected,
      ),
    );
  }

  Future<void> deleteExercise(String id) async {
    final updatedExercises =
        state.exercises.where((e) => e.id != id).toList();
    final updatedProgress =
        state.progress.where((p) => p.exerciseId != id).toList();

    await _exerciseRepository.saveExercises(updatedExercises);
    await _exerciseRepository.saveProgress(updatedProgress);

    final selected =
        state.selectedExercise?.id == id && updatedExercises.isNotEmpty
            ? updatedExercises.first
            : state.selectedExercise;

    emit(
      state.copyWith(
        exercises: updatedExercises,
        progress: updatedProgress,
        selectedExercise: selected,
      ),
    );
  }

  List<ExerciseProgress> getProgressForExercise(
    String exerciseId, {
    bool ascending = true,
  }) {
    final list =
        state.progress.where((p) => p.exerciseId == exerciseId).toList();
    list.sort(
      (a, b) =>
          ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
    );
    return list;
  }

  List<Map<String, dynamic>> calculateRMPercentages(double maxWeight) {
    final List<Map<String, dynamic>> percentages = [];
    for (int percent = 10; percent <= 100; percent += 5) {
      percentages.add({
        'percent': percent,
        'weight': (maxWeight * percent / 100).toStringAsFixed(1),
      });
    }
    return percentages;
  }
}

