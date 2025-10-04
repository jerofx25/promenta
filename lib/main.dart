import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'dart:ui'; // Importar para ImageFilter

import 'firebase_options.dart';
import 'screens/fitness_tracker_screen.dart';
import 'screens/rm_calculator_screen.dart';
import 'screens/workout_list_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'utils/theme.dart';
import 'providers/exercise_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'router/router_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final authService = AuthService();
  final authRepository = FirebaseAuthRepository(authService);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: authService)),
      ],
      child: BlocProvider(
        create: (context) =>
            AuthBloc(authRepository: authRepository)..add(const AuthStarted()),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.authenticated != curr.authenticated,
      listener: (context, state) {
        routerNotifier.refresh();
      },
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
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
          height: 60,
          index: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            CurvedNavigationBarItem(
              child: Icon(
                Icons.home,
                color: Colors.white, // Color blanco para los iconos
              ),
              label: 'Home',
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
              label: 'Fitness',
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
              label: 'Weight',
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
              label: 'Menu',
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
