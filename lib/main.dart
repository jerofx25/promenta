import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

import 'screens/fitness_tracker_screen.dart';
import 'screens/rm_calculator_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/workout_list_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'screens/progress_dashboard_screen.dart';
import 'utils/theme.dart';
import 'providers/exercise_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'router/router_notifier.dart'; // ✅ Importamos el notifier global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            final authProvider = AuthProvider();
            authProvider.setRouterNotifier(routerNotifier); // ✅ Correcto
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Fitness Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter, // ✅ Usa GoRouter correctamente
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FitnessTrackerScreen(),
    const WorkoutListScreen(),
    const RMCalculatorScreen(),
    const TimerScreen(),
    const RecipeListScreen(),
    const ProgressDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        height: 60.0,
        backgroundColor: Colors.transparent,
        color: theme.colorScheme.surface,
        buttonBackgroundColor: theme.colorScheme.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          _navItem(Icons.home_outlined, 'Home', 0),
          _navItem(Icons.fitness_center_outlined, 'Rutinas', 1),
          _navItem(Icons.monitor_weight_outlined, 'Calculadora', 2),
          _navItem(Icons.timer_outlined, 'Timer', 3),
          _navItem(Icons.restaurant_menu_outlined, 'Recetas', 4),
          _navItem(Icons.bar_chart_outlined, 'Progreso', 5),
        ],
      ),
    );
  }

  CurvedNavigationBarItem _navItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    return CurvedNavigationBarItem(
      child: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onBackground.withOpacity(0.7),
      ),
      label: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.onBackground.withOpacity(0.7),
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
