import 'package:IAEntrenar/features/ai_workout/domain/ai_workout_result.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/ai_model_manager.dart';
import 'package:IAEntrenar/models/user_profile.dart';
import 'package:IAEntrenar/models/workup_day.dart';
import 'package:llamadart/llamadart.dart';
import 'dart:convert';

import '../../workout/infrastructure/serializers/workup_day_serializer.dart';

class AiWorkoutGeneratorService {
  AiWorkoutGeneratorService();

  LlamaEngine? _engine;
  String? _loadedModelPath;

  Future<void> _ensureLoaded() async {
    final modelPath = await AiModelManager.instance.getOrDownloadModelPath();
    if (_engine != null && _loadedModelPath == modelPath) return;

    await _engine?.dispose();
    final engine = LlamaEngine(LlamaBackend());
    await engine.loadModel(
      modelPath,
      modelParams: const ModelParams(
        contextSize: 2048,
        preferredBackend: GpuBackend.auto,
        numberOfThreads: 4,
        numberOfThreadsBatch: 4,
        batchSize: 512,
        microBatchSize: 512,
      ),
    );
    _engine = engine;
    _loadedModelPath = modelPath;
  }

  Future<AiWorkoutResult> generateAlternative({
    required WorkupDay current,
    required UserProfile profile,
    required List<String> catalog,
    double? sleepHours,
  }) async {
    await _ensureLoaded();

    final currentJson = workupDayToJson(current);
    final minifiedJson = _minifyForAi(currentJson);
    final currentJsonCompact = jsonEncode(minifiedJson);

    const params = GenerationParams(
      maxTokens: 250,
      temp: 0.25,
      topP: 0.9,
      topK: 40,
      stopSequences: ['}\n', '}\r\n', '}\n\n', '}\r\n\r\n'],
      streamBatchTokenThreshold: 24,
      streamBatchByteThreshold: 1536,
    );

    final effectiveCatalog = _limitCatalog(
      catalog,
      maxItems: 120,
    );

    // Retry strategy:
    // - Attempt #1: normal prompt with catalog
    // - Attempt #2: stricter prompt + smaller catalog to reduce confusion
    final attempts = <String>[
      _buildPrompt(
        currentJsonCompact: currentJsonCompact,
        goals: profile.goals,
        injuries: profile.injuries,
        trainingLevel: profile.trainingLevel,
        catalog: effectiveCatalog,
        sleepHours: sleepHours,
        strict: false,
      ),
      _buildPrompt(
        currentJsonCompact: currentJsonCompact,
        goals: profile.goals,
        injuries: profile.injuries,
        trainingLevel: profile.trainingLevel,
        catalog: effectiveCatalog.take(60).toList(),
        sleepHours: sleepHours,
        strict: true,
      ),
    ];

    Map<String, dynamic> changeMap = <String, dynamic>{};
    String raw = '';

    for (final prompt in attempts) {
      raw = await _generateText(prompt: prompt, params: params);
      changeMap = _parseChangeMap(raw);
      if (_hasConcreteChanges(changeMap)) break;
    }

    changeMap = _ensureConcreteChanges(
      currentJson: currentJson,
      changeMap: changeMap,
      catalog: effectiveCatalog,
      sleepHours: sleepHours,
    );

    final mergedJson = _applyChanges(currentJson, changeMap);
    final parsedMerged = WorkupDay.fromJson(mergedJson);

    // Enforce critical invariants regardless of model output.
    final fixed = WorkupDay(
      dayNumber: current.dayNumber,
      title: parsedMerged.title.isNotEmpty ? parsedMerged.title : current.title,
      type: current.type,
      description: parsedMerged.description,
      difficulty: current.difficulty,
      warmUp: parsedMerged.warmUp,
      blocks: parsedMerged.blocks,
    );

    return AiWorkoutResult(day: fixed, rawText: raw);
  }

  Future<String> _generateText({
    required String prompt,
    required GenerationParams params,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in _engine!.generate(prompt, params: params)) {
      buffer.write(chunk);
    }
    return buffer.toString().trim();
  }

  Map<String, dynamic> _parseChangeMap(String raw) {
    final aiJson = AiWorkoutResult.tryParseJsonMap(raw);
    final replacements = aiJson?['replacements'];
    final changeMap = <String, dynamic>{};

    if (replacements is List) {
      for (final r in replacements) {
        if (r is Map && r['from'] is String && r['to'] is String) {
          final from = (r['from'] as String).trim();
          final to = (r['to'] as String).trim();
          if (from.isEmpty || to.isEmpty) continue;

          int? newVolume;
          if (r['new_volume'] != null) {
            if (r['new_volume'] is int) {
              newVolume = r['new_volume'] as int;
            } else if (r['new_volume'] is String) {
              newVolume = int.tryParse(r['new_volume'] as String);
            }
          }

          changeMap[from] = {
            'to': to,
            if (newVolume != null) 'new_volume': newVolume,
          };
        }
      }
    }

    final additions = aiJson?['additions'];
    if (additions is List) {
      changeMap['__additions__'] = additions
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) =>
              e['movement'] is String &&
              (e['movement'] as String).trim().isNotEmpty)
          .toList();
    }

    return changeMap;
  }

  List<String> _limitCatalog(List<String> catalog, {required int maxItems}) {
    if (catalog.isEmpty) return const [];
    final cleaned = <String>[];
    final seen = <String>{};
    for (final c in catalog) {
      final s = c.trim();
      if (s.isEmpty) continue;
      final key = s.toLowerCase();
      if (seen.add(key)) cleaned.add(s);
      if (cleaned.length >= maxItems) break;
    }
    return cleaned;
  }

  Map<String, dynamic> _applyChanges(
    Map<String, dynamic> currentJson,
    Map<String, dynamic> changeMap,
  ) {
    final replaceMap = Map<String, dynamic>.from(changeMap)
      ..remove('__additions__');
    final merged =
        _deepReplace(currentJson, replaceMap) as Map<String, dynamic>;
    final additions = changeMap['__additions__'];
    if (additions is List && additions.isNotEmpty) {
      _appendAdditions(merged, additions);
    }
    return merged;
  }

  dynamic _deepReplace(dynamic node, Map<String, dynamic> map) {
    if (map.isEmpty) return node;

    if (node is String) {
      if (map.containsKey(node)) {
        return map[node]['to'] as String;
      }
      return node;
    }
    if (node is List) {
      return node.map((e) => _deepReplace(e, map)).toList();
    }
    if (node is Map<String, dynamic>) {
      final res = <String, dynamic>{};
      final originalMovement = node['movement'];

      // First, handle simple string replacements for title/description if any
      for (final e in node.entries) {
        if (e.key == 'movement') {
          res[e.key] = e.value;
        } else if ((e.key == 'title' || e.key == 'description') &&
            e.value is String) {
          String val = e.value as String;
          for (final entry in map.entries) {
            val = val.replaceAll(entry.key, entry.value['to'] as String);
          }
          res[e.key] = val;
        } else {
          res[e.key] = _deepReplace(e.value, map);
        }
      }

      // Second, if this node is an exercise/movement definition, apply specific overrides (volume)
      if (originalMovement is String) {
        final movementName = originalMovement;
        if (map.containsKey(movementName)) {
          final overrideData = map[movementName];
          res['movement'] = overrideData['to'];
          if (overrideData.containsKey('new_volume')) {
            res['volume'] = overrideData['new_volume'];
          }
        }
      }

      return res;
    }
    return node;
  }

  bool _hasConcreteChanges(Map<String, dynamic> changeMap) {
    for (final entry in changeMap.entries) {
      if (entry.key == '__additions__') {
        final additions = entry.value;
        if (additions is List && additions.isNotEmpty) return true;
        continue;
      }
      final value = entry.value;
      if (value is! Map) continue;
      final to = value['to'];
      final changesMovement =
          to is String && to.trim().isNotEmpty && to != entry.key;
      final changesVolume = value.containsKey('new_volume');
      if (changesMovement || changesVolume) return true;
    }
    return false;
  }

  Map<String, dynamic> _ensureConcreteChanges({
    required Map<String, dynamic> currentJson,
    required Map<String, dynamic> changeMap,
    required List<String> catalog,
    double? sleepHours,
  }) {
    final movements = _collectMovementNames(currentJson);
    final normalizedMap = _normalizeChangeKeys(changeMap, movements);
    if (_hasApplicableConcreteChanges(normalizedMap, movements)) {
      return normalizedMap;
    }

    if (movements.isEmpty) return changeMap;

    final fallback = Map<String, dynamic>.from(normalizedMap);
    final firstMovement = movements.first;
    final replacement = _pickCatalogAlternative(
      from: firstMovement,
      catalog: catalog,
      existingMovements: movements,
    );
    if (replacement != null) {
      fallback[firstMovement] = {'to': replacement};
      return fallback;
    }

    final currentVolume = _findVolumeForMovement(currentJson, firstMovement);
    final shouldDeload = sleepHours != null && sleepHours < 6;
    final newVolume = _adjustVolume(currentVolume, shouldDeload: shouldDeload);
    fallback[firstMovement] = {
      'to': firstMovement,
      'new_volume': newVolume,
    };
    return fallback;
  }

  Map<String, dynamic> _normalizeChangeKeys(
    Map<String, dynamic> changeMap,
    List<String> movements,
  ) {
    if (changeMap.isEmpty || movements.isEmpty) return changeMap;

    final byLower = {
      for (final movement in movements) movement.toLowerCase(): movement,
    };
    final normalized = <String, dynamic>{};
    for (final entry in changeMap.entries) {
      if (entry.key == '__additions__') {
        normalized[entry.key] = entry.value;
        continue;
      }
      final realKey = byLower[entry.key.toLowerCase()] ?? entry.key;
      normalized[realKey] = entry.value;
    }
    return normalized;
  }

  bool _hasApplicableConcreteChanges(
    Map<String, dynamic> changeMap,
    List<String> movements,
  ) {
    if (!_hasConcreteChanges(changeMap)) return false;

    final movementSet = movements.map((e) => e.toLowerCase()).toSet();
    for (final entry in changeMap.entries) {
      if (entry.key == '__additions__') {
        final additions = entry.value;
        if (additions is List && additions.isNotEmpty) return true;
        continue;
      }
      if (movementSet.contains(entry.key.toLowerCase())) return true;
    }
    return false;
  }

  List<String> _collectMovementNames(dynamic node) {
    final names = <String>[];
    void visit(dynamic value) {
      if (value is Map<String, dynamic>) {
        final movement = value['movement'];
        if (movement is String && movement.trim().isNotEmpty) {
          names.add(movement.trim());
        }
        final movements = value['movements'];
        if (movements is List) {
          for (final item in movements) {
            if (item is String && item.trim().isNotEmpty) {
              names.add(item.trim());
            } else {
              visit(item);
            }
          }
        }
        for (final child in value.values) {
          if (child != movement && child != movements) visit(child);
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child);
        }
      }
    }

    visit(node);
    final seen = <String>{};
    return names.where((name) => seen.add(name.toLowerCase())).toList();
  }

  String? _pickCatalogAlternative({
    required String from,
    required List<String> catalog,
    required List<String> existingMovements,
  }) {
    final existing = existingMovements.map((e) => e.toLowerCase()).toSet();
    final fromKey = from.toLowerCase();
    final preferredKeywords = [
      'power',
      'strict',
      'push',
      'pull',
      'row',
      'lunge',
      'squat',
      'bike',
      'run',
      'plank',
      'hollow',
    ];

    for (final keyword in preferredKeywords) {
      for (final item in catalog) {
        final key = item.toLowerCase();
        if (key == fromKey || existing.contains(key)) continue;
        if (key.contains(keyword)) return item;
      }
    }

    for (final item in catalog) {
      final key = item.toLowerCase();
      if (key != fromKey && !existing.contains(key)) return item;
    }
    return null;
  }

  dynamic _findVolumeForMovement(dynamic node, String movementName) {
    if (node is Map<String, dynamic>) {
      if (node['movement'] == movementName && node.containsKey('volume')) {
        return node['volume'];
      }
      for (final value in node.values) {
        final found = _findVolumeForMovement(value, movementName);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findVolumeForMovement(value, movementName);
        if (found != null) return found;
      }
    }
    return null;
  }

  int _adjustVolume(dynamic currentVolume, {required bool shouldDeload}) {
    final parsed = currentVolume is int
        ? currentVolume
        : int.tryParse(currentVolume?.toString() ?? '');
    if (parsed == null || parsed <= 0) return shouldDeload ? 8 : 12;
    final adjusted =
        shouldDeload ? (parsed * 0.75).round() : (parsed * 1.25).round();
    return adjusted.clamp(1, 999);
  }

  void _appendAdditions(Map<String, dynamic> json, List<dynamic> additions) {
    final blocks = json['blocks'];
    if (blocks is! List || blocks.isEmpty) return;

    final firstAddition = additions.first;
    if (firstAddition is! Map) return;

    final movement = firstAddition['movement'];
    if (movement is! String || movement.trim().isEmpty) return;

    Map<String, dynamic>? targetBlock;
    final blockLetter = firstAddition['blockLetter'];
    if (blockLetter is String) {
      for (final block in blocks) {
        if (block is Map<String, dynamic> &&
            block['blockLetter'] == blockLetter) {
          targetBlock = block;
          break;
        }
      }
    }
    if (targetBlock == null) {
      for (final block in blocks) {
        if (block is Map<String, dynamic>) {
          targetBlock = block;
          break;
        }
      }
    }
    if (targetBlock == null) return;

    final exercises = targetBlock['exercises'];
    final newExercise = <String, dynamic>{
      'movement': movement.trim(),
      'volume': firstAddition['volume'] is int ? firstAddition['volume'] : 10,
      'unit': firstAddition['unit'] is String ? firstAddition['unit'] : 'reps',
      'notes': 'Añadido por IA como accesorio personalizado.',
    };

    if (exercises is List) {
      exercises.add(newExercise);
    } else {
      targetBlock['exercises'] = [newExercise];
    }
  }

  Map<String, dynamic> _minifyForAi(Map<String, dynamic> json) {
    final keep = {
      'warmUp',
      'blocks',
      'blockLetter',
      'exercises',
      'parts',
      'movements',
      'movement',
      'volume',
      'sets'
    };
    final res = <String, dynamic>{};
    for (final e in json.entries) {
      if (!keep.contains(e.key)) continue;
      final val = e.value;
      if (val == null) continue;
      if (val is String && val.isEmpty) continue;
      if (val is List) {
        if (val.isEmpty) continue;
        res[e.key] = val
            .map((v) => v is Map<String, dynamic> ? _minifyForAi(v) : v)
            .toList();
      } else if (val is Map<String, dynamic>) {
        res[e.key] = _minifyForAi(val);
      } else {
        res[e.key] = val;
      }
    }
    return res;
  }

  String _buildPrompt({
    required String currentJsonCompact,
    required List<String> goals,
    required List<String> injuries,
    required String? trainingLevel,
    required List<String> catalog,
    double? sleepHours,
    required bool strict,
  }) {
    final sleepInfo = sleepHours != null
        ? 'Durmió ${sleepHours.toStringAsFixed(1)} horas anoche.'
        : 'Sueño desconocido.';
    final catText =
        catalog.isEmpty ? 'Cualquier ejercicio' : catalog.join(', ');

    return [
      'Eres un Head Coach experto. Trabajas con atletas reales.',
      'Tu tarea: DEBES aplicar al menos 1 o 2 cambios a este entrenamiento para adaptarlo al usuario.',
      'Puedes reemplazar un ejercicio, o bien, mantener el mismo ejercicio y modificar su volumen o repeticiones (new_volume).',
      'Contexto del Atleta:',
      '- Metas: ${goals.join(", ")}',
      '- Lesiones: ${injuries.join(", ")} (Evita o cambia movimientos que afecten esto).',
      '- Nivel: ${trainingLevel ?? "intermedio"}',
      '- Estado hoy: $sleepInfo (Si durmió mal, baja el volumen o cambia a un ejercicio seguro).',
      '',
      'Entrenamiento actual:',
      currentJsonCompact,
      '',
      'Catálogo permitido para nuevos ejercicios:',
      catText,
      '',
      'Salida esperada (Obligatoria):',
      'Un JSON estricto con cambios concretos. Usa EXACTAMENTE el nombre del catálogo en "to" o en "additions.movement".',
      'Puedes devolver "replacements" para cambiar movimientos/volumen y "additions" para agregar un accesorio corto a un bloque.',
      'Si solo quieres cambiar repeticiones/volumen, pon el mismo ejercicio en "from" y "to", pero agrega "new_volume" con un NÚMERO (ej. 15, 5, 10).',
      'Ejemplo 1 (Cambio de ejercicio): {"replacements": [{"from": "squat snatch", "to": "power snatch"}]}',
      'Ejemplo 2 (Cambio de volumen): {"replacements": [{"from": "hs walk", "to": "hs walk", "new_volume": 10}]}',
      'Ejemplo 3 (Agregar ejercicio): {"replacements": [{"from": "toes to bar", "to": "knee raises"}], "additions": [{"blockLetter": "C", "movement": "plank", "volume": 30, "unit": "sec"}]}',
      '¡REGLA DE ORO! Genera solo el JSON, empieza con { y termina con }.',
      if (strict)
        'Si dudas, haz un reemplazo seguro y agrega un accesorio corto, pero NO lo dejes vacío.',
      'Genera:',
    ].join('\n');
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _loadedModelPath = null;
  }
}
