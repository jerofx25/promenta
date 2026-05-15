import 'package:IAEntrenar/features/meals/domain/daily_meal_plan.dart';
import 'package:equatable/equatable.dart';

enum DailyMealPlanStatus {
  idle,
  downloadingModel,
  generating,
  ready,
  error,
}

class DailyMealPlanState extends Equatable {
  const DailyMealPlanState({
    required this.status,
    required this.plan,
    required this.error,
    required this.downloadProgress,
  });

  final DailyMealPlanStatus status;
  final DailyMealPlan? plan;
  final String? error;
  final double? downloadProgress;

  const DailyMealPlanState.initial()
      : status = DailyMealPlanStatus.idle,
        plan = null,
        error = null,
        downloadProgress = null;

  DailyMealPlanState copyWith({
    DailyMealPlanStatus? status,
    DailyMealPlan? plan,
    String? error,
    double? downloadProgress,
  }) {
    return DailyMealPlanState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      error: error,
      downloadProgress: downloadProgress,
    );
  }

  @override
  List<Object?> get props => [status, plan, error, downloadProgress];
}
