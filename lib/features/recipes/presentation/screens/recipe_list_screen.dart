import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:IAEntrenar/models/recipe.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';
import 'package:IAEntrenar/features/ai_coach/presentation/ai_model_download_banner.dart';
import 'package:IAEntrenar/features/meals/application/daily_meal_plan_cubit.dart';
import 'package:IAEntrenar/features/meals/application/daily_meal_plan_state.dart';
import 'package:IAEntrenar/features/meals/domain/daily_meal_plan.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_cubit.dart';
import 'package:IAEntrenar/features/recipes/application/recipe_state.dart';
import 'package:IAEntrenar/features/workout/application/workups_cubit.dart';
import 'package:IAEntrenar/features/workout/application/workups_state.dart';
import 'package:IAEntrenar/models/workup_day.dart';

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
      context.read<RecipeCubit>().setSearchQuery(_searchController.text);
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
    final bottomSafeSpace = MediaQuery.of(context).padding.bottom;
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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomSafeSpace),
        child: Column(
          children: [
            _DailyMealGeneratorSection(
              onMenuAdded: () {
                _searchController.clear();
                _tabController.animateTo(0);
              },
            ),
            const AiModelDownloadBanner(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
              compact: true,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.text,
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
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
            BlocBuilder<RecipeCubit, RecipeState>(
              builder: (context, state) {
                final recipes = state.filteredRecipes;

                if (recipes.isEmpty) {
                  return _buildEmptyRecipes(theme);
                }

                return _buildRecipeGrid(recipes);
              },
            ),
          ],
        ),
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

  Widget _buildEmptyRecipes(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_food,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
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

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return Center(
        child: Text(
          'No hay recetas en esta categoru00eda',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720 ? 3 : 2;
        final aspectRatio = width < 380 ? 0.58 : 0.65;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            return _buildRecipeCard(recipes[index]);
          },
        );
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
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          color: Colors.black.withValues(alpha: 0.6),
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

class _DailyMealGeneratorSection extends StatefulWidget {
  const _DailyMealGeneratorSection({required this.onMenuAdded});

  final VoidCallback onMenuAdded;

  @override
  State<_DailyMealGeneratorSection> createState() =>
      _DailyMealGeneratorSectionState();
}

class _DailyMealGeneratorSectionState
    extends State<_DailyMealGeneratorSection> {
  int? _selectedDayNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<DailyMealPlanCubit, DailyMealPlanState>(
            builder: (context, mealState) {
              final isBusy =
                  mealState.status == DailyMealPlanStatus.downloadingModel ||
                      mealState.status == DailyMealPlanStatus.generating;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alimentacion diaria con IA',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Usa tus datos reales y una base local de comidas.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BlocBuilder<WorkupsCubit, WorkupsState>(
                    builder: (context, workupsState) {
                      final workouts = workupsState.workupDays;
                      final selectedWorkout =
                          _findSelectedWorkout(workouts, _selectedDayNumber);
                      final safeValue =
                          selectedWorkout == null ? null : _selectedDayNumber;

                      return DropdownButtonFormField<int?>(
                        initialValue: safeValue,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Entrenamiento del dia (opcional)',
                          prefixIcon: const Icon(Icons.fitness_center),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Dia de descanso / sin entrenamiento'),
                          ),
                          ...workouts.map(
                            (day) => DropdownMenuItem<int?>(
                              value: day.dayNumber,
                              child: Text(
                                'Dia ${day.dayNumber}: ${day.title}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: isBusy
                            ? null
                            : (value) {
                                setState(() => _selectedDayNumber = value);
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          isBusy ? null : () => _generateDailyMeals(context),
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restaurant_menu),
                      label: Text(
                        isBusy
                            ? 'Generando alimentacion...'
                            : 'Generar alimentacion diaria',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (mealState.status == DailyMealPlanStatus.downloadingModel)
                    const _GenerationMessage(
                      text:
                          'Instalando IA local. La barra global muestra el progreso de descarga.',
                    ),
                  if (mealState.status == DailyMealPlanStatus.generating)
                    const _GenerationMessage(
                      text:
                          'Preparando prompt con onboarding, Health real, recuperacion y comidas locales...',
                    ),
                  if (mealState.status == DailyMealPlanStatus.error)
                    _GenerationError(message: mealState.error),
                  if (mealState.status == DailyMealPlanStatus.ready &&
                      mealState.plan != null)
                    _DailyMealPlanResult(
                      plan: mealState.plan!,
                      onMenuAdded: widget.onMenuAdded,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  WorkupDay? _findSelectedWorkout(List<WorkupDay> workouts, int? dayNumber) {
    if (dayNumber == null) return null;
    for (final workout in workouts) {
      if (workout.dayNumber == dayNumber) return workout;
    }
    return null;
  }

  void _generateDailyMeals(BuildContext context) {
    final profile = context.read<AuthBloc>().state.profile;
    if (profile == null) {
      AppAlerts.showInfo(
        context,
        'Completa tu perfil antes de generar la alimentacion diaria',
      );
      return;
    }

    final workouts = context.read<WorkupsCubit>().state.workupDays;
    final selectedWorkout = _findSelectedWorkout(workouts, _selectedDayNumber);
    context.read<DailyMealPlanCubit>().generate(
          profile: profile,
          selectedWorkout: selectedWorkout,
        );
  }
}

class _GenerationMessage extends StatelessWidget {
  const _GenerationMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationError extends StatelessWidget {
  const _GenerationError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'No se pudo generar el plan de alimentacion.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMealPlanResult extends StatelessWidget {
  const _DailyMealPlanResult({
    required this.plan,
    required this.onMenuAdded,
  });

  final DailyMealPlan plan;
  final VoidCallback onMenuAdded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCalories =
        plan.meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final totalProtein =
        plan.meals.fold<int>(0, (sum, meal) => sum + meal.proteinGrams);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.summary,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MacroChip(
                icon: Icons.local_fire_department,
                label: '$totalCalories kcal',
              ),
              _MacroChip(
                icon: Icons.monitor_weight,
                label: '$totalProtein g proteina',
              ),
              _MacroChip(
                icon: Icons.flag,
                label: 'Objetivo ${plan.targetCalories} kcal',
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<RecipeCubit, RecipeState>(
            builder: (context, state) {
              final alreadyAdded =
                  context.read<RecipeCubit>().containsGeneratedMealPlan(plan);

              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: alreadyAdded
                      ? null
                      : () {
                          context
                              .read<RecipeCubit>()
                              .addGeneratedMealPlan(plan);
                          onMenuAdded();
                          AppAlerts.showSuccess(
                            context,
                            'Menu agregado a tus cards de comidas',
                          );
                        },
                  icon: Icon(
                    alreadyAdded
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  label: Text(alreadyAdded ? 'Menu agregado' : 'Agregar menu'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final cardWidth =
                  availableWidth < 420 ? availableWidth * 0.84 : 280.0;
              final listHeight = availableWidth < 360 ? 292.0 : 268.0;

              return SizedBox(
                height: listHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: plan.meals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: _GeneratedMealCard(meal: plan.meals[index]),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GeneratedMealCard extends StatelessWidget {
  const _GeneratedMealCard({required this.meal});

  final DailyMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _mealColor(meal.type, theme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_mealIcon(meal.type), size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        meal.typeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${meal.calories} kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meal.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroChip(
                  icon: Icons.fitness_center,
                  label: 'P ${meal.proteinGrams} g',
                ),
                _MacroChip(
                  icon: Icons.grain,
                  label: 'C ${meal.carbsGrams} g',
                ),
                _MacroChip(
                  icon: Icons.water_drop,
                  label: 'G ${meal.fatGrams} g',
                ),
              ],
            ),
            if (meal.ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                meal.ingredients.take(4).join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (meal.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meal.reason,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _mealColor(DailyMealType type, ThemeData theme) {
    switch (type) {
      case DailyMealType.breakfast:
        return Colors.orange;
      case DailyMealType.lunch:
        return Colors.green;
      case DailyMealType.dinner:
        return Colors.blue;
      case DailyMealType.snack:
        return Colors.purple;
    }
  }

  IconData _mealIcon(DailyMealType type) {
    switch (type) {
      case DailyMealType.breakfast:
        return Icons.free_breakfast;
      case DailyMealType.lunch:
        return Icons.lunch_dining;
      case DailyMealType.dinner:
        return Icons.dinner_dining;
      case DailyMealType.snack:
        return Icons.cake;
    }
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
