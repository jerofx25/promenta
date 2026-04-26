import 'dart:convert';

import 'package:IAEntrenar/features/ai_coach/infrastructure/ai_model_manager.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/model_downloader.dart';
import 'package:IAEntrenar/features/meals/domain/daily_meal_input.dart';
import 'package:IAEntrenar/features/meals/domain/daily_meal_plan.dart';
import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

class LocalLlmMealPlanService {
  LocalLlmMealPlanService();

  LlamaEngine? _engine;
  String? _loadedModelPath;
  List<_FoodOption>? _cachedFoodOptions;

  Stream<DownloadProgress> downloadModelInBackground() {
    return AiModelManager.instance.ensureDownloaded();
  }

  Future<DailyMealPlan> generateDailyMealPlan(DailyMealInput input) async {
    final foodOptions = await _loadFoodOptions();
    final modelPath = await AiModelManager.instance.getOrDownloadModelPath();
    await _ensureLoadedModel(modelPath);

    final prompt = _buildPrompt(
      input: input,
      foodOptions: _relevantFoodOptions(foodOptions, input),
    );

    const params = GenerationParams(
      maxTokens: 900,
      temp: 0.2,
      topP: 0.9,
      topK: 40,
      streamBatchTokenThreshold: 24,
      streamBatchByteThreshold: 1536,
    );

    final buffer = StringBuffer();
    await for (final token in _engine!.generate(prompt, params: params)) {
      buffer.write(token);
    }

    final rawText = buffer.toString().trim();
    final parsed = DailyMealPlan.tryParseModelText(rawText);
    if (parsed != null) return parsed;

    return _fallbackPlan(
        input: input, foodOptions: foodOptions, rawText: rawText);
  }

  Future<void> _ensureLoadedModel(String modelPath) async {
    if (_engine != null && _loadedModelPath == modelPath) return;

    await _engine?.dispose();
    final engine = LlamaEngine(LlamaBackend());
    await engine.loadModel(
      modelPath,
      modelParams: const ModelParams(
        contextSize: 4096,
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

  Future<List<_FoodOption>> _loadFoodOptions() async {
    final cached = _cachedFoodOptions;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/meals_database.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final meals = (decoded['meals'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => _FoodOption.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.category.isNotEmpty)
        .toList();
    _cachedFoodOptions = meals;
    return meals;
  }

  List<_FoodOption> _relevantFoodOptions(
    List<_FoodOption> options,
    DailyMealInput input,
  ) {
    final selected = <_FoodOption>[];
    for (final category in ['breakfast', 'lunch', 'dinner', 'snack']) {
      final categoryOptions =
          options.where((o) => o.category == category).toList();
      categoryOptions.sort((a, b) => b.proteinGrams.compareTo(a.proteinGrams));
      selected.addAll(categoryOptions.take(4));
    }
    return selected;
  }

  String _buildPrompt({
    required DailyMealInput input,
    required List<_FoodOption> foodOptions,
  }) {
    final target = _estimateTargets(input);
    final compactFoods = foodOptions.map((o) => o.toPromptJson()).toList();
    return [
      'Eres nutricionista deportivo para atletas de fuerza, CrossFit y fitness.',
      'Habla en espanol y devuelve SOLO JSON valido, sin markdown.',
      '',
      'Objetivo: crear alimentacion diaria personalizada de 3 comidas obligatorias y snack opcional.',
      'No inventes recetas fuera de la base. Puedes combinar ingredientes, pero cada comida debe citar source_ids de la base.',
      'Usa desayuno, almuerzo y cena siempre. Incluye snack solo si ayudan las calorias, alto estres o baja recuperacion.',
      'No uses datos de salud ausentes como si fueran reales.',
      '',
      'Formato exacto:',
      '{"summary":"...","target_calories":2200,"target_protein_g":150,"meals":[{"type":"breakfast","title":"Desayuno","name":"...","calories":500,"protein_g":35,"carbs_g":55,"fat_g":15,"ingredients":["..."],"reason":"...","source_ids":["..."]}]}',
      '',
      'Targets orientativos calculados por la app:',
      jsonEncode(target),
      '',
      'Contexto del usuario:',
      input.toCompactJson(),
      '',
      'Base de comidas permitida:',
      jsonEncode(compactFoods),
      '',
      'Reglas:',
      '- Ajusta carbohidratos al entrenamiento: mas si hay CrossFit/endurance/powerlifting pesado; menos en descanso.',
      '- Proteina objetivo: aproxima 1.6-2.2 g/kg cuando haya peso.',
      '- Total diario esperado: +/- 15% de target_calories.',
      '- Cada reason debe explicar por que encaja con objetivo, entreno o recuperacion.',
      '- Devuelve 3 o 4 meals; snack solo si procede.',
      '',
      'Devuelve SOLO el JSON final.',
    ].join('\n');
  }

  Map<String, dynamic> _estimateTargets(DailyMealInput input) {
    final profile = input.profile;
    final weight = profile.weightKg;
    final height = profile.heightCm;
    final age = profile.age;
    final gender = (profile.gender ?? '').toLowerCase();

    double calories = 2200;
    if (weight != null && height != null && age != null) {
      final sexOffset =
          gender.contains('f') || gender.contains('mujer') ? -161.0 : 5.0;
      final bmr = (10 * weight) + (6.25 * height) - (5 * age) + sexOffset;
      final activityFactor = input.workout.isRestDay ? 1.35 : 1.55;
      calories = bmr * activityFactor;
    } else if (weight != null) {
      calories = weight * (input.workout.isRestDay ? 30 : 35);
    }

    final goals = profile.goals.join(' ').toLowerCase();
    if (goals.contains('perder') ||
        goals.contains('fat loss') ||
        goals.contains('defin')) {
      calories *= 0.9;
    } else if (goals.contains('ganar') ||
        goals.contains('muscle') ||
        goals.contains('masa')) {
      calories *= 1.08;
    }

    final healthCalories = input.health?.activeCalories;
    if (healthCalories != null && healthCalories > 500) {
      calories += 150;
    }
    final recovery = input.recovery;
    if (recovery != null && (recovery.stress > 65 || recovery.recovery < 45)) {
      calories += 100;
    }

    final protein = weight != null ? (weight * 1.9).round() : 140;
    return {
      'target_calories': calories.round(),
      'target_protein_g': protein,
      'snack_hint': calories >= 2400 ||
          (recovery != null &&
              (recovery.stress > 65 || recovery.recovery < 45)),
    };
  }

  DailyMealPlan _fallbackPlan({
    required DailyMealInput input,
    required List<_FoodOption> foodOptions,
    required String rawText,
  }) {
    final targets = _estimateTargets(input);
    final shouldSnack = targets['snack_hint'] == true;
    final meals = <DailyMeal>[
      _fallbackMeal('breakfast', foodOptions),
      _fallbackMeal('lunch', foodOptions),
      _fallbackMeal('dinner', foodOptions),
      if (shouldSnack) _fallbackMeal('snack', foodOptions),
    ];

    return DailyMealPlan(
      summary:
          'Plan generado con la base local de comidas y ajustado al contexto disponible.',
      targetCalories: targets['target_calories'] as int,
      targetProteinGrams: targets['target_protein_g'] as int,
      meals: meals,
      rawText: rawText,
    );
  }

  DailyMeal _fallbackMeal(String category, List<_FoodOption> foodOptions) {
    final option = foodOptions
        .where((o) => o.category == category)
        .fold<_FoodOption?>(null, (best, current) {
      if (best == null) return current;
      return current.proteinGrams > best.proteinGrams ? current : best;
    });

    final food = option ?? foodOptions.first;
    final type = DailyMealType.values.firstWhere(
      (e) => e.name == category,
      orElse: () => DailyMealType.snack,
    );
    return DailyMeal(
      type: type,
      title: _titleForCategory(category),
      name: food.name,
      calories: food.calories,
      proteinGrams: food.proteinGrams,
      carbsGrams: food.carbsGrams,
      fatGrams: food.fatGrams,
      ingredients: food.ingredients,
      reason: 'Seleccionado por aporte proteico y macros consistentes.',
      sourceIds: [food.id],
    );
  }

  String _titleForCategory(String category) {
    switch (category) {
      case 'breakfast':
        return 'Desayuno';
      case 'lunch':
        return 'Almuerzo';
      case 'dinner':
        return 'Cena';
      case 'snack':
        return 'Snack';
      default:
        return 'Comida';
    }
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _loadedModelPath = null;
  }
}

class _FoodOption {
  const _FoodOption({
    required this.id,
    required this.category,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.ingredients,
  });

  final String id;
  final String category;
  final String name;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final List<String> ingredients;

  factory _FoodOption.fromJson(Map<String, dynamic> json) {
    return _FoodOption(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      calories: _intFrom(json['calories']),
      proteinGrams: _intFrom(json['protein_g']),
      carbsGrams: _intFrom(json['carbs_g']),
      fatGrams: _intFrom(json['fat_g']),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toPromptJson() => {
        'id': id,
        'category': category,
        'name': name,
        'calories': calories,
        'protein_g': proteinGrams,
        'carbs_g': carbsGrams,
        'fat_g': fatGrams,
        'ingredients': ingredients,
      };
}

int _intFrom(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
