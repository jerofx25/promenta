import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/local_recipe_datasource.dart';

class LocalRecipeRepository implements RecipeRepository {
  LocalRecipeRepository(this._dataSource);

  final LocalRecipeDataSource _dataSource;

  @override
  Future<List<Recipe>> fetchRecipes() {
    return _dataSource.loadRecipes();
  }

  @override
  Future<void> saveRecipes(List<Recipe> recipes) {
    return _dataSource.saveRecipes(recipes);
  }

  @override
  Future<void> syncWithRemote() async {
    // Repositorio local: no hay backend todavía.
    // Aquí se podrá añadir lógica de sincronización (Firestore/REST)
    // sin cambiar la firma del contrato.
    return;
  }
}

