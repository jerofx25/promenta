class Exercise {
  final String id;
  final String name;
  final double maxWeight; // RM weight
  final DateTime date;

  Exercise({
    required this.id,
    required this.name,
    required this.maxWeight,
    required this.date,
  });

  // Create an Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      maxWeight: json['maxWeight'],
      date: DateTime.parse(json['date']),
    );
  }

  // Convert an Exercise to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'maxWeight': maxWeight,
      'date': date.toIso8601String(),
    };
  }

  // Create a copy of Exercise with updated values
  Exercise copyWith({
    String? id,
    String? name,
    double? maxWeight,
    DateTime? date,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      maxWeight: maxWeight ?? this.maxWeight,
      date: date ?? this.date,
    );
  }
}

class ExerciseProgress {
  final String exerciseId;
  final double weight;
  final DateTime date;

  ExerciseProgress({
    required this.exerciseId,
    required this.weight,
    required this.date,
  });

  // Create an ExerciseProgress from JSON
  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      exerciseId: json['exerciseId'],
      weight: json['weight'],
      date: DateTime.parse(json['date']),
    );
  }

  // Convert an ExerciseProgress to JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}