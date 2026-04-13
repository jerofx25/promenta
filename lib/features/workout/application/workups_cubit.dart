import 'package:bloc/bloc.dart';

import 'package:IAEntrenar/features/workout/infrastructure/repositories/workups_firestore_repository.dart';
import 'package:IAEntrenar/models/workup_day.dart';

import 'workups_state.dart';

class WorkupsCubit extends Cubit<WorkupsState> {
  WorkupsCubit({required WorkupsFirestoreRepository workupsRepository})
      : _workupsRepository = workupsRepository,
        super(const WorkupsState.initial());

  final WorkupsFirestoreRepository _workupsRepository;

  Future<void> loadWorkupDays() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final List<WorkupDay> days = await _workupsRepository.getWorkupDays();
      emit(state.copyWith(workupDays: days, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void toggleTypeFilter(WorkupType type) {
    final updated = Set<WorkupType>.from(state.selectedTypes);
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    emit(state.copyWith(selectedTypes: updated));
  }

  void selectWorkupDay(int dayNumber) {
    final workupDay =
      state.workupDays.firstWhere((w) => w.dayNumber == dayNumber, orElse: () => state.workupDays.first);
    emit(state.copyWith(selectedWorkupDay: workupDay));
  }

  void resetTypeFilters() {
    emit(state.copyWith(selectedTypes: <WorkupType>{}));
  }

  void setDifficultyFilter(DifficultyLevel? difficulty) {
    emit(state.copyWith(selectedDifficulty: difficulty));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
