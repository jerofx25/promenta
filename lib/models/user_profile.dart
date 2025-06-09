import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final double? bodyFatPercentage;
  final double? bmi;
  final List<String> goals;
  final List<String> injuries;
  final String? trainingLevel;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool planGenerated;
  final bool isPremium;
  final String aiModelVersion;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.bodyFatPercentage,
    this.bmi,
    this.goals = const [],
    this.injuries = const [],
    this.trainingLevel,
    this.createdAt,
    this.lastLogin,
    this.planGenerated = false,
    this.isPremium = false,
    this.aiModelVersion = 'v1.3',
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      age: data['age'],
      gender: data['gender'],
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble(),
      bmi: (data['bmi'] as num?)?.toDouble(),
      goals: List<String>.from(data['goals'] ?? []),
      injuries: List<String>.from(data['injuries'] ?? []),
      trainingLevel: data['trainingLevel'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      planGenerated: data['planGenerated'] ?? false,
      isPremium: data['isPremium'] ?? false,
      aiModelVersion: data['aiModelVersion'] ?? 'v1.3',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'bmi': bmi,
      'goals': goals,
      'injuries': injuries,
      'trainingLevel': trainingLevel,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'planGenerated': planGenerated,
      'isPremium': isPremium,
      'aiModelVersion': aiModelVersion,
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? bodyFatPercentage,
    double? bmi,
    List<String>? goals,
    List<String>? injuries,
    String? trainingLevel,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? planGenerated,
    bool? isPremium,
    String? aiModelVersion,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bmi: bmi ?? this.bmi,
      goals: goals ?? this.goals,
      injuries: injuries ?? this.injuries,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      planGenerated: planGenerated ?? this.planGenerated,
      isPremium: isPremium ?? this.isPremium,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'bmi': bmi,
      'goals': goals,
      'injuries': injuries,
      'trainingLevel': trainingLevel,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'planGenerated': planGenerated,
      'isPremium': isPremium,
      'aiModelVersion': aiModelVersion,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      age: json['age'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      bodyFatPercentage: json['bodyFatPercentage'],
      bmi: json['bmi'],
      goals: List<String>.from(json['goals'] ?? []),
      injuries: List<String>.from(json['injuries'] ?? []),
      trainingLevel: json['trainingLevel'],
      createdAt: json['createdAt'],
      lastLogin: json['lastLogin'],
      planGenerated: json['planGenerated'],
      isPremium: json['isPremium'],
      aiModelVersion: json['aiModelVersion'],
    );
  }

  get progressPhotoDate => null;

  get progressPhotoDescription => null;

  get phone => null;
}
