import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  Workout? _selectedWorkout;
  
  // Filter states
  Set<WorkoutType> _selectedTypes = Set<WorkoutType>();
  DifficultyLevel? _selectedDifficulty;
  String _searchQuery = '';

  // Getters
  List<Workout> get workouts => _workouts;
  Workout? get selectedWorkout => _selectedWorkout;
  Set<WorkoutType> get selectedTypes => _selectedTypes;
  DifficultyLevel? get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;

  WorkoutProvider() {
    _loadWorkouts();
  }

  // Load workouts from SharedPreferences
  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = prefs.getStringList('workouts');
    
    if (workoutsJson == null || workoutsJson.isEmpty) {
      // Initialize with sample data if none exists
      await _initializeSampleWorkouts();
    } else {
      _workouts = workoutsJson
          .map((json) => Workout.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    }
  }

  // Save workouts to SharedPreferences
  Future<void> _saveWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsJson = _workouts
        .map((workout) => jsonEncode(workout.toJson()))
        .toList();
    
    await prefs.setStringList('workouts', workoutsJson);
  }

  // Initialize with sample workouts
  Future<void> _initializeSampleWorkouts() async {
    _workouts = [
      Workout(
        id: '1',
        name: 'Fran',
        type: WorkoutType.crossfit,
        difficulty: DifficultyLevel.intermediate,
        description: 'Uno de los benchmarks clásicos de CrossFit.',
        imageUrl: "https://pixabay.com/get/g9ba7862e30c0c935fbf38596bff0850bb54ea24470299660ea59eaf21e1aa37becd412ad603d747e99e7cbee5eb6abdaf62999d28c2c3e4772386dcb64ede5ad_1280.jpg",
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '3 rondas de: 1 minuto de saltos de cuerda',
            '10 estiramientos dinámicos de hombros',
            '10 sentadillas sin peso',
            '5 flexiones',
            '5 dominadas de práctica'
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
          exercises: ['21-15-9 reps de:', 'Thrusters (43kg/30kg)', 'Dominadas (Pull-ups)'],
          description: 'Por tiempo: Completa los ejercicios lo más rápido posible con buena técnica',
          parameters: {'Meta de tiempo': 'Menos de 7 minutos'},
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            'Colgar de la barra 30 segundos',
            'Estiramiento de hombros 1 minuto',
            'Estiramiento de cuádriceps 1 minuto',
            'Foam roller 3 minutos'
          ],
        ),
        mobilityExercises: [
          'Rotaciones de hombro con banda elástica',
          'Estiramiento de muñecas',
          'Movilidad de cadera con sentadilla profunda',
          'Extensiones torácicas con foam roller'
        ],
      ),
      Workout(
        id: '2',
        name: 'Deadlift Day',
        type: WorkoutType.powerlifting,
        difficulty: DifficultyLevel.elite,
        description: 'Día focalizado en el desarrollo de fuerza máxima en peso muerto.',
        imageUrl: "https://pixabay.com/get/g22585ea7fd5ce6065acb1a45ed510d0461716bcc8522cb431ddd7746280c8637658e35cde90e3469d89b018a75f04dd73229cfa461cfa8c78e594b95b0378176_1280.jpg",
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '5 minutos de remo o bicicleta a ritmo suave',
            '2 series de 10 buenos días sin peso',
            '2 series de 10 hip thrusts sin peso',
            '10 peso muerto rumano con barra vacía'
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
            'Foam roller para cadena posterior 5 minutos'
          ],
        ),
        mobilityExercises: [
          'Foam roller para espalda baja',
          'Extensiones de cadera en posición cuadrúpeda',
          'Rotación externa/interna de cadera',
          'Movilidad de tobillo'
        ],
      ),
      Workout(
        id: '3',
        name: 'Endurance Session',
        type: WorkoutType.endurance,
        difficulty: DifficultyLevel.basic,
        description: 'Entrenamiento para mejorar la resistencia cardiovascular y muscular.',
        imageUrl: "https://pixabay.com/get/gead97492173ea89eea74c8c6a3d54db048106d2af2c0d67fbfef55e706e0ef989c005b63cc9c634a3cb3d40d1030e786cca81a69876ce00f758ce99882aa2e79_1280.jpg",
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '5 minutos de trote suave',
            'Movilidad dinámica - 10 de cada: jumping jacks, circle arms, high knees',
            '5 burpees a ritmo lento'
          ],
        ),
        strength: WorkoutComponent(
          title: 'Circuito de Acondicionamiento',
          exercises: [
            '3 series de:',
            '15 sentadillas con peso corporal',
            '10 flexiones modificadas',
            '10 superman',
            '45 segundos de plancha',
          ],
          description: 'Descansa 1 minuto entre series',
        ),
        wod: WorkoutComponent(
          title: 'EMOM 20 minutos',
          exercises: [
            'Minuto 1: 15 mountain climbers por pierna',
            'Minuto 2: 12 sentadillas',
            'Minuto 3: 10 flexiones de rodillas',
            'Minuto 4: 10 V-ups o abdominales',
            'Minuto 5: 30 segundos de descanso'
          ],
          description: 'EMOM: Every Minute On the Minute. Completa los ejercicios prescritos en el minuto y descansa el tiempo restante.',
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            '5 minutos de caminata o trote muy suave',
            'Estiramientos estáticos: 30 segundos para cada grupo muscular principal',
            'Respiración profunda 1 minuto'
          ],
        ),
        mobilityExercises: [
          'Estiramiento dinámico de cuádriceps',
          'Rotaciones de cadera',
          'Estiramiento de pantorrillas en escalón',
          'Yoga: postura del niño'
        ],
      ),
      Workout(
        id: '4',
        name: 'Technique Day',
        type: WorkoutType.weightlifting,
        difficulty: DifficultyLevel.intermediate,
        description: 'Desarrollo de técnica en los movimientos olímpicos.',
        imageUrl: "https://pixabay.com/get/g865dccc6f0d9acd170ce318255c13a69124c4f772d50bee1d1b54120292e2666971724205db4f6e70689d9d4d8b2a27e5ada1dff9802c2c36c608595710336fc_1280.jpg",
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '3 minutos de remo suave',
            'Movilidad de hombros y tobillos',
            '10 good mornings sin peso',
            '10 overhead squats con palo'
          ],
        ),
        strength: WorkoutComponent(
          title: 'Trabajo Técnico',
          exercises: [
            'Posición de arranque - 5 series de 3 reps',
            'Arranque colgante - 5 series de 3 reps',
            'Arranque completo - 7 series de 2 reps',
          ],
          description: 'Enfócate en la posición y la velocidad. Intensidad: 65-75% de tu máximo',
        ),
        wod: WorkoutComponent(
          title: 'Complejo Técnico',
          exercises: [
            '5 series del complejo:',
            '1 Arranque colgante + 1 Overhead squat + 1 Sentadilla frontal + 1 Push press',
          ],
          description: 'Usa un peso moderado que permita buena técnica',
          parameters: {'Descanso': '2 minutos entre series'},
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            'Colgarse de la barra 2 series de 30 segundos',
            'Estiramiento de hombros, muñecas y tobillos',
            'Foam roller para cuádriceps y espalda'
          ],
        ),
        mobilityExercises: [
          'Estiramientos de muñeca con la palma hacia abajo y arriba',
          'Pase inferior con banda para movilidad de hombros',
          'Sentadilla profunda sostenida',
          'Extensión de cadera y tobillo'
        ],
      ),
      Workout(
        id: '5',
        name: 'Hypertrophy Focus',
        type: WorkoutType.bodybuilding,
        difficulty: DifficultyLevel.basic,
        description: 'Rutina enfocada en hipertrofia para pecho y espalda.',
        imageUrl: "https://pixabay.com/get/g248b8205514067dd2eacedbd20cfbca8338b2ce92b450c65e150c31f0bddc6bdc0709da5ab1dcac2c7d3d09a06f60aadcfaba21ce3ecd27c2885c3a9845db52f_1280.jpg",
        warmup: WorkoutComponent(
          title: 'Calentamiento',
          exercises: [
            '5 minutos de cardio ligero (bicicleta o elíptica)',
            '15 rotaciones de hombro',
            '15 bird dogs por lado',
            '10 push-ups con rango de movimiento parcial a completo'
          ],
        ),
        strength: WorkoutComponent(
          title: 'Trabajo Principal',
          exercises: [
            'Press de banca - 4 series de 8-10 reps',
            'Remo con barra - 4 series de 8-10 reps',
            'Press inclinado con mancuernas - 3 series de 10-12 reps',
            'Jalón al pecho agarre cerrado - 3 series de 10-12 reps',
          ],
          description: 'Usa un peso que te permita completar las repeticiones con buena técnica pero que sea desafiante',
          parameters: {'Descanso': '60-90 segundos entre series'},
        ),
        wod: WorkoutComponent(
          title: 'Trabajo de Volumen',
          exercises: [
            'Superseries (3 rondas):',
            'Aperturas con mancuernas - 12-15 reps',
            'Remo con mancuerna a una mano - 12-15 reps por lado',
            'Fondos (asistidos si es necesario) - máximas repeticiones',
            'Pull-ups (asistidos si es necesario) - máximas repeticiones',
          ],
          description: 'Mínimo descanso entre ejercicios, 2 minutos entre rondas completas',
        ),
        cooldown: WorkoutComponent(
          title: 'Vuelta a la calma',
          exercises: [
            'Estiramientos de pecho contra pared - 2 x 30 segundos',
            'Colgarse de barra para descomprimir columna - 30 segundos',
            'Estiramientos de dorsal con brazo extendido - 2 x 30 segundos por lado'
          ],
        ),
        mobilityExercises: [
          'Foam roller para espalda superior',
          'Aperturas de pecho con banda elástica',
          'Face pulls con banda para movilidad de hombros',
          'Cat-cow para movilidad de columna'
        ],
      ),
    ];

    await _saveWorkouts();
    notifyListeners();
  }

  // Set the selected workout
  void selectWorkout(String id) {
    _selectedWorkout = _workouts.firstWhere(
      (workout) => workout.id == id,
      orElse: () => _workouts.first,
    );
    notifyListeners();
  }

  // Update filter for workout types
  void toggleWorkoutType(WorkoutType type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    notifyListeners();
  }

  // Reset workout type filters
  void resetTypeFilters() {
    _selectedTypes.clear();
    notifyListeners();
  }

  // Set difficulty filter
  void setDifficultyFilter(DifficultyLevel? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Get filtered workouts
  List<Workout> getFilteredWorkouts() {
    return _workouts.where((workout) {
      // Filter by type if any types are selected
      bool matchesType = _selectedTypes.isEmpty || _selectedTypes.contains(workout.type);
      
      // Filter by difficulty if selected
      bool matchesDifficulty = _selectedDifficulty == null || workout.difficulty == _selectedDifficulty;
      
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          workout.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesType && matchesDifficulty && matchesSearch;
    }).toList();
  }
}