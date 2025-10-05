import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../onboarding/age_selection_screen.dart';
import '../onboarding/weight_selection_screen.dart';
import '../onboarding/height_selection_screen.dart';
import '../onboarding/training_goal_screen.dart';
import '../onboarding/injuries_screen.dart';
import '../onboarding/dietary_preferences_screen.dart';
import '../onboarding/profile_photo_screen.dart';
import '../fitness_tracker_screen.dart';
import '../home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show a loading indicator while determining the auth state
        if (authProvider.authStatus == AuthStatus.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the user is authenticated, show the main app
        if (authProvider.authStatus == AuthStatus.authenticated) {
          return const HomeScreen();
        }

        // If the user is in the onboarding process, show the appropriate screen
        if (authProvider.authStatus == AuthStatus.onboarding) {
          switch (authProvider.onboardingStep) {
            case 0:
              return const AgeSelectionScreen();
            case 1:
              return const WeightSelectionScreen();
            case 2:
              return const HeightSelectionScreen();
            case 3:
              return const TrainingGoalScreen();
            case 4:
              return const InjuriesScreen();
            case 5:
              return const DietaryPreferencesScreen();
            case 6:
              return const ProfilePhotoScreen();
            default:
              return const FitnessTrackerScreen();
          }
        }

        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}
