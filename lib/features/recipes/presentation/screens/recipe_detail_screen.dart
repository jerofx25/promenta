import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_cubit.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = context.watch<RecipeCubit>().state.selectedRecipe;

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle no disponible'),
        ),
        body: Center(
          child: Text(
            'No se ha seleccionado ninguna receta',
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl ??
                        "https://pixabay.com/get/gfdd69c81ced52694716baa327bbcc6a82f715ddefd188020a2e64773abccf80289eb8497324cba8def0418506a7005512d578015637019a8f20e203d31356bf8_1280.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  AppAlerts.showInfo(context, 'Compartir receta');
                },
              ),
              IconButton(
                icon: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    _liked = !_liked;
                  });
                  if (_liked) {
                    AppAlerts.showSuccess(context, 'Añadido a favoritos');
                  } else {
                    AppAlerts.showInfo(context, 'Eliminado de favoritos');
                  }
                },
              ),
            ],
          ),

          // Recipe info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.access_time,
                        value: '${recipe.preparationTime} min',
                        label: 'Preparación',
                      ),
                      _buildInfoItem(
                        icon: Icons.local_fire_department,
                        value: '${recipe.calories} kcal',
                        label: 'Calorías',
                      ),
                      _buildInfoItem(
                        icon: Icons.restaurant,
                        value: recipe.getMealTypeText(),
                        label: 'Tipo',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Nutrition Facts
                  if (recipe.nutritionFacts != null) ...[
                    // Fixed bracket syntax
                    Text(
                      'Información Nutricional',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: recipe.nutritionFacts!.entries.map((entry) {
                          return Column(
                            children: [
                              Text(
                                entry.value,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.key,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor:
                          theme.colorScheme.onSurface.withOpacity(0.6),
                      tabs: const [
                        Tab(text: 'Ingredientes'),
                        Tab(text: 'Preparación'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  SizedBox(
                    height: 300, // Fixed height for tab content
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIngredientsTab(recipe.ingredients),
                        _buildPreparationTab(recipe.preparationSteps),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add to meal plan functionality would go here
          AppAlerts.showSuccess(
            context,
            'Receta añadida al plan de comidas',
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir a Mi Plan'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildIngredientsTab(List<String> ingredients) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ingredients[index],
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreparationTab(List<String> steps) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  steps[index],
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
