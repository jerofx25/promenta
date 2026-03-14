import '../entities/recipe.dart';

/// Abstracción para recetas: hoy solo local, pero preparada para
/// añadir datasources remotos (Firestore, REST, etc.) en el futuro.
abstract class RecipeRepository {
  Future<List<Recipe>> fetchRecipes();

  Future<void> saveRecipes(List<Recipe> recipes);

  /// Pensado para una futura integración con backend (opcional).
  /// Por ahora no se implementa en el repositorio local.
  Future<void> syncWithRemote() async {}
}

