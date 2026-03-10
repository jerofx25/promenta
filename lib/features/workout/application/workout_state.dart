import 'package:equatable/equatable.dart';

import '../domain/entities/workout.dart';

class WorkoutState extends Equatable {
  final List<Workout> workouts;
  final Workout? selectedWorkout;
  final Set<WorkoutType> selectedTypes;
  final DifficultyLevel? selectedDifficulty;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const WorkoutState({
    required this.workouts,
    required this.selectedWorkout,
    required this.selectedTypes,
    required this.selectedDifficulty,
    required this.searchQuery,
    required this.isLoading,
    required this.error,
  });

  const WorkoutState.initial()
      : workouts = const [],
        selectedWorkout = null,
        selectedTypes = const {},
        selectedDifficulty = null,
        searchQuery = '',
        isLoading = false,
        error = null;

  WorkoutState copyWith({
    List<Workout>? workouts,
    Workout? selectedWorkout,
    Set<WorkoutType>? selectedTypes,
    DifficultyLevel? selectedDifficulty,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      selectedWorkout: selectedWorkout ?? this.selectedWorkout,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Workout> get filteredWorkouts {
    var result = workouts;

    if (selectedTypes.isNotEmpty) {
      result =
          result.where((w) => selectedTypes.contains(w.type)).toList();
    }

    if (selectedDifficulty != null) {
      result = result
          .where((w) => w.difficulty == selectedDifficulty)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (w) =>
                w.name.toLowerCase().contains(q) ||
                (w.description ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [
        workouts,
        selectedWorkout,
        selectedTypes,
        selectedDifficulty,
        searchQuery,
        isLoading,
        error,
      ];
}

