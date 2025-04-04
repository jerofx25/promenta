import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_screen.dart';
import '../screens/onboarding/age_selection_screen.dart';
import '../screens/onboarding/height_selection_screen.dart';
import '../screens/onboarding/weight_selection_screen.dart';
import '../screens/onboarding/injuries_screen.dart';
import '../screens/onboarding/training_goal_screen.dart';
import '../screens/onboarding/dietary_preferences_screen.dart';
import '../screens/onboarding/profile_photo_screen.dart';
import 'router_notifier.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: routerNotifier,
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authStatus = authProvider.authStatus;
    final currentLoc = state.subloc;

    if (authStatus == AuthStatus.unauthenticated) {
      if (currentLoc != '/login') return '/login';
      return null;
    }

    if (authStatus == AuthStatus.onboarding) {
      if (!currentLoc.startsWith('/onboarding')) {
        return '/onboarding/step${authProvider.onboardingStep}';
      }
      return null;
    }

    if (authStatus == AuthStatus.authenticated) {
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
    /// Ruta raíz — evita el error de GoException
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final authStatus = authProvider.authStatus;

        if (authStatus == AuthStatus.unauthenticated) {
          return '/login';
        } else if (authStatus == AuthStatus.onboarding) {
          return '/onboarding/step${authProvider.onboardingStep}';
        } else if (authStatus == AuthStatus.authenticated) {
          return '/home';
        }
        return null;
      },
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SignupScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ForgotPasswordScreen(),
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
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AgeSelectionScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step1',
      name: 'onboarding-step1',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const HeightSelectionScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step2',
      name: 'onboarding-step2',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const WeightSelectionScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step3',
      name: 'onboarding-step3',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const InjuriesScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step4',
      name: 'onboarding-step4',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const TrainingGoalScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step5',
      name: 'onboarding-step5',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const DietaryPreferencesScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),
    GoRoute(
      path: '/onboarding/step6',
      name: 'onboarding-step6',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ProfilePhotoScreen(),
        transitionsBuilder: _slideLeftTransition,
      ),
    ),

    /// Ruta de perfil
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

class AppRouterNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

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
