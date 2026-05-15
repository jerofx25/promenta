import 'dart:convert';

import 'package:equatable/equatable.dart';

enum DailyMealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

class DailyMeal extends Equatable {
  const DailyMeal({
    required this.type,
    required this.title,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.ingredients,
    required this.reason,
    required this.sourceIds,
  });

  final DailyMealType type;
  final String title;
  final String name;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final List<String> ingredients;
  final String reason;
  final List<String> sourceIds;

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    final typeText = (json['type'] ?? '').toString().trim().toLowerCase();
    return DailyMeal(
      type: DailyMealType.values.firstWhere(
        (e) => e.name == typeText,
        orElse: () => DailyMealType.snack,
      ),
      title: (json['title'] ?? _titleForType(typeText)).toString(),
      name: (json['name'] ?? '').toString(),
      calories: _intFrom(json['calories']),
      proteinGrams: _intFrom(json['protein_g'] ?? json['proteinGrams']),
      carbsGrams: _intFrom(json['carbs_g'] ?? json['carbsGrams']),
      fatGrams: _intFrom(json['fat_g'] ?? json['fatGrams']),
      ingredients: _stringList(json['ingredients']),
      reason: (json['reason'] ?? '').toString(),
      sourceIds: _stringList(json['source_ids'] ?? json['sourceIds']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'name': name,
        'calories': calories,
        'protein_g': proteinGrams,
        'carbs_g': carbsGrams,
        'fat_g': fatGrams,
        'ingredients': ingredients,
        'reason': reason,
        'source_ids': sourceIds,
      };

  String get typeLabel {
    switch (type) {
      case DailyMealType.breakfast:
        return 'Desayuno';
      case DailyMealType.lunch:
        return 'Almuerzo';
      case DailyMealType.dinner:
        return 'Cena';
      case DailyMealType.snack:
        return 'Snack';
    }
  }

  @override
  List<Object?> get props => [
        type,
        title,
        name,
        calories,
        proteinGrams,
        carbsGrams,
        fatGrams,
        ingredients,
        reason,
        sourceIds,
      ];
}

class DailyMealPlan extends Equatable {
  const DailyMealPlan({
    required this.summary,
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.meals,
    required this.rawText,
  });

  final String summary;
  final int targetCalories;
  final int targetProteinGrams;
  final List<DailyMeal> meals;
  final String rawText;

  factory DailyMealPlan.fromJson(
    Map<String, dynamic> json, {
    String rawText = '',
  }) {
    final meals = (json['meals'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => DailyMeal.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.name.trim().isNotEmpty && m.calories > 0)
        .toList();

    return DailyMealPlan(
      summary: (json['summary'] ?? '').toString(),
      targetCalories:
          _intFrom(json['target_calories'] ?? json['targetCalories']),
      targetProteinGrams:
          _intFrom(json['target_protein_g'] ?? json['targetProteinGrams']),
      meals: meals,
      rawText: rawText,
    );
  }

  static DailyMealPlan? tryParseModelText(String text) {
    final jsonStr = _extractJsonObject(text);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      final result = DailyMealPlan.fromJson(decoded, rawText: text);
      final requiredTypes = {
        DailyMealType.breakfast,
        DailyMealType.lunch,
        DailyMealType.dinner,
      };
      final foundTypes = result.meals.map((m) => m.type).toSet();
      if (!foundTypes.containsAll(requiredTypes)) return null;
      if (result.meals.length < 3 || result.meals.length > 4) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'target_calories': targetCalories,
        'target_protein_g': targetProteinGrams,
        'meals': meals.map((m) => m.toJson()).toList(),
        'rawText': rawText,
      };

  @override
  List<Object?> get props => [
        summary,
        targetCalories,
        targetProteinGrams,
        meals,
        rawText,
      ];
}

int _intFrom(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

String _titleForType(String type) {
  switch (type) {
    case 'breakfast':
      return 'Desayuno';
    case 'lunch':
      return 'Almuerzo';
    case 'dinner':
      return 'Cena';
    case 'snack':
      return 'Snack';
    default:
      return 'Comida';
  }
}

String? _extractJsonObject(String text) {
  final s = text.trim();
  final fence =
      RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
  final fenceMatch = fence.firstMatch(s);
  final candidate = fenceMatch != null ? (fenceMatch.group(1) ?? '') : s;
  final start = candidate.indexOf('{');
  if (start < 0) return null;
  final end = candidate.lastIndexOf('}');
  if (end <= start) return null;
  return candidate.substring(start, end + 1);
}
