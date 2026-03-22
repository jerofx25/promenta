import 'package:IAEntrenar/models/workup_day.dart';
import 'package:equatable/equatable.dart';

/// Marca parámetros omitidos en [copyWith] (distinto de pasar `null` a propósito).
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class WorkupsState extends Equatable {
  final List<WorkupDay> workupDays;
  final WorkupDay? selectedWorkupDay;
  final Set<WorkupType> selectedTypes;
  final DifficultyLevel? selectedDifficulty;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const WorkupsState({
    required this.workupDays,
    required this.selectedWorkupDay,
    required this.selectedTypes,
    required this.selectedDifficulty,
    required this.searchQuery,
    required this.isLoading,
    required this.error,
  });

  const WorkupsState.initial()
      : workupDays = const [],
        selectedWorkupDay = null,
        selectedTypes = const {},
        selectedDifficulty = null,
        searchQuery = '',
        isLoading = false,
        error = null;

  WorkupsState copyWith({
    List<WorkupDay>? workupDays,
    Object? selectedWorkupDay = _unset,
    Set<WorkupType>? selectedTypes,
    Object? selectedDifficulty = _unset,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return WorkupsState(
      workupDays: workupDays ?? this.workupDays,
      selectedWorkupDay: identical(selectedWorkupDay, _unset)
          ? this.selectedWorkupDay
          : selectedWorkupDay as WorkupDay?,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedDifficulty: identical(selectedDifficulty, _unset)
          ? this.selectedDifficulty
          : selectedDifficulty as DifficultyLevel?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<WorkupDay> get filteredWorkupDays {
    var result = workupDays;

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
                w.title.toLowerCase().contains(q) ||
                (w.description).toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [
        workupDays,
        selectedWorkupDay,
        selectedTypes,
        selectedDifficulty,
        searchQuery,
        isLoading,
        error,
      ];
}
