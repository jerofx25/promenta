import 'package:IAEntrenar/features/workout/infrastructure/serializers/workup_day_serializer.dart';
import 'package:IAEntrenar/features/workout/infrastructure/datasources/user_workup_overrides_datasource.dart';
import 'package:IAEntrenar/features/workout/application/workups_cubit.dart';
import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiWorkoutApplySheet extends StatelessWidget {
  const AiWorkoutApplySheet({
    super.key,
    required this.profile,
    required this.current,
    required this.proposed,
  });

  final UserProfile profile;
  final WorkupDay current;
  final WorkupDay proposed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = _WorkoutDiff.fromDays(current, proposed);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrenamiento sugerido por IA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes aplicar esta versión o mantener tu rutina actual. Esto solo cambia tu cuenta (no modifica la BD base).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            _ChangeSummaryCard(changes: changes),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _WorkoutPreviewCard(
                    title: 'Actual',
                    day: current,
                    accent: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _WorkoutPreviewCard(
                    title: 'IA',
                    day: proposed,
                    accent: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Mantener actual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final ds = UserWorkupOverridesDatasource();
                      final json = workupDayToJson(proposed);
                      final workupsCubit = context.read<WorkupsCubit>();
                      await ds.saveOverride(profile.id, proposed, json);
                      workupsCubit.applyOverride(proposed);
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: const Text('Aplicar IA'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeSummaryCard extends StatelessWidget {
  const _ChangeSummaryCard({required this.changes});

  final _WorkoutDiff changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleChanges = changes.lines.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cambios principales',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleChanges.isEmpty)
            Text(
              'La IA mantuvo la estructura base sin cambios fuertes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            )
          else
            ...visibleChanges.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutDiff {
  const _WorkoutDiff(this.lines);

  final List<String> lines;

  static _WorkoutDiff fromDays(WorkupDay current, WorkupDay proposed) {
    final before = _WorkoutEntry.flatten(current);
    final after = _WorkoutEntry.flatten(proposed);
    final beforeByMovement = {
      for (final entry in before) entry.identity: entry,
    };
    final afterByMovement = {
      for (final entry in after) entry.identity: entry,
    };
    final lines = <String>[];

    for (final entry in after) {
      final previous = beforeByMovement[entry.identity];
      if (previous == null) {
        lines.add('Agrega ${entry.displayName} en ${entry.section}.');
      } else if (previous.volumeText != entry.volumeText) {
        lines.add(
          '${entry.displayName}: ${previous.volumeText} a ${entry.volumeText}.',
        );
      }
    }

    for (final entry in before) {
      if (!afterByMovement.containsKey(entry.identity)) {
        lines.add('Retira ${entry.displayName} de ${entry.section}.');
      }
    }

    return _WorkoutDiff(lines);
  }
}

class _WorkoutEntry {
  const _WorkoutEntry({
    required this.section,
    required this.movement,
    required this.volume,
    required this.unit,
  });

  final String section;
  final String movement;
  final dynamic volume;
  final String? unit;

  String get identity => '${section.toLowerCase()}|${movement.toLowerCase()}';

  String get displayName => movement.replaceAll('_', ' ');

  String get volumeText {
    if (volume == null) return 'sin volumen definido';
    final suffix = unit == null || unit!.isEmpty ? '' : ' $unit';
    return '$volume$suffix';
  }

  static List<_WorkoutEntry> flatten(WorkupDay day) {
    final entries = <_WorkoutEntry>[];
    final warmUp = day.warmUp ?? const <WarmUp>[];
    for (final w in warmUp) {
      if (w.movement != null && w.movement!.isNotEmpty) {
        entries.add(
          _WorkoutEntry(
            section: 'Warm Up',
            movement: w.movement!,
            volume: w.volume,
            unit: w.unit?.name.toLowerCase(),
          ),
        );
      }
      for (final e in w.exercises ?? const <MovementElement>[]) {
        entries.add(
          _WorkoutEntry(
            section: 'Warm Up',
            movement: e.movement,
            volume: e.volume,
            unit: e.unit?.name.toLowerCase(),
          ),
        );
      }
    }

    for (final b in day.blocks) {
      final section =
          b.blockLetter == null ? 'Bloque' : 'Bloque ${b.blockLetter!.name}';
      for (final e in b.exercises ?? const <BlockExercise>[]) {
        if (e.movement != null && e.movement!.isNotEmpty) {
          entries.add(
            _WorkoutEntry(
              section: section,
              movement: e.movement!,
              volume: e.volume,
              unit: e.unit?.name.toLowerCase(),
            ),
          );
        }
        for (final m in e.movements ?? const <MovementElement>[]) {
          entries.add(
            _WorkoutEntry(
              section: section,
              movement: m.movement,
              volume: m.volume,
              unit: m.unit?.name.toLowerCase(),
            ),
          );
        }
      }
      for (final p in b.parts ?? const <Part>[]) {
        if (p.movement != null && p.movement!.isNotEmpty) {
          entries.add(
            _WorkoutEntry(
              section: section,
              movement: p.movement!,
              volume: p.volume,
              unit: p.unit?.name.toLowerCase(),
            ),
          );
        }
        for (final e in p.exercises ?? const <PartExercise>[]) {
          if (e.movement != null && e.movement!.isNotEmpty) {
            entries.add(
              _WorkoutEntry(
                section: section,
                movement: e.movement!,
                volume: e.volume,
                unit: e.unit,
              ),
            );
          }
        }
      }
    }

    return entries;
  }
}

class _WorkoutPreviewCard extends StatelessWidget {
  const _WorkoutPreviewCard({
    required this.title,
    required this.day,
    required this.accent,
  });

  final String title;
  final WorkupDay day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWarmUp = (day.warmUp?.isNotEmpty ?? false);
    final blockLetters =
        day.blocks.map((b) => b.blockLetter?.name).whereType<String>().toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasWarmUp) _chip(context, 'Warm Up'),
              ..._blockChips(context, blockLetters),
              _chip(context, '${day.blocks.length} bloques'),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              'Ver detalle',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: [
              if (hasWarmUp) _section(context, 'Warm Up', _warmUpLines(day)),
              ..._blockSections(context, day),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _blockSections(BuildContext context, WorkupDay day) {
    final blocks = day.blocks;
    return blocks.map((b) {
      final letter = b.blockLetter?.name;
      final name = letter != null ? 'Bloque $letter' : 'Bloque';
      final lines = <String>[];
      if (b.format != null && b.format!.isNotEmpty) lines.add(b.format!);
      final ex = b.exercises;
      if (ex != null) {
        for (final e in ex) {
          if (e.movement != null && e.movement!.isNotEmpty) {
            String line = e.movement!.replaceAll('_', ' ');
            if (e.volume != null) {
              line += ' (${e.volume} ${e.unit?.name.toLowerCase() ?? ""})';
            }
            lines.add(line);
          } else if (e.movements != null) {
            for (final m in e.movements!) {
              String line = m.movement.replaceAll('_', ' ');
              if (m.volume != null) {
                line += ' (${m.volume} ${m.unit?.name.toLowerCase() ?? ""})';
              }
              lines.add(line);
            }
          }
        }
      }
      final parts = b.parts;
      if (parts != null) {
        for (final p in parts) {
          if (p.movement != null && p.movement!.isNotEmpty) {
            String line = p.movement!.replaceAll('_', ' ');
            if (p.volume != null) {
              line += ' (${p.volume} ${p.unit?.name.toLowerCase() ?? ""})';
            }
            lines.add(line);
          }
          if (p.exercises != null) {
            for (final pe in p.exercises!) {
              if (pe.movement != null && pe.movement!.isNotEmpty) {
                String line = pe.movement!.replaceAll('_', ' ');
                if (pe.volume != null) {
                  line += ' (${pe.volume} ${pe.unit ?? ""})';
                }
                lines.add(line);
              }
            }
          }
        }
      }
      return _section(context, name, lines.take(12).toList());
    }).toList();
  }

  List<String> _warmUpLines(WorkupDay day) {
    final warmUp = day.warmUp ?? const [];
    final lines = <String>[];
    for (final w in warmUp) {
      if (w.movement != null && w.movement!.isNotEmpty) {
        String line = w.movement!.replaceAll('_', ' ');
        if (w.volume != null) {
          line += ' (${w.volume} ${w.unit?.name.toLowerCase() ?? ""})';
        }
        lines.add(line);
      }
      if (w.exercises != null) {
        for (final e in w.exercises!) {
          if (e.movement.isNotEmpty) {
            String line = e.movement.replaceAll('_', ' ');
            if (e.volume != null) {
              line += ' (${e.volume} ${e.unit?.name.toLowerCase() ?? ""})';
            }
            lines.add(line);
          }
        }
      }
    }
    return lines.take(12).toList();
  }

  Widget _section(BuildContext context, String title, List<String> lines) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $l', style: theme.textTheme.bodySmall),
              )),
        ],
      ),
    );
  }

  List<Widget> _blockChips(BuildContext context, List<String> letters) {
    final unique = <String>{};
    final ordered = <String>[];
    for (final l in letters) {
      if (unique.add(l)) ordered.add(l);
    }
    return ordered.map((l) => _chip(context, 'Bloque $l')).toList();
  }

  Widget _chip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
