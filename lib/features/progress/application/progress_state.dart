import 'package:equatable/equatable.dart';

import '../domain/entities/progress_snapshot.dart';

class ProgressState extends Equatable {
  final ProgressSnapshot? snapshot;
  final bool isLoading;
  final String? error;

  const ProgressState({
    required this.snapshot,
    required this.isLoading,
    required this.error,
  });

  const ProgressState.initial()
      : snapshot = null,
        isLoading = false,
        error = null;

  ProgressState copyWith({
    ProgressSnapshot? snapshot,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [snapshot, isLoading, error];
}

