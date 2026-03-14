import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/exercise.dart';

class LocalExerciseDataSource {
  static const _exercisesKey = 'exercises';
  static const _progressKey = 'progress_data';

  Future<List<Exercise>> loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = prefs.getStringList(_exercisesKey) ?? [];

    return exercisesJson
        .map((json) => Exercise.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveExercises(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson =
        exercises.map((exercise) => jsonEncode(exercise.toJson())).toList();
    await prefs.setStringList(_exercisesKey, exercisesJson);
  }

  Future<List<ExerciseProgress>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getStringList(_progressKey) ?? [];

    return progressJson
        .map((json) => ExerciseProgress.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveProgress(List<ExerciseProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson =
        progress.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList(_progressKey, progressJson);
  }
}

