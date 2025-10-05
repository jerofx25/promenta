import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../blocs/auth/auth_bloc.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/age_selection_screen.dart';
import '../screens/onboarding/height_selection_screen.dart';
import '../screens/onboarding/weight_selection_screen.dart';
import '../screens/onboarding/injuries_screen.dart';
import '../screens/onboarding/training_goal_screen.dart';
import '../screens/onboarding/dietary_preferences_screen.dart';
import '../screens/onboarding/profile_photo_screen.dart';
import '../screens/timer_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/recipe_list_screen.dart';
import '../screens/recipe_detail_screen.dart';
import 'router_notifier.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: routerNotifier,
  redirect: (context, state) {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.state.authenticated;
    final currentLoc = state.subloc;

    // Onboarding se mantiene con AuthProvider mientras migramos gradualmente
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authStatus = authProvider.authStatus;

    if (!isAuthenticated) {
      // Permitir rutas públicas sin autenticación
      const publicRoutes = ['/login', '/signup', '/forgot-password'];
      if (!publicRoutes.contains(currentLoc)) return '/login';
      return null;
    }

    if (authStatus == AuthStatus.onboarding) {
      final desired = '/onboarding/step${authProvider.onboardingStep}';
      if (!currentLoc.startsWith('/onboarding')) {
        return desired;
      }
      // Si ya estamos en onboarding pero en un paso distinto, redirigir al paso correcto
      if (currentLoc != desired) {
        return desired;
      }
      return null;
    }

    if (isAuthenticated) {
      if (currentLoc == '/' ||
          currentLoc == '/login' ||
          currentLoc.startsWith('/onboarding')) {
        return '/home';
      }
      return null;
    }

    return null;
  },
  routes: [
    /// Ruta raíz — necesita un builder aunque tenga redirect
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text("Loading...")),
      ),
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final authStatus = authProvider.authStatus;
        final isAuthenticated = context.read<AuthBloc>().state.authenticated;

        if (!isAuthenticated) {
          return '/login';
        } else if (authStatus == AuthStatus.onboarding) {
          return '/onboarding/step${authProvider.onboardingStep}';
        } else if (isAuthenticated) {
          return '/home';
        }
        return null;
      },
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: LoginScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SignupScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: ForgotPasswordScreen(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    /// Ruta principal después del login
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainScreen(),
    ),

    /// Onboarding
    GoRoute(
      path: '/onboarding/step0',
      name: 'onboarding-step0',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AgeSelectionScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step1',
      name: 'onboarding-step1',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: HeightSelectionScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step2',
      name: 'onboarding-step2',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: WeightSelectionScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step3',
      name: 'onboarding-step3',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: InjuriesScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step4',
      name: 'onboarding-step4',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: TrainingGoalScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step5',
      name: 'onboarding-step5',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: DietaryPreferencesScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step6',
      name: 'onboarding-step6',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: ProfilePhotoScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),

    /// Ruta de perfil
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    /// Ruta del Timer
    GoRoute(
      path: '/timer',
      name: 'timer',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: TimerScreen(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    /// Ruta del Dashboard de Progreso
    GoRoute(
      path: '/progress',
      name: 'progress',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: ProgressDashboardScreen(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    /// Rutas de Recetas
    GoRoute(
      path: '/recipes',
      name: 'recipe-list',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: RecipeListScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/recipe-detail',
      name: 'recipe-detail',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: RecipeDetailScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
  ],
);

/// Transiciones
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideLeftTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}
