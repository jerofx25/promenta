import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';

import 'package:IAEntrenar/features/workout/application/workups_cubit.dart';
import 'package:IAEntrenar/features/workout/application/workups_state.dart';
import 'package:IAEntrenar/models/workup_day.dart';

class WorkupDayDetailScreen extends StatefulWidget {
  const WorkupDayDetailScreen({super.key});

  @override
  State<WorkupDayDetailScreen> createState() => _WorkupDayDetailScreenState();
}

class _WorkupDayDetailScreenState extends State<WorkupDayDetailScreen> {
  static const String _placeholderImage =
      'https://pixabay.com/get/g8ba5e8c41aa0548f299dd6bbdaa01a0f2e30fb8076d56ecc7c4cbe2b469570e00b43c151a0d89fce219400b9f6893714932c903edfe776a600689f070ea801e2_1280.jpg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WorkupsCubit, WorkupsState>(
      builder: (context, state) {
        final day = state.selectedWorkupDay;

        if (day == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detalle no disponible'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Text(
                'No se ha seleccionado ningún entrenamiento',
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }

        // Tabs structure
        final hasWarmUp = day.warmUp != null && day.warmUp!.isNotEmpty;
        final tabsCount = (hasWarmUp ? 1 : 0) + day.blocks.length;

        return DefaultTabController(
          length: tabsCount,
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                // App bar with image
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day.title,
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
                          _placeholderImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Center(
                                child: Icon(
                                  Icons.fitness_center,
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
                                Colors.black.withValues(alpha: 0.5),
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
                        AppAlerts.showInfo(context, 'Compartir entrenamiento');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        AppAlerts.showSuccess(context, 'Añadido a favoritos');
                      },
                    ),
                  ],
                ),

                // Workout info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags Row
                        Row(
                          children: [
                            _buildTag(
                              day.type.name.toUpperCase(),
                              _getWorkupTypeColor(day.type, theme),
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              _difficultyLabel(day.difficulty),
                              _getDifficultyColor(day.difficulty, theme),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        if (day.description.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Descripción',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                day.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        if (tabsCount > 0) ...[
                          // Tab Bar
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                              ),
                              labelColor: theme.colorScheme.primary,
                              unselectedLabelColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              tabs: [
                                if (hasWarmUp) const Tab(text: 'Warm Up'),
                                ...day.blocks.map((b) => Tab(
                                      text: b.blockLetter != null
                                          ? 'Bloque ${b.blockLetter!.name}'
                                          : 'Bloque',
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tab Content
                          SizedBox(
                            height: 400, // Fixed height for tab content, can be dynamic but let's stick to the style
                            child: TabBarView(
                              children: [
                                if (hasWarmUp)
                                  _buildWarmUpSection(day.warmUp!),
                                ...day.blocks.map((b) => _buildBlockSection(b)),
                              ],
                            ),
                          ),
                        ] else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No hay rutinas definidas para este día.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildWarmUpSection(List<WarmUp> warmUps) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: warmUps.length,
      itemBuilder: (context, index) {
        final w = warmUps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (w.format != null)
                  Text(
                    w.format!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                if (w.movement != null)
                  _buildExerciseRow(w.movement!, w.volume, w.unit?.name),
                if (w.exercises != null)
                  ...w.exercises!.map((e) =>
                      _buildExerciseRow(e.movement, e.volume, e.unit?.name)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockSection(Block block) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (block.format != null || block.repScheme != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              [
                if (block.format != null) block.format!,
                if (block.volume != null) '${block.volume} ${block.unit?.name ?? ''}',
                if (block.repScheme != null) 'Reps: ${block.repScheme!.join('-')}',
              ].join(' • '),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),

        // If it has exercises
        if (block.exercises != null)
          ...block.exercises!.map((e) => _buildBlockExercise(e)),

        // If it has parts
        if (block.parts != null)
          ...block.parts!.map((p) => _buildPart(p)),

        // If it has movements + ladder (like Day 10)
        if (block.movements != null && block.ladder != null) ...[
          Text(
            block.movements!.join(', ').replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...block.ladder!.map((l) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text('• ${l.volume} reps @ ${l.weight} ${l.weightUnit}'),
              )),
        ],
      ],
    );
  }

  Widget _buildBlockExercise(BlockExercise e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.type != null)
              Text(
                e.type!.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary),
              ),
            if (e.movement != null)
              _buildExerciseRow(e.movement!, e.volume, e.unit?.name,
                  notes: e.notes, intensity: e.intensity),
            if (e.movements != null)
              ...e.movements!.map((m) =>
                  _buildExerciseRow(m.movement, m.volume, m.unit?.name)),
            if (e.notes != null && e.movement == null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  e.notes!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPart(Part p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.format != null)
              Text(
                [
                  p.format!,
                  if (p.volume != null) '${p.volume} ${p.unit?.name ?? ''}',
                ].join(' '),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            if (p.movement != null)
              _buildExerciseRow(p.movement!, null, null),
            if (p.exercises != null)
              ...p.exercises!.map((pe) => _buildExerciseRow(
                  pe.movement ?? '', pe.volume, pe.unit,
                  notes: pe.notes, weight: pe.weight, weightUnit: pe.weightUnit)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(String name, dynamic volume, String? unit,
      {String? notes, dynamic intensity, int? weight, String? weightUnit}) {
    final theme = Theme.of(context);
    final displayName = name.replaceAll('_', ' ').toUpperCase();

    String details = '';
    if (volume != null) details += '$volume';
    if (unit != null) details += ' $unit';
    if (intensity != null) details += ' @ $intensity%';
    if (weight != null) details += ' @ $weight $weightUnit';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                if (notes != null)
                  Text(
                    notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(DifficultyLevel d) {
    switch (d) {
      case DifficultyLevel.basic:
        return 'Básico';
      case DifficultyLevel.intermediate:
        return 'Intermedio';
      case DifficultyLevel.elite:
        return 'Elite';
    }
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
