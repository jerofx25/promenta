
enum MealType {
  breakfast,
  lunch,
  snack,
  dinner
}

class Recipe {
  final String id;
  final String name;
  final MealType mealType;
  final List<String> ingredients;
  final List<String> preparationSteps;
  final int preparationTime; // in minutes
  final int calories;
  final String? imageUrl;
  final Map<String, String>? nutritionFacts; // Protein, carbs, etc.

  Recipe({
    required this.id,
    required this.name,
    required this.mealType,
    required this.ingredients,
    required this.preparationSteps,
    required this.preparationTime,
    required this.calories,
    this.imageUrl,
    this.nutritionFacts,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      mealType: MealType.values.byName(json['mealType']),
      ingredients: List<String>.from(json['ingredients']),
      preparationSteps: List<String>.from(json['preparationSteps']),
      preparationTime: json['preparationTime'],
      calories: json['calories'],
      imageUrl: json['imageUrl'],
      nutritionFacts: json['nutritionFacts'] != null
          ? Map<String, String>.from(json['nutritionFacts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType.name,
      'ingredients': ingredients,
      'preparationSteps': preparationSteps,
      'preparationTime': preparationTime,
      'calories': calories,
      'imageUrl': imageUrl,
      'nutritionFacts': nutritionFacts,
    };
  }

  String getMealTypeText() {
    switch (mealType) {
      case MealType.breakfast:
        return 'Desayuno';
      case MealType.lunch:
        return 'Almuerzo';
      case MealType.snack:
        return 'Snack';
      case MealType.dinner:
        return 'Cena';
      default:
        return 'Desconocido';
    }
  }
}