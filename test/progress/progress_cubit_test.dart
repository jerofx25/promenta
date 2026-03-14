import 'package:flutter_test/flutter_test.dart';
import 'package:IAEntrenar/features/progress/application/progress_cubit.dart';
import 'package:IAEntrenar/features/progress/domain/entities/progress_snapshot.dart';
import 'package:IAEntrenar/features/progress/domain/repositories/progress_repository.dart';

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<ProgressSnapshot> fetchProgress() async {
    return ProgressSnapshot(
      today: const DailyActivity(
        caloriesBurned: 500,
        steps: 8000,
        distanceKm: 5,
        activeMinutes: 45,
      ),
      weeklyWorkoutHours: const [1, 2, 3],
      heartRateBpm: const [60, 70, 80],
    );
  }
}

void main() {
  group('ProgressCubit', () {
    test('loadProgress carga snapshot sin error', () async {
      final cubit =
          ProgressCubit(progressRepository: _FakeProgressRepository());

      await cubit.loadProgress();

      final state = cubit.state;
      expect(state.isLoading, false);
      expect(state.snapshot, isNotNull);
      expect(state.snapshot!.today.caloriesBurned, 500);
    });
  });
}

