import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';

class ExerciseProvider extends ChangeNotifier {
  List<Exercise> _exercises = [];
  List<ExerciseProgress> _progressData = [];
  Exercise? _selectedExercise;

  List<Exercise> get exercises => _exercises;
  List<ExerciseProgress> get progressData => _progressData;
  Exercise? get selectedExercise => _selectedExercise;

  // Constructor loads data from local storage
  ExerciseProvider() {
    _loadExercises();
    _loadProgressData();
  }

  // Load exercises from SharedPreferences
  Future<void> _loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = prefs.getStringList('exercises') ?? [];
    
    _exercises = exercisesJson
        .map((json) => Exercise.fromJson(jsonDecode(json)))
        .toList();
    
    if (_exercises.isNotEmpty && _selectedExercise == null) {
      _selectedExercise = _exercises.first;
    }
    
    notifyListeners();
  }

  // Save exercises to SharedPreferences
  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = _exercises
        .map((exercise) => jsonEncode(exercise.toJson()))
        .toList();
    
    await prefs.setStringList('exercises', exercisesJson);
  }

  // Load progress data from SharedPreferences
  Future<void> _loadProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getStringList('progress_data') ?? [];
    
    _progressData = progressJson
        .map((json) => ExerciseProgress.fromJson(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  // Save progress data to SharedPreferences
  Future<void> _saveProgressData() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = _progressData
        .map((progress) => jsonEncode(progress.toJson()))
        .toList();
    
    await prefs.setStringList('progress_data', progressJson);
  }

  // Add a new exercise
  Future<void> addExercise(String name, double maxWeight) async {
    final exercise = Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      maxWeight: maxWeight,
      date: DateTime.now(),
    );
    
    _exercises.add(exercise);
    
    // Add initial progress entry
    addProgressEntry(exercise.id, maxWeight);
    
    if (_selectedExercise == null) {
      _selectedExercise = exercise;
    }
    
    await _saveExercises();
    notifyListeners();
  }

  // Update an existing exercise
  Future<void> updateExercise(String id, String name, double maxWeight) async {
    final index = _exercises.indexWhere((e) => e.id == id);
    
    if (index != -1) {
      final updatedExercise = _exercises[index].copyWith(
        name: name,
        maxWeight: maxWeight,
        date: DateTime.now(),
      );
      
      _exercises[index] = updatedExercise;
      
      // Add progress entry with new max weight
      addProgressEntry(id, maxWeight);
      
      // Update selected exercise if needed
      if (_selectedExercise?.id == id) {
        _selectedExercise = updatedExercise;
      }
      
      await _saveExercises();
      notifyListeners();
    }
  }

  // Delete an exercise
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    
    // Also remove associated progress data
    _progressData.removeWhere((p) => p.exerciseId == id);
    
    // Update selected exercise if needed
    if (_selectedExercise?.id == id) {
      _selectedExercise = _exercises.isNotEmpty ? _exercises.first : null;
    }
    
    await _saveExercises();
    await _saveProgressData();
    notifyListeners();
  }

  // Set the selected exercise
  void setSelectedExercise(String id) {
    final exercise = _exercises.firstWhere(
      (e) => e.id == id,
      orElse: () => _exercises.first,
    );
    
    _selectedExercise = exercise;
    notifyListeners();
  }

  // Add a progress entry for an exercise
  Future<void> addProgressEntry(String exerciseId, double weight) async {
    final progress = ExerciseProgress(
      exerciseId: exerciseId,
      weight: weight,
      date: DateTime.now(),
    );
    
    _progressData.add(progress);
    await _saveProgressData();
    notifyListeners();
  }

  // Get progress entries for a specific exercise, sorted by date
  List<ExerciseProgress> getProgressForExercise(String exerciseId, {bool ascending = true}) {
    final progress = _progressData
        .where((p) => p.exerciseId == exerciseId)
        .toList();
    
    // Sort by date
    progress.sort((a, b) => ascending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));
    
    return progress;
  }

  // Get progress entries for a specific exercise, filtered by date range
  List<ExerciseProgress> getProgressInDateRange(
    String exerciseId, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _progressData
        .where((p) => p.exerciseId == exerciseId)
        .where((p) => p.date.isAfter(startDate) && p.date.isBefore(endDate))
        .toList();
  }

  // Calculate RM percentages for an exercise
  List<Map<String, dynamic>> calculateRMPercentages(double maxWeight) {
    List<Map<String, dynamic>> percentages = [];
    
    for (int percent = 10; percent <= 100; percent += 5) {
      percentages.add({
        'percent': percent,
        'weight': (maxWeight * percent / 100).toStringAsFixed(1),
      });
    }
    
    return percentages;
  }
}