import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const OnboardingState.initial()) {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<UserProfile?>? _profileSubscription;

  void _init() {
    _profileSubscription = _authRepository.currentUserProfile().listen((profile) {
      if (profile == null) {
        emit(const OnboardingState.initial());
        return;
      }

      final status = profile.onboardingCompleted
          ? OnboardingStatus.completed
          : OnboardingStatus.inProgress;
      final step = profile.onboardingCompleted
          ? state.totalSteps - 1
          : (profile.onboardingStep ?? _calculateLegacyStep(profile))
              .clamp(0, state.totalSteps - 1);

      emit(
        state.copyWith(
          status: status,
          currentStep: step,
          profile: profile,
        ),
      );
    });
  }

  int _calculateLegacyStep(UserProfile profile) {
    if (profile.age == null) {
      return 0;
    } else if (profile.height == null) {
      return 1;
    } else if (profile.weight == null) {
      return 2;
    } else if (profile.injuries.isEmpty) {
      return 3;
    } else if (profile.goals.isEmpty || profile.trainingLevel == null) {
      return 4;
    } else if (profile.photoUrl == null) {
      return 5;
    } else {
      return 6;
    }
  }

  Future<void> saveStep({
    required int currentStep,
    Map<String, dynamic> fields = const {},
  }) async {
    final nextStep = _getNextStep(currentStep);
    final payload = {
      ...fields,
      'onboardingStep': nextStep,
      'onboardingCompleted': false,
    };

    await _authRepository.updateUserFields(payload);

    emit(
      state.copyWith(
        status: OnboardingStatus.inProgress,
        currentStep: nextStep,
        profile: state.profile == null
            ? null
            : _applyFieldsToProfile(state.profile!, payload),
      ),
    );
  }

  Future<void> completeOnboarding({
    Map<String, dynamic> fields = const {},
  }) async {
    final payload = {
      ...fields,
      'onboardingStep': state.totalSteps,
      'onboardingCompleted': true,
    };

    await _authRepository.updateUserFields(payload);

    emit(
      state.copyWith(
        status: OnboardingStatus.completed,
        currentStep: state.totalSteps - 1,
        profile: state.profile == null
            ? null
            : _applyFieldsToProfile(state.profile!, payload),
      ),
    );
  }

  int _getNextStep(int currentStep) {
    if (currentStep >= state.totalSteps - 1) {
      return state.totalSteps - 1;
    }

    return currentStep + 1;
  }

  UserProfile _applyFieldsToProfile(
    UserProfile profile,
    Map<String, dynamic> fields,
  ) {
    return profile.copyWith(
      phone: fields.containsKey('phone') ? fields['phone'] as String? : null,
      photoUrl:
          fields.containsKey('photoUrl') ? fields['photoUrl'] as String? : null,
      age: fields.containsKey('age') ? fields['age'] as int? : null,
      gender: fields.containsKey('gender') ? fields['gender'] as String? : null,
      height: fields.containsKey('height')
          ? (fields['height'] as num?)?.toDouble()
          : null,
      weight: fields.containsKey('weight')
          ? (fields['weight'] as num?)?.toDouble()
          : null,
      bodyFatPercentage: fields.containsKey('bodyFatPercentage')
          ? (fields['bodyFatPercentage'] as num?)?.toDouble()
          : null,
      bmi:
          fields.containsKey('bmi') ? (fields['bmi'] as num?)?.toDouble() : null,
      goals: fields.containsKey('goals')
          ? List<String>.from(fields['goals'] as List<dynamic>)
          : null,
      injuries: fields.containsKey('injuries')
          ? List<String>.from(fields['injuries'] as List<dynamic>)
          : null,
      trainingLevel: fields.containsKey('trainingLevel')
          ? fields['trainingLevel'] as String?
          : null,
      onboardingStep: fields.containsKey('onboardingStep')
          ? fields['onboardingStep'] as int?
          : null,
      onboardingCompleted: fields.containsKey('onboardingCompleted')
          ? fields['onboardingCompleted'] as bool?
          : null,
    );
  }

  @override
  Future<void> close() async {
    await _profileSubscription?.cancel();
    return super.close();
  }
}

