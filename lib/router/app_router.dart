import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/core/ui/sleek_spinner.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/onboarding/onboarding_cubit.dart';
import '../blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/features/auth/presentation/screens/login_screen.dart';
import 'package:IAEntrenar/features/auth/presentation/screens/profile_screen.dart';
import 'package:IAEntrenar/features/auth/presentation/screens/signup_screen.dart';
import 'package:IAEntrenar/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/age_selection_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/height_selection_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/weight_selection_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/injuries_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/training_goal_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/dietary_preferences_screen.dart';
import 'package:IAEntrenar/features/onboarding/presentation/screens/profile_photo_screen.dart';
import 'package:IAEntrenar/features/timer/presentation/screens/timer_screen.dart';
import 'package:IAEntrenar/features/recipes/presentation/screens/recipe_list_screen.dart';
import 'package:IAEntrenar/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:IAEntrenar/features/workout/presentation/screens/workout_detail_screen.dart';
import 'package:IAEntrenar/features/workout/presentation/screens/workout_list_screen.dart';
import 'package:IAEntrenar/features/progress/presentation/screens/fitness_tracker_screen.dart';
import 'router_notifier.dart';
import 'route_logging_observer.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: routerNotifier,
  observers: [RouteLoggingObserver()],
  redirect: (context, state) {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.state.authenticated;
    final currentLoc = state.subloc;

    final onboardingState = context.read<OnboardingCubit>().state;

    if (!isAuthenticated) {
      // Permitir rutas públicas sin autenticación
      const publicRoutes = ['/login', '/signup', '/forgot-password'];
      if (!publicRoutes.contains(currentLoc)) return '/login';
      return null;
    }

    // Si está autenticado pero aún no sabemos el estado del onboarding, mostrar loading
    if (onboardingState.status == OnboardingStatus.idle) {
      // Si el usuario acaba de autenticarse y sigue en login/signup, forzar loading
      if (currentLoc == '/login' || currentLoc == '/signup') {
        return '/';
      }
      // Permitir rutas de onboarding o forgot-password para no bloquear la navegación manual
      if (currentLoc == '/forgot-password' || currentLoc.startsWith('/onboarding')) {
        return null; // Dejar que pase a la ruta solicitada
      }
      return '/'; // Si intenta ir a /home u otra ruta protegida, forzar loading
    }

    if (onboardingState.status == OnboardingStatus.inProgress) {
      final desired = '/onboarding/step${onboardingState.currentStep}';
      final requestedOnboardingStep = _extractOnboardingStep(currentLoc);

      if (requestedOnboardingStep == null) {
        return desired;
      }

      // Permite volver a pasos anteriores, pero no saltar a uno futuro.
      if (requestedOnboardingStep > onboardingState.currentStep) {
        return desired;
      }

      return null;
    }

    // Si está autenticado y el onboarding está completo
    if (onboardingState.status == OnboardingStatus.completed) {
      if (currentLoc == '/' ||
          currentLoc == '/login' ||
          currentLoc == '/signup' ||
          currentLoc == '/forgot-password' ||
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
        body: Center(child: SleekSpinner(size: 56)),
      ),
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

    /// Ruta del Fitness Tracker (detalle de actividad)
    GoRoute(
      path: '/fitness-tracker',
      name: 'fitness-tracker',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: FitnessTrackerScreen(),
        transitionsBuilder: _slideUpTransition,
      ),
    ),

    /// Ruta de detalle de entrenamiento
    GoRoute(
      path: '/workout-detail',
      name: 'workout-detail',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: WorkoutDetailScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),

    /// Ruta de lista de entrenamientos
    GoRoute(
      path: '/workouts',
      name: 'workout-list',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: WorkoutListScreen(),
        transitionsBuilder: _slideLeftTransition,
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

int? _extractOnboardingStep(String? location) {
  if (location == null) {
    return null;
  }

  final match = RegExp(r'^/onboarding/step(\d+)$').firstMatch(location);
  if (match == null) {
    return null;
  }

  return int.tryParse(match.group(1) ?? '');
}
