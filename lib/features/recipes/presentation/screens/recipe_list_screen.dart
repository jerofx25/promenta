import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:IAEntrenar/models/recipe.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_cubit.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_state.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _searchController.addListener(() {
      context
          .read<RecipeCubit>()
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recetas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite_border,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              AppAlerts.showInfo(
                context,
                'Funcionalidad de favoritos no implementada',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              maxLength: 10, // Ejemplo: máximo 10 caracteres
              maxLengthEnforcement:
                  MaxLengthEnforcement.none, // Oculta el contador
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: 'Buscar recetas...',
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Tab Bar for meal types
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            tabs: [
              _buildTab('Todos', Icons.restaurant),
              _buildTab('Desayuno', Icons.free_breakfast),
              _buildTab('Almuerzo', Icons.lunch_dining),
              _buildTab('Snack', Icons.cake),
              _buildTab('Cena', Icons.dinner_dining),
            ],
            onTap: (index) {
              final cubit = context.read<RecipeCubit>();
              switch (index) {
                case 0:
                  cubit.setMealTypeFilter(null);
                  break;
                case 1:
                  cubit.setMealTypeFilter(MealType.breakfast);
                  break;
                case 2:
                  cubit.setMealTypeFilter(MealType.lunch);
                  break;
                case 3:
                  cubit.setMealTypeFilter(MealType.snack);
                  break;
                case 4:
                  cubit.setMealTypeFilter(MealType.dinner);
                  break;
              }
            },
          ),

          // Recipe list
          Expanded(
            child: BlocBuilder<RecipeCubit, RecipeState>(
                builder: (context, state) {
              final recipes = state.filteredRecipes;

              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_food,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron recetas',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          final cubit = context.read<RecipeCubit>();
                          cubit.setMealTypeFilter(null);
                          cubit.setSearchQuery('');
                          _tabController.animateTo(0);
                        },
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildRecipeGrid(recipes),
                  _buildRecipeGrid(
                    recipes
                        .where((r) => r.mealType == MealType.breakfast)
                        .toList(),
                  ),
                  _buildRecipeGrid(
                    recipes
                        .where((r) => r.mealType == MealType.lunch)
                        .toList(),
                  ),
                  _buildRecipeGrid(
                    recipes
                        .where((r) => r.mealType == MealType.snack)
                        .toList(),
                  ),
                  _buildRecipeGrid(
                    recipes
                        .where((r) => r.mealType == MealType.dinner)
                        .toList(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return Center(
        child: Text(
          'No hay recetas en esta categoru00eda',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _buildRecipeCard(recipes[index]);
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        context.read<RecipeCubit>().selectRecipe(recipe.id);
        context.pushNamed('recipe-detail');
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      recipe.imageUrl ??
                          "https://pixabay.com/get/g017315c430cca167d9d976a80d92cf078dfbdffbe94ec8db4bc17618f6a98f386d955da9ecc4fddd34e0c6412218b00dbb5f099d1d6b73fef307b6c7c2b1e787_1280.jpg",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    // Meal type tag
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getMealTypeColor(recipe.mealType, theme),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          recipe.getMealTypeText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Preparation time
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.preparationTime} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Recipe info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.calories} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} ingredientes',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealTypeColor(MealType mealType, ThemeData theme) {
    switch (mealType) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.snack:
        return Colors.purple;
      case MealType.dinner:
        return Colors.blue;
    }
  }
}
