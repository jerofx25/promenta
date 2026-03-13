import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

import 'core/ui/alerts.dart';
import 'core/ui/pending_profile_snackbar.dart';
import 'firebase_options.dart';
import 'package:IAEntrenar/features/progress/presentation/screens/fitness_tracker_screen.dart';
import 'package:IAEntrenar/features/workout/presentation/screens/rm_calculator_screen.dart';
import 'package:IAEntrenar/features/workout/presentation/screens/workout_list_screen.dart';
import 'package:IAEntrenar/features/recipes/presentation/screens/recipe_list_screen.dart';
import 'utils/theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/onboarding/onboarding_cubit.dart';
import 'blocs/onboarding/onboarding_state.dart';
import 'router/router_notifier.dart';
import 'features/workout/domain/repositories/workout_repository.dart';
import 'features/workout/domain/repositories/exercise_repository.dart';
import 'features/workout/infrastructure/datasources/local_workout_datasource.dart';
import 'features/workout/infrastructure/datasources/local_exercise_datasource.dart';
import 'features/workout/infrastructure/repositories/local_workout_repository.dart';
import 'features/workout/infrastructure/repositories/local_exercise_repository.dart';
import 'features/workout/application/workout_cubit.dart';
import 'features/workout/application/exercise_cubit.dart';
import 'features/recipes/domain/repositories/recipe_repository.dart';
import 'features/recipes/infrastructure/datasources/local_recipe_datasource.dart';
import 'features/recipes/infrastructure/repositories/local_recipe_repository.dart';
import 'features/recipes/application/recipe_cubit.dart';
import 'features/progress/domain/repositories/progress_repository.dart';
import 'features/progress/infrastructure/datasources/local_progress_datasource.dart';
import 'features/progress/infrastructure/repositories/local_progress_repository.dart';
import 'features/progress/application/progress_cubit.dart';
import 'features/metrics/domain/repositories/metrics_repository.dart';
import 'features/metrics/data/datasources/firestore_metrics_datasource.dart';
import 'features/metrics/data/repositories/firestore_metrics_repository.dart';
import 'features/metrics/application/metrics_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final authService = AuthService();
  final authRepository = FirebaseAuthRepository(authService);
  final workoutRepository =
      LocalWorkoutRepository(LocalWorkoutDataSource());
  final exerciseRepository =
      LocalExerciseRepository(LocalExerciseDataSource());
  final recipeRepository =
      LocalRecipeRepository(LocalRecipeDataSource());
  final progressRepository =
      LocalProgressRepository(LocalProgressDataSource());
  final metricsDataSource = FirestoreMetricsDataSource();
  final metricsRepository = FirestoreMetricsRepository(metricsDataSource);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<WorkoutRepository>.value(value: workoutRepository),
        Provider<ExerciseRepository>.value(value: exerciseRepository),
        Provider<RecipeRepository>.value(value: recipeRepository),
        Provider<ProgressRepository>.value(value: progressRepository),
        Provider<MetricsRepository>.value(value: metricsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository: authRepository)
              ..add(const AuthStarted()),
          ),
          BlocProvider<OnboardingCubit>(
            create: (context) =>
                OnboardingCubit(authRepository: authRepository),
          ),
          BlocProvider<WorkoutCubit>(
            create: (_) =>
                WorkoutCubit(workoutRepository: workoutRepository)
                  ..loadWorkouts(),
          ),
          BlocProvider<ExerciseCubit>(
            create: (_) =>
                ExerciseCubit(exerciseRepository: exerciseRepository)
                  ..loadInitial(),
          ),
          BlocProvider<RecipeCubit>(
            create: (_) =>
                RecipeCubit(recipeRepository: recipeRepository)
                  ..loadRecipes(),
          ),
          BlocProvider<ProgressCubit>(
            create: (_) =>
                ProgressCubit(progressRepository: progressRepository)
                  ..loadProgress(),
          ),
          BlocProvider<MetricsCubit>(
            create: (_) => MetricsCubit(repository: metricsRepository),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.authenticated != curr.authenticated,
          listener: (context, state) {
            routerNotifier.refresh();
          },
        ),
        BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.currentStep != curr.currentStep,
          listener: (context, state) {
            routerNotifier.refresh();
          },
        ),
      ],
      child: MaterialApp.router(
          title: 'IA Entrenar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
        ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (consumeProfileCompletedSnackBarPending()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppAlerts.showSuccessAtBottom(
          context,
          'Perfil completado correctamente',
          durationSeconds: 4,
        );
      });
    }
  }

  final List<Widget> _screens = [
    const FitnessTrackerScreen(),
    const WorkoutListScreen(),
    const RMCalculatorScreen(),
    const RecipeListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final mediaQueryPadding = MediaQuery.of(context).padding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
      child: Scaffold(
        body: _screens[_currentIndex],
        extendBody: true,
        // Barra de navegación con estilo curvo (sin efecto flotante y sin transparencia)
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor:
              Colors.transparent, // Fondo transparente para extendBody
          color: theme.colorScheme.primary
              .withOpacity(0.8), // Color primario para mejor contraste
          buttonBackgroundColor: theme.colorScheme
              .primary, // Mismo color pero sólido para el botón seleccionado
          height: 75,
          index: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            CurvedNavigationBarItem(
              child: Icon(
                Icons.home,
                color: Colors.white, // Color blanco para los iconos
              ),
              label: 'Tracker',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold, // Hacer el texto más visible
              ),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                Icons.fitness_center,
                color: Colors.white,
              ),
              label: 'Program',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                Icons.monitor_weight,
                color: Colors.white,
              ),
              label: 'You vs You',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            CurvedNavigationBarItem(
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.white,
              ),
              label: 'Meal',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }
}
