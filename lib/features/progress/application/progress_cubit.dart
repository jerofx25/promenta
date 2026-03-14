import 'package:bloc/bloc.dart';

import '../domain/repositories/progress_repository.dart';
import 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({required ProgressRepository progressRepository})
      : _progressRepository = progressRepository,
        super(const ProgressState.initial());

  final ProgressRepository _progressRepository;

  Future<void> loadProgress() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final snapshot = await _progressRepository.fetchProgress();
      emit(
        state.copyWith(
          isLoading: false,
          snapshot: snapshot,
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
}

