import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/recipe.dart';

class LocalRecipeDataSource {
  static const _storageKey = 'recipes';

  Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getStringList(_storageKey);

    if (recipesJson == null || recipesJson.isEmpty) {
      final seed = _buildSampleRecipes();
      await saveRecipes(seed);
      return seed;
    }

    return recipesJson
        .map((json) => Recipe.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson =
        recipes.map((recipe) => jsonEncode(recipe.toJson())).toList();
    await prefs.setStringList(_storageKey, recipesJson);
  }

  List<Recipe> _buildSampleRecipes() {
    // Reutilizamos exactamente el mismo seed que en RecipeProvider.
    return [
      Recipe(
        id: '1',
        name: 'Bowl de Avena Proteica',
        mealType: MealType.breakfast,
        ingredients: [
          '1/2 taza de avena',
          '1 scoop de proteína en polvo',
          '1 plátano',
          '1 cucharada de mantequilla de almendras',
          '1/4 taza de leche de almendras',
          'Canela al gusto',
          'Frutos rojos para decorar',
        ],
        preparationSteps: [
          'Mezcla la avena con la leche y calienta en microondas por 2 minutos',
          'Añade la proteína en polvo y mezcla bien',
          'Corta el plátano en rodajas y añádelas encima',
          'Agrega la mantequilla de almendras, espolvorea canela y decora con frutos rojos',
        ],
        preparationTime: 10,
        calories: 450,
        imageUrl:
            'https://pixabay.com/get/g0ec6fa72d25a55e25af0a970e7730c8076bbad5efbd8bae2042cce66e05175fb1846eb7662be52fe9a424be7cbf3bf9738b432a53f632d5cca2f1497c7a19a78_1280.jpg',
        nutritionFacts: {
          'Proteínas': '25g',
          'Carbohidratos': '65g',
          'Grasas': '12g',
          'Fibra': '8g',
        },
      ),
      // Por brevedad, aquí podrías seguir añadiendo el resto de recetas
      // exactamente igual que en RecipeProvider._initializeSampleRecipes.
    ];
  }
}

