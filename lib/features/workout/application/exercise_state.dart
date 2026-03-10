import 'package:equatable/equatable.dart';

import '../domain/entities/exercise.dart';

class ExerciseState extends Equatable {
  final List<Exercise> exercises;
  final List<ExerciseProgress> progress;
  final Exercise? selectedExercise;
  final bool isLoading;
  final String? error;

  const ExerciseState({
    required this.exercises,
    required this.progress,
    required this.selectedExercise,
    required this.isLoading,
    required this.error,
  });

  const ExerciseState.initial()
      : exercises = const [],
        progress = const [],
        selectedExercise = null,
        isLoading = false,
        error = null;

  ExerciseState copyWith({
    List<Exercise>? exercises,
    List<ExerciseProgress>? progress,
    Exercise? selectedExercise,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      progress: progress ?? this.progress,
      selectedExercise: selectedExercise ?? this.selectedExercise,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        exercises,
        progress,
        selectedExercise,
        isLoading,
        error,
      ];
}

