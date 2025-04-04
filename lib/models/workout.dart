import 'dart:convert';

enum WorkoutType {
  endurance,
  powerlifting,
  crossfit,
  weightlifting,
  bodybuilding
}

enum DifficultyLevel { basic, intermediate, elite }

class WorkoutComponent {
  final String title;
  final List<String> exercises;
  final String? description;
  final Map<String, String>? parameters; // Reps, sets, etc.

  WorkoutComponent({
    required this.title,
    required this.exercises,
    this.description,
    this.parameters,
  });

  factory WorkoutComponent.fromJson(Map<String, dynamic> json) {
    return WorkoutComponent(
      title: json['title'],
      exercises: List<String>.from(json['exercises']),
      description: json['description'],
      parameters: json['parameters'] != null
          ? Map<String, String>.from(json['parameters'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'exercises': exercises,
      'description': description,
      'parameters': parameters,
    };
  }
}

class Workout {
  final String id;
  final String name;
  final WorkoutType type;
  final DifficultyLevel difficulty;
  final WorkoutComponent warmup;
  final WorkoutComponent strength;
  final WorkoutComponent wod;
  final WorkoutComponent cooldown;
  final List<String> mobilityExercises;
  final String? description;
  final String? imageUrl;

  Workout({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.warmup,
    required this.strength,
    required this.wod,
    required this.cooldown,
    required this.mobilityExercises,
    this.description,
    this.imageUrl,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      type: WorkoutType.values.byName(json['type']),
      difficulty: DifficultyLevel.values.byName(json['difficulty']),
      warmup: WorkoutComponent.fromJson(json['warmup']),
      strength: WorkoutComponent.fromJson(json['strength']),
      wod: WorkoutComponent.fromJson(json['wod']),
      cooldown: WorkoutComponent.fromJson(json['cooldown']),
      mobilityExercises: List<String>.from(json['mobilityExercises']),
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'difficulty': difficulty.name,
      'warmup': warmup.toJson(),
      'strength': strength.toJson(),
      'wod': wod.toJson(),
      'cooldown': cooldown.toJson(),
      'mobilityExercises': mobilityExercises,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  String getDifficultyText() {
    switch (difficulty) {
      case DifficultyLevel.basic:
        return 'Básico';
      case DifficultyLevel.intermediate:
        return 'Intermedio';
      case DifficultyLevel.elite:
        return 'Elite';
      default:
        return 'Desconocido';
    }
  }

  String getWorkoutTypeText() {
    switch (type) {
      case WorkoutType.endurance:
        return 'Endurance';
      case WorkoutType.powerlifting:
        return 'Powerlifting';
      case WorkoutType.crossfit:
        return 'CrossFit';
      case WorkoutType.weightlifting:
        return 'Halterofilia';
      case WorkoutType.bodybuilding:
        return 'Musculación';
      default:
        return 'Desconocido';
    }
  }
}
