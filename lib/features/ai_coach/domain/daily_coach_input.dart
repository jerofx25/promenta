import 'dart:convert';

import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';

class DailyCoachInput {
  const DailyCoachInput({
    required this.dateIso,
    required this.locale,
    required this.profile,
    required this.workupDay,
    this.sleepHours,
  });

  final String dateIso;
  final String locale;
  final DailyCoachProfile profile;
  final DailyCoachWorkoutDay workupDay;
  final double? sleepHours;

  Map<String, dynamic> toJson() => {
        'dateIso': dateIso,
        'locale': locale,
        'profile': profile.toJson(),
        'workupDay': workupDay.toJson(),
        if (sleepHours != null) 'sleepHours': sleepHours,
      };

  String toCompactJson() => jsonEncode(toJson());

  static DailyCoachInput from({
    required DateTime now,
    required UserProfile profile,
    required WorkupDay day,
    double? sleepHours,
  }) {
    return DailyCoachInput(
      dateIso: DateTime(now.year, now.month, now.day).toIso8601String(),
      locale: 'es',
      profile: DailyCoachProfile.fromUserProfile(profile),
      workupDay: DailyCoachWorkoutDay.fromWorkupDay(day),
      sleepHours: sleepHours,
    );
  }
}

class DailyCoachProfile {
  const DailyCoachProfile({
    required this.goals,
    required this.injuries,
    required this.trainingLevel,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  final List<String> goals;
  final List<String> injuries;
  final String? trainingLevel;
  final int? age;
  final double? heightCm;
  final double? weightKg;

  Map<String, dynamic> toJson() => {
        'goals': goals,
        'injuries': injuries,
        'trainingLevel': trainingLevel,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
      };

  static DailyCoachProfile fromUserProfile(UserProfile p) {
    return DailyCoachProfile(
      goals: p.goals,
      injuries: p.injuries,
      trainingLevel: p.trainingLevel,
      age: p.age,
      heightCm: p.height,
      weightKg: p.weight,
    );
  }
}

class DailyCoachWorkoutDay {
  const DailyCoachWorkoutDay({
    required this.dayNumber,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.movements,
    required this.details,
  });

  final int dayNumber;
  final String title;
  final String type;
  final String difficulty;
  final List<String> movements;
  final List<String> details;

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'title': title,
        'type': type,
        'difficulty': difficulty,
        'movements': movements,
        'details': details,
      };

  static DailyCoachWorkoutDay fromWorkupDay(WorkupDay d) {
    return DailyCoachWorkoutDay(
      dayNumber: d.dayNumber,
      title: d.title,
      type: d.type.name,
      difficulty: d.difficulty.name,
      movements: _extractMovements(d),
      details: _extractDetails(d),
    );
  }

  static List<String> _extractDetails(WorkupDay day) {
    final result = <String>[];

    final warmUps = day.warmUp;
    if (warmUps != null && warmUps.isNotEmpty) {
      for (final w in warmUps) {
        final movement = w.movement;
        if (movement != null && movement.trim().isNotEmpty) {
          result.add(_line(
              'Warm Up', movement, w.volume, w.unit?.name, null, null, null));
        }
        final nested = w.exercises;
        if (nested != null) {
          for (final e in nested) {
            if (e.movement.trim().isNotEmpty) {
              result.add(_line('Warm Up', e.movement, e.volume, e.unit?.name,
                  null, null, null));
            }
          }
        }
      }
    }

    for (final block in day.blocks) {
      final section = block.blockLetter == null
          ? 'Bloque'
          : 'Bloque ${block.blockLetter!.name}';
      final blockMeta = [
        if (block.format != null && block.format!.trim().isNotEmpty)
          block.format!,
        if (block.volume != null)
          '${block.volume} ${block.unit?.name.toLowerCase() ?? ''}'.trim(),
        if (block.repScheme != null) 'reps ${block.repScheme!.join("-")}',
        if (block.intensity != null)
          '${block.intensity}${block.intensityUnit ?? ""}',
        if (block.restBetweenRounds != null)
          'descanso ${block.restBetweenRounds}s',
      ].join(' / ');

      final exercises = block.exercises;
      if (exercises != null) {
        for (final ex in exercises) {
          if (ex.movement != null && ex.movement!.trim().isNotEmpty) {
            result.add(_line(section, ex.movement!, ex.volume, ex.unit?.name,
                ex.sets, ex.intensity, blockMeta));
          }
          final sub = ex.movements;
          if (sub != null) {
            for (final sm in sub) {
              if (sm.movement.trim().isNotEmpty) {
                result.add(_line(section, sm.movement, sm.volume, sm.unit?.name,
                    null, null, blockMeta));
              }
            }
          }
        }
      }

      final parts = block.parts;
      if (parts != null) {
        for (final p in parts) {
          final partMeta = [
            blockMeta,
            if (p.format != null && p.format!.trim().isNotEmpty) p.format!,
            if (p.repScheme != null) 'reps ${p.repScheme!.join("-")}',
            if (p.totalRounds != null) '${p.totalRounds} rounds',
            if (p.intervalDuration != null)
              'intervalo ${p.intervalDuration}${p.intervalUnit?.name.toLowerCase() ?? ""}',
          ].where((e) => e.trim().isNotEmpty).join(' / ');

          if (p.movement != null && p.movement!.trim().isNotEmpty) {
            result.add(_line(section, p.movement!, p.volume, p.unit?.name,
                p.sets, p.intensity, partMeta));
          }
          final pe = p.exercises;
          if (pe != null) {
            for (final row in pe) {
              if (row.movement != null && row.movement!.trim().isNotEmpty) {
                result.add(_line(section, row.movement!, row.volume, row.unit,
                    null, row.intensity, partMeta));
              }
            }
          }
        }
      }

      final ladder = block.ladder;
      final topMovements = block.movements;
      if (ladder != null && topMovements != null && topMovements.isNotEmpty) {
        final ladderText = ladder
            .map((l) =>
                '${l.volume} ${l.unit?.name.toLowerCase() ?? ''} @ ${l.weight}${l.weightUnit}'
                    .trim())
            .join(', ');
        result
            .add('$section: ${topMovements.join(", ")} / escalera $ladderText');
      }
    }

    return result.take(24).toList();
  }

  static String _line(
    String section,
    String movement,
    dynamic volume,
    String? unit,
    dynamic sets,
    dynamic intensity,
    String? context,
  ) {
    final parts = <String>[
      '$section: ${movement.replaceAll("_", " ")}',
      if (volume != null) '$volume ${unit?.toLowerCase() ?? ''}'.trim(),
      if (sets != null) '$sets sets',
      if (intensity != null) 'intensidad $intensity',
      if (context != null && context.trim().isNotEmpty) context,
    ];
    return parts.join(' / ');
  }

  static List<String> _extractMovements(WorkupDay day) {
    final result = <String>[];

    final warmUps = day.warmUp;
    if (warmUps != null) {
      for (final w in warmUps) {
        if (w.movement != null && w.movement!.trim().isNotEmpty) {
          result.add(w.movement!.trim());
        }
        final nested = w.exercises;
        if (nested != null) {
          for (final e in nested) {
            if (e.movement.trim().isNotEmpty) result.add(e.movement.trim());
          }
        }
      }
    }

    for (final block in day.blocks) {
      final topMovements = block.movements;
      if (topMovements != null) {
        for (final m in topMovements) {
          if (m.trim().isNotEmpty) result.add(m.trim());
        }
      }
      final exercises = block.exercises;
      if (exercises != null) {
        for (final ex in exercises) {
          if (ex.movement != null && ex.movement!.trim().isNotEmpty) {
            result.add(ex.movement!.trim());
          }
          final sub = ex.movements;
          if (sub != null) {
            for (final sm in sub) {
              if (sm.movement.trim().isNotEmpty) result.add(sm.movement.trim());
            }
          }
        }
      }
      final parts = block.parts;
      if (parts != null) {
        for (final p in parts) {
          if (p.movement != null && p.movement!.trim().isNotEmpty) {
            result.add(p.movement!.trim());
          }
          final pe = p.exercises;
          if (pe != null) {
            for (final row in pe) {
              if (row.movement != null && row.movement!.trim().isNotEmpty) {
                result.add(row.movement!.trim());
              }
            }
          }
        }
      }
    }

    // Clean: remove rest & duplicates, normalize underscores for LLM readability.
    final seen = <String>{};
    final cleaned = <String>[];
    for (final m in result) {
      final normalized = m.trim();
      if (normalized.isEmpty) continue;
      if (normalized.toLowerCase() == 'rest') continue;
      if (seen.add(normalized)) cleaned.add(normalized);
    }
    return cleaned.take(50).toList();
  }
}
