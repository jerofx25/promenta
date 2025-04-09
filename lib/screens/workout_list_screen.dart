import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import 'workout_detail_screen.dart';
import '../utils/theme.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({Key? key}) : super(key: key);

  @override
  _WorkoutListScreenState createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _searchController.addListener(() {
      Provider.of<WorkoutProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rutinas de Entrenamiento',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: theme.colorScheme.primary,
            ),
            onPressed: _toggleFilters,
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
              decoration: InputDecoration(
                hintText: 'Buscar entrenamientos...',
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

          // Filters
          SizeTransition(
            sizeFactor: _animation,
            child: _buildFilters(),
          ),

          // Workout list
          Expanded(
            child:
                Consumer<WorkoutProvider>(builder: (context, provider, child) {
              final workouts = provider.getFilteredWorkouts();

              if (workouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron entrenamientos',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.resetTypeFilters();
                          provider.setDifficultyFilter(null);
                          provider.setSearchQuery('');
                        },
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _buildWorkoutCard(context, workout);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout type filter
          Text(
            'Tipo de entrenamiento',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip(
                  'Endurance',
                  WorkoutType.endurance,
                  provider.selectedTypes.contains(WorkoutType.endurance),
                ),
                _buildTypeFilterChip(
                  'Powerlifting',
                  WorkoutType.powerlifting,
                  provider.selectedTypes.contains(WorkoutType.powerlifting),
                ),
                _buildTypeFilterChip(
                  'CrossFit',
                  WorkoutType.crossfit,
                  provider.selectedTypes.contains(WorkoutType.crossfit),
                ),
                _buildTypeFilterChip(
                  'Halterofilia',
                  WorkoutType.weightlifting,
                  provider.selectedTypes.contains(WorkoutType.weightlifting),
                ),
                _buildTypeFilterChip(
                  'Musculación',
                  WorkoutType.bodybuilding,
                  provider.selectedTypes.contains(WorkoutType.bodybuilding),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Difficulty filter
          Text(
            'Nivel de dificultad',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDifficultyChip(
                  'Básico',
                  DifficultyLevel.basic,
                  provider.selectedDifficulty == DifficultyLevel.basic,
                ),
                _buildDifficultyChip(
                  'Intermedio',
                  DifficultyLevel.intermediate,
                  provider.selectedDifficulty == DifficultyLevel.intermediate,
                ),
                _buildDifficultyChip(
                  'Elite',
                  DifficultyLevel.elite,
                  provider.selectedDifficulty == DifficultyLevel.elite,
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    provider.resetTypeFilters();
                    provider.setDifficultyFilter(null);
                    provider.setSearchQuery('');
                    _searchController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, WorkoutType type, bool isSelected) {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          provider.toggleWorkoutType(type);
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
      String label, DifficultyLevel difficulty, bool isSelected) {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          provider.setDifficultyFilter(selected ? difficulty : null);
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: _getDifficultyColor(difficulty, theme).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? _getDifficultyColor(difficulty, theme)
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty, ThemeData theme) {
    switch (difficulty) {
      case DifficultyLevel.basic:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.elite:
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Provider.of<WorkoutProvider>(context, listen: false)
            .selectWorkout(workout.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkoutDetailScreen(),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                workout.imageUrl ??
                    "https://pixabay.com/get/g8ba5e8c41aa0548f299dd6bbdaa01a0f2e30fb8076d56ecc7c4cbe2b469570e00b43c151a0d89fce219400b9f6893714932c903edfe776a600689f070ea801e2_1280.jpg",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getWorkoutTypeColor(workout.type, theme)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workout.getWorkoutTypeText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getWorkoutTypeColor(workout.type, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(workout.difficulty, theme)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workout.getDifficultyText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                _getDifficultyColor(workout.difficulty, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Workout name
                  Text(
                    workout.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Workout description
                  if (workout.description != null)
                    Text(
                      workout.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Preview exercises
                  Text(
                    'Incluye: ${workout.wod.exercises.length} ejercicios',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getWorkoutTypeColor(WorkoutType type, ThemeData theme) {
    switch (type) {
      case WorkoutType.endurance:
        return Colors.blue;
      case WorkoutType.powerlifting:
        return Colors.purple;
      case WorkoutType.crossfit:
        return Colors.red;
      case WorkoutType.weightlifting:
        return Colors.orange;
      case WorkoutType.bodybuilding:
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }
}
