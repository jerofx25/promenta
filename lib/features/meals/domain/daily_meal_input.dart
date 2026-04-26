import 'dart:convert';

import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:equatable/equatable.dart';

class DailyMealInput extends Equatable {
  const DailyMealInput({
    required this.dateIso,
    required this.profile,
    required this.health,
    required this.recovery,
    required this.workout,
  });

  final String dateIso;
  final DailyMealProfile profile;
  final VerifiedAppleHealthData? health;
  final DailyMealRecoveryMetrics? recovery;
  final DailyMealWorkoutContext workout;

  factory DailyMealInput.from({
    required DateTime now,
    required UserProfile profile,
    required VerifiedAppleHealthData? health,
    required DailyMealRecoveryMetrics? recovery,
    required WorkupDay? selectedWorkout,
  }) {
    return DailyMealInput(
      dateIso: DateTime(now.year, now.month, now.day).toIso8601String(),
      profile: DailyMealProfile.fromUserProfile(profile),
      health: health,
      recovery: recovery,
      workout: DailyMealWorkoutContext.fromWorkupDay(selectedWorkout),
    );
  }

  Map<String, dynamic> toJson() => {
        'dateIso': dateIso,
        'profile': profile.toJson(),
        if (health != null) 'appleHealth': health!.toJson(),
        if (recovery != null) 'internalMetrics': recovery!.toJson(),
        'workout': workout.toJson(),
      };

  String toCompactJson() => jsonEncode(toJson());

  @override
  List<Object?> get props => [dateIso, profile, health, recovery, workout];
}

class DailyMealProfile extends Equatable {
  const DailyMealProfile({
    required this.age,
    required this.heightCm,
    required this.gender,
    required this.weightKg,
    required this.goals,
    required this.trainingLevel,
  });

  final int? age;
  final double? heightCm;
  final String? gender;
  final double? weightKg;
  final List<String> goals;
  final String? trainingLevel;

  factory DailyMealProfile.fromUserProfile(UserProfile profile) {
    return DailyMealProfile(
      age: profile.age,
      heightCm: profile.height,
      gender: profile.gender,
      weightKg: profile.weight,
      goals: profile.goals,
      trainingLevel: profile.trainingLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        if (age != null) 'age': age,
        if (heightCm != null) 'heightCm': heightCm,
        if (gender != null && gender!.trim().isNotEmpty) 'gender': gender,
        if (weightKg != null) 'weightKg': weightKg,
        'goals': goals,
        if (trainingLevel != null && trainingLevel!.trim().isNotEmpty)
          'trainingLevel': trainingLevel,
      };

  @override
  List<Object?> get props => [
        age,
        heightCm,
        gender,
        weightKg,
        goals,
        trainingLevel,
      ];
}

class VerifiedAppleHealthData extends Equatable {
  const VerifiedAppleHealthData({
    this.steps,
    this.activeCalories,
    this.exerciseMinutes,
    this.hrvMs,
    this.sleepLastNightHours,
  });

  final int? steps;
  final int? activeCalories;
  final int? exerciseMinutes;
  final double? hrvMs;
  final double? sleepLastNightHours;

  bool get isEmpty =>
      steps == null &&
      activeCalories == null &&
      exerciseMinutes == null &&
      hrvMs == null &&
      sleepLastNightHours == null;

  Map<String, dynamic> toJson() => {
        if (steps != null) 'steps': steps,
        if (activeCalories != null) 'activeCalories': activeCalories,
        if (exerciseMinutes != null) 'exerciseMinutes': exerciseMinutes,
        if (hrvMs != null) 'hrvMs': hrvMs,
        if (sleepLastNightHours != null)
          'sleepLastNightHours': sleepLastNightHours,
        'sourcePolicy': 'only_positive_user_recorded_values',
      };

  @override
  List<Object?> get props => [
        steps,
        activeCalories,
        exerciseMinutes,
        hrvMs,
        sleepLastNightHours,
      ];
}

class DailyMealRecoveryMetrics extends Equatable {
  const DailyMealRecoveryMetrics({
    required this.stress,
    required this.recovery,
  });

  final double stress;
  final double recovery;

  Map<String, dynamic> toJson() => {
        'stress': double.parse(stress.toStringAsFixed(1)),
        'recovery': double.parse(recovery.toStringAsFixed(1)),
        'scale': '0-100',
      };

  @override
  List<Object?> get props => [stress, recovery];
}

class DailyMealWorkoutContext extends Equatable {
  const DailyMealWorkoutContext({
    required this.isRestDay,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.movements,
  });

  final bool isRestDay;
  final String title;
  final String? type;
  final String? difficulty;
  final List<String> movements;

  factory DailyMealWorkoutContext.fromWorkupDay(WorkupDay? day) {
    if (day == null) {
      return const DailyMealWorkoutContext(
        isRestDay: true,
        title: 'Dia de descanso',
        type: null,
        difficulty: null,
        movements: [],
      );
    }

    return DailyMealWorkoutContext(
      isRestDay: false,
      title: day.title,
      type: day.type.name,
      difficulty: day.difficulty.name,
      movements: _extractMovements(day),
    );
  }

  Map<String, dynamic> toJson() => {
        'isRestDay': isRestDay,
        'title': title,
        if (type != null) 'type': type,
        if (difficulty != null) 'difficulty': difficulty,
        'movements': movements,
      };

  static List<String> _extractMovements(WorkupDay day) {
    final result = <String>[];
    for (final warmUp in day.warmUp ?? const <WarmUp>[]) {
      final movement = warmUp.movement;
      if (movement != null && movement.trim().isNotEmpty) {
        result.add(movement.trim());
      }
      for (final exercise in warmUp.exercises ?? const <MovementElement>[]) {
        if (exercise.movement.trim().isNotEmpty) {
          result.add(exercise.movement.trim());
        }
      }
    }

    for (final block in day.blocks) {
      for (final movement in block.movements ?? const <String>[]) {
        if (movement.trim().isNotEmpty) result.add(movement.trim());
      }
      for (final exercise in block.exercises ?? const <BlockExercise>[]) {
        final movement = exercise.movement;
        if (movement != null && movement.trim().isNotEmpty) {
          result.add(movement.trim());
        }
        for (final nested in exercise.movements ?? const <MovementElement>[]) {
          if (nested.movement.trim().isNotEmpty) {
            result.add(nested.movement.trim());
          }
        }
      }
      for (final part in block.parts ?? const <Part>[]) {
        final movement = part.movement;
        if (movement != null && movement.trim().isNotEmpty) {
          result.add(movement.trim());
        }
      }
    }

    final seen = <String>{};
    return result
        .where((m) => m.toLowerCase() != 'rest')
        .where((m) => seen.add(m.toLowerCase()))
        .take(20)
        .toList();
  }

  @override
  List<Object?> get props => [
        isRestDay,
        title,
        type,
        difficulty,
        movements,
      ];
}
