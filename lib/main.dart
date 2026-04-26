import 'package:IAEntrenar/features/workout/application/workups_cubit.dart';
import 'package:IAEntrenar/features/workout/infrastructure/datasources/workups_firestore_datasource.dart';
import 'package:IAEntrenar/features/workout/infrastructure/repositories/workups_firestore_repository.dart';
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
import 'features/ai_coach/infrastructure/ai_model_manager.dart';
import 'features/ai_coach/application/daily_coach_cubit.dart';
import 'features/ai_coach/application/daily_coach_state.dart';
import 'features/ai_coach/infrastructure/local_llm_coach_service.dart';
import 'features/ai_workout/application/ai_workout_cubit.dart';
import 'features/ai_workout/presentation/ai_workout_apply_sheet.dart';
import 'features/meals/application/daily_meal_plan_cubit.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es', null);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final authService = AuthService();
  final authRepository = FirebaseAuthRepository(authService);
  final workoutRepository = LocalWorkoutRepository(LocalWorkoutDataSource());
  final exerciseRepository = LocalExerciseRepository(LocalExerciseDataSource());
  final recipeRepository = LocalRecipeRepository(LocalRecipeDataSource());
  final progressRepository = LocalProgressRepository(LocalProgressDataSource());
  final metricsDataSource = FirestoreMetricsDataSource();
  final metricsRepository = FirestoreMetricsRepository(metricsDataSource);
  final workoutFirestoreDatasource = WorkupsFirestoreDatasource();
  final workoutFirestoreRepository =
      WorkupsFirestoreRepository(workoutFirestoreDatasource);

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
        Provider<WorkupsFirestoreRepository>.value(
          value: workoutFirestoreRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository: authRepository)
              ..add(const AuthStarted()),
          ),
          BlocProvider<WorkupsCubit>(
            create: (_) =>
                WorkupsCubit(workupsRepository: workoutFirestoreRepository)
                  ..loadWorkupDays(),
          ),
          BlocProvider<OnboardingCubit>(
            create: (context) =>
                OnboardingCubit(authRepository: authRepository),
          ),
          BlocProvider<WorkoutCubit>(
            create: (_) => WorkoutCubit(workoutRepository: workoutRepository)
              ..loadWorkouts(),
          ),
          BlocProvider<ExerciseCubit>(
            create: (_) => ExerciseCubit(exerciseRepository: exerciseRepository)
              ..loadInitial(),
          ),
          BlocProvider<RecipeCubit>(
            create: (_) =>
                RecipeCubit(recipeRepository: recipeRepository)..loadRecipes(),
          ),
          BlocProvider<ProgressCubit>(
            create: (_) => ProgressCubit(progressRepository: progressRepository)
              ..loadProgress(),
          ),
          BlocProvider<MetricsCubit>(
            create: (_) => MetricsCubit(repository: metricsRepository),
          ),
          BlocProvider<AiWorkoutCubit>(
            create: (_) => AiWorkoutCubit(),
          ),
          BlocProvider<DailyMealPlanCubit>(
            create: (_) => DailyMealPlanCubit(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // Prefetch del modelo IA apenas arranca la app (no bloquea UI).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // No necesitamos await aquí; queremos dispararlo y listo.
    AiModelManager.instance.ensureDownloaded().listen((_) {}, onError: (_) {});
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastShownRequestId;
  bool _sheetOpen = false;
  String? _lastShownDailyCoachCacheKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailyCoachCubit>(
      create: (_) => DailyCoachCubit(service: LocalLlmCoachService()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                prev.authenticated != curr.authenticated ||
                prev.profile?.id != curr.profile?.id,
            listener: (context, state) {
              routerNotifier.refresh();
              final userId = state.profile?.id;
              if (userId != null && userId.isNotEmpty) {
                context.read<WorkupsCubit>().loadWorkupDaysForUser(userId);
              }
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
          BlocListener<AiWorkoutCubit, AiWorkoutState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status || prev.requestId != curr.requestId,
            listener: (context, state) async {
              if (state.status != AiWorkoutStatus.ready) return;
              if (_sheetOpen) return;
              if (state.requestId == null ||
                  state.requestId == _lastShownRequestId) {
                return;
              }
              final profile = context.read<AuthBloc>().state.profile;
              if (profile == null) return;
              final current = state.current;
              final proposed = state.proposed;
              if (current == null || proposed == null) return;

              _sheetOpen = true;
              _lastShownRequestId = state.requestId;

              final sheetContext = rootNavigatorKey.currentContext;
              if (sheetContext == null) {
                _sheetOpen = false;
                return;
              }

              await showModalBottomSheet<bool>(
                context: sheetContext,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: false,
                builder: (_) {
                  return FractionallySizedBox(
                    heightFactor: 0.9,
                    child: AiWorkoutApplySheet(
                      profile: profile,
                      current: current,
                      proposed: proposed,
                    ),
                  );
                },
              );

              if (!mounted) return;
              _sheetOpen = false;
              context.read<AiWorkoutCubit>().reset();
            },
          ),
          BlocListener<DailyCoachCubit, DailyCoachState>(
            listenWhen: (prev, curr) =>
                prev.status == DailyCoachStatus.generating &&
                curr.status == DailyCoachStatus.ready,
            listener: (context, state) {
              if (state.cacheKey == null ||
                  state.cacheKey == _lastShownDailyCoachCacheKey) {
                return;
              }
              _lastShownDailyCoachCacheKey = state.cacheKey;

              final currentPath =
                  appRouter.routerDelegate.currentConfiguration.uri.path;
              if (currentPath == '/workup-day-detail') return;

              rootScaffoldMessengerKey.currentState
                ?..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Asistente del día listo'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
            },
          ),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'IA Entrenar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
        ),
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
