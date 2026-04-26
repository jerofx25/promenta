import 'package:IAEntrenar/features/ai_coach/domain/daily_coach_result.dart';
import 'package:equatable/equatable.dart';

enum DailyCoachStatus {
  idle,
  downloadingModel,
  generating,
  ready,
  error,
}

class DailyCoachState extends Equatable {
  const DailyCoachState({
    required this.status,
    required this.downloadProgress,
    required this.result,
    required this.error,
    required this.cacheKey,
  });

  final DailyCoachStatus status;
  final double? downloadProgress; // 0..1
  final DailyCoachResult? result;
  final String? error;
  final String? cacheKey;

  const DailyCoachState.initial()
      : status = DailyCoachStatus.idle,
        downloadProgress = null,
        result = null,
        error = null,
        cacheKey = null;

  DailyCoachState copyWith({
    DailyCoachStatus? status,
    double? downloadProgress,
    DailyCoachResult? result,
    String? error,
    String? cacheKey,
    bool clearResult = false,
  }) {
    return DailyCoachState(
      status: status ?? this.status,
      downloadProgress: downloadProgress,
      result: clearResult ? null : result ?? this.result,
      error: error,
      cacheKey: cacheKey ?? this.cacheKey,
    );
  }

  @override
  List<Object?> get props => [
        status,
        downloadProgress,
        result,
        error,
        cacheKey,
      ];
}
