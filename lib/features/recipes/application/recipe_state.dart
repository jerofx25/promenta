import 'package:equatable/equatable.dart';

import '../domain/entities/recipe.dart';

class RecipeState extends Equatable {
  final List<Recipe> recipes;
  final Recipe? selectedRecipe;
  final MealType? selectedMealType;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const RecipeState({
    required this.recipes,
    required this.selectedRecipe,
    required this.selectedMealType,
    required this.searchQuery,
    required this.isLoading,
    required this.error,
  });

  const RecipeState.initial()
      : recipes = const [],
        selectedRecipe = null,
        selectedMealType = null,
        searchQuery = '',
        isLoading = false,
        error = null;

  RecipeState copyWith({
    List<Recipe>? recipes,
    Recipe? selectedRecipe,
    MealType? selectedMealType,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      selectedRecipe: selectedRecipe ?? this.selectedRecipe,
      selectedMealType: selectedMealType ?? this.selectedMealType,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Recipe> get filteredRecipes {
    var result = recipes;

    if (selectedMealType != null) {
      result =
          result.where((r) => r.mealType == selectedMealType).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                r.ingredients
                    .join(' ')
                    .toLowerCase()
                    .contains(q),
          )
          .toList();
    }

    return result;
  }

  @override
  List<Object?> get props =>
      [recipes, selectedRecipe, selectedMealType, searchQuery, isLoading, error];
}

