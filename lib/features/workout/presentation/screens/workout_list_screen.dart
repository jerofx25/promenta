import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:IAEntrenar/features/workout/application/workups_cubit.dart';
import 'package:IAEntrenar/features/workout/application/workups_state.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<WorkupsCubit>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por título o descripción',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: BlocBuilder<WorkupsCubit, WorkupsState>(
                builder: (context, state) {
              final workouts = state.filteredWorkupDays;
              final hasLoadedDays = state.workupDays.isNotEmpty;

              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar el programa',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final userId =
                                context.read<AuthBloc>().state.profile?.id;
                            if (userId != null && userId.isNotEmpty) {
                              context
                                  .read<WorkupsCubit>()
                                  .loadWorkupDaysForUser(userId);
                            } else {
                              context.read<WorkupsCubit>().loadWorkupDays();
                            }
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (workouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasLoadedDays ? Icons.search_off : Icons.fitness_center,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasLoadedDays
                            ? 'Ningún día coincide con los filtros o la búsqueda'
                            : 'No se encontraron entrenamientos',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (!hasLoadedDays) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<WorkupsCubit>().loadWorkupDays();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workupDay = workouts[index];
                  return _buildWorkupDayCard(context, workupDay);
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
    final state = context.watch<WorkupsCubit>().state;

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
                  WorkupType.endurance,
                  state.selectedTypes.contains(WorkupType.endurance),
                ),
                _buildTypeFilterChip(
                  'Powerlifting',
                  WorkupType.powerlifting,
                  state.selectedTypes.contains(WorkupType.powerlifting),
                ),
                _buildTypeFilterChip(
                  'CrossFit',
                  WorkupType.crossfit,
                  state.selectedTypes.contains(WorkupType.crossfit),
                ),
                _buildTypeFilterChip(
                  'Halterofilia',
                  WorkupType.weightlifting,
                  state.selectedTypes.contains(WorkupType.weightlifting),
                ),
                _buildTypeFilterChip(
                  'Musculación',
                  WorkupType.bodybuilding,
                  state.selectedTypes.contains(WorkupType.bodybuilding),
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
                  state.selectedDifficulty == DifficultyLevel.basic,
                ),
                _buildDifficultyChip(
                  'Intermedio',
                  DifficultyLevel.intermediate,
                  state.selectedDifficulty == DifficultyLevel.intermediate,
                ),
                _buildDifficultyChip(
                  'Elite',
                  DifficultyLevel.elite,
                  state.selectedDifficulty == DifficultyLevel.elite,
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    context.read<WorkupsCubit>().resetTypeFilters();
                    context.read<WorkupsCubit>().setDifficultyFilter(null);
                    context.read<WorkupsCubit>().setSearchQuery('');
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

  Widget _buildTypeFilterChip(String label, WorkupType type, bool isSelected) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          context.read<WorkupsCubit>().toggleTypeFilter(type);
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

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          context
              .read<WorkupsCubit>()
              .setDifficultyFilter(selected ? difficulty : null);
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
    }
  }

  Widget _buildWorkupDayCard(BuildContext context, WorkupDay workupDay) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        context.read<WorkupsCubit>().selectWorkupDay(workupDay.dayNumber);
        context.pushNamed('workup-day-detail');
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
                          color: _getWorkupTypeColor(workupDay.type, theme)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workupDay.type.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getWorkupTypeColor(workupDay.type, theme),
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
                          color:
                              _getDifficultyColor(workupDay.difficulty, theme)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workupDay.difficulty.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getDifficultyColor(
                                workupDay.difficulty, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Workout name
                  Text(
                    workupDay.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Workout description
                  if (workupDay.description.isNotEmpty)
                    Text(
                      workupDay.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Preview exercises
                  Text(
                    'Incluye: ${_getTotalExercises(workupDay)} ejercicios',
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

  int _getTotalExercises(WorkupDay day) {
    int n = 0;
    final warmUp = day.warmUp;
    if (warmUp != null) {
      for (final w in warmUp) {
        n += _countWarmUpSegment(w);
      }
    }
    for (final block in day.blocks) {
      n += _countBlockSegment(block);
    }
    return n;
  }

  bool _isRestMovement(String? movement) {
    if (movement == null || movement.isEmpty) return false;
    return movement.toLowerCase() == 'rest';
  }

  int _countWarmUpSegment(WarmUp w) {
    final nested = w.exercises;
    if (nested != null && nested.isNotEmpty) {
      return nested.where((e) => !_isRestMovement(e.movement)).length;
    }
    if (_isRestMovement(w.movement)) return 0;
    if (w.movement != null && w.movement!.isNotEmpty) return 1;
    return 0;
  }

  /// Un [BlockExercise]: fila simple, intervalo impar/par, o complex con varios movimientos.
  int _countBlockExerciseRow(BlockExercise be) {
    final sub = be.movements;
    if (sub != null && sub.isNotEmpty) {
      return sub.where((m) => !_isRestMovement(m.movement)).length;
    }
    if (_isRestMovement(be.movement)) return 0;
    if (be.movement != null && be.movement!.isNotEmpty) return 1;
    return 0;
  }

  int _countPartExerciseRow(PartExercise pe) {
    if (_isRestMovement(pe.movement)) return 0;
    if (pe.movement != null && pe.movement!.isNotEmpty) return 1;
    return 0;
  }

  /// Cada [Part] puede ser un mini-bloque con lista o una sola línea (p. ej. descanso o un movimiento).
  int _countPartSegment(Part part) {
    final rows = part.exercises;
    if (rows != null && rows.isNotEmpty) {
      return rows.fold<int>(0, (s, pe) => s + _countPartExerciseRow(pe));
    }
    if (_isRestMovement(part.movement)) return 0;
    if (part.movement != null && part.movement!.isNotEmpty) return 1;
    return 0;
  }

  int _countBlockSegment(Block block) {
    // Día 10: "movements": ["clean_and_jerk"] + "ladder" → un solo ejercicio con progresión de cargas.
    final topMovements = block.movements;
    if (topMovements != null && topMovements.isNotEmpty) {
      return topMovements.length;
    }

    int n = 0;
    final exercises = block.exercises;
    if (exercises != null) {
      for (final be in exercises) {
        n += _countBlockExerciseRow(be);
      }
    }
    final parts = block.parts;
    if (parts != null) {
      for (final part in parts) {
        n += _countPartSegment(part);
      }
    }
    return n;
  }

  Color _getWorkupTypeColor(WorkupType type, ThemeData theme) {
    switch (type) {
      case WorkupType.endurance:
        return Colors.blue;
      case WorkupType.powerlifting:
        return Colors.purple;
      case WorkupType.crossfit:
        return Colors.red;
      case WorkupType.weightlifting:
        return Colors.orange;
      case WorkupType.bodybuilding:
        return Colors.teal;
    }
  }
}
