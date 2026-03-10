import 'package:equatable/equatable.dart';

import '../../models/user_profile.dart';

enum OnboardingStatus {
  idle,
  inProgress,
  completed,
}

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final int currentStep;
  final int totalSteps;
  final UserProfile? profile;

  const OnboardingState({
    required this.status,
    required this.currentStep,
    required this.totalSteps,
    required this.profile,
  });

  const OnboardingState.initial()
      : status = OnboardingStatus.idle,
        currentStep = 0,
        totalSteps = 7,
        profile = null;

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? currentStep,
    int? totalSteps,
    UserProfile? profile,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [status, currentStep, totalSteps, profile];
}

