import 'package:IAEntrenar/features/ai_workout/infrastructure/ai_workout_generator_service.dart';
import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:IAEntrenar/services/apple_health_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

enum AiWorkoutStatus { idle, running, ready, error }

class AiWorkoutState extends Equatable {
  const AiWorkoutState({
    required this.status,
    required this.requestId,
    required this.current,
    required this.proposed,
    required this.error,
  });

  final AiWorkoutStatus status;
  final String? requestId;
  final WorkupDay? current;
  final WorkupDay? proposed;
  final String? error;

  const AiWorkoutState.initial()
      : status = AiWorkoutStatus.idle,
        requestId = null,
        current = null,
        proposed = null,
        error = null;

  AiWorkoutState copyWith({
    AiWorkoutStatus? status,
    String? requestId,
    WorkupDay? current,
    WorkupDay? proposed,
    String? error,
  }) {
    return AiWorkoutState(
      status: status ?? this.status,
      requestId: requestId ?? this.requestId,
      current: current ?? this.current,
      proposed: proposed ?? this.proposed,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, requestId, current, proposed, error];
}

class AiWorkoutCubit extends Cubit<AiWorkoutState> {
  AiWorkoutCubit({AiWorkoutGeneratorService? service})
      : _service = service ?? AiWorkoutGeneratorService(),
        super(const AiWorkoutState.initial());

  final AiWorkoutGeneratorService _service;

  Future<void> generate({
    required WorkupDay current,
    required UserProfile profile,
    required List<String> catalog,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    emit(state.copyWith(
      status: AiWorkoutStatus.running,
      requestId: requestId,
      current: current,
      proposed: null,
      error: null,
    ));
    try {
      double? sleepHours;
      try {
        final health = AppleHealthService();
        if (await health.requestPermissions()) {
          sleepHours = await health.getSleepLastNightHours();
        }
      } catch (_) {}

      final result = await _service.generateAlternative(
        current: current,
        profile: profile,
        catalog: catalog,
        sleepHours: sleepHours,
      );
      emit(state.copyWith(
        status: AiWorkoutStatus.ready,
        proposed: result.day,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AiWorkoutStatus.error,
        error: e.toString(),
      ));
    }
  }

  void reset() {
    emit(const AiWorkoutState.initial());
  }

  @override
  Future<void> close() async {
    await _service.dispose();
    return super.close();
  }
}

