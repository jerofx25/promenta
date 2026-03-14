import 'package:flutter_test/flutter_test.dart';
import 'package:IAEntrenar/features/workout/application/workout_cubit.dart';
import 'package:IAEntrenar/features/workout/domain/entities/workout.dart';
import 'package:IAEntrenar/features/workout/domain/repositories/workout_repository.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  @override
  Future<List<Workout>> fetchWorkouts() async {
    final component = WorkoutComponent(
      title: 'Test',
      exercises: const ['Push up'],
    );
    return [
      Workout(
        id: '1',
        name: 'Test workout',
        type: WorkoutType.endurance,
        difficulty: DifficultyLevel.basic,
        warmup: component,
        strength: component,
        wod: component,
        cooldown: component,
        mobilityExercises: const [],
      ),
    ];
  }

  @override
  Future<void> saveWorkouts(List<Workout> workouts) async {}
}

void main() {
  group('WorkoutCubit', () {
    test('loadWorkouts carga lista y selecciona el primero', () async {
      final cubit =
          WorkoutCubit(workoutRepository: _FakeWorkoutRepository());

      await cubit.loadWorkouts();

      final state = cubit.state;
      expect(state.isLoading, false);
      expect(state.workouts.length, 1);
      expect(state.selectedWorkout?.id, '1');
    });
  });
}


