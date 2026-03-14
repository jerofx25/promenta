import 'package:bloc/bloc.dart';

import '../domain/entities/workout.dart';
import '../domain/repositories/workout_repository.dart';
import 'workout_state.dart';

class WorkoutCubit extends Cubit<WorkoutState> {
  WorkoutCubit({required WorkoutRepository workoutRepository})
      : _workoutRepository = workoutRepository,
        super(const WorkoutState.initial());

  final WorkoutRepository _workoutRepository;

  Future<void> loadWorkouts() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final workouts = await _workoutRepository.fetchWorkouts();
      emit(
        state.copyWith(
          isLoading: false,
          workouts: workouts,
          selectedWorkout:
              workouts.isNotEmpty ? workouts.first : state.selectedWorkout,
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

  void selectWorkout(String id) {
    final workout =
        state.workouts.firstWhere((w) => w.id == id, orElse: () => state.workouts.first);
    emit(state.copyWith(selectedWorkout: workout));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void toggleTypeFilter(WorkoutType type) {
    final updated = Set<WorkoutType>.from(state.selectedTypes);
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    emit(state.copyWith(selectedTypes: updated));
  }

  void resetTypeFilters() {
    emit(state.copyWith(selectedTypes: <WorkoutType>{}));
  }

  void setDifficultyFilter(DifficultyLevel? difficulty) {
    emit(state.copyWith(selectedDifficulty: difficulty));
  }
}

