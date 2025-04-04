class UserProfile {
  final String? id;
  final String? email;
  final String? name;
  int? age;
  double? weight;
  String weightUnit = 'kg';
  double? height;
  String heightUnit = 'cm';
  String? trainingFrequency;
  String? fitnessGoal;
  List<String> injuries = [];
  List<String> dietaryHabits = [];
  String? profileImageUrl;

  UserProfile({
    this.id,
    this.email,
    this.name,
    this.age,
    this.weight,
    this.weightUnit = 'kg',
    this.height,
    this.heightUnit = 'cm',
    this.trainingFrequency,
    this.fitnessGoal,
    this.injuries = const [],
    this.dietaryHabits = const [],
    this.profileImageUrl,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    double? weight,
    String? weightUnit,
    double? height,
    String? heightUnit,
    String? trainingFrequency,
    String? fitnessGoal,
    List<String>? injuries,
    List<String>? dietaryHabits,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      injuries: injuries ?? this.injuries,
      dietaryHabits: dietaryHabits ?? this.dietaryHabits,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'weight': weight,
      'weightUnit': weightUnit,
      'height': height,
      'heightUnit': heightUnit,
      'trainingFrequency': trainingFrequency,
      'fitnessGoal': fitnessGoal,
      'injuries': injuries,
      'dietaryHabits': dietaryHabits,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      age: json['age'],
      weight: json['weight'],
      weightUnit: json['weightUnit'] ?? 'kg',
      height: json['height'],
      heightUnit: json['heightUnit'] ?? 'cm',
      trainingFrequency: json['trainingFrequency'],
      fitnessGoal: json['fitnessGoal'],
      injuries: List<String>.from(json['injuries'] ?? []),
      dietaryHabits: List<String>.from(json['dietaryHabits'] ?? []),
      profileImageUrl: json['profileImageUrl'],
    );
  }

  get progressPhotoDate => null;

  get progressPhotoDescription => null;

  get phone => null;
}
