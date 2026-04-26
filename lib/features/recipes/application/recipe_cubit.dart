import 'package:bloc/bloc.dart';

import 'package:IAEntrenar/features/meals/domain/daily_meal_plan.dart';
import '../domain/entities/recipe.dart';
import '../domain/repositories/recipe_repository.dart';
import 'recipe_state.dart';

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required RecipeRepository recipeRepository})
      : _recipeRepository = recipeRepository,
        super(const RecipeState.initial());

  final RecipeRepository _recipeRepository;

  Future<void> loadRecipes() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final recipes = await _recipeRepository.fetchRecipes();
      emit(
        state.copyWith(
          isLoading: false,
          recipes: recipes,
          selectedRecipe:
              recipes.isNotEmpty ? recipes.first : state.selectedRecipe,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void selectRecipe(String id) {
    final recipe = state.recipes.firstWhere(
      (r) => r.id == id,
      orElse: () => state.recipes.first,
    );
    emit(state.copyWith(selectedRecipe: recipe));
  }

  void setMealTypeFilter(MealType? type) {
    emit(state.copyWith(selectedMealType: type));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void addGeneratedMealPlan(DailyMealPlan plan) {
    final generatedRecipes = plan.meals.map(_recipeFromDailyMeal).toList();
    final regularRecipes = state.recipes
        .where((recipe) => !recipe.id.startsWith(_generatedMealPrefix))
        .toList();

    emit(
      state.copyWith(
        recipes: [...generatedRecipes, ...regularRecipes],
        selectedMealType: null,
        searchQuery: '',
      ),
    );
  }

  bool containsGeneratedMealPlan(DailyMealPlan plan) {
    final ids = state.recipes.map((recipe) => recipe.id).toSet();
    return plan.meals.every((meal) => ids.contains(_generatedMealId(meal)));
  }

  static const String _generatedMealPrefix = 'generated_daily_menu_';

  Recipe _recipeFromDailyMeal(DailyMeal meal) {
    return Recipe(
      id: _generatedMealId(meal),
      name: meal.name,
      mealType: _mealTypeFromDailyMeal(meal.type),
      ingredients: meal.ingredients,
      preparationSteps: [
        if (meal.reason.trim().isNotEmpty) meal.reason.trim(),
        'Generado por IA local como parte del menu diario.',
      ],
      preparationTime: 15,
      calories: meal.calories,
      nutritionFacts: {
        'Proteina': '${meal.proteinGrams} g',
        'Carbohidratos': '${meal.carbsGrams} g',
        'Grasas': '${meal.fatGrams} g',
        if (meal.sourceIds.isNotEmpty) 'Base': meal.sourceIds.join(', '),
      },
    );
  }

  static String _generatedMealId(DailyMeal meal) {
    final safeName = meal.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '$_generatedMealPrefix${meal.type.name}_$safeName';
  }

  MealType _mealTypeFromDailyMeal(DailyMealType type) {
    switch (type) {
      case DailyMealType.breakfast:
        return MealType.breakfast;
      case DailyMealType.lunch:
        return MealType.lunch;
      case DailyMealType.dinner:
        return MealType.dinner;
      case DailyMealType.snack:
        return MealType.snack;
    }
  }
}
