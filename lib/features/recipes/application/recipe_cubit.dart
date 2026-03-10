import 'package:bloc/bloc.dart';

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
}

