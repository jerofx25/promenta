import 'dart:async';

import 'package:IAEntrenar/features/ai_coach/domain/daily_coach_input.dart';
import 'package:IAEntrenar/features/ai_coach/domain/daily_coach_result.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/ai_model_manager.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/model_downloader.dart';
import 'package:llamadart/llamadart.dart';

class LocalLlmCoachService {
  LocalLlmCoachService();

  LlamaEngine? _engine;
  String? _loadedModelPath;

  Stream<DownloadProgress> downloadModelInBackground() {
    // Descarga única por app-run. Si ya está descargado, el stream simplemente termina.
    return AiModelManager.instance.ensureDownloaded();
  }

  Future<void> _ensureLoadedModel(String modelPath) async {
    if (_engine != null && _loadedModelPath == modelPath) {
      return;
    }

    await _engine?.dispose();
    final engine = LlamaEngine(LlamaBackend());
    await engine.loadModel(
      modelPath,
      modelParams: const ModelParams(
        // For "daily advice" we don't need huge context; smaller is faster/less RAM.
        contextSize: 2048,
        // Let llamadart pick the best GPU backend when available; on emulator this
        // will likely be CPU-only.
        preferredBackend: GpuBackend.auto,
        // Use a reasonable thread count for phones/emulators.
        numberOfThreads: 4,
        numberOfThreadsBatch: 4,
        batchSize: 512,
        microBatchSize: 512,
      ),
    );
    _engine = engine;
    _loadedModelPath = modelPath;
  }

  Future<DailyCoachResult> generateDailyCoach(DailyCoachInput input) async {
    final modelPath = await AiModelManager.instance.getOrDownloadModelPath();
    await _ensureLoadedModel(modelPath);

    final prompt = _buildPrompt(input);
    final buffer = StringBuffer();
    // IMPORTANT: limit tokens hard; otherwise it may generate for minutes.
    // We also stop as soon as the JSON closes.
    const params = GenerationParams(
      maxTokens: 320,
      temp: 0.25,
      topP: 0.9,
      topK: 40,
      stopSequences: ['}\n', '}\r\n', '}\n\n', '}\r\n\r\n'],
      // Reduce isolate message overhead a bit.
      streamBatchTokenThreshold: 24,
      streamBatchByteThreshold: 1536,
    );

    await for (final token in _engine!.generate(prompt, params: params)) {
      buffer.write(token);
    }

    final text = buffer.toString().trim();
    final result = DailyCoachResult.fromModelText(text);
    if (_isWeakResult(result)) {
      return _professionalFallback(input: input, rawText: text);
    }
    return result;
  }

  String _buildPrompt(DailyCoachInput input) {
    final movements = input.workupDay.movements
        .map((m) => m.replaceAll('_', ' ').trim())
        .where((m) => m.isNotEmpty)
        .toList();

    final injuries = input.profile.injuries
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final goals = input.profile.goals
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final sleepInfo = input.sleepHours != null
        ? '${input.sleepHours!.toStringAsFixed(1)} horas'
        : 'desconocido';
    final details = input.workupDay.details.take(18).toList();

    return [
      'Eres un Head Coach profesional de CrossFit, weightlifting y fuerza. Habla en español, directo y técnico.',
      'NO des consejos genéricos como hidratarse, descansar o calentar sin explicar cómo aplicarlo a ESTE entrenamiento.',
      'Genera SOLO un JSON válido con:',
      '{"headline": "Resumen técnico específico", "tips": ["..."], "caution": ["..."]}',
      '',
      'Reglas obligatorias de tips (4 tips):',
      '- Tip 1: carga/intensidad concreta. Usa % de 1RM, RPE o rango técnico realista.',
      '- Tip 2: pacing o estrategia por bloque. Si hay AMRAP/For time/intervalos, define ritmo objetivo o descansos exactos.',
      '- Tip 3: técnica específica para 1 o 2 movimientos del entrenamiento.',
      '- Tip 4: ajuste por sueño, lesión, nivel u objetivo. Debe decir qué bajar/subir y cuánto.',
      '- Cada tip debe mencionar al menos un movimiento, bloque, %/RPE, tiempo, descanso o volumen.',
      '',
      'Reglas de caution (1 a 2):',
      '- Advierte riesgos técnicos reales de los movimientos del día: lumbar, hombro, rodilla, muñeca, cuello o fatiga.',
      '- Si hay lesiones, conecta la advertencia con esa lesión y con un movimiento concreto.',
      '',
      'Prohibido:',
      '- Frases vagas como "mantén buena técnica", "hidrátate" o "descansa suficiente" sin números ni aplicación específica.',
      '- Inventar movimientos que no estén en el entrenamiento.',
      '',
      'Atleta:',
      '- Nivel: ${input.profile.trainingLevel ?? "no especificado"}',
      '- Objetivo: ${goals.isEmpty ? "Fitness general" : goals.join(", ")}',
      '- Lesiones: ${injuries.isEmpty ? "Ninguna" : injuries.join(", ")}',
      '- Edad: ${input.profile.age ?? "desconocida"}',
      '- Peso: ${input.profile.weightKg?.toStringAsFixed(1) ?? "desconocido"} kg',
      '- Sueño anoche: $sleepInfo',
      '',
      'Entrenamiento:',
      '- Tipo: ${input.workupDay.type}',
      '- Dificultad: ${input.workupDay.difficulty}',
      '- Movimientos clave: ${movements.isEmpty ? "Varios" : movements.join(", ")}',
      '- Detalle por bloques:',
      if (details.isEmpty) 'No disponible' else ...details.map((d) => '- $d'),
      '',
      'Ejemplo de estilo esperado:',
      '{"headline":"Día técnico de snatch: controla carga y hombro","tips":["Bloque A: trabaja snatch entre 65-75% 1RM o RPE 7; si la barra se aleja del cuerpo, baja 5-10%.","Bloque B AMRAP: divide toes to bar en series cortas desde el inicio, por ejemplo 4-4-4, y descansa 10-15s antes de fallar.","En hs walk, prioriza línea costillas-cadera; si pierdes bloqueo de hombro, cambia a wall walk controlado.","Con sueño bajo, reduce volumen total 15% y evita llegar a RPE 9 en movimientos olímpicos."],"caution":["Snatch y hs walk cargan hombro y zona lumbar: si compensas arqueando la espalda, reduce carga o rango antes de seguir."]}',
      '',
      'Devuelve SOLO el JSON final.',
    ].join('\n');
  }

  bool _isWeakResult(DailyCoachResult result) {
    final text = [
      result.headline,
      ...result.tips,
      ...result.caution,
    ].join(' ').toLowerCase();

    if (result.headline == 'Consejo rápido para hoy') return true;
    if (result.tips.length < 3) return true;

    final hasSpecificMetric =
        RegExp(r'(\d+\s?(%|s|min|seg|kg|m)|rpe|rm|amrap|for time)')
            .hasMatch(text);
    final genericSignals = [
      'hidrátate',
      'calentamiento corto',
      'técnica limpia',
      'descansa lo suficiente',
    ].where(text.contains).length;

    return !hasSpecificMetric || genericSignals >= 2;
  }

  DailyCoachResult _professionalFallback({
    required DailyCoachInput input,
    required String rawText,
  }) {
    final movements = input.workupDay.movements
        .map((m) => m.replaceAll('_', ' ').trim())
        .where((m) => m.isNotEmpty)
        .toList();
    final primary =
        movements.isNotEmpty ? movements.first : 'el movimiento principal';
    final secondary = movements.length > 1 ? movements[1] : primary;
    final hasLowSleep = input.sleepHours != null && input.sleepHours! < 6;
    final level = (input.profile.trainingLevel ?? '').toLowerCase();
    final rpe = hasLowSleep
        ? 'RPE 6-7'
        : level.contains('elite')
            ? 'RPE 8'
            : level.contains('basic') || level.contains('básico')
                ? 'RPE 6-7'
                : 'RPE 7-8';
    final load = hasLowSleep ? '60-70% de tu 1RM' : '70-80% de tu 1RM';
    final sleepAdjustment = hasLowSleep
        ? 'reduce el volumen total 15-20% y evita series al fallo'
        : 'mantén el volumen planeado, pero corta la serie si pasas de RPE 8';
    final blockDetail = input.workupDay.details.isNotEmpty
        ? input.workupDay.details.first
        : 'trabajo principal del día';

    return DailyCoachResult(
      headline: 'Plan técnico para ${input.workupDay.title}',
      tips: [
        '$blockDetail: trabaja $primary en $load o $rpe; si la velocidad cae mucho, baja 5-10% la carga.',
        'En $secondary, usa descansos de 60-90s si es accesorio y 2-3 min si es fuerza pesada; no sacrifiques rango por terminar antes.',
        'Si aparece un bloque por tiempo o AMRAP, sal al 75-80% de ritmo los primeros 2 min y acelera solo si mantienes respiración controlada.',
        'Ajuste del día: $sleepAdjustment. La meta es sostener técnica estable, no buscar récord.',
      ],
      caution: [
        '$primary puede cargar hombro, lumbar o rodilla según la técnica: si pierdes postura neutra o bloqueo articular, reduce carga/rango antes de continuar.',
      ],
      rawText: rawText,
    );
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _loadedModelPath = null;
  }
}
