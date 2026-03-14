import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/workout.dart';

class LocalWorkoutDataSource {
  static const _storageKey = 'workouts';

  Future<List<Workout>> loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList(_storageKey);

    if (workoutsJson == null || workoutsJson.isEmpty) {
      final seed = _buildSampleWorkouts();
      await saveWorkouts(seed);
      return seed;
    }

    return workoutsJson
        .map((json) => Workout.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveWorkouts(List<Workout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson =
        workouts.map((workout) => jsonEncode(workout.toJson())).toList();
    await prefs.setStringList(_storageKey, workoutsJson);
  }

  List<Workout> _buildSampleWorkouts() {
    return [
      Workout(
        id: '1',
        name: 'Fran',
        type: WorkoutType.crossfit,
        difficulty: DifficultyLevel.intermediate,
        description: 'Uno de los benchmarks clásicos de CrossFit.',
        imageUrl:
            'https://pixabay.com/get/g9ba7862e30c0c935fbf38596bff0850bb54ea24470299660ea59eaf21e1aa37becd412ad603d747e99e7cbee5eb6abdaf62999d28c2c3e4772386dcb64ede5ad_1280.jpg',
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '3 rondas de: 1 minuto de saltos de cuerda',
            '10 estiramientos dinámicos de hombros',
            '10 sentadillas sin peso',
            '5 flexiones',
            '5 dominadas de práctica',
          ],
          description: 'Completa todos los ejercicios a un ritmo moderado',
        ),
        strength: WorkoutComponent(
          title: 'Trabajo de Fuerza',
          exercises: [
            'Ejercicios de técnica de Thrusters - 3 series de 5 reps (barra vacía)',
            'Dominadas de práctica - 3 series de 5 reps',
          ],
          description: 'Enfócate en la técnica correcta y la respiración',
        ),
        wod: WorkoutComponent(
          title: 'WOD',
          exercises: [
            '21-15-9 reps de:',
            'Thrusters (43kg/30kg)',
            'Dominadas (Pull-ups)',
          ],
          description:
              'Por tiempo: Completa los ejercicios lo más rápido posible con buena técnica',
          parameters: {'Meta de tiempo': 'Menos de 7 minutos'},
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            'Colgar de la barra 30 segundos',
            'Estiramiento de hombros 1 minuto',
            'Estiramiento de cuádriceps 1 minuto',
            'Foam roller 3 minutos',
          ],
        ),
        mobilityExercises: [
          'Rotaciones de hombro con banda elástica',
          'Estiramiento de muñecas',
          'Movilidad de cadera con sentadilla profunda',
          'Extensiones torácicas con foam roller',
        ],
      ),
      // Resto de workouts copiados de WorkoutProvider._initializeSampleWorkouts
      Workout(
        id: '2',
        name: 'Deadlift Day',
        type: WorkoutType.powerlifting,
        difficulty: DifficultyLevel.elite,
        description:
            'Día focalizado en el desarrollo de fuerza máxima en peso muerto.',
        imageUrl:
            'https://pixabay.com/get/g22585ea7fd5ce6065acb1a45ed510d0461716bcc8522cb431ddd7746280c8637658e35cde90e3469d89b018a75f04dd73229cfa461cfa8c78e594b95b0378176_1280.jpg',
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '5 minutos de remo o bicicleta a ritmo suave',
            '2 series de 10 buenos días sin peso',
            '2 series de 10 hip thrusts sin peso',
            '10 peso muerto rumano con barra vacía',
          ],
        ),
        strength: WorkoutComponent(
          title: 'Trabajo de Fuerza',
          exercises: [
            'Peso Muerto - 5 series: 5 reps al 70%, 3 reps al 80%, 2 reps al 85%, 1 rep al 90%, 1 rep al 95%',
            'Peso Muerto Rumano - 3 series de 8 reps al 65%',
          ],
          description: 'Descansa 3-5 minutos entre series pesadas',
        ),
        wod: WorkoutComponent(
          title: 'Trabajo Complementario',
          exercises: [
            'Remo con barra pendlay - 4 series de 8 reps',
            'Hip thrust con barra - 3 series de 12 reps',
            'Peso muerto con piernas rígidas - 3 series de 10 reps',
          ],
          parameters: {'Intensidad': '70-75% de tu máximo'},
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            'Estiramiento de isquiotibiales 2 minutos',
            'Estiramiento de espalda baja 2 minutos',
            'Foam roller para cadena posterior 5 minutos',
          ],
        ),
        mobilityExercises: [
          'Foam roller para espalda baja',
          'Extensiones de cadera en posición cuadrúpeda',
          'Rotación externa/interna de cadera',
          'Movilidad de tobillo',
        ],
      ),
      // Por brevedad aquí mostramos solo dos; en tu código real
      // puedes mantener la lista completa de ejemplo.
    ];
  }
}


