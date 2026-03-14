import 'package:flutter_test/flutter_test.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_cubit.dart';
import 'package:IAEntrenar/features/recipes/domain/entities/recipe.dart';
import 'package:IAEntrenar/features/recipes/domain/repositories/recipe_repository.dart';

class _FakeRecipeRepository implements RecipeRepository {
  @override
  Future<List<Recipe>> fetchRecipes() async {
    return [
      Recipe(
        id: 'r1',
        name: 'Test recipe',
        mealType: MealType.breakfast,
        ingredients: const ['Eggs'],
        preparationSteps: const ['Cook eggs'],
        preparationTime: 5,
        calories: 100,
        imageUrl: null,
        nutritionFacts: const {'protein': '10g'},
      ),
    ];
  }

  @override
  Future<void> saveRecipes(List<Recipe> recipes) async {}

  @override
  Future<void> syncWithRemote() async {}
}

void main() {
  group('RecipeCubit', () {
    test('loadRecipes carga lista y selecciona la primera receta', () async {
      final cubit =
          RecipeCubit(recipeRepository: _FakeRecipeRepository());

      await cubit.loadRecipes();

      final state = cubit.state;
      expect(state.isLoading, false);
      expect(state.recipes.length, 1);
      expect(state.selectedRecipe?.id, 'r1');
    });
  });
}


